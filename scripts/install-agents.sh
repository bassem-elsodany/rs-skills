#!/usr/bin/env bash
# install-agents — install rs-skills for agents other than Claude Code (Codex, Cursor, Gemini CLI, GitHub Copilot,
# OpenCode, Windsurf/Devin, Kiro, …) WITHOUT their plugin systems.
#
#   scripts/install-agents.sh [--scope project|user] [--dest DIR] [--mode link|copy] [--kiro]
#                             [--agents-md [FILE]] [--dry-run] [--uninstall]
#
# Why a script: these tools discover skills as folders containing SKILL.md in a shared location
# (`.agents/skills/` in a project, `~/.agents/skills/` per user — read by Codex, Cursor, Gemini CLI, Copilot, OpenCode,
# Windsurf/Devin; Kiro uses `.kiro/skills/`). rs-skills' skills also use bundle-level files (scripts/, templates/) and
# write their paths as ${CLAUDE_PLUGIN_ROOT}/… — a bare folder copy would lose them. This script
#   link mode (default)  symlinks every skill folder to this clone; the clone IS the bundle root (keep it in place)
#   copy mode            copies the skill folders AND the bundle support files (scripts, templates, _meta, index)
#                        into <dest>/../rs-skills-bundle so the install is self-contained
# and (optionally) writes a managed block into AGENTS.md that tells the agent where the bundle root is, how to read
# ${CLAUDE_PLUGIN_ROOT}, and which "before you build" gates apply — because Claude Code hooks do not exist elsewhere.
#
# Safe by design: never overwrites a path it did not create; --uninstall removes only what it created; --dry-run prints.
# Hooks, slash commands and agents are Claude Code features and are NOT installed here.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE=project; DEST=""; MODE=link; KIRO=0; AGENTS_MD=""; WANT_MD=0; DRY=0; UNINSTALL=0
while [[ $# -gt 0 ]]; do case "$1" in
  --scope) SCOPE="$2"; shift 2;; --dest) DEST="$2"; shift 2;; --mode) MODE="$2"; shift 2;; --kiro) KIRO=1; shift;;
  --agents-md) WANT_MD=1; if [[ $# -gt 1 && "$2" != --* ]]; then AGENTS_MD="$2"; shift 2; else shift; fi;;
  --dry-run) DRY=1; shift;; --uninstall) UNINSTALL=1; shift;;
  -h|--help) sed -n 2,22p "$0"; exit 0;; *) echo "unknown argument $1" >&2; exit 2;; esac; done
[[ "$SCOPE" == project || "$SCOPE" == user ]] || { echo "--scope must be project or user" >&2; exit 2; }
[[ "$MODE" == link || "$MODE" == copy ]] || { echo "--mode must be link or copy" >&2; exit 2; }
if [[ -z "$DEST" ]]; then [[ "$SCOPE" == user ]] && DEST="$HOME/.agents/skills" || DEST="$PWD/.agents/skills"; fi
if (( WANT_MD )) && [[ -z "$AGENTS_MD" ]]; then
  [[ "$SCOPE" == project ]] && AGENTS_MD="$PWD/AGENTS.md" || { echo "--agents-md needs a FILE with --scope user" >&2; exit 2; }
fi
BUNDLE_COPY="$(dirname "$DEST")/rs-skills-bundle"
MARK=".rs-skills-installed"
START="<!-- rs-skills:start (managed by scripts/install-agents.sh; remove with --uninstall) -->"; END="<!-- rs-skills:end -->"
run() { if (( DRY )); then echo "  [dry-run] $*"; else "$@"; fi; }
say() { echo "$@"; }

