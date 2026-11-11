---
description: Run the rs-release pre-release gate on a crate (lints, tests, docs, contracts, structure, supply chain, semver)
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/release-check.sh:*), Bash(cargo install:*)
---

# /rs-release-check

```
/rs-release-check [crate-dir] [--strict] [--no-net]
```

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/release-check.sh $ARGUMENTS`.
2. For each **FAIL**: fix it (Skill(rs-release) for lint/MSRV policy, Skill(rs-testing) for failing tests, Skill(rs-design-contract) for missing contracts, Skill(rs-structure) for structure smells) and re-run.
3. For each **WARN** about a missing tool, offer the install command (`cargo install cargo-deny --locked`, `cargo-semver-checks`, `cargo-msrv`) — do not install without asking.
4. Report the final summary line, the version to be released and the CHANGELOG entry that should accompany it (BREAKING / MSRV bump flagged).
