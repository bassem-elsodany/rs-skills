#!/usr/bin/env bash
# Depth-rule integrity: every rule link resolves, ids are unique across skills,
# every rule in the compile-check manifest exists, indexes are current.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; fail=0
files=$(find "$ROOT/skills" -path '*/rules/*.md' ! -name '_*' | sort)
total=$(echo "$files" | wc -l | tr -d ' ')
missing=0; n=0
while read -r rel; do n=$((n+1)); [[ -f "$ROOT/$rel" ]] || { echo "  manifest entry missing: $rel"; missing=1; }; done < "$ROOT/checks/rule-manifest.txt"
[[ $missing -eq 0 && $n -gt 0 ]] && echo "OK  $n compile-checked rules present (of $total rule files)" || { echo "FAIL checks/rule-manifest.txt does not match the rule files"; fail=1; }
dups=$(echo "$files" | xargs -n1 basename | sort | uniq -d)
[[ -z "$dups" ]] && echo "OK  rule ids unique across skills" || { echo "FAIL duplicate rule ids:"; echo "$dups"; fail=1; }
dead=0
for f in $files; do
  for l in $(grep -oE '\]\(([^)#[:space:]]+\.md)' "$f" | sed 's/^](//'); do
    [[ "$l" == http* ]] && continue
    [[ -e "$(dirname "$f")/$l" ]] || { echo "  dead link in ${f#$ROOT/}: $l"; dead=1; }
  done
done
[[ $dead -eq 0 ]] && echo "OK  all rule-to-rule links resolve" || fail=1
python3 -I "$ROOT/scripts/gen-rule-index.py" --check >/dev/null && echo "OK  rule indexes current" || { echo "FAIL rule indexes stale (run scripts/gen-rule-index.py)"; fail=1; }
# every skill with rules/ links them from SKILL.md
for d in "$ROOT"/skills/*/rules; do s=$(dirname "$d")/SKILL.md; grep -q "rules-index:start" "$s" || { echo "FAIL $(basename $(dirname $d))/SKILL.md has no rules index"; fail=1; }; done
exit $fail
