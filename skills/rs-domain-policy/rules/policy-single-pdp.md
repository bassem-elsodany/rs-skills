# policy-single-pdp

> Decide in one place; enforcement points only ask and obey
> **rs-domain-policy · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Authorisation logic copied into handlers drifts: one endpoint forgets a check, another interprets a role differently. A single decision point can be tested, audited and changed once.

## Do

- Business code calls `authorizer.decide(&request)` (a port) and `enforce`s the result; no `if role == …` in handlers or filters.
- The same `Request` model for every PEP (HTTP, gateway, MCP tool call, batch job).
- Defence in depth is fine (tenant filters in SQL) but the *decision* lives in the PDP.

## Bad

```rust
if user.roles.contains("admin") || (user.tenant == doc.tenant && req.method == "GET") { /* … */ }   // policy buried in a handler
```

## See Also

- [policy-default-deny](policy-default-deny.md)
- [rs-ports-adapters port-design-by-need](../../rs-ports-adapters/rules/port-design-by-need.md)
