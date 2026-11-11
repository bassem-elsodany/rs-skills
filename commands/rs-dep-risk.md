---
description: Dependency supply-chain risk report for a Cargo project (yanked, advisories, build-time code, git/path sources, owners, age); --offline for the local census
allowed-tools: Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/rs-release/scripts/dep-risk.py:*)
---

# /rs-dep-risk

```
/rs-dep-risk [dir] [--offline] [--all] [--out report.md] [--json findings.json]
```

1. Run `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/rs-release/scripts/dep-risk.py $ARGUMENTS`. It sends only public crate names/versions to crates.io and OSV (nothing with `--offline`).
2. Quote its numbers verbatim; read the **Coverage** section first — *unassessable is not risk, no flags is not endorsement*.
3. Act on yanked/advisory/git-path-wildcard flags; review build-time code of new crates (Skill(rs-security-review) `sec-supply-chain-build-time-code`); pair with `cargo deny check` and `cargo audit`.
4. Record upgrade/replace decisions (Skill(rs-reuse-first) decision record).
