#!/usr/bin/env bash
# Compile-verify the ```rust examples in skills/*/rules/*.md (rules listed in rule-manifest.txt).
# Pinned toolchain via checks/rust-toolchain.toml (1.95.0); cross-checks x86_64 linux
# so Apple Silicon hosts get the same diagnostics as CI.   bash checks/check.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; TARGET="x86_64-unknown-linux-gnu"
echo "==> rule integrity"; bash "$ROOT/scripts/rules-check.sh"
echo "==> generating example files from rules"; cd "$ROOT/checks"; python3 gen.py
echo "==> compile-checking examples (target: $TARGET)"
cargo check --examples --target "$TARGET" --keep-going --message-format=json > check.json 2> check.err || true
echo "==> gating against the baseline"; python3 analyze.py check.json --check-baseline baseline.txt
echo "All checks passed."
