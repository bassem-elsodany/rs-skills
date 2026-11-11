---
description: Search crates.io and GitHub for the official / de-facto SDK before implementing a standard, protocol or vendor API
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/skills/rs-reuse-first/scripts/sdk-scout.sh:*)
---

# /rs-sdk-scout

```
/rs-sdk-scout <term> [<term>...] [--limit N] [--github]
```

1. Run `${CLAUDE_PLUGIN_ROOT}/skills/rs-reuse-first/scripts/sdk-scout.sh $ARGUMENTS --github`.
2. Read the flags: `OFFICIAL?` (repo owned by the spec/vendor org), `STALE` (no release for 12 months), `IN-TREE` (already a dependency). Cross-check `${CLAUDE_PLUGIN_ROOT}/skills/rs-reuse-first/registry/standards.md`.
3. Evaluate the top candidates with the scorecard in `skills/rs-reuse-first/rules/reuse-evaluate-candidate.md` (spec version, roles/transports, health, licence, MSRV).
4. Answer with the **Reuse report** from Skill(rs-reuse-first): need, searched, chosen (+why), runner-up, gaps. Hand-rolling needs a decision record (`templates/decision-record.md`).
5. Isolate the choice behind a port: Skill(rs-ports-adapters).
