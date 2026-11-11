# Cognitive layer definitions (rs-skills)

> Four layers. actionbook's L1–L3 are kept as-is; L4 Delivery is new because
> "production Rust" means tests, observability and release engineering are
> first-class concerns.

```
┌──────────────────────────────────────────────────────────────┐
│  L4 Delivery (SHIP)      tests · observability · release · style │
├──────────────────────────────────────────────────────────────┤
│  L3 Domain (WHY)         business rules · regulation · SLAs      │
├──────────────────────────────────────────────────────────────┤
│  L2 Design (WHAT)        patterns · API shape · trade-offs       │
├──────────────────────────────────────────────────────────────┤
│  L1 Mechanics (HOW)      ownership · types · errors · async      │
└──────────────────────────────────────────────────────────────┘
```

## L1 Mechanics (HOW)

Rust language features, compiler rules, runtime behaviour.

| Category | Skill |
|---|---|
| Ownership, borrowing, lifetimes | rs-ownership |
| Smart pointers, heap/stack | rs-resource |
| Mutability, interior mutability | rs-mutability |
| Generics, traits, dispatch, zero-cost abstraction | rs-traits |
| Type-driven design: newtype, type state, builder | rs-type-driven |
| Result/Option, panics, error types | rs-error-handling |
| Threads, async, Send/Sync, channels | rs-concurrency |
| unsafe, FFI, soundness | rs-unsafe |
| Actors, shutdown, streams, Pin | rs-async-patterns |
| Macros, const evaluation | rs-macros-const |

Entry signals: `E0xxx`, compile errors, runtime panics.
Key questions: What rule is violated? What is the idiomatic fix?

## L2 Design (WHAT)

Design patterns, module structure, trade-offs.

| Category | Skill |
|---|---|
| Domain modelling (DDD) | rs-domain-model |
| Design patterns & idioms catalogue | rs-patterns |
| Project & module structure, split ladder, visibility | rs-structure |
| Public API design | rs-api-design |
| Performance patterns | rs-performance |
| Crate ecosystem, serde, workspaces | rs-ecosystem |
| Resource lifecycle, RAII | rs-lifecycle |
| Domain error strategy | rs-domain-error |
| Mental models | rs-mental-model |
| Anti-patterns | rs-anti-pattern |
| Reuse the official SDK before building a standard | rs-reuse-first |
| Ports & adapters: decouple anything replaceable | rs-ports-adapters |

Entry signals: "how to design…", "which pattern…", "trade-off…", "best practice…".
Key questions: Which pattern fits? What does it trade away?

## L3 Domain (WHY)

Business rules, regulatory requirements, domain invariants.

| Domain | Skill |
|---|---|
| Financial technology | rs-domain-fintech |
| Web services | rs-domain-web |
| CLI applications | rs-domain-cli |
| Embedded systems | rs-domain-embedded |
| IoT | rs-domain-iot |
| Machine learning | rs-domain-ml |
| Cloud native | rs-domain-cloud-native |
| API gateways, proxy-wasm policies | rs-domain-gateway |
| Databases, caches, analytics stores | rs-domain-data |
| Authentication and authorisation | rs-domain-auth |
| Policy decision points and engines | rs-domain-policy |
| Distributed systems | rs-domain-distributed |
| Kernel, GPU, I/O, SIMD | rs-domain-systems |

Entry signals: "building a [domain] app", "must be auditable", "users expect…".
Key questions: Which constraints cannot be violated? What trade-offs does the domain allow?

## L4 Delivery (SHIP)

Everything between "it compiles" and "it is running in production".

| Category | Skill |
|---|---|
| Code style, naming, clippy, rustfmt | rs-style |
| Testing strategy: unit, property, mocks, benches, loom | rs-testing |
| Observability: tracing, spans, structured fields, redaction | rs-observability |
| Release engineering: MSRV, profiles, cargo-deny/audit/semver, CI, Docker | rs-release |
| Design Contract headers in every generated file | rs-design-contract |
| Review reports (day folders, cards, work log) | rs-review |
| Version control from design to release, any Git host | rs-git |
| Security hunt and triage (threat model, sec-* classes) | rs-security-review |
| Fuzzing and mutation testing | rs-fuzzing |
| Bug fixing: failing test, invariant fix, variants, proof | rs-bugfix |
| Build/Docker/disk hygiene and the cleanup report | rs-cleanup |

Entry signals: "review", "clean up", "ready to ship", "release", "CI", "add tests", "add tracing".
Key questions: Is it testable? Observable? Releasable without surprises?

## Layer interactions

```
Design time   L3 → L2 → L1 → L4     constraint → pattern → implementation → shippable
Debug time    L1 → L2 → L3          symptom → why this design → which constraint
Review time   L4 → L2 → L1          is it shippable → is the design right → is the code right
```

## Mapping table

| Question type | Entry | Direction |
|---|---|---|
| compiler error | L1 | UP ↑ |
| "how to fix…" | L1 | UP ↑ |
| "what pattern…" | L2 | DOWN ↓ |
| "best practice…" | L2 | BOTH ↕ |
| "building [domain]…" | L3 | DOWN ↓ |
| "why in Rust…" | L2 (rs-mental-model) | UP ↑ |
| performance issue | L1 → L2 | UP then DOWN |
| review / release | L4 | DOWN ↓ |
