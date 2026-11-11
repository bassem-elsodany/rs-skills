#!/usr/bin/env bash
# PreToolUse hook (Bash): protect the disk and the user's data.
#  1. heavy builds (cargo build/test/…, docker build, compose up) -> deny when free space < RS_MIN_FREE_GB (default 10)
#  2. destructive Docker commands that can delete DATA (volumes, prune -a) -> ask the user, never run silently
# Silent and instant (one `df`) otherwise. Disable with RS_DISK_GUARD=off.
set -uo pipefail
[[ "${RS_DISK_GUARD:-on}" == off ]] && exit 0
input=$(cat)
# fast path: this hook runs before EVERY Bash call — leave in microseconds unless the raw input mentions something it guards
case "$input" in *cargo*|*docker*|*wasm-pack*|*trunk*) ;; *) exit 0 ;; esac
P="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cmd=$(printf '%s' "$input" | python3 -I -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)
[[ -z "$cmd" ]] && exit 0

emit() { # emit <decision> <reason>
  python3 -I -c 'import json,sys; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":sys.argv[1],"permissionDecisionReason":sys.argv[2]}}))' "$1" "$2"
}

# 2. data-destroying Docker commands
if [[ "$cmd" =~ docker[[:space:]]+(system[[:space:]]+prune.*(--volumes|-a|--all)|volume[[:space:]]+(rm|prune.*(-a|--all))|(rm|container[[:space:]]+rm)[[:space:]].*-v|compose[[:space:]]+down.*(-v|--volumes)) ]] \
   || [[ "$cmd" =~ docker-compose[[:space:]]+down.*(-v|--volumes) ]]; then
  emit ask "rs-cleanup: this Docker command can delete volumes or every unused image — volumes hold databases and other user data. Prefer $P/skills/rs-cleanup/scripts/cleanup.sh plan (tiered, labelled, volumes only with --volumes). Confirm only if the user asked for exactly this."
  exit 0
fi

# 1. heavy builds
if [[ "$cmd" =~ (^|[\;\&\|[:space:]])(cargo[[:space:]]+(build|test|bench|install|doc|llvm-cov|nextest|miri|fuzz)|docker([[:space:]]+buildx)?[[:space:]]+build|docker[[:space:]]+compose[[:space:]]+(build|up)|docker-compose[[:space:]]+(build|up)|wasm-pack|trunk[[:space:]]+build) ]]; then
  min="${RS_MIN_FREE_GB:-10}"
  free_kb=$(df -Pk "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null | awk 'NR==2{print $4}')
  [[ -z "$free_kb" ]] && exit 0
  if (( free_kb < min * 1048576 )); then
    free_gb=$(awk -v k="$free_kb" 'BEGIN{printf "%.1f", k/1048576}')
    emit deny "rs-cleanup: only ${free_gb} GiB free (< ${min} GiB). Do not start another build. Run $P/skills/rs-cleanup/scripts/disk-guard.sh status, then cleanup.sh plan and apply (safe tier), report what was removed, then retry."
    exit 0
  fi
fi
exit 0
