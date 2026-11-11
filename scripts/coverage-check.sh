#!/usr/bin/env bash
# Verifies that every item from the three upstream sources has landed where the
# coverage matrix says it should, for all phases that are already complete.
#
#   scripts/coverage-check.sh            # checks phases <= docs/coverage/PHASE
#   scripts/coverage-check.sh --phase 3  # checks phases <= 3
#   scripts/coverage-check.sh --all      # report every row (missing rows are not errors)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COV="$ROOT/docs/coverage"
[[ -d "$COV" ]] || { echo "coverage: no matrix in this checkout (private planning data) — skipped"; exit 0; }
PHASE=$(cat "$COV/PHASE" 2>/dev/null || echo 0)
MODE=check
while [[ $# -gt 0 ]]; do case $1 in --phase) PHASE=$2; shift 2;; --all) MODE=all; shift;; *) echo "unknown arg $1"; exit 2;; esac; done

total=0; present=0; missing=0; pending=0
for tsv in "$COV"/*.tsv; do
  src=$(basename "$tsv" .tsv)
  while IFS=$'\t' read -r source item dest phase note; do
    [[ "$source" == "source" || -z "$source" ]] && continue
    total=$((total+1))
    target="$ROOT/${dest%/}"
    if [[ -e "$target" ]]; then present=$((present+1))
    elif (( phase <= PHASE )); then missing=$((missing+1)); echo "MISSING [$src phase $phase] $item -> $dest"
    else pending=$((pending+1)); [[ $MODE == all ]] && echo "pending [$src phase $phase] $item -> $dest"
    fi
  done < "$tsv"
done
echo "coverage: $present/$total landed, $pending pending (phase > $PHASE), $missing missing"
[[ $missing -eq 0 ]]
