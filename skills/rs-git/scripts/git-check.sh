#!/usr/bin/env bash
# git-check — repository hygiene for any Git host (GitHub, GitLab, Bitbucket, Gitea, Azure DevOps, Gerrit, plain SSH, no remote).
#
#   git-check.sh audit   [dir] [--range A..B] [--strict] [--public]   repo health: ignore rules, tracked junk, big files, secrets, message style, history policy
#   git-check.sh staged  [dir]                              what is about to be committed: secrets, artefacts, big files, conflict markers (pre-commit)
#   git-check.sh msg     <file>                             commit message lint (commit-msg hook)
#   git-check.sh install-hooks [dir]                        copy this script + hooks into <repo>/.githooks and set core.hooksPath
#
# Policy knobs (env or marker files in the repo root):
#   RS_GIT_MAX_FILE_KB=5120        files above this are reported (staged: blocked)
#   RS_GIT_ALLOW_AI_TRAILERS=1     or an empty file `.rs-git-allow-ai-trailers`  — otherwise "Co-Authored-By: <AI>" / "Claude-Session:" trailers are rejected
#   RS_GIT_SUBJECT_MAX=72          soft limit (warning); the hard limit is 100
#   a line containing `rs-git:allow-secret` (e.g. in a secret-detector's own test patterns) is skipped by the credential scan
# Read-only except install-hooks. Bash 3.2 compatible.
set -uo pipefail
MODE="${1:-audit}"; shift || true
MAXKB="${RS_GIT_MAX_FILE_KB:-5120}"; SUBJ="${RS_GIT_SUBJECT_MAX:-72}"
errors=0; warns=0
err()  { echo "ERROR  $*"; errors=$((errors+1)); }
warn() { echo "WARN   $*"; warns=$((warns+1)); }
ok()   { echo "OK     $*"; }

SECRET_RE='(AKIA[0-9A-Z]{12}[0-9A-DF-Z][0-9A-Z]{3}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|xox[baprs]-[0-9A-Za-z-]{10,}|gh[pousr]_[A-Za-z0-9]{36,}|glpat-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9]{32,}|-----BEGIN PGP PRIVATE KEY BLOCK-----)'   # rs-git:allow-secret (detector patterns, not credentials)
GENERIC_RE='([Pp]assword|[Ss]ecret|[Aa]pi[_-]?[Kk]ey|[Tt]oken)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$ {}]{8,}["'"'"']'
ARTEFACT_RE='(^|/)(target|node_modules|dist|build|\.venv|__pycache__)/|\.(o|a|so|dylib|dll|exe|class|pyc|rlib|rmeta)$|(^|/)\.env(\.(local|production|prod|dev|development|staging))?$|\.pem$|\.p12$|\.pfx$|id_rsa|\.DS_Store$|\.rs\.bk$'
AI_TRAILER_RE='^(Co-Authored-By:.*(Claude|Anthropic|noreply@anthropic\.com|Copilot|ChatGPT|OpenAI|Gemini)|Claude-Session:|Generated (with|by) .*(Claude|Copilot|ChatGPT))'

allow_ai() { [[ "${RS_GIT_ALLOW_AI_TRAILERS:-0}" == 1 ]] || [[ -f "$(git rev-parse --show-toplevel 2>/dev/null)/.rs-git-allow-ai-trailers" ]]; }

