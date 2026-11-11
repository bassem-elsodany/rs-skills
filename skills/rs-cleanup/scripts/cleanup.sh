#!/usr/bin/env bash
# cleanup — give back the disk your builds and containers took. DRY-RUN unless you say `apply`.
#
#   cleanup.sh plan  [dir] [--tier safe|more|all] [--volumes] [--keep-days N]
#   cleanup.sh apply [dir] [--tier safe|more|all] [--volumes] [--keep-days N]
#
# Tiers (each includes the one before):
#   safe  regenerable things only:
#           - Cargo: `cargo sweep --time N` on every target/ under dir (needs cargo-sweep); otherwise
#             removes only target/*/incremental and reports the full-clean command
#           - Docker: stopped containers carrying label rs-skills.created-by=agent, dangling images, build cache older than 24h
#   more  + Cargo targets still over budget -> `cargo clean` (rebuild cost: minutes, not data)
#         + Docker images not used by any container and older than N days (they must be re-pulled or rebuilt)
#   all   + Docker images built by the agent (label rs-skills.created-by=agent), all of them
# Volumes hold data (databases!). They are listed, never removed, unless you add --volumes, and then only
# anonymous dangling volumes (`docker volume prune`, never -a).
#
# Never touched: running containers, named volumes, anything outside dir's target/ dirs and Docker's own prune sets.
# Env: RS_TARGET_BUDGET_GB=15  RS_KEEP_DAYS=7
set -uo pipefail
ACTION="${1:-plan}"; shift || true
DIR="$PWD"; TIER=safe; VOLUMES=0; KEEP="${RS_KEEP_DAYS:-7}"; BUDGET="${RS_TARGET_BUDGET_GB:-15}"
while [[ $# -gt 0 ]]; do case "$1" in
  --tier) TIER="$2"; shift 2;; --volumes) VOLUMES=1; shift;; --keep-days) KEEP="$2"; shift 2;;
  *) DIR="$1"; shift;; esac; done
[[ "$ACTION" == plan || "$ACTION" == apply ]] || { sed -n 2,22p "$0"; exit 2; }
case "$TIER" in safe|more|all) ;; *) echo "tier must be safe|more|all" >&2; exit 2;; esac
APPLY=0; [[ "$ACTION" == apply ]] && APPLY=1
tt() { local s="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@" 2>/dev/null; }
free_kb() { df -Pk "$DIR" 2>/dev/null | awk 'NR==2{print $4}'; }
gb() { awk -v k="$1" 'BEGIN{printf "%.1f", k/1048576}'; }
LABEL="rs-skills.created-by=agent"

run() { # run <description> <cmd...>
  local d="$1"; shift
  if (( APPLY )); then echo "  [apply] $d"; "$@" 2>&1 | sed 's/^/          /'; else echo "  [plan]  $d"; echo "          \$ $*"; fi
}
docker_up() { command -v docker >/dev/null 2>&1 && tt 6 docker info >/dev/null 2>&1; }
targets() { find "$DIR" -maxdepth 6 \( -name node_modules -o -name .git \) -prune -o -type d -name target -prune -print 2>/dev/null \
            | while read -r t; do [[ -f "$(dirname "$t")/Cargo.toml" ]] && echo "$t"; done; }

before=$(free_kb); before=${before:-0}
echo "== rs-cleanup ${ACTION} (tier=${TIER}, dir=${DIR}) =="; (( APPLY )) || echo "   dry run: nothing is deleted. Re-run with \`apply\` to execute."

echo; echo "-- Cargo --"
have_sweep=0; command -v cargo-sweep >/dev/null 2>&1 && have_sweep=1
while IFS= read -r t; do
  [[ -z "$t" ]] && continue
  proj="$(dirname "$t")"; kb=$(tt 25 du -sk "$t" | awk '{print $1}'); kb=${kb:-0}
  printf "  %8s GiB  %s\n" "$(gb "$kb")" "$t"
  if (( have_sweep )); then
    run "cargo sweep --time $KEEP (drop artifacts unused for $KEEP days)" bash -c "cd '$proj' && cargo sweep --time $KEEP"
  else
    for inc in "$t"/*/incremental; do [[ -d "$inc" ]] && run "remove incremental cache $inc" rm -rf "$inc"; done
    (( kb > BUDGET * 1048576 )) && echo "          hint: cargo install cargo-sweep   (prunes stale hashed artifacts without a full rebuild)"
  fi
  if [[ "$TIER" != safe ]] && (( kb > BUDGET * 1048576 )); then
    run "target over ${BUDGET} GiB budget -> cargo clean" bash -c "cd '$proj' && cargo clean"
  fi
done < <(targets)

echo; echo "-- Docker --"
if docker_up; then
  docker system df 2>/dev/null | sed 's/^/  /'
  run "remove stopped containers labelled $LABEL" docker container prune -f --filter "label=$LABEL"
  run "remove dangling images (untagged build leftovers)" docker image prune -f
  run "remove build cache older than 24h" docker builder prune -f --filter until=24h
  if [[ "$TIER" != safe ]]; then
    run "remove images unused by any container and older than ${KEEP} days" docker image prune -a -f --filter "until=$((KEEP * 24))h"
  fi
  if [[ "$TIER" == all ]]; then
    run "remove ALL images labelled $LABEL" docker image prune -a -f --filter "label=$LABEL"
  fi
  nv=$(docker volume ls -f dangling=true -q 2>/dev/null | wc -l | tr -d ' ')
  echo "  volumes (data!): $nv dangling volume(s) — list with: docker volume ls -f dangling=true"
  if (( VOLUMES )); then
    echo "  --volumes given: pruning anonymous dangling volumes only"
    run "docker volume prune (anonymous volumes not used by any container)" docker volume prune -f
  else
    echo "  (not touched — add --volumes to prune anonymous dangling volumes; named volumes are never pruned here)"
  fi
else
  echo "  docker not installed or daemon not running — skipped"
fi

after=$(free_kb); after=${after:-0}
echo; if (( APPLY )); then echo "== reclaimed: $(gb $((after - before))) GiB (free now $(gb "$after") GiB) =="; echo "Report this in your answer (\"Cleanup report\": created, removed, reclaimed)."
else echo "== free now $(gb "$before") GiB; run again with \`apply\` to execute the lines marked [plan] =="; fi
