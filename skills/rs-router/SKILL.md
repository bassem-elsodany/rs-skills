---
name: rs-router
description: |-
  CRITICAL: Use FIRST for ALL Rust questions — errors, design, code writing, review, release.
  HIGHEST PRIORITY for: compare, vs, versus, difference, best practice, recommend, should I use.
  Triggers on: Rust, cargo, rustc, crate, Cargo.toml, .rs files,
  compile error, borrow error, lifetime error, ownership error, type error, trait error,
  value moved, cannot borrow, does not live long enough, mismatched types, trait bound not satisfied,
  E0382, E0597, E0277, E0308, E0499, E0502, E0596, E0433,
  async, await, Send, Sync, tokio, concurrency, error handling, unsafe, FFI,
  design pattern, idiom, anti-pattern, builder, newtype, RAII, API design,
  performance, benchmark, testing, clippy, release, production, ship,
  how to, why, what is, implement, explain, help me write
---

# rs-router — Rust question router

> **rs-skills** · entry point · v1.1

## Core principle

**Don't answer directly. Identify the layer, load the entry skill, trace.**

### Gates before you build (apply to every task, in this order)

| Gate | Trigger | Do |
|---|---|---|
| **Reuse first** | the task implements a standard, protocol, file format or vendor/product API (MCP, JSON-RPC, OAuth/JWT, gRPC, Kafka, Redis, ClickHouse, S3, Kubernetes …) | **Skill(rs-reuse-first) before any design**: `sdk-scout.sh`, official/de-facto SDK, decision record; never draft the protocol from memory |
| **Decouple what can change** | code touches a database, cache, queue, search/analytics engine, SDK, downstream service, LLM provider | Skill(rs-ports-adapters): port + adapters + contract tests; vendor types stay in `adapters/` |
| **Clean up** | you will build, test, run containers or build images | Skill(rs-cleanup): `disk-guard.sh status` first, label what you create, finish with cleanup + report |
| **Untrusted input / security** | the code parses, filters, authorises, deserialises, runs as a service, or the task says review/audit/vulnerability | Skill(rs-security-review): threat model first, `rust-caps.sh`, `sec-*` classes, triage; fuzz parsers with Skill(rs-fuzzing) |
| **Version control** | you will commit, branch, tag, rewrite history | Skill(rs-git): atomic conventional commits, no secrets/artefacts, no AI trailers unless asked |
| **Lost?** | unsure which skill applies | Skill(rs-guide): the navigation map and lifecycle |

### Design Contract rule (applies to every `.rs` file you touch)

| Action | Rule |
|---|---|
| Creating a `.rs` file under `src/` | First decide *where it lives* — Skill(rs-structure); then write its `//! # Design Contract` — Skill(rs-design-contract) |
| A function or file is too long | Follow the rs-structure split ladder (extract → promote to directory → feature module); never leave the pieces in a flat `src/` |
| Editing a `.rs` file | Read its Design Contract; follow **Extend by**, respect **Avoid**; update it if the design changes |
| Reviewing | Code vs contract mismatch is a finding |

```
L4 Delivery   (SHIP)   Is it testable, observable, releasable?      rs-style (+ L4 skills in later phases)
L3 Domain     (WHY)    Which domain constraints shape the design?   rs-domain-*
L2 Design     (WHAT)   Which pattern / trade-off fits?              rs-domain-model … rs-anti-pattern
L1 Mechanics  (HOW)    How is it implemented in Rust?               rs-ownership … rs-unsafe
```

### Routing by entry point

