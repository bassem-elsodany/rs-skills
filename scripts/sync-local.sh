#!/usr/bin/env bash
# Make the working copy of rs-skills the one your Claude Code sessions load.
#
# Preferred: install as a local marketplace plugin (hooks, agents, commands all work):
#   claude plugin marketplace add ~/.claude/plugins/marketplaces/rs-skills
#   claude plugin install rs-skills@rs-skills
# After changes, re-run this script to refresh the installed cache in place:
#   scripts/sync-local.sh          # the profile in $CLAUDE_CONFIG_DIR (default ~/.claude)
#   scripts/sync-local.sh --all    # every profile (~/.claude and ~/.claude-account-*) that has rs-skills installed
#
# Fallback (skills-only, no hooks): symlink every skill into ~/.agents/skills,
# which ~/.claude/skills points at:   scripts/sync-local.sh --skills-only
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
if [[ "${1:-}" == "--skills-only" ]]; then
  mkdir -p "$HOME/.agents/skills"
  for s in "$ROOT"/skills/*/; do n=$(basename "$s"); ln -sfn "$s" "$HOME/.agents/skills/$n"; done
  echo "linked $(ls -d "$ROOT"/skills/*/ | wc -l | tr -d ' ') skills into ~/.agents/skills"
  exit 0
fi
if [[ "${1:-}" == "--all" ]]; then
  for cfg in "$HOME/.claude" "$HOME"/.claude-account-*; do
    [[ -d "$cfg/plugins/cache/rs-skills/rs-skills" ]] || { echo "skip $cfg (rs-skills not installed)"; continue; }
    CLAUDE_CONFIG_DIR="$cfg" bash "$0"
  done
  exit 0
fi
CACHE="$CONFIG_DIR/plugins/cache/rs-skills/rs-skills"
if [[ ! -d "$CACHE" ]]; then
  echo "rs-skills is not installed for $CONFIG_DIR yet. Run:"
  echo "  claude plugin marketplace add $ROOT"
  echo "  claude plugin install rs-skills@rs-skills"
  exit 1
fi
for v in "$CACHE"/*/; do
  rsync -a --delete --exclude '.git' --exclude '.DS_Store' --exclude 'checks/target' "$ROOT/" "$v"
  echo "synced -> $v"
done
