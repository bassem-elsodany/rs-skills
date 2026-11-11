---
description: Threat-model-first security review of a Rust crate or change set, with capability probe, bug-class passes and a triage verdict per finding
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/skills/rs-security-review/scripts/rust-caps.sh:*), Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/rs-review/scripts/diff-review.py:*), Bash(${CLAUDE_PLUGIN_ROOT}/skills/rs-review/scripts/review-report.sh:*)
---

# /rs-security-review

```
/rs-security-review [path] [--threat REMOTE | LOCAL_UNPRIVILEGED | BOTH] [--diff <base>]
```

1. Ask for the **threat model** if not given; list entry points and trust boundaries.
2. `rust-caps.sh <path>` → the passes to run. With `--diff <base>` also run `diff-review.py --base <base>`.
3. Run the passes (Skill(rs-security-review) table → `rules/sec-*`, rs-unsafe checklists, rs-concurrency, rs-domain-auth/policy/gateway).
4. **Triage every candidate** (`guides/triage.md`): restate → verdict → seven dismissal tests → gates → severity for this threat model. Report traced flows, not patterns.
5. Write the report through Skill(rs-review) (`review-report.sh <path> --scope <name> [--diff <base>]`): P1 cards, work log, Coverage. Offer rs-fuzzing for parsers and rs-bugfix for confirmed bugs.