| User signal | Entry | Direction | First skill |
|---|---|---|---|
| E0xxx / compile error | L1 | Trace UP ↑ | error table below |
| "How to design…", "which pattern…", "is there an idiom…" | L2 | check L3, then DOWN ↓ | rs-patterns / rs-domain-model |
| "Where should this go", "split this", "too long", "organise the modules", new file/crate | L2 | DOWN ↓ | **rs-structure** |
| "Building a [domain] app" | L3 | Trace DOWN ↓ | rs-domain-* |
| "Best practice…", "compare…" | L2 | both ↕ + negotiation | L2 skills |
| Performance issue | L1 → L2 | UP then DOWN | rs-performance |
| "Review / clean up / is this idiomatic" | L4 → L2 | DOWN ↓ | rs-review (report), rs-anti-pattern, rs-style |
| "Ready to ship / release / CI" | L4 | DOWN ↓ | rs-release, rs-testing, rs-observability |
| "Implement <protocol / SDK / standard / vendor client>" | L2 gate | **before design** | **rs-reuse-first**, then rs-ports-adapters |
| "Swap / decouple / repository / adapter / vendor lock-in" | L2 | DOWN ↓ | **rs-ports-adapters** |
| commit / branch / tag / revert / history | L4 | — | **rs-git** |
| security review / audit / vulnerability / "is this exploitable" / threat model | L4 | — | **rs-security-review** (+ rs-review for the report) |
| fuzz / cargo-fuzz / harness / mutation testing / "are my tests good" | L4 | — | **rs-fuzzing** |
| fix this bug / regression / bisect / same bug elsewhere / hotfix | L4 | — | **rs-bugfix** |
| review a PR/MR/diff | L4 | — | **rs-review** (`--diff`, `guides/differential-review.md`) |
| disk full / docker images / target dir / cleanup | L4 | — | **rs-cleanup** |
| "which skill?" / onboarding | Entry | — | **rs-guide** |

### CRITICAL — dual-skill loading

When a domain keyword is present you MUST load the mechanics skill **and** the domain skill:

| Domain keywords | L1/L2 skill | L3 skill |
|---|---|---|
| web API, HTTP, REST, axum, actix, handler, middleware | rs-concurrency | **rs-domain-web** |
| gateway policy, proxy-wasm, Envoy filter, Flex Gateway, PDK, request/response filter | rs-error-handling | **rs-domain-gateway** |
| payment, trading, fintech, decimal, currency, ledger | rs-ownership, rs-type-driven | **rs-domain-fintech** |
| CLI, terminal, clap, exit code, config precedence | rs-error-handling | **rs-domain-cli** |
| kubernetes, docker, gRPC, tonic, microservice, graceful shutdown | rs-concurrency | **rs-domain-cloud-native** |
| embedded, no_std, MCU, firmware, interrupt | rs-resource | **rs-domain-embedded** |
| IoT, sensor, MQTT, telemetry, edge | rs-concurrency | **rs-domain-iot** |
| ML, tensor, model, inference, ndarray | rs-performance | **rs-domain-ml** |
| database, SQL, sqlx, cache, Redis, ClickHouse, migration, pool | rs-error-handling, rs-ports-adapters | **rs-domain-data** |
| JWT, OAuth, OIDC, API key, password, session, login | rs-error-handling, rs-type-driven | **rs-domain-auth** |
| policy engine, PDP/PEP, RBAC/ABAC, Cedar, OPA, permit/deny | rs-error-handling, rs-ports-adapters | **rs-domain-policy** |
| retries, idempotency, outbox, saga, consensus, timeouts across services | rs-concurrency, rs-domain-error | **rs-domain-distributed** |
| eBPF, GPU, io_uring, SIMD, mmap, kernel bypass | rs-unsafe, rs-performance | **rs-domain-systems** |

---

## Negotiation protocol

| Query contains | Action |
|---|---|
| compare, vs, versus, difference | **MUST negotiate** |
| best practice, recommend, should I | **MUST negotiate** |
| domain + error (e.g. "trading system E0382") | **MUST negotiate** (dual load) |
| ambiguous scope ("tokio performance") | SHOULD negotiate |

Output template → `patterns/negotiation.md`.

---

## L1 Mechanics

| Pattern | Route to |
|---|---|
| move, borrow, lifetime, `'a`, `'static`, clone to escape borrowck | rs-ownership |
| Box, Rc, Arc, Weak, heap vs stack, reference counting | rs-resource |
| mut, interior mutability, Cell, RefCell, Mutex, RwLock | rs-mutability |
| generic, trait, impl Trait, dyn, where, monomorphization, object safety | rs-traits |
| newtype, type state, PhantomData, marker trait, sealed trait, builder | rs-type-driven |
| Result, Option, `?`, panic, unwrap, anyhow, thiserror | rs-error-handling |
| Send, Sync, thread, async, await, channel, tokio, rayon | rs-concurrency |
| actor, mailbox, supervision, graceful shutdown, Stream/backpressure, Pin/Unpin, `select!` cancel safety, `JoinSet` | **rs-async-patterns** |
| macro_rules, derive/proc-macro, syn/quote, const fn, const generics, build.rs codegen | **rs-macros-const** |
| unsafe, FFI, extern, raw pointer, transmute, MaybeUninit, bindgen | **rs-unsafe** (API shape: rs-patterns FFI pages) |