lint_message() { # lint_message <file> ; prints problems, returns count
  local f="$1" n=0 subj
  subj=$(grep -v '^#' "$f" | sed -n '1p')
  [[ -z "$subj" ]] && { err "empty commit message"; return 1; }
  [[ "$subj" =~ ^(Merge|Revert|fixup!|squash!) ]] && return 0
  if ! [[ "$subj" =~ ^(feat|fix|refactor|perf|test|docs|build|ci|chore|style|revert)(\([a-z0-9_./-]+\))?!?:\ .+ ]]; then
    err "subject must be '<type>(<scope>)?: <summary>' (types: feat fix refactor perf test docs build ci chore style revert): \"$subj\""; n=$((n+1))
  fi
  if (( ${#subj} > 100 )); then err "subject is ${#subj} chars (hard max 100, aim for $SUBJ)"; n=$((n+1)); elif (( ${#subj} > SUBJ )); then warn "subject is ${#subj} chars (aim for $SUBJ)"; fi
  [[ "$subj" =~ \.$ ]] && { warn "subject ends with a period"; }
  local second; second=$(grep -v '^#' "$f" | sed -n '2p'); [[ -n "$second" ]] && { err "line 2 must be blank (subject, blank line, body)"; n=$((n+1)); }
  if ! allow_ai && grep -v '^#' "$f" | grep -Eiq "$AI_TRAILER_RE"; then
    err "AI attribution trailer found. This repo's policy is none unless the owner opts in (touch .rs-git-allow-ai-trailers). Ask the owner; don't add it by default."; n=$((n+1))
  fi
  return $n
}

staged_checks() {
  local top; top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git repository"; exit 2; }
  cd "$top" || exit 2
  local files; files=$(git diff --cached --name-only --diff-filter=ACMR)
  [[ -z "$files" ]] && { ok "nothing staged"; return; }
  while IFS= read -r f; do
    [[ "$f" =~ $ARTEFACT_RE ]] && err "build artefact / secret-bearing file staged: $f  (add to .gitignore; git rm --cached)"
    if [[ -f "$f" ]]; then
      kb=$(( $(wc -c < "$f") / 1024 )); (( kb > MAXKB )) && err "large file staged: $f (${kb} KiB > ${MAXKB} KiB) — use Git LFS or keep it out of the repo"
    fi
  done <<< "$files"
  local added; added=$(git diff --cached -U0 --no-color | grep -E '^\+[^+]' || true)
  if echo "$added" | grep -Eq "$SECRET_RE"; then err "possible credential in staged changes:"; echo "$added" | grep -E "$SECRET_RE" | sed -E 's/(.{80}).*/\1…/' | head -5 | sed 's/^/         /'; fi
  if echo "$added" | grep -Eq "$GENERIC_RE"; then warn "possible hard-coded secret (password/token/api key literal):"; echo "$added" | grep -E "$GENERIC_RE" | sed -E 's/(.{80}).*/\1…/' | head -3 | sed 's/^/         /'; fi
  git diff --cached --check >/dev/null 2>&1 || { err "whitespace errors / conflict markers (git diff --cached --check)"; }
  [[ -f Cargo.toml ]] && echo "$files" | grep -q '\.rs$' && command -v cargo >/dev/null && { cargo fmt --all -- --check >/dev/null 2>&1 || err "cargo fmt --check fails — run cargo fmt"; }
  local n; n=$(echo "$files" | wc -l | tr -d ' '); (( n > 40 )) && warn "$n files in one commit — is this one logical change? (atomic commits)"
}

case "$MODE" in
  msg) [[ -f "${1:-}" ]] || { echo "usage: git-check.sh msg <file>"; exit 2; }; lint_message "$1"; (( errors == 0 )); exit $? ;;
  staged) [[ -n "${1:-}" ]] && cd "$1"; staged_checks; (( errors == 0 )); exit $? ;;
  install-hooks)
    top=$(cd "${1:-.}" && git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git repository"; exit 2; }
    mkdir -p "$top/.githooks"; self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    cp "$self" "$top/.githooks/rs-git-check.sh"; chmod +x "$top/.githooks/rs-git-check.sh"
    printf '#!/usr/bin/env bash\nexec "$(dirname "$0")/rs-git-check.sh" staged\n' > "$top/.githooks/pre-commit"
    printf '#!/usr/bin/env bash\nexec "$(dirname "$0")/rs-git-check.sh" msg "$1"\n' > "$top/.githooks/commit-msg"
    chmod +x "$top/.githooks/pre-commit" "$top/.githooks/commit-msg"
    git -C "$top" config core.hooksPath .githooks
    echo "installed .githooks/{pre-commit,commit-msg,rs-git-check.sh} and set core.hooksPath=.githooks in $top"
    echo "commit .githooks/ so every clone gets them (each clone runs: git config core.hooksPath .githooks)"; exit 0 ;;
  audit) ;;
  *) sed -n 2,16p "$0"; exit 2 ;;
