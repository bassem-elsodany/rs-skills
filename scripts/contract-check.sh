#!/usr/bin/env bash
# Design Contract checker — every non-exempt .rs file carries a valid
# `//! # Design Contract` block (see skills/rs-design-contract/SKILL.md).
#
#   scripts/contract-check.sh [path ...]      default: current directory
#   --all        include tests/, benches/, examples/, build.rs
#   --quiet      print only the summary
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALL=0; QUIET=0; PATHS=()
for a in "$@"; do case $a in --all) ALL=1;; --quiet) QUIET=1;; *) PATHS+=("$a");; esac; done
[[ ${#PATHS[@]} -eq 0 ]] && PATHS=(.)
MAX_LINES=12; REQUIRED=("Role" "Patterns" "Invariants" "Extend by" "Skills")
ok=0; bad=0; exempt=0
say() { [[ $QUIET -eq 1 ]] || echo "$@"; }
# path of $1 relative to the nearest ancestor directory holding a Cargo.toml (or unchanged)
crate_rel() { local f="$1" d base; base=$(cd "$(dirname "$f")" && pwd); d=$base
  while [[ "$d" != "/" ]]; do
    if [[ -f "$d/Cargo.toml" ]]; then local r="${base#"$d"}"; r="${r#/}"; echo "${r:+$r/}$(basename "$f")"; return; fi
    d=$(dirname "$d"); done
  echo "$f"; }
is_pure_mod() { ! grep -qvE '^[[:space:]]*(//.*|#!?\[.*\]|(pub(\([a-z]+\))? )?mod [a-z_0-9]+;|pub(\([a-z]+\))? use .*;)?[[:space:]]*$' "$1"; }
while IFS= read -r f; do
  rel=$(crate_rel "$f")
  if [[ $ALL -eq 0 ]] && [[ "$rel" =~ (^|/)(tests|benches|examples)/ || "$rel" == "build.rs" ]]; then exempt=$((exempt+1)); continue; fi
  # generated code (a `generated/` directory, or an @generated / "do not edit" marker in the first 5 lines) is exempt
  if [[ $ALL -eq 0 ]] && { [[ "$rel" =~ (^|/)generated/ ]] || head -5 "$f" | grep -qiE '@generated|do not edit'; }; then exempt=$((exempt+1)); continue; fi
  # pure re-export mod.rs (only mod/pub use/comments/blank) is exempt
  if [[ "$(basename "$f")" == "mod.rs" ]] && is_pure_mod "$f"; then exempt=$((exempt+1)); continue; fi
  # leading //! run (allow blank lines, // comments and #![..] before/among)
  block=$(awk '/^[[:space:]]*\/\/!/{p=1; print; next} /^[[:space:]]*(\/\/[^!]|\/\/$|#!\[|$)/{ if(p) print ""; next} {exit}' "$f")
  if ! grep -q '^[[:space:]]*//! *# Design Contract' <<<"$block"; then say "MISSING  $f — no \`//! # Design Contract\` block"; bad=$((bad+1)); continue; fi
  contract=$(awk '/\/\/! *# Design Contract/{p=1} p && /^[[:space:]]*\/\/!/{print; next} p{exit}' <<<"$block")
  n=$(wc -l <<<"$contract" | tr -d ' ')
  errs=()
  (( n > MAX_LINES )) && errs+=("$n lines (max $MAX_LINES)")
  for r in "${REQUIRED[@]}"; do grep -q "\*\*$r:\*\*" <<<"$contract" || errs+=("missing **$r:**"); done
  # bare <placeholder> outside backticks breaks `cargo doc -Dwarnings` (rustdoc::invalid_html_tags)
  if sed -E 's/`[^`]*`//g' <<<"$contract" | grep -qE '<[a-zA-Z][a-zA-Z0-9_-]*>'; then errs+=("bare <placeholder> in doc — wrap in backticks"); fi
  for s in $(grep -oE '\brs-[a-z][a-z0-9-]*' <<<"$contract" | sort -u); do
    [[ "$s" == "rs-skills" ]] && continue
    [[ -d "$ROOT/skills/$s" ]] || errs+=("unknown skill $s")
  done
  for p in $(grep -oE 'rs-patterns/[A-Za-z0-9_./-]+\.md' <<<"$contract" | sort -u); do
    [[ -f "$ROOT/skills/$p" ]] || errs+=("unknown page $p")
  done
  if (( ${#errs[@]} )); then say "INVALID  $f — $(IFS='; '; echo "${errs[*]}")"; bad=$((bad+1)); else ok=$((ok+1)); fi
done < <(find "${PATHS[@]}" -type f -name '*.rs' -not -path '*/target/*' -not -path '*/.git/*' | sort)
echo "design contracts: $ok valid, $bad missing/invalid, $exempt exempt"
(( bad == 0 ))
