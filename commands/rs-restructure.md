---
description: Analyse a flat or tangled Rust crate and restructure it into feature modules, in compiling steps
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/structure-map.sh:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/structure-check.sh:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh:*), Bash(cargo check:*), Bash(cargo clippy:*), Bash(cargo test:*), Bash(git mv:*), Bash(git status:*)
---

# /rs-restructure

Turn a flat `src/` into feature modules without rewriting code.

```
/rs-restructure [crate-dir] [--plan-only]
```

Steps (Skill(rs-structure) → `guides/restructure-existing.md` is the manual):
1. `${CLAUDE_PLUGIN_ROOT}/scripts/structure-map.sh <dir>` and `${CLAUDE_PLUGIN_ROOT}/scripts/structure-check.sh <dir>` — read the inventory and the smells.
2. Cluster files by feature (types → `use` edges → names). Decide what goes to `shared/<topic>.rs` (≥3 features) and what goes next to its single caller (`utils.rs` contents).
3. Write the **target tree** and show it to the user as the `lib.rs` Design Contract **Layout** line plus a tree diagram. Stop here with `--plan-only`, or wait for a yes.
4. Apply leaves-first: `shared/` → one feature at a time (`git mv`, create `mod.rs` with `mod` lines and `pub use` for previously public paths) → `main.rs` last (extract `run` into `lib.rs`). `cargo check` after every feature; never mix moves with logic edits.
5. Narrow visibility (`pub(super)`/`pub(crate)`), add `#![warn(unreachable_pub)]`, write Design Contracts for every new `mod.rs`/file (Skill(rs-design-contract)).
6. Finish with `cargo clippy --all-targets`, `cargo test`, `${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh`, `${CLAUDE_PLUGIN_ROOT}/scripts/structure-check.sh`; report the before/after tree and remaining smells.
