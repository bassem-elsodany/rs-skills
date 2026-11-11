#!/usr/bin/env bash
# Inventory of a crate's module structure for restructuring (rs-structure):
# every .rs with lines, pub items, and the sibling modules it `use`s.
#   scripts/structure-map.sh [crate-dir]        → Markdown table on stdout
set -uo pipefail
DIR="${1:-.}"; SRC="$DIR/src"; [[ -d "$SRC" ]] || { echo "no src/ under $DIR"; exit 1; }
echo "| File | Lines | pub items | fns | Uses (crate-internal) | Feature guess |"
echo "|---|---|---|---|---|---|"
total=0
while IFS= read -r f; do
  rel="${f#"$SRC"/}"; n=$(wc -l < "$f" | tr -d ' '); total=$((total+n))
  pubs=$(grep -cE '^[[:space:]]*pub(\([a-z:]+\))? (fn|struct|enum|trait|type|const|static|mod) ' "$f")
  fns=$(grep -cE '^[[:space:]]*(pub(\([a-z:]+\))? )?(async )?fn ' "$f")
  uses=$(grep -oE '^[[:space:]]*(pub(\([a-z:]+\))? )?use (crate|super|self)::[A-Za-z0-9_:{}, *]+' "$f" | sed -E 's/.*use (crate|super|self):://; s/::.*//; s/[{} ,].*//' | sort -u | tr '\n' ' ')
  # feature guess: the most frequent CamelCase type name in signatures
  guess=$(grep -oE '\b[A-Z][a-z]+[A-Za-z0-9]*\b' "$f" | grep -vE '^(Self|Result|Option|Vec|String|Box|Arc|Rc|Ok|Err|Some|None|Debug|Clone|Default|Error|Display|From|Into|Send|Sync|Fn|Copy|PartialEq|Eq|Hash|Serialize|Deserialize|Path|PathBuf|HashMap|BTreeMap)$' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
  echo "| \`$rel\` | $n | $pubs | $fns | ${uses:-—} | ${guess:-—} |"
done < <(find "$SRC" -name '*.rs' -not -path '*/target/*' | sort)
echo
echo "Total: $(find "$SRC" -name '*.rs' | wc -l | tr -d ' ') files, $total lines; top-level files: $(find "$SRC" -maxdepth 1 -name '*.rs' | wc -l | tr -d ' '), feature dirs: $(find "$SRC" -mindepth 1 -maxdepth 1 -type d ! -name bin | wc -l | tr -d ' ')"
echo "Next: cluster rows by 'Uses' and 'Feature guess' into feature directories — skills/rs-structure/guides/restructure-existing.md"
