# Trigger keywords index

Keyword → skill. English only. The hook matcher lives in `hooks/hooks.json`.

## Error codes

| Code | Meaning | Skill |
|---|---|---|
| E0382 | use of moved value | rs-ownership |
| E0597 | borrowed value does not live long enough | rs-ownership |
| E0506 | cannot assign to borrowed value | rs-ownership |
| E0507 | cannot move out of borrowed content | rs-ownership |
| E0515 | cannot return reference to local | rs-ownership |
| E0716 | temporary value dropped while borrowed | rs-ownership |
| E0106 | missing lifetime specifier | rs-ownership |
| E0596 | cannot borrow as mutable | rs-mutability |
| E0499 | multiple mutable borrows | rs-mutability |
| E0502 | borrow conflict | rs-mutability |
| E0277 | trait bound not satisfied | rs-traits (Send/Sync → rs-concurrency) |
| E0308 | mismatched types | rs-traits |
| E0599 | no method found | rs-traits |
| E0038 | trait not dyn-compatible | rs-traits |
| E0433 | cannot find crate / module | rs-ecosystem |

## L1 Mechanics

| Keywords | Skill |
|---|---|
| ownership, borrow, lifetime, move, moved value, clone to fix borrow | rs-ownership |
| Box, Rc, Arc, Weak, RefCell, smart pointer, heap | rs-resource |
| mut, mutable, interior mutability, Cell, RefCell, Mutex, RwLock | rs-mutability |
| generic, trait, impl Trait, dyn, where clause, monomorphization, object safety | rs-traits |
| newtype, type state, PhantomData, marker trait, sealed trait, builder | rs-type-driven |
| Result, Option, ?, unwrap, expect, panic, anyhow, thiserror | rs-error-handling |
| Send, Sync, thread, async, await, channel, tokio, rayon | rs-concurrency |
| unsafe, FFI, extern, raw pointer, transmute, MaybeUninit, bindgen, cbindgen | rs-unsafe |
| actor, mailbox, supervision, graceful shutdown, Stream, backpressure, Pin, Unpin, select! cancel safety, JoinSet | rs-async-patterns |
| macro_rules, proc-macro, derive macro, syn, quote, const fn, const generics, build.rs | rs-macros-const |

## L2 Design

| Keywords | Skill |
|---|---|
| domain model, DDD, entity, value object, aggregate, business logic | rs-domain-model |
| performance, optimisation, benchmark, profiling, allocation | rs-performance |
| crate, dependency, feature flag, workspace, serde, interop, wasm, PyO3 | rs-ecosystem |
| RAII, Drop, resource lifecycle, connection pool, lazy init, OnceLock | rs-lifecycle |
| domain error, retry, circuit breaker, recovery | rs-domain-error |
| mental model, how to think, learning Rust, why does Rust | rs-mental-model |
| anti-pattern, common mistake, pitfall, code smell, idiomatic | rs-anti-pattern |
| project structure, module layout, where should this go, split this function, file too long, mod.rs, workspace, pub(crate), utils.rs, flat structure | rs-structure |
| design pattern, idiom, visitor, strategy, command, fold, RAII guard, mem::take, move out of &mut, non_exhaustive, C API / FFI API shape, Deref for inheritance | rs-patterns |
| public API, non_exhaustive, From/Into, AsRef, must_use, docs | rs-api-design |
| implement a protocol / standard / SDK / vendor API, which crate, build vs buy, from scratch, MCP server | **rs-reuse-first** |
| repository pattern, adapter, ports and adapters, hexagonal, decouple, vendor lock-in, swap database/cache/queue | **rs-ports-adapters** |

## L3 Domain

| Keywords | Skill |
|---|---|
| fintech, trading, decimal, currency, payment, ledger | rs-domain-fintech |
| web, HTTP, REST, axum, actix, handler, middleware | rs-domain-web |
| CLI, command line, clap, terminal, exit code | rs-domain-cli |
| kubernetes, docker, gRPC, tonic, microservice | rs-domain-cloud-native |
| embedded, no_std, microcontroller, firmware | rs-domain-embedded |
| IoT, sensor, MQTT, edge, telemetry | rs-domain-iot |
| ML, tensor, model, inference, ndarray | rs-domain-ml |
| gateway policy, proxy-wasm, Flex PDK, Envoy filter | rs-domain-gateway |
| database, SQL, sqlx, diesel, cache, Redis, ClickHouse, migration, connection pool | rs-domain-data |
| JWT, OAuth, OIDC, API key, password hash, session, login, RBAC | rs-domain-auth |
| policy engine, PDP, PEP, XACML, Cedar, OPA, permit/deny, combining algorithm | rs-domain-policy |
| idempotency, outbox, saga, Raft, consensus, retry budget, deadline, partition | rs-domain-distributed |
| eBPF, aya, GPU, wgpu, io_uring, SIMD, mmap, kernel bypass | rs-domain-systems |

## L4 Delivery

| Keywords | Skill |
|---|---|
| review, code review, PR review, review report | rs-review |
| naming, formatting, clippy, rustfmt, lint, code style | rs-style |
| latest version, what's new, changelog, crate info | rs-learner |
| Rust news | rs-daily |
| test, proptest, mockall, criterion, loom, snapshot | rs-testing |
| tracing, span, structured logging, metrics, redaction | rs-observability |
| release, MSRV, semver, cargo-deny, cargo-audit, CI, Docker, LTO | rs-release |
| design contract, file header | rs-design-contract |
| git, commit message, branch, rebase, tag, hooks, secrets in git, history rewrite | **rs-git** |
| security review, audit, vulnerability, threat model, DoS, untrusted input, triage, severity, supply chain | **rs-security-review** |
| fuzz, cargo-fuzz, libFuzzer, arbitrary, sanitizer, mutation testing, cargo-mutants | **rs-fuzzing** |
| fix a bug, reproduce, regression, bisect, variants, hotfix, root cause | **rs-bugfix** |
| disk full, target size, docker prune, build cache, cleanup | **rs-cleanup** |
| which skill, skill map, where to start | **rs-guide** |

## Query patterns → actions

| Pattern | Action |
|---|---|
| compare / vs / versus / difference | negotiation protocol |
| best practice / recommend / should I | negotiation protocol |
| domain keyword + error | load rs-domain-* AND the mechanics skill |
| single error code | direct lookup, no negotiation |
| version query | rs-learner, direct lookup |

## Conflict resolution

| Conflict | Resolution |
|---|---|
| unsafe: rs-ecosystem vs rs-unsafe | rs-unsafe |
| error: rs-error-handling vs rs-domain-error | mechanics → rs-error-handling; strategy → rs-domain-error |
| RAII: rs-resource vs rs-lifecycle | design → rs-lifecycle; implementation → rs-resource |
| newtype: rs-type-driven vs rs-traits | type → rs-type-driven; orphan rule → rs-traits |
| crate: rs-learner vs rs-ecosystem | version → rs-learner; integration → rs-ecosystem |

Related: [skills-index.md](./skills-index.md) · [meta-questions.md](./meta-questions.md) · [../skills/rs-router/SKILL.md](../skills/rs-router/SKILL.md)