esac

# ---------------- audit ----------------
DIR="."; RANGE=""; STRICT=0; PUBLIC=0
while [[ $# -gt 0 ]]; do case "$1" in --range) RANGE="$2"; shift 2;; --strict) STRICT=1; shift;; --public) PUBLIC=1; shift;; *) DIR="$1"; shift;; esac; done
cd "$DIR" 2>/dev/null || { echo "no such dir $DIR"; exit 2; }
top=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git repository"; exit 2; }; cd "$top" || exit 2
echo "== git audit: $top =="
branch=$(git symbolic-ref --short -q HEAD || echo "(detached)"); echo "branch: $branch"
remotes=$(git remote -v | awk '{print $1" "$2}' | sort -u)
if [[ -z "$remotes" ]]; then echo "remote: none (local-only repository — valid; the checks below still apply)"; else echo "remotes:"; echo "$remotes" | sed 's/^/  /'; fi
host=$(git remote get-url origin 2>/dev/null | sed -E 's#^(git@|https?://|ssh://([^@]+@)?)([^/:]+).*#\3#'); [[ -n "$host" ]] && echo "host: $host  (checks are host-neutral; use the host's own CLI only when it matches)"
echo

# working tree state
dirty=$(git status --porcelain | wc -l | tr -d ' ')
(( dirty > 0 )) && warn "$dirty uncommitted change(s) — commit or stash before release/branch work" || ok "working tree clean"
# ignore rules
if [[ -n "$(find . -maxdepth 4 -name Cargo.toml -not -path '*/target/*' -print -quit)" ]]; then
  unignored=""
  while IFS= read -r ct; do d=$(dirname "$ct"); [[ -d "$d/target" ]] || continue; git check-ignore -q "$d/target" 2>/dev/null || unignored="$unignored $d/target"; done < <(find . -maxdepth 4 -name Cargo.toml -not -path '*/target/*')
  [[ -n "$unignored" ]] && warn "target/ not ignored:$unignored — build output would be committed" || ok "every Cargo target/ is ignored"
  [[ -n "$(git ls-files '*Cargo.lock' | head -1)" ]] || warn "no Cargo.lock tracked (commit it for binaries; recommended for libraries' CI reproducibility)"
fi
[[ -f .gitignore ]] && ok ".gitignore present" || warn "no .gitignore"
# tracked junk
junk=$(git ls-files | grep -E "$ARTEFACT_RE" | head -10)
[[ -n "$junk" ]] && { err "build artefacts / secret-bearing files are tracked:"; echo "$junk" | sed 's/^/         /'; } || ok "no build artefacts tracked"
# big files tracked
big=$(git ls-files -z | xargs -0 -n1 -I{} sh -c 'f="{}"; [ -f "$f" ] && s=$(wc -c < "$f") && [ "$s" -gt '$((MAXKB*1024))' ] && echo "$((s/1024)) KiB $f"' 2>/dev/null | head -10)
[[ -n "$big" ]] && { warn "large tracked files (> ${MAXKB} KiB):"; echo "$big" | sed 's/^/         /'; } || ok "no oversized tracked files"
# secrets in tracked files (cheap pass); tests/fixtures/examples are reported separately — they are usually samples
allsec=$(git grep -nIE "$SECRET_RE" -- . ':!*.lock' ':!*.md' 2>/dev/null | grep -v 'EXAMPLE' | grep -v 'rs-git:allow-secret' )
realsec=$(echo "$allsec" | grep -Ev '(^|/)(tests?|fixtures?|spec|examples?|testdata|__tests__)/' | head -5)
fixsec=$(echo "$allsec" | grep -E '(^|/)(tests?|fixtures?|spec|examples?|testdata|__tests__)/' | wc -l | tr -d ' ')
[[ -n "$realsec" ]] && { err "possible credentials in tracked files (rotate, then remove from history with the owner's consent):"; echo "$realsec" | sed -E 's/(.{100}).*/\1…/;s/^/         /'; } || ok "no obvious credentials in tracked non-test files"
[[ "${fixsec:-0}" -gt 0 ]] && echo "INFO   $fixsec credential-shaped string(s) under tests/fixtures/examples — confirm they are samples"
# history style
base="${RANGE:-}"
if [[ -z "$base" ]]; then
  d=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##'); d=${d:-main}
  if git rev-parse -q --verify "$d" >/dev/null 2>&1 && [[ "$branch" != "$d" ]]; then base="$d..HEAD"; else base="HEAD"; REVOPT="-n 30"; fi
fi
REVOPT="${REVOPT:-}"
echo; echo "-- commits (${RANGE:-$base}${REVOPT:+, last 30}) --"
bad=0; total=0; ai=0
while IFS= read -r h; do
  [[ -z "$h" ]] && continue; total=$((total+1)); tmp=$(mktemp); git log -1 --format=%B "$h" > "$tmp"
  out=$(errors=0; warns=0; lint_message "$tmp" 2>&1) || true
  [[ -n "$out" ]] && { bad=$((bad+1)); (( bad <= 5 )) && echo "  $(git log -1 --format='%h %s' "$h" | cut -c1-90)" && echo "$out" | sed 's/^/      /'; }
  grep -Eiq "$AI_TRAILER_RE" "$tmp" && ai=$((ai+1)); rm -f "$tmp"
done < <(git rev-list $REVOPT $base 2>/dev/null)
(( total == 0 )) && echo "  (no commits in range)" || { (( bad == 0 )) && ok "$total commit(s) follow the message convention" || warn "$bad of $total commit(s) break the message convention"; }
(( ai > 0 )) && { allow_ai && echo "INFO   $ai commit(s) carry an AI attribution trailer (allowed by policy)" || warn "$ai commit(s) carry an AI attribution trailer — policy says none; removing it rewrites history (needs the owner's explicit yes, then a force-push)"; }
ids=$(git log $REVOPT $base --format='%an <%ae>' 2>/dev/null | sort | uniq -c | sort -rn | head -5); [[ -n "$ids" ]] && { echo "authors in range:"; echo "$ids" | sed 's/^/  /'; }
# public-readiness checklist (informational): what an outsider expects to find
if (( PUBLIC )); then
  echo; echo "-- public readiness --"
  for f in README.md LICENSE SECURITY.md CONTRIBUTING.md CHANGELOG.md; do [[ -f "$f" || -f "${f%.md}" ]] && echo "INFO   have $f" || echo "INFO   missing $f"; done
  [[ -d .github/workflows || -f .gitlab-ci.yml || -f azure-pipelines.yml || -f .circleci/config.yml ]] && echo "INFO   CI configuration present" || echo "INFO   no CI configuration"
  if command -v gitleaks >/dev/null 2>&1; then echo "INFO   gitleaks available — run: gitleaks git ."; elif command -v trufflehog >/dev/null 2>&1; then echo "INFO   trufflehog available — run: trufflehog git file://\$PWD"; else echo "WARN   no history secret scanner installed (gitleaks / trufflehog) — scan the FULL history before going public"; warns=$((warns+1)); fi
  echo "INFO   if history ever held secrets: rotate, then prefer a fresh repository over a rewrite (guides/publish-ready.md)"
fi
# hooks
hp=$(git config core.hooksPath || true); [[ -n "$hp" && -x "$hp/pre-commit" ]] && ok "hooks installed ($hp)" || warn "no pre-commit/commit-msg hooks — git-check.sh install-hooks"
# tags
tags=$(git tag --list 'v*' | wc -l | tr -d ' '); echo "version tags (v*): $tags"
echo
cat <<'TXT'
Manual (host-specific, cannot be checked from git alone):
  - default branch protected: no force-push, no deletion; required review/CI per your policy
  - secret scanning / dependency alerts enabled on the host
TXT
echo "== audit: $errors error(s), $warns warning(s) =="
(( errors > 0 )) && exit 1; (( STRICT && warns > 0 )) && exit 1; exit 0
