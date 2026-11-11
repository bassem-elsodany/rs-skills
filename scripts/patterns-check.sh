#!/usr/bin/env bash
# Completeness check for skills/rs-patterns (Phase 1).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; S="$ROOT/skills/rs-patterns"; fail=0
pages=$(find "$S" -name '*.md' ! -name SKILL.md ! -name SOURCES.md | wc -l | tr -d ' ')
[[ $pages -eq 50 ]] && echo "OK  50 book pages present" || { echo "FAIL expected 50 pages, found $pages"; fail=1; }
if grep -rq '{{#' "$S"; then echo "FAIL mdBook directives left"; fail=1; else echo "OK  no mdBook syntax"; fi
missing=$(grep -L "rs-patterns ·" $(find "$S" -name '*.md' ! -name SKILL.md ! -name SOURCES.md) || true)
[[ -z "$missing" ]] && echo "OK  every page has a header block" || { echo "FAIL pages without header:"; echo "$missing"; fail=1; }
dead=0
while IFS= read -r f; do
  for l in $(grep -oE '\]\(([^)#[:space:]]+\.md)' "$f" | sed 's/^](//' ; grep -oE '^\[[^]]+\]:[[:space:]]+[^[:space:]<]+\.md' "$f" | awk '{print $2}'); do
    [[ "$l" == http* ]] && continue
    [[ -e "$(dirname "$f")/$l" ]] || { echo "  dead link in ${f#$ROOT/}: $l"; dead=1; }
  done
done < <(find "$S" -name '*.md')
[[ $dead -eq 0 ]] && echo "OK  all relative links in rs-patterns resolve" || fail=1
# links from the 12 enriched skills into rs-patterns
dead=0
for f in "$ROOT"/skills/*/SKILL.md; do
  for l in $(grep -oE '`\.\./rs-patterns/[^`]+`' "$f" | tr -d '`'); do [[ -e "$(dirname "$f")/$l" ]] || { echo "  dead link in ${f#$ROOT/}: $l"; dead=1; }; done
done
[[ $dead -eq 0 ]] && echo "OK  all rs-patterns references from other skills resolve" || fail=1
dlen=$(python3 -c "import re,sys;s=open('$S/SKILL.md').read();m=re.search(r'^description: \"(.*)\"',s,re.M);print(len(m.group(1)))")
[[ $dlen -lt 1024 ]] && echo "OK  SKILL.md description $dlen chars (<1024)" || { echo "FAIL description too long: $dlen"; fail=1; }
words=$(sed '1,/^---$/d' "$S/SKILL.md" | sed '1,/^---$/d' | wc -w | tr -d ' ')
echo "OK  SKILL.md body $words words"
exit $fail
