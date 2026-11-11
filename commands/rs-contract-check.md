---
description: Check that every Rust source file carries a valid Design Contract header
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh:*)
---

# /rs-contract-check

Run the Design Contract checker on the current project (or a given path).

```
/rs-contract-check [path] [--all]
```

Steps:
1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh $ARGUMENTS`.
2. For every `MISSING` file: read it, infer Role / Patterns / Invariants / Extend by from the code and its callers, and propose a contract block (use `Skill(rs-design-contract)` for the field rules). Do not write it without showing it first.
3. For every `INVALID` file: fix the specific complaint (too long, missing field, unknown skill or page).
4. Report the summary line and what you changed.
