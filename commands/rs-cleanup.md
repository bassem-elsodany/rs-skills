---
description: Show disk usage of builds, containers and caches; plan and apply a tiered cleanup (dry-run by default)
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/skills/rs-cleanup/scripts/disk-guard.sh:*), Bash(${CLAUDE_PLUGIN_ROOT}/skills/rs-cleanup/scripts/cleanup.sh:*)
---

# /rs-cleanup

```
/rs-cleanup [status | plan | apply] [dir] [--tier safe|more|all] [--volumes]
```

1. `status` (default): run `disk-guard.sh status` and report free space, every `target/`, caches and Docker usage against the budgets.
2. `plan`: run `cleanup.sh plan [dir] [--tier ...]` and show the plan. Nothing is deleted.
3. `apply`: only after the user has seen the plan. Run `cleanup.sh apply ...`; volumes only when the user explicitly asked (`--volumes`).
4. Finish with a **Cleanup report** (before → after, removed, left in place and why) — Skill(rs-cleanup).
