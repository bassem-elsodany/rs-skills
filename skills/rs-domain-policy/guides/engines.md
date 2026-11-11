# Engines — what to use when

> **rs-domain-policy · guide** — verified on crates.io 2026-11-11; confirm versions with `skills/rs-reuse-first/scripts/sdk-scout.sh`

| Engine | Language | Strengths | Watch |
|---|---|---|---|
| **Cedar** — `cedar-policy` 4.x (cedar-policy/cedar) | Cedar (readable permit/forbid with conditions) | formal analysis, fast, deny-by-default, `forbid` overrides `permit`; schema validation; entity store | entities (principal/resource hierarchy) must be supplied per request; policy store/versioning is yours |
| **OPA / Rego** — `regorus` 0.x (Microsoft, pure-Rust Rego interpreter) or OPA server/sidecar | Rego | huge ecosystem, bundles, decision logs, works across languages | Rego learning curve; `regorus` coverage of Rego builtins — check; sidecar adds a network hop (timeout ⇒ Indeterminate) |
| **Casbin** — `casbin` | model files (ACL/RBAC/ABAC) | simple RBAC/ABAC with adapters | looser semantics; check maintenance and async support |
| **OpenFGA / SpiceDB** — `openfga-client` etc. | relationship tuples (Zanzibar) | sharing/hierarchy at scale | external service; consistency tokens; latency |
| in-process Rust rules | Rust | fastest, simplest, type-checked | changes need a release; fine for a small fixed rule set |

Selection heuristics:
- Rules reviewed by security/compliance people or changing weekly → a policy language (Cedar, Rego).
- Must run inside a wasm filter → check that the engine builds for `wasm32` and has no thread/network needs; else evaluate at a sidecar PDP and treat unavailability as deny, or compile a minimal rule table into the filter (document why, rs-reuse-first decision record).
- Don't write your own policy language or evaluator for anything non-trivial: you will re-discover conflict resolution, analysis and tooling the hard way. A small combining-algorithm core (as in the template) around an engine's per-policy results is fine.

Always behind the `Authorizer` port; always with the decision table contract suite; always default deny.
