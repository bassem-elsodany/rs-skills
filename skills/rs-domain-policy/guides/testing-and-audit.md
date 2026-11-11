# Testing, rollout and audit of policies

> **rs-domain-policy · guide**

## Test pyramid

| Level | What | How |
|---|---|---|
| decision table | `(request, expected decision)` rows covering each rule and each combining case | table-driven test; same table runs against every `Authorizer` adapter |
| negative space | missing attribute → not Permit; empty policy set → not Permit; unknown action → not Permit | one test per class (see the template's tests) |
| properties | adding a `Deny` rule never turns a Deny into a Permit; permutation of rules under deny-overrides gives the same answer; `Indeterminate` never yields Permit | `proptest` (rs-testing) |
| golden/regression | past incidents as fixtures ("this request was wrongly allowed in March") | files in the repo, replayed in CI |
| integration | PEP + PDP: gateway returns 403 and the audit log has the trail | scenario tests (rs-testing `test-env-bound-integration`) |

## Rollout

- Policies are versioned artefacts (`policy_epoch`/hash) loaded atomically (`arc-swap` of a compiled set); a failed load keeps the previous version and alerts.
- **Shadow mode:** evaluate the new policy alongside the live one, log differences, enforce only the live one; promote when diffs are explained.
- Canary by tenant; instant rollback by epoch.
- Review: policy changes go through the same review as code (rs-git) with the decision table diff in the description.

## Decision log (audit)

Per decision record: timestamp, request id/trace id, principal (id, tenant, delegated-for), action, resource id/type, decision, **rules fired (trail)**, policy version/epoch, obligations, latency, PEP identity. **Not**: tokens, secrets, raw payloads (hash/classify). Write through a port to an append-only store (rs-domain-data `analytics-stores`), batch with backpressure; decide whether audit failure blocks the action (usually yes for high-risk operations: fail closed). The log must let you answer "why was X allowed on date D?" months later — hence the policy version.

## Metrics

Decisions by result and rule, `Indeterminate` rate (attribute/engine health), decision latency p50/p99, cache hit ratio, policy load failures. Alert on a rising `Indeterminate` rate — it is a denial-of-service on your users and a sign of a broken dependency.