## L2 Design

| Pattern | Route to |
|---|---|
| design pattern, idiom, anti-pattern, builder, newtype, visitor, strategy, command, RAII guard, mem::take, move out of &mut, non_exhaustive, Deref for inheritance | **rs-patterns** |
| implement a protocol/standard/SDK/vendor API, "which crate", "is there a library for", build vs buy | **rs-reuse-first** (before anything else) |
| repository pattern, adapter, ports and adapters, hexagonal, decouple DB/cache/queue/SDK, vendor lock-in, swap product | **rs-ports-adapters** |
| C API, expose Rust to C, FFI API shape, strings across FFI, errors across FFI | **rs-patterns** (`design-patterns/ffi/`, `idioms/ffi/`) + rs-unsafe |
| project structure, module layout, where does this go, split function/file, too long, mod.rs, lib.rs vs main.rs, workspace, pub(crate), utils.rs | **rs-structure** |
| public API, library design, breaking change, From/Into, AsRef, must_use, sealed trait, rustdoc, doc comments, # Errors section | **rs-api-design** |
| domain model, entity, value object, aggregate, business rule | rs-domain-model |
| performance, optimisation, allocation, benchmark, profiling | rs-performance |
| crate selection, dependencies, features, workspace, serde, interop | rs-ecosystem |
| resource lifecycle, RAII, Drop, pool, lazy init, OnceLock | rs-lifecycle |
| domain error, retry, circuit breaker, recovery strategy | rs-domain-error |
| mental model, how to think, "why does Rust…", coming from <language> | rs-mental-model |
| anti-pattern, code smell, common mistake, pitfall, "is this bad", Deref polymorphism, clone to satisfy borrowck | rs-anti-pattern (+ rs-patterns `anti-patterns/`) |

## L3 Domain

| Keywords | Route to |
|---|---|
| fintech, trading, decimal, currency, audit | rs-domain-fintech |
| ML, tensor, model, inference | rs-domain-ml |
| kubernetes, docker, gRPC, microservice | rs-domain-cloud-native |
| IoT, sensor, MQTT, edge | rs-domain-iot |
| web server, HTTP, REST, axum, actix | rs-domain-web |
| proxy-wasm, Envoy wasm filter, Flex Gateway PDK, gateway policy | rs-domain-gateway |
| CLI, command line, clap, terminal | rs-domain-cli |
| no_std, microcontroller, firmware | rs-domain-embedded |

## L4 Delivery

