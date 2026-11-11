#!/usr/bin/env bash
# Build a clean, ready-to-publish copy of this repository: current tracked files only, ONE fresh commit, an author
# identity you choose. It never adds a remote and never pushes — publishing is a separate, deliberate step.
#
#   scripts/export-public.sh --out <empty-dir> --name "Your Name" --email you@example.com [--repo owner/name] [--host https://github.com] [--message "..."] [--no-verify]
#   --repo fills every bassem-elsodany/rs-skills placeholder in the docs and sets homepage/repository in plugin.json (so the README install lines work as written)
#
# Why a fresh commit: the working history may carry personal e-mail addresses and informal commit messages; a fresh
# repository publishes neither and needs no history rewrite or force-push (rs-git: guides/publish-ready.md).
# Keep this repository as the private archive.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT=""; NAME=""; EMAIL=""; MSG=""; VERIFY=1; REPO=""; HOST="https://github.com"
while [[ $# -gt 0 ]]; do case "$1" in
  --out) OUT="$2"; shift 2;; --name) NAME="$2"; shift 2;; --email) EMAIL="$2"; shift 2;;
  --message) MSG="$2"; shift 2;; --repo) REPO="$2"; shift 2;; --host) HOST="$2"; shift 2;; --no-verify) VERIFY=0; shift;; -h|--help) sed -n 2,10p "$0"; exit 0;;
  *) echo "unknown argument $1" >&2; exit 2;; esac; done
[[ -n "$OUT" && -n "$NAME" && -n "$EMAIL" ]] || { echo "usage: export-public.sh --out <dir> --name <name> --email <email>" >&2; exit 2; }
[[ -z "$(git -C "$ROOT" status --porcelain)" ]] || { echo "working tree is not clean — commit or stash first" >&2; exit 1; }
if [[ -e "$OUT" && -n "$(ls -A "$OUT" 2>/dev/null)" ]]; then echo "$OUT exists and is not empty" >&2; exit 1; fi
VER="$(tr -d '[:space:]' < "$ROOT/VERSION")"; MSG="${MSG:-feat: rs-skills $VER}"
mkdir -p "$OUT"
git -C "$ROOT" archive --format=tar HEAD | tar -x -C "$OUT"       # tracked files only: no .git, no caches, no ignored artefacts
cd "$OUT"
rm -rf docs/specs docs/coverage        # private planning data (maps work items to their sources); the checks skip when it is absent
if [[ -n "$REPO" ]]; then
  [[ "$REPO" == */* ]] || { echo "--repo must look like owner/name" >&2; exit 2; }
  grep -rlF 'bassem-elsodany/rs-skills' . 2>/dev/null | while IFS= read -r f; do python3 -I - "$f" "$REPO" <<'PY'
import sys
p, repo = sys.argv[1], sys.argv[2]
s = open(p, errors="surrogateescape").read()
open(p, "w", errors="surrogateescape").write(s.replace("bassem-elsodany/rs-skills", repo))
PY
  done
  python3 -I - "$REPO" "$HOST" <<'PY'
import json, sys
repo, host = sys.argv[1], sys.argv[2].rstrip("/")
p = ".claude-plugin/plugin.json"
d = json.load(open(p))
d["homepage"] = f"{host}/{repo}"
d["repository"] = f"{host}/{repo}"
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False); open(p, "a").write("\n")
PY
  echo "filled placeholders and set homepage/repository to $HOST/$REPO"
fi
git init -q -b main
git add -A
git -c user.name="$NAME" -c user.email="$EMAIL" -c commit.gpgsign=false commit -q -m "$MSG"
echo "exported $(git ls-files | wc -l | tr -d ' ') files to $OUT as one commit by $NAME <$EMAIL> (no remote added)"
if (( VERIFY )); then
  echo "== verifying the export =="
  rc=0
  bash skills/rs-git/scripts/git-check.sh audit . --public 2>&1 | grep -E "^(ERROR|WARN|OK)" | grep -v "no pre-commit" || true
  ids=$(git log --format='%an <%ae>' | sort -u); echo "author(s) in history: $ids"
  bad=$(git grep -nIiE "gmail\.com|hotmail\.com|@epam|/Users/[a-z]" -- . ':!NOTICE.md' ':!LICENSE' ':!SECURITY.md' ':!tests' ':!scripts/export-public.sh' ':!scripts/validate-plugin.py' | head -5 || true)
  [[ -n "$bad" ]] && { echo "WARN personal-looking strings in the export:"; echo "$bad"; rc=1; } || echo "OK   no personal e-mails or home paths in tracked files"
  names=$(git grep -nIiE "leonardomso|leonardo maldonado|zhanghandong|trailofbits|huiali" -- . ':!NOTICE.md' ':!skills/rs-patterns' ':!scripts/export-public.sh' ':!scripts/validate-plugin.py' | head -5 || true)
  [[ -n "$names" ]] && { echo "WARN source names outside NOTICE.md and the MPL pages:"; echo "$names"; rc=1; } || echo "OK   source names appear only in NOTICE.md and the MPL pages"
  for c in quality rules coverage patterns; do bash scripts/$c-check.sh >/dev/null 2>&1 && echo "OK   scripts/$c-check.sh" || { echo "FAIL scripts/$c-check.sh"; rc=1; }; done
  [[ -z "$REPO" ]] && { grep -rn "<owner>" README.md | head -1 >/dev/null && echo "NOTE README still has <owner> placeholders (pass --repo owner/name to fill them)"; }
  python3 -I scripts/gen-guide.py --check >/dev/null 2>&1 && echo "OK   gen-guide --check" || { echo "FAIL gen-guide --check"; rc=1; }
  find . -name __pycache__ -not -path './.git/*' -exec rm -rf {} + 2>/dev/null || true
  exit $rc
fi
