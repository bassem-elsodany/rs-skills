# policy-as-tested-data

> Version policies, test them with decision tables, roll out in shadow mode
> **rs-domain-policy · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A policy change is a production change with security impact. It needs review, tests and a rollback exactly like code.

## Do

- Policies in git (or a versioned store) with an epoch/hash; loaded atomically; failed load keeps the previous set.
- Decision-table tests per policy file; properties ("adding a Deny never permits"); regression fixtures from incidents.
- Shadow-evaluate new policy against live traffic, diff, then promote; canary by tenant; roll back by epoch.
- Decision caches include the epoch in the key.

## See Also

- [policy-decision-log](policy-decision-log.md)
- [rs-domain-data cache-stampede-and-jitter](../../rs-domain-data/rules/cache-stampede-and-jitter.md)
