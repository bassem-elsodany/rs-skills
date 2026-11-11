#!/usr/bin/env bash
# Stop hook: do not finish the session while the disk budgets are blown.
# Budgets (env): RS_MIN_FREE_GB=15  RS_TARGET_BUDGET_GB=15  RS_DOCKER_BUDGET_GB=25.  Disable: RS_DISK_GUARD=off.
# Runs only inside a Rust or Docker project, is time-boxed, and never blocks twice in a row (stop_hook_active).
set -uo pipefail
[[ "${RS_DISK_GUARD:-on}" == off ]] && exit 0
input=$(cat)
active=$(printf '%s' "$input" | python3 -I -c 'import json,sys
try: print(str(json.load(sys.stdin).get("stop_hook_active", False)).lower())
except Exception: print("false")' 2>/dev/null)
[[ "$active" == true ]] && exit 0
root="${CLAUDE_PROJECT_DIR:-$PWD}"
# only relevant where builds happen (this dir, an ancestor, or a project a few levels below)
d="$root"; found=0
while [[ "$d" != "/" ]]; do [[ -f "$d/Cargo.toml" || -f "$d/Dockerfile" || -f "$d/docker-compose.yml" || -f "$d/compose.yaml" ]] && { found=1; break; }; d="$(dirname "$d")"; done
if (( ! found )); then
  d="$root"
  [[ -n "$(find "$root" -maxdepth 3 \( -name node_modules -o -name target -o -name .git \) -prune -o \( -name Cargo.toml -o -name Dockerfile \) -print -quit 2>/dev/null)" ]] && found=1
fi
(( found )) || exit 0
plugin="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
guard="$plugin/skills/rs-cleanup/scripts/disk-guard.sh"
[[ -x "$guard" ]] || exit 0
why=$(perl -e 'alarm 40; exec @ARGV' bash "$guard" over "$d" 2>/dev/null); rc=$?
# rc 1 + a reason = over budget; a timeout or any other failure must never block the user
if [[ $rc -eq 1 && -n "$why" ]]; then
  python3 -I -c 'import json,sys; print(json.dumps({"decision":"block","reason":"rs-cleanup: disk budget exceeded — "+sys.argv[1]+" Before finishing: run "+sys.argv[2]+"/skills/rs-cleanup/scripts/disk-guard.sh status, then cleanup.sh plan and apply (safe tier; volumes are never removed without the user), and put a \"Cleanup report\" (created / removed / reclaimed) in your final answer."}))' "$why" "$plugin"
fi
exit 0
