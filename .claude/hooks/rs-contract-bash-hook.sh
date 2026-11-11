#!/usr/bin/env bash
# PostToolUse hook (Bash): edits made through shell commands (sed -i, python, heredocs)
# bypass the Write/Edit contract hook. After a Bash call that touched Rust sources,
# check every changed .rs file in the current git work tree for a Design Contract.
set -uo pipefail
input=$(cat)
# fast path: this hook runs after EVERY Bash call — leave immediately unless the raw input mentions Rust sources
case "$input" in *.rs*|*src/*) ;; *) exit 0 ;; esac
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)
# Only shell commands that can write files and mention Rust sources.
[[ "$cmd" =~ \.rs|src/ ]] || exit 0
[[ "$cmd" =~ (sed[[:space:]]+-i|python|>[[:space:]]*[^&]|tee|git[[:space:]]+mv|cp[[:space:]]|mv[[:space:]]|cat[[:space:]]*>) ]] || exit 0
top=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
changed=$( { git -C "$top" diff --name-only --diff-filter=AMR; git -C "$top" ls-files --others --exclude-standard; } 2>/dev/null \
  | grep -E '(^|/)src/.*\.rs$' | grep -v '/target/' | sort -u)
[[ -z "$changed" ]] && exit 0
missing=""
while IFS= read -r rel; do
  f="$top/$rel"; [[ -f "$f" ]] || continue
  printf '{"tool_input":{"file_path":"%s"}}' "$f" | bash "$(dirname "${BASH_SOURCE[0]}")/rs-contract-hook.sh" 2>/dev/null || missing+="  $rel"$'\n'
done <<< "$changed"
[[ -z "$missing" ]] && exit 0
cat >&2 <<MSG
rs-skills: these changed Rust files have no Design Contract (edited via a shell command):
$missing Add a \`//! # Design Contract\` block to each — see Skill(rs-design-contract).
MSG
exit 2