targets=("$DEST"); (( KIRO )) && { [[ "$SCOPE" == user ]] && targets+=("$HOME/.kiro/skills") || targets+=("$PWD/.kiro/skills"); }
skills=(); for d in "$ROOT"/skills/*/; do [[ -f "$d/SKILL.md" ]] && skills+=("$(basename "$d")"); done
[[ ${#skills[@]} -gt 0 ]] || { echo "no skills found under $ROOT/skills" >&2; exit 1; }

strip_block() { # strip_block FILE  — remove the managed block, keep the rest
  local f="$1"; [[ -f "$f" ]] || return 0
  awk -v s="$START" -v e="$END" 'index($0,"<!-- rs-skills:start")==1{skip=1} !skip{print} index($0,e)==1{skip=0}' "$f" > "$f.rs-tmp" && mv "$f.rs-tmp" "$f"
}

if (( UNINSTALL )); then
  for t in "${targets[@]}"; do
    [[ -d "$t" ]] || continue
    for s in "${skills[@]}"; do
      p="$t/$s"
      if [[ -L "$p" && "$(readlink "$p")" == "$ROOT/skills/$s" ]]; then say "remove link  $p"; run rm "$p"
      elif [[ -d "$p" && -f "$p/$MARK" ]]; then say "remove copy  $p"; run rm -rf "$p"; fi
    done
  done
  if [[ -d "$BUNDLE_COPY" && -f "$BUNDLE_COPY/$MARK" ]]; then say "remove bundle copy $BUNDLE_COPY"; run rm -rf "$BUNDLE_COPY"; fi
  if [[ -n "$AGENTS_MD" && -f "$AGENTS_MD" ]] && grep -q "rs-skills:start" "$AGENTS_MD"; then say "strip managed block from $AGENTS_MD"; (( DRY )) || strip_block "$AGENTS_MD"; fi
  say "uninstall complete (only items created by this script were touched)"; exit 0
fi

BR="$ROOT"
if [[ "$MODE" == copy ]]; then
  BR="$BUNDLE_COPY"
  say "bundle copy -> $BR (scripts, templates, _meta, index)"
  if [[ -e "$BR" && ! -f "$BR/$MARK" ]]; then echo "refusing: $BR exists and was not created by this script" >&2; exit 1; fi
  run mkdir -p "$BR"
  for d in scripts templates _meta index; do [[ -d "$ROOT/$d" ]] && { (( DRY )) && echo "  [dry-run] copy $d" || { rm -rf "$BR/$d"; cp -R "$ROOT/$d" "$BR/$d"; }; }; done
  (( DRY )) || echo "rs-skills bundle support files copied from $ROOT" > "$BR/$MARK"
fi

skipped=0
for t in "${targets[@]}"; do
  installed=0
  say "install into $t ($MODE)"; run mkdir -p "$t"
  for s in "${skills[@]}"; do
    p="$t/$s"
    if [[ -L "$p" && "$(readlink "$p")" == "$ROOT/skills/$s" ]]; then installed=$((installed+1)); continue; fi      # already ours
    if [[ -d "$p" && -f "$p/$MARK" ]]; then (( DRY )) || rm -rf "$p"; fi                                          # our old copy: refresh
    if [[ -e "$p" || -L "$p" ]]; then echo "  skip $s: $p exists and is not ours" >&2; skipped=$((skipped+1)); continue; fi
    if [[ "$MODE" == link ]]; then run ln -s "$ROOT/skills/$s" "$p"
    else (( DRY )) && echo "  [dry-run] copy $s" || { cp -R "$ROOT/skills/$s" "$p"; echo "copied from $ROOT/skills/$s" > "$p/$MARK"; }; fi
    installed=$((installed+1))
  done
  say "  skills installed here: $installed"
done
[[ $skipped -gt 0 ]] && say "skipped (not ours, left untouched): $skipped"

if (( WANT_MD )); then
  say "write managed block into $AGENTS_MD"
  if (( ! DRY )); then
    touch "$AGENTS_MD"; strip_block "$AGENTS_MD"
    { [[ -s "$AGENTS_MD" ]] && echo ""
      cat <<EOF
$START
## rs-skills (Rust)

Skills are installed in \`$DEST\`. For any Rust task, first read \`$DEST/rs-guide/SKILL.md\` and \`$DEST/rs-router/SKILL.md\`, then follow the router.

- **Bundle root:** \`$BR\`. Skill text writes script paths as \`\${CLAUDE_PLUGIN_ROOT}/…\` or \`\${CLAUDE_SKILL_DIR}/…\`: read \`\${CLAUDE_PLUGIN_ROOT}\` as \`$BR\` and \`\${CLAUDE_SKILL_DIR}\` as the skill's own folder.
- **No hooks or slash commands here** (Claude Code features): apply the gates yourself and run the scripts directly.
- **Gates before you build:** (1) implementing a standard/protocol/vendor API → load \`rs-reuse-first\` and run \`$BR/skills/rs-reuse-first/scripts/sdk-scout.sh "<standard>" --github\` first; (2) anything replaceable (database, cache, queue, SDK, downstream) → \`rs-ports-adapters\`; (3) building, testing, containers → \`rs-cleanup\` (\`$BR/skills/rs-cleanup/scripts/disk-guard.sh status\`, clean up what you create, never prune Docker volumes without asking); (4) untrusted input, review, audit or bug fixing → \`rs-security-review\`, \`rs-review\`, \`rs-bugfix\`; (5) commits, branches, tags → \`rs-git\` (no AI co-author trailers unless asked).
- Every \`.rs\` file you create starts with a Design Contract (\`rs-design-contract\`); release gate: \`$BR/scripts/release-check.sh\`.
$END
EOF
    } >> "$AGENTS_MD"
  fi
fi
say "done. Restart the agent (or reload skills) so it rediscovers $DEST."
[[ "$MODE" == link ]] && say "link mode: keep this clone in place ($ROOT) — the links point into it."
exit 0
