# policy-decision-log

> Log every decision with its trail and policy version; never the secrets
> **rs-domain-policy · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

"Why was this allowed?" is the first question after an incident and the main thing auditors ask. Without the rules fired and the policy version you cannot answer it.

## Do

Record: time, trace id, principal (+ delegated-for), action, resource id/type, decision, trail of rule ids, policy version, obligations, latency. Hash or classify payload data; no tokens or secrets (`obs-no-sensitive-data`). Write via an `AuditStore` port with batching and backpressure (rs-domain-data); decide per risk whether audit failure blocks the action.

## Bad

`info!("authz ok")` — no principal, no resource, no policy version, no reason.

## See Also

- [policy-as-tested-data](policy-as-tested-data.md)
