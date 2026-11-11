---
name: rs-domain-policy
description: "Use when designing or reviewing authorisation decisions and policy engines — PDP/PEP architecture, XACML concepts, RBAC/ABAC/ReBAC, combining algorithms, default deny, Cedar, OPA/Rego (regorus), Casbin, OpenFGA, decision logs, policy versioning and testing, governance of tools and agents. Triggers: policy engine, policy decision point, PDP, PEP, PIP, PAP, XACML, permit, deny, NotApplicable, Indeterminate, combining algorithm, deny-overrides, permit-overrides, first-applicable, default deny, obligation, advice, RBAC, ABAC, ReBAC, Zanzibar, OpenFGA, Cedar, OPA, Rego, regorus, Casbin, authorization decision, access control, policy as code, policy testing, decision log, audit trail, governance, guardrail, tool authorisation, agent permissions"
user-invocable: false
---

# Policy Decisions — PDP, PEP and engines

> **Layer 3: Domain** · where "may they?" is decided, enforced and audited, and why it is not an `if` in a handler
>
> Depth: `guides/architecture.md` · `guides/engines.md` · `guides/testing-and-audit.md` · compile-verified core: `templates/policy-engine/policy.rs`

## Core Question

**Is the decision made in one place, from explicit policy, with a default of deny, and can we later prove why it was made?**

For governance platforms (MCP/agent gateways, API gateways) the policy layer *is* the product: it must be correct, explainable, fast, testable and fail closed.

## The architecture (XACML vocabulary, engine-neutral)

```
request ─▶ PEP (enforce) ──ask──▶ PDP (decide) ◀── PIP (attributes: user, resource, risk, time)
              │ only Permit passes        │ reads policies from PAP (admin/store, versioned)
              ▼                           ▼
        allow / deny + obligations   decision + trail ──▶ audit log
```

| Part | Job | Rust shape |
|---|---|---|
| **PEP** policy enforcement point | intercepts the action (gateway filter, middleware, tool-call hook), builds the request, enforces the answer, applies obligations | thin; no policy logic; fail closed |
| **PDP** policy decision point | evaluates policies for a request, returns a decision and why | a port (`Authorizer`) with adapters: in-process rules, Cedar, OPA/regorus, remote service (rs-ports-adapters) |
| **PIP** policy information point | supplies attributes the request lacks (roles, risk score, resource owner) | port with caching; attribute failure ⇒ `Indeterminate` |
| **PAP** policy administration point | authoring, review, versioning, rollout of policies | policy-as-data in git/DB with versions and tests |

## Decisions are four-valued

| Decision | Meaning | PEP does |
|---|---|---|
| `Permit` | a policy explicitly allows | allow (apply obligations) |
| `Deny` | a policy explicitly forbids | deny |
| `NotApplicable` | no policy matched | **deny** (default deny) |
| `Indeterminate` | evaluation failed (missing attribute, engine error, timeout) | **deny**, log loudly |

`enforce(&Decision) -> bool` returns true **only** for `Permit` — see the template. A two-valued `bool` hides the difference between "no" and "I could not tell", which is exactly what fail-open bugs are made of.

## Combining algorithms (when several rules apply)

| Algorithm | Result | Use |
|---|---|---|
| **deny-overrides** | any Deny wins; Permit only if none denied and none Indeterminate | safe default; guardrails and prohibitions |
| permit-overrides | any Permit wins | additive grants (use with care) |
| first-applicable | first rule that decides | ordered rule lists (firewall style) — order is the policy |
| only-one-applicable | exactly one must apply | catch overlapping policies |

State the algorithm explicitly in the policy set; an *implicit* order is a bug waiting for a reordering. An `Indeterminate` under deny-overrides must not become `Permit`.

## Choosing the model and the engine

| Need | Model | Engine candidates (verify with `sdk-scout.sh`) |
|---|---|---|
| few stable roles | RBAC | plain enum + table; `casbin` if you want model files |
| rules over attributes (tenant, classification, tool risk, time) | ABAC | **Cedar** (`cedar-policy`, analysable, fast), OPA/Rego via **`regorus`**, in-process rules |
| sharing/ownership/hierarchy ("editor of the folder") | ReBAC (Zanzibar) | OpenFGA/SpiceDB via their clients behind a port; relation store consistency matters |
| central policy shared by many services in many languages | OPA (sidecar/server) or Cedar service | PDP as a remote adapter with timeout → `Indeterminate` → deny |
| ultra-low latency at a gateway | in-process engine, compiled policies, decision cache keyed with the policy epoch | wasm-compatible engine only if it builds for the target (rs-domain-gateway) |

Prefer a **policy language over code** when rules change often, must be reviewed by non-developers, or must be analysable ("can anyone reach X?"). Prefer plain Rust for a handful of fixed rules.

## Rules

| Rule | Detail |
|---|---|
| **Default deny; Indeterminate denies** | `policy-default-deny` |
| **One decision point, many enforcement points** | handlers/filters ask, never decide (`policy-single-pdp`) |
| **Explicit combining algorithm** | in the policy data, tested (`policy-explicit-combining`) |
| **Every decision is logged with its trail** | request summary, policy version, rules fired, result, latency — no secrets (`policy-decision-log`) |
| **Policies are versioned data with tests** | decision tables as golden tests; rollout with canary/shadow mode; rollback (`policy-as-tested-data`) |
| **Cache decisions only with the policy epoch and full request key in the key** | a stale allow after a revocation is a breach (rs-domain-data caching) |
| **Attributes come from trusted sources** | identity from the verified token; never from client-settable headers (rs-domain-auth) |
| **Obligations are mandatory** | "permit *and* redact field X", "permit *and* log": if the PEP cannot fulfil an obligation, deny |

## Trace

| Direction | Go to |
|---|---|
| ↑ Up | rs-domain-auth (who is the principal), rs-domain-gateway (PEP in a filter chain, property contracts), rs-domain-cloud-native |
| ↓ Down | rs-ports-adapters (`Authorizer` port + memory fake + contract suite), rs-error-handling (`err-fail-closed`), rs-type-driven (`Decision` as enum, `Principal` newtypes), rs-performance (decision latency) |
| → Delivery | rs-testing (decision tables, property tests: "adding a Deny never turns a Deny into a Permit"), rs-observability (decision log), rs-review (security pass) |

<!-- rules-index:start -->
## Rules (5)

Depth rules under `rules/` — open the one the question needs, not all of them.

**policy-**

- [`policy-as-tested-data`](rules/policy-as-tested-data.md) — Version policies, test them with decision tables, roll out in shadow mode
- [`policy-decision-log`](rules/policy-decision-log.md) — Log every decision with its trail and policy version; never the secrets
- [`policy-default-deny`](rules/policy-default-deny.md) — Only an explicit Permit passes; NotApplicable and Indeterminate deny
- [`policy-explicit-combining`](rules/policy-explicit-combining.md) — Name the combining algorithm; never rely on rule order by accident
- [`policy-single-pdp`](rules/policy-single-pdp.md) — Decide in one place; enforcement points only ask and obey

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| Identity, tokens, sessions | rs-domain-auth |
| Gateway enforcement | rs-domain-gateway |
| Making the engine replaceable | rs-ports-adapters |
| Picking Cedar/OPA/OpenFGA | rs-reuse-first |