| Keywords | Route to |
|---|---|
| security review, audit, vulnerability, threat model, DoS, untrusted input, triage, false positive, supply chain | **rs-security-review** |
| fuzz, cargo-fuzz, libFuzzer, arbitrary, sanitizer, mutation testing, cargo-mutants | **rs-fuzzing** |
| fix a bug, reproduce, regression, bisect, variant analysis, hotfix | **rs-bugfix** |
| review, code review, PR/MR review, review report, is this production ready | **rs-review** (writes `<docs>/rs-reviews/YYYY-MM-DD-<scope>.md` in the project's docs folder) |
| naming, formatting, code style, pattern matching idioms, macros | rs-style |
| test, unit test, integration test, doctest, mock, proptest, snapshot, loom, criterion, how do I test | **rs-testing** |
| logging, tracing, span, instrument, structured logs, metrics, redact, what to log | **rs-observability** |
| release, ship, production ready, CI, clippy config, lints, MSRV, semver, cargo-deny, release profile | **rs-release** |
| design contract, file header, new module, lib.rs, main.rs, extend this file | **rs-design-contract** |
| git, commit message, branch, rebase, tag, release flow, hooks, secrets in git, history rewrite | **rs-git** |
| disk full, `target/` size, docker image/build cache, prune, cleanup, testcontainers left running | **rs-cleanup** |
| latest version, what's new, changelog, crate info | rs-learner |
| Rust news digest | rs-daily |

> Commands: `/rs-review` · `/rs-release-check` · `/rs-new-crate` · `/rs-restructure` · `/rs-contract-check` · `/rs-sdk-scout` · `/rs-ports-check` · `/rs-git-check` · `/rs-cleanup` · `/rs-diff-review` · `/rs-dep-risk` · `/rs-security-review`. Map of everything: **rs-guide**.

---

## Error code routing

| Code | Route to | Common cause |
|---|---|---|
| E0382 | rs-ownership | use of moved value |
| E0597 | rs-ownership | borrowed value does not live long enough |
| E0506 | rs-ownership | cannot assign to borrowed |
| E0507 | rs-ownership | cannot move out of borrowed content — if you need to move a field out of `&mut self`, see rs-patterns `idioms/mem-replace.md` |
| E0515 | rs-ownership | returning reference to local |
| E0716 | rs-ownership | temporary value dropped while borrowed |
| E0106 | rs-ownership | missing lifetime specifier |
| E0596 | rs-mutability | cannot borrow as mutable |
| E0499 | rs-mutability | two mutable borrows |
| E0502 | rs-mutability | mutable + immutable borrow conflict |
| E0277 | rs-traits / rs-concurrency | trait bound not satisfied (Send/Sync → rs-concurrency) |
| E0308 | rs-traits | mismatched types |
| E0599 | rs-traits | no method found |
| E0038 | rs-traits | trait not dyn-compatible |
| E0433 | rs-ecosystem | cannot find crate / module |

Full table: `index/error-codes.md`.

---

## Tooling routes

| Need | Route to |
|---|---|
| latest Rust / crate version | **rs-learner** → agents rs-changelog, crate-researcher |
| API docs | agent docs-researcher |
| clippy lint details | agent clippy-researcher |
| navigate code, call graph, symbols, trait impls, refactor impact | rs-code-navigator, rs-call-graph, rs-symbol-analyzer, rs-trait-explorer, rs-refactor-helper |
| dependency graph | rs-deps-visualizer |
| create / fix a skill | rs-skill-creator, rs-util-fix-skill-docs |
| how the skills fit together, where to start | **rs-guide** |
| start a new crate | `/rs-new-crate` (rs-release, rs-structure, rs-design-contract) |
| review / ship | `/rs-review`, `/rs-release-check` |
| parallel 3-layer analysis | rs-meta-parallel |

---

## Priority order

1. **Identify layer** (L1 / L2 / L3 / L4).
2. **Load the entry skill.**
3. **Trace** UP ↑ or DOWN ↓ using the skill's Trace tables.
4. **Cross-reference** related skills.
5. **Answer with the reasoning chain**, then code.

### Keyword conflict resolution

| Keyword | Resolution |
|---|---|
| `unsafe` | rs-unsafe (more specific than rs-ecosystem) |
| `error` | rs-error-handling for mechanics, rs-domain-error for strategy, rs-observability for logging it |
| `doc` / `documentation` | rs-api-design for rustdoc rules, rs-learner/docs-researcher for fetching docs |
| `test` | rs-testing (strategy, tools); rs-unsafe for Miri |
| `clippy` | rs-release for the lint policy, rs-style for the fix |
| `RAII` | rs-lifecycle for design, rs-patterns for the guard pattern, rs-resource for implementation |
| `newtype` | rs-patterns for when/why, rs-type-driven for the type, rs-traits for the orphan-rule use |
| `anti-pattern` | rs-anti-pattern for review, rs-patterns for the book's three canonical ones |
| `FFI` | rs-unsafe for soundness, rs-patterns for API shape (object-based API, wrappers, errors) |
| `builder` | rs-patterns for trade-offs, rs-type-driven for the type-state variant |
| `split` / `refactor` | rs-structure for where pieces go, rs-anti-pattern for what smells |
| `crate` (small crates?) | rs-structure for module vs crate, rs-ecosystem for dependencies |
| `crate` | rs-learner for versions, rs-ecosystem for integration |
| `tokio` | rs-concurrency for concepts, crate skill (if generated) for API |

```
1. Error codes (E0xxx)             → direct lookup, highest priority
2. Negotiation triggers            → enable negotiation
3. Domain keyword + error          → load BOTH domain + mechanics skills
4. Specific crate keyword          → crate-specific skill if one exists
5. General concept                 → the L1/L2 skill above
```

## Default project settings

```toml
[package]
edition = "2024"
rust-version = "1.85"

[lints.rust]
unsafe_code = "warn"

[lints.clippy]
all = "warn"
pedantic = "warn"
```

## Sub-files

| File | Content |
|---|---|
| `patterns/negotiation.md` | negotiation protocol details |
| `examples/workflow.md` | worked routing examples |
| `integrations/os-checker.md` | os-checker integration |
