#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): remind when a .rs file under src/ was written
# without a Design Contract block. Exit 2 feeds the message back to Claude.
set -uo pipefail
input=$(cat)
path=$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))
except Exception: print("")' 2>/dev/null)
[[ -z "$path" || "$path" != *.rs ]] && exit 0
[[ -f "$path" ]] || exit 0
[[ "$path" =~ /target/ ]] && exit 0
# exemptions are judged relative to the nearest Cargo.toml
base=$(cd "$(dirname "$path")" && pwd); d=$base; rel="$path"
while [[ "$d" != "/" ]]; do if [[ -f "$d/Cargo.toml" ]]; then r="${base#"$d"}"; r="${r#/}"; rel="${r:+$r/}$(basename "$path")"; break; fi; d=$(dirname "$d"); done
[[ "$rel" =~ (^|/)(tests|benches|examples)/ || "$rel" =~ (^|/)build\.rs$ ]] && exit 0
if head -40 "$path" | grep -q '^[[:space:]]*//! *# Design Contract'; then exit 0; fi
# pure mod.rs re-export files are exempt
if [[ "$(basename "$path")" == "mod.rs" ]] && ! grep -qvE '^[[:space:]]*(//.*|#!?\[.*\]|(pub(\([a-z]+\))? )?mod [a-z_0-9]+;|pub(\([a-z]+\))? use .*;)?[[:space:]]*$' "$path"; then exit 0; fi
cat >&2 <<MSG
rs-skills: $path has no Design Contract. Add a \`//! # Design Contract\` block at the top
(Role, Patterns, Invariants, Extend by, Skills; <=12 lines) — see Skill(rs-design-contract).
If you edited an existing file, re-read its contract and make sure the change still fits "Extend by".
MSG
exit 2
