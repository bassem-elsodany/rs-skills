#!/usr/bin/env bash
# disk-guard — what are my builds and containers costing, and is there room to continue?
#
#   disk-guard.sh status    [dir]   report: free space, every Cargo target/ under dir, cargo+rustup caches, Docker usage
#   disk-guard.sh preflight [dir]   exit 1 when free space < RS_MIN_FREE_GB — run before a heavy build / image build
#   disk-guard.sh over      [dir]   exit 1 when a budget below is exceeded (used by the Stop hook), prints why
#
# Budgets (override with env):   RS_MIN_FREE_GB=15   RS_TARGET_BUDGET_GB=15   RS_DOCKER_BUDGET_GB=25
# Read-only. Works with macOS bash 3.2 (no associative arrays, no GNU timeout).
set -uo pipefail

MODE="${1:-status}"; DIR="${2:-$PWD}"
MIN_FREE="${RS_MIN_FREE_GB:-15}"; T_BUDGET="${RS_TARGET_BUDGET_GB:-15}"; D_BUDGET="${RS_DOCKER_BUDGET_GB:-25}"

# portable timeout: tt SECONDS cmd args...
tt() { local s="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@" 2>/dev/null; }
gb()  { awk -v k="$1" 'BEGIN{printf "%.1f", k/1048576}'; }          # KiB -> GiB
free_kb() { df -Pk "$1" 2>/dev/null | awk 'NR==2{print $4}'; }

# Cargo target dirs below DIR (depth-limited, never descends into a target/ or node_modules/)
target_dirs() {
  find "$DIR" -maxdepth 6 \( -name node_modules -o -name .git \) -prune -o -type d -name target -prune -print 2>/dev/null \
  | while read -r t; do [[ -f "$(dirname "$t")/Cargo.toml" ]] && echo "$t"; done
}
size_kb() { tt "${2:-25}" du -sk "$1" | awk '{print $1}'; }

docker_up() { command -v docker >/dev/null 2>&1 && tt 6 docker info >/dev/null 2>&1; }
# docker df line for a type -> "size reclaimable" as KiB, best effort
docker_df() {
  tt 20 docker system df --format '{{.Type}}|{{.Size}}|{{.Reclaimable}}' 2>/dev/null
}
to_kb() { # "12.3GB" / "512MB" / "39.23MB (17%)" -> KiB
  echo "$1" | awk '{v=$1; u=v; gsub(/[0-9.]/,"",u); sub(u"$","",v); m=1; if(u=="B")m=1/1024; else if(u=="kB"||u=="KB")m=1; else if(u=="MB")m=1024; else if(u=="GB")m=1048576; else if(u=="TB")m=1073741824; printf "%d", v*m}'
}

total_target_kb=0; docker_rec_kb=0; docker_total_kb=0
collect() {
  total_target_kb=0
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    k=$(size_kb "$t"); k=${k:-0}; total_target_kb=$((total_target_kb + k))
  done < <(target_dirs)
  if docker_up; then
    while IFS='|' read -r typ size rec; do
      [[ -z "$typ" || "$typ" == "Local Volumes" ]] && continue   # volumes hold user data: never counted as reclaimable
      docker_total_kb=$((docker_total_kb + $(to_kb "$size")))
      docker_rec_kb=$((docker_rec_kb + $(to_kb "$rec")))
    done < <(docker_df)
  fi
}

case "$MODE" in
  preflight)
    fk=$(free_kb "$DIR"); fk=${fk:-0}
    if (( fk < MIN_FREE * 1048576 )); then
      echo "disk-guard: only $(gb "$fk") GiB free (< ${MIN_FREE} GiB). Clean up before building:"
      echo "  skills/rs-cleanup/scripts/cleanup.sh plan   (then apply)"; exit 1
    fi
    echo "disk-guard: $(gb "$fk") GiB free — ok"; exit 0 ;;

  over)
    fk=$(free_kb "$DIR"); fk=${fk:-0}; collect; why=""
    (( fk < MIN_FREE * 1048576 )) && why="$why free space $(gb "$fk") GiB < ${MIN_FREE} GiB;"
    (( total_target_kb > T_BUDGET * 1048576 )) && why="$why Cargo target/ dirs $(gb "$total_target_kb") GiB > ${T_BUDGET} GiB;"
    (( docker_rec_kb > D_BUDGET * 1048576 )) && why="$why Docker reclaimable $(gb "$docker_rec_kb") GiB > ${D_BUDGET} GiB;"
    [[ -n "$why" ]] && { echo "$why"; exit 1; }; exit 0 ;;

  status)
    fk=$(free_kb "$DIR"); fk=${fk:-0}
    echo "== disk =="; df -h "$DIR" 2>/dev/null | awk 'NR==1||NR==2'
    echo; echo "== Cargo target/ directories under $DIR =="
    n=0; total=0
    while IFS= read -r t; do
      [[ -z "$t" ]] && continue
      k=$(size_kb "$t"); if [[ -z "$k" ]]; then echo "  (timed out)  $t"; continue; fi
      total=$((total + k)); n=$((n + 1)); printf "  %8s GiB  %s" "$(gb "$k")" "$t"
      files=$(tt 10 find "$t/debug/deps" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
      [[ -n "$files" && "$files" -gt 20000 ]] && printf "   <- %s files in debug/deps: stale artifacts, run cargo sweep (rs-cleanup)" "$files"
      echo
    done < <(target_dirs)
    (( n == 0 )) && echo "  none found"
    echo "  total: $(gb "$total") GiB (budget ${T_BUDGET} GiB)"
    echo; echo "== toolchain and registry caches =="
    for p in "$HOME/.cargo/registry" "$HOME/.cargo/git" "$HOME/.rustup/toolchains" "${SCCACHE_DIR:-$HOME/Library/Caches/Mozilla.sccache}" "$HOME/.cache/sccache"; do
      [[ -d "$p" ]] && printf "  %8s GiB  %s\n" "$(gb "$(size_kb "$p" 15)")" "$p"
    done
    echo; echo "== Docker =="
    if docker_up; then
      docker system df 2>/dev/null | sed 's/^/  /'
      echo "  (Volumes may hold user data — cleanup.sh never removes them without --volumes)"
    else
      echo "  docker not installed or daemon not running"
    fi
    echo
    collect
    flag=0
    (( fk < MIN_FREE * 1048576 )) && { echo "WARN free space below ${MIN_FREE} GiB"; flag=1; }
    (( total_target_kb > T_BUDGET * 1048576 )) && { echo "WARN Cargo targets exceed ${T_BUDGET} GiB -> cleanup.sh plan (cargo sweep)"; flag=1; }
    (( docker_rec_kb > D_BUDGET * 1048576 )) && { echo "WARN Docker reclaimable exceeds ${D_BUDGET} GiB -> cleanup.sh plan"; flag=1; }
    (( flag == 0 )) && echo "within budgets"; exit 0 ;;
  *) echo "usage: disk-guard.sh status|preflight|over [dir]" >&2; exit 2 ;;
esac
