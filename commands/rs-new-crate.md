---
description: Scaffold a production-ready Rust crate (Design Contracts, lint policy, CI, deny.toml, Dockerfile) with rs-skills
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/new-crate.sh:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/release-check.sh:*), Bash(cargo:*)
---

# /rs-new-crate

```
/rs-new-crate <name> [--lib|--bin|--service] [--ci github|gitlab|none] [--dir parent]
```

1. Ask only what is missing: kind (library / binary / service) and CI flavour. Default: `--bin --ci github`.
2. `${CLAUDE_PLUGIN_ROOT}/scripts/new-crate.sh $ARGUMENTS` — creates Cargo.toml (edition 2024, MSRV, `[lints]` policy, release profile), `src/` with a Design Contract in every file and a feature-module layout, tests, `deny.toml`, `CHANGELOG.md`, CI file, Dockerfile (binaries).
3. Run `cargo test` and `${CLAUDE_PLUGIN_ROOT}/scripts/release-check.sh <dir> --no-net`; both must pass before handing over.
4. Replace the TODOs (description, repository) with the user, then explain the layout in two lines: where features go (`src/<feature>/`) and what `main.rs`/`lib.rs` may contain (Skill(rs-structure)).
