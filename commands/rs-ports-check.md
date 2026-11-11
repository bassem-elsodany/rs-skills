---
description: Find vendor/product code that leaked out of the adapter layer (ports & adapters)
allowed-tools: Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/port-check.py:*)
---

# /rs-ports-check

```
/rs-ports-check [dir] [--strict] [--adapters a,b] [--allow x.rs]
```

1. Run `python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/port-check.py $ARGUMENTS`.
2. For each LEAK/SQL/CFG/DEP/NOPORT finding: define the port in the feature module, move the vendor code to `adapters/<product>/`, map types and errors there (Skill(rs-ports-adapters): `port-no-vendor-in-domain`, `port-row-types`, `port-map-errors`).
3. Add or extend the contract suite so every adapter passes the same cases (`port-contract-tests`), then run the swap drill (`port-swap-drill`).
4. Re-run until clean; keep it in the release gate (`--strict`).
