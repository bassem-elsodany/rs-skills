#!/usr/bin/env bash
# Structure smells (rs-structure): long files, long functions, dumping-ground
# modules, flat src/, logic in mod.rs.  Heuristic — a report, not a gate.
#   scripts/structure-check.sh [crate-dir] [--max-file 400] [--max-fn 60] [--strict]
set -uo pipefail
DIR=.; MAX_FILE=400; MAX_FN=60; STRICT=0
while [[ $# -gt 0 ]]; do case $1 in --max-file) MAX_FILE=$2; shift 2;; --max-fn) MAX_FN=$2; shift 2;; --strict) STRICT=1; shift;; *) DIR=$1; shift;; esac; done
issues=0; note() { echo "$@"; issues=$((issues+1)); }
files=$(find "$DIR" -type f -name '*.rs' -not -path '*/target/*' -not -path '*/.git/*' | sort)
for f in $files; do
  n=$(wc -l < "$f" | tr -d ' ')
  (( n > MAX_FILE )) && note "LONG FILE   $f: $n lines (> $MAX_FILE) — promote to a directory (rs-structure split ladder step 3)"
  case "$(basename "$f")" in utils.rs|helpers.rs|common.rs|misc.rs|stuff.rs) note "DUMPING GROUND  $f — move each helper next to its user, or shared/<topic>.rs";; esac
  if [[ "$(basename "$f")" == "mod.rs" ]]; then
    logic=$(grep -cE '^[[:space:]]*(pub(\([a-z:]+\))? )?(fn|struct|enum|impl|trait) ' "$f")
    (( logic > 3 )) && note "LOGIC IN mod.rs  $f: $logic items — keep mod.rs for mod/pub use/docs; move items to aspect files"
  fi
  # function length: from a line starting a fn to the matching closing brace at the same indent
  awk -v max="$MAX_FN" -v file="$f" '
    match($0, /^([[:space:]]*)(pub(\([a-z:]+\))? )?(async )?(unsafe )?(const )?fn [A-Za-z_0-9]+/) {
      if (!infn) { infn=1; start=NR; indent=substr($0,1,RLENGTH); sub(/[^ \t].*/,"",indent); name=$0; sub(/^.*fn /,"",name); sub(/[<(].*/,"",name); next }
    }
    infn && $0 ~ ("^" indent "}") { len=NR-start+1; if (len>max) printf("LONG FN     %s:%d fn %s: %d lines (> %d) — extract verbs into private fns (split ladder step 1-2)\n", file, start, name, len, max); infn=0 }
  ' "$f" > "${TMPDIR:-/tmp}/rs-structure-fn.$$" ; while IFS= read -r l; do note "$l"; done < "${TMPDIR:-/tmp}/rs-structure-fn.$$"; rm -f "${TMPDIR:-/tmp}/rs-structure-fn.$$"
done
# flat src/: many files, no feature directories
for src in $(find "$DIR" -type d -name src -not -path '*/target/*'); do
  nfiles=$(find "$src" -maxdepth 1 -name '*.rs' | wc -l | tr -d ' '); ndirs=$(find "$src" -mindepth 1 -maxdepth 1 -type d ! -name bin | wc -l | tr -d ' ')
  (( nfiles >= 12 && ndirs == 0 )) && note "FLAT src/   $src: $nfiles files, no feature directories — group by feature (rs-structure)"
  main="$src/main.rs"; [[ -f "$main" ]] && (( $(wc -l < "$main") > 150 )) && [[ ! -f "$src/lib.rs" ]] && note "FAT main.rs $main without lib.rs — split into lib.rs + thin main (rs-structure bin layout)"
done
echo "structure: $issues issue(s)"
(( STRICT == 0 || issues == 0 ))
