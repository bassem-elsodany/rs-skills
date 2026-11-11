#!/usr/bin/env bash
# Pre-release gate (rs-release). Runs every check a crate must pass before it ships.
#   scripts/release-check.sh [crate-dir] [--no-net] [--strict]
# Missing optional tools (cargo-deny, cargo-audit, cargo-semver-checks, cargo-msrv)
# are reported as WARN with an install hint; --strict turns WARN into failure.
set -uo pipefail
BUNDLE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR=.; STRICT=0; NONET=0
for a in "$@"; do case $a in --strict) STRICT=1;; --no-net) NONET=1;; *) DIR=$a;; esac; done
cd "$DIR" || exit 2
[[ -f Cargo.toml ]] || { echo "no Cargo.toml in $DIR"; exit 2; }
TMP=$(mktemp "${TMPDIR:-/tmp}/rs-release-check.XXXXXX"); trap 'rm -f "$TMP"' EXIT
pass=0; warn=0; fail=0
ok()   { echo "PASS  $1"; pass=$((pass+1)); }
wr()   { echo "WARN  $1"; warn=$((warn+1)); }
bad()  { echo "FAIL  $1"; fail=$((fail+1)); }
run()  { local name=$1; shift; if "$@" >"$TMP" 2>&1; then ok "$name"; else bad "$name"; sed 's/^/      /' "$TMP" | tail -15; fi; }
have() { cargo --list 2>/dev/null | grep -qE "^\s+$1( |$)"; }

echo "== rs-release gate: $(pwd)"
# 1. metadata
grep -qE '^rust-version' Cargo.toml && ok "rust-version (MSRV) declared" || bad "rust-version missing in Cargo.toml (proj-msrv-declare)"
grep -qE '^\[lints' Cargo.toml && ok "[lints] table present" || bad "no [lints] table — see rs-release lint policy"
# Effective edition (handles `edition.workspace = true`).
edition=$(cargo metadata --no-deps --format-version 1 --offline 2>/dev/null | python3 -c 'import json,os,sys; d=json.load(sys.stdin); m=os.path.realpath("Cargo.toml"); print(next((p["edition"] for p in d["packages"] if os.path.realpath(p["manifest_path"])==m), ""))' 2>/dev/null)
[[ -z "$edition" ]] && edition=$(sed -nE 's/^edition = "([0-9]+)".*/\1/p' Cargo.toml | head -1)
[[ "$edition" == "2024" ]] && ok "edition 2024" || wr "edition is not 2024 (found: ${edition:-unknown})"
grep -rqE '^#!\[deny\(warnings\)\]' src 2>/dev/null && bad "#![deny(warnings)] in source (rs-patterns anti-pattern) — use RUSTFLAGS=-Dwarnings in CI" || ok "no #![deny(warnings)] in source"
[[ -f CHANGELOG.md ]] && ok "CHANGELOG.md present" || wr "no CHANGELOG.md"
# The lockfile lives at the workspace root for workspace members.
lock_dir=$(cargo metadata --no-deps --format-version 1 --offline 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["workspace_root"])' 2>/dev/null || pwd)
[[ -f "$lock_dir/Cargo.lock" ]] && ok "Cargo.lock committed ($([[ "$lock_dir" == "$(pwd)" ]] && echo crate || echo workspace root))" || wr "no Cargo.lock (commit it for binaries; libraries may omit)"
# 2. format / lint / test / docs
export RUSTFLAGS="${RUSTFLAGS:--Dwarnings}" RUSTDOCFLAGS="${RUSTDOCFLAGS:--Dwarnings}"
run "cargo fmt --check"                      cargo fmt --all --check
run "cargo clippy --all-targets --all-features" cargo clippy --all-targets --all-features --quiet
run "cargo test --all-targets --all-features" cargo test --all-targets --all-features --quiet
run "cargo test --no-default-features"       cargo test --no-default-features --quiet
run "cargo doc --no-deps (warnings denied)"  cargo doc --no-deps --all-features --quiet
# 3. structure + contracts
run "design contracts"                       bash "$BUNDLE/scripts/contract-check.sh" .
if bash "$BUNDLE/scripts/structure-check.sh" . --strict >"$TMP" 2>&1; then ok "structure smells: none"; else wr "structure smells (see below)"; grep -vE "^structure:" "$TMP" | sed 's/^/      /' | head -10; fi
# 3b. decoupling, repository hygiene, disk (rs-ports-adapters, rs-git, rs-cleanup)
if python3 -I "$BUNDLE/scripts/port-check.py" . >"$TMP" 2>&1 && ! grep -qE '^(LEAK|SQL|CFG|DEP|NOPORT)' "$TMP"; then ok "ports & adapters: no vendor code outside adapters"; else wr "vendor code outside adapters (rs-ports-adapters)"; grep -E '^(LEAK|SQL|CFG|DEP|NOPORT)' "$TMP" | head -8 | sed 's/^/      /'; fi
if git rev-parse --git-dir >/dev/null 2>&1; then
  if bash "$BUNDLE/skills/rs-git/scripts/git-check.sh" audit . >"$TMP" 2>&1; then ok "git hygiene (rs-git audit)"; else wr "git hygiene findings (rs-git audit)"; grep -E '^(ERROR|WARN)' "$TMP" | head -8 | sed 's/^/      /'; fi
fi
if why=$(bash "$BUNDLE/skills/rs-cleanup/scripts/disk-guard.sh" over . 2>/dev/null); then ok "disk within budgets (rs-cleanup)"; else wr "disk budget exceeded:${why} — run skills/rs-cleanup/scripts/cleanup.sh plan"; fi
if python3 -I "$BUNDLE/skills/rs-release/scripts/dep-risk.py" . --offline --json "$TMP.json" >/dev/null 2>&1; then
  census=$(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); bad=[r["name"] for r in d["rows"] if r["source"]!="registry" or any(q in ("*","") for q in r["req"])]; print(len(d["build_time"]), ",".join(sorted(set(bad))))' "$TMP.json" 2>/dev/null)
  nbt=${census%% *}; bad=${census#* }
  if [[ -n "$bad" && "$bad" != "$nbt" ]]; then wr "git/path/wildcard dependency sources: $bad (dep-risk.py, rs-release rel-supply-chain-evidence)"; else ok "dependency sources are pinned registry versions ($nbt crates run build-time code — dep-risk.py lists them)"; fi
  rm -f "$TMP.json"
fi
# 4. supply chain / compatibility (optional tools)
if (( NONET == 0 )); then
  if have deny; then run "cargo deny check" cargo deny check; else wr "cargo-deny not installed (cargo install cargo-deny --locked) — licences/advisories unchecked"; fi
  if ! have deny; then if have audit; then run "cargo audit" cargo audit -q; else wr "cargo-audit not installed (cargo install cargo-audit --locked)"; fi; fi
  if have semver-checks; then run "cargo semver-checks" cargo semver-checks; else wr "cargo-semver-checks not installed — breaking-change detection skipped"; fi
  if have msrv; then run "cargo msrv verify" cargo msrv verify; else wr "cargo-msrv not installed — MSRV not verified (CI should test on rust-version)"; fi
fi
echo "== $pass passed, $warn warnings, $fail failed"
(( fail == 0 )) && (( STRICT == 0 || warn == 0 ))
