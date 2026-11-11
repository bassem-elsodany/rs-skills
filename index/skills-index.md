# Skills index

All `rs-*` skills, by layer. Core questions follow each skill's SKILL.md.

## Entry

| Skill | Purpose | Key triggers |
|---|---|---|
| rs-router | Routes every Rust question to a layer and an entry skill; negotiation protocol; the gates before you build | Rust, cargo, E0xxx, compare, best practice |
| rs-guide | Navigation map: load order, lifecycle, gates, catalogue, glossary | which skill, where to start |

## L1 Mechanics (HOW)

| Skill | Core question | Key concepts |
|---|---|---|
| rs-ownership | Who owns this memory, when is it freed? | ownership, borrowing, lifetime, move, E0382, E0597 |
| rs-resource | Determinism vs flexibility — which pointer? | Box, Rc, Arc, Weak, smart pointers |
| rs-mutability | Where are the immutability boundaries? | mut, Cell, RefCell, Mutex, E0596, E0499, E0502 |
| rs-traits | What can the compiler optimise away? | generics, traits, dyn, monomorphization, E0277, E0308 |
| rs-type-driven | How do types encode constraints? | newtype, type state, PhantomData, builder, sealed trait |
| rs-error-handling | Is this failure expected or exceptional? | Result, Option, ?, panic, anyhow, thiserror |
| rs-concurrency | How is concurrency safety proven at compile time? | Send, Sync, async, await, tokio, channels |
| rs-unsafe | Is this unsafe block sound, and is it documented? | unsafe, FFI, raw pointers, transmute, SAFETY comments |
| rs-async-patterns | Who owns this state, who waits for whom, what happens at shutdown? | actor, mailbox, shutdown, Stream, backpressure, Pin |
| rs-macros-const | Can plain code do this? If not, the smallest tool that can | macro_rules, proc-macro, const fn, const generics |

## L2 Design (WHAT)

| Skill | Core question | Key concepts |
|---|---|---|
| rs-domain-model | How do domain rules become types? | DDD, entity, value object, aggregate |
| rs-performance | Where is the bottleneck? | profiling, allocation, benchmark |
| rs-ecosystem | Which crate fits, and how does it integrate? | crates, features, workspace, serde, interop |
| rs-lifecycle | When is a resource created, used, cleaned up? | RAII, Drop, pools, OnceLock |
| rs-domain-error | Who handles this failure, and how is it recovered? | retry, circuit breaker, domain errors |
| rs-mental-model | What is the correct mental model? | learning, analogies, "why does Rust" |
| rs-anti-pattern | Is this pattern hiding a design problem? | code smell, common mistakes, review |
| rs-patterns | Which proven pattern fits, and what does it trade away? | idioms, design patterns, anti-patterns, functional |
| rs-structure | Where does this code live, who may see it, what happens when it grows? | module layout, split ladder, group by feature, visibility, workspace |
| rs-api-design | Will this public API still be right in two years? | builder, non_exhaustive, sealed, conversions, docs |
| rs-reuse-first | Has someone already built (and maintains) what I am about to write? | SDK, standard, protocol, MCP, build vs buy |
| rs-ports-adapters | If this product were replaced, how many files would change? | repository, adapter, port, hexagonal, vendor lock-in |

## L3 Domain (WHY)

| Skill | Domain | Core constraints |
|---|---|---|
| rs-domain-fintech | Financial technology | audit trail, decimal precision, consistency |
| rs-domain-web | Web services | stateless handlers, latency, Send + Sync state |
| rs-domain-cli | CLI applications | UX, config precedence, exit codes |
| rs-domain-cloud-native | Cloud native | 12-factor, observability, graceful shutdown |
| rs-domain-embedded | Embedded | no heap, no_std, real time |
| rs-domain-iot | IoT | offline first, power, security |
| rs-domain-ml | Machine learning | memory efficiency, GPU acceleration |
| rs-domain-gateway | API gateway / proxy-wasm policies | fail closed, phases, property contracts |
| rs-domain-data | Databases, caches, analytics stores | timeouts, short transactions, migrations, cache stampede |
| rs-domain-auth | Authentication and authorisation | JWT validation, OAuth/OIDC/MCP, keys, passwords, object-level checks |
| rs-domain-policy | Policy decision points and engines | default deny, combining, decision log, Cedar/OPA |
| rs-domain-distributed | Services over a network | idempotency, outbox, saga, consensus, deadlines |
| rs-domain-systems | Kernel, GPU, I/O, SIMD | eBPF, wgpu, io_uring, SIMD, mmap |

## L4 Delivery (SHIP)

| Skill | Purpose | Key triggers |
|---|---|---|
| rs-review | Review code and write a Markdown report (severity, citations, verdict, follow-up) | review, code review, PR review, review report |
| rs-style | Rust-specific style and naming rules | naming, clippy, rustfmt, code style |
| rs-learner | Latest Rust / crate information via agents | version, changelog, what's new |
| rs-daily | Rust news digest | Rust news, this week in Rust |
| rs-testing | Testing strategy | unit, proptest, mockall, criterion, loom |
| rs-observability | tracing, spans, structured logs | tracing, metrics, redaction |
| rs-release | Release engineering | MSRV, profiles, cargo-deny, semver, CI |
| rs-design-contract | Design Contract header in every generated file | design contract, file header |
| rs-git | Version control across the lifecycle, any Git host | commit, branch, tag, hooks, history, hygiene |
| rs-security-review | Threat-model-first security hunt and triage | untrusted input, DoS, path traversal, supply chain, triage, severity |
| rs-fuzzing | Fuzzing and mutation testing | cargo-fuzz, harness, arbitrary, sanitizers, cargo-mutants |
| rs-bugfix | Reproduce, fix at the invariant, hunt variants, prove | regression, bisect, hotfix, variants |
| rs-cleanup | Leave the machine as you found it | disk, target/, docker, prune, report |

## Tools

| Skill | Purpose |
|---|---|
| rs-code-navigator | LSP navigation: definitions, references, hover |
| rs-call-graph | Call hierarchies |
| rs-symbol-analyzer | Project symbol structure |
| rs-trait-explorer | Trait implementations |
| rs-refactor-helper | Refactoring with impact analysis |
| rs-deps-visualizer | Dependency graph |
| rs-meta-parallel | Parallel L1/L2/L3 analysis (experimental) |
| rs-skill-creator | Create new skills in the house format |
| rs-util-actionbook | actionbook MCP integration |
| rs-util-agent-browser | Browser-based fetching |
| rs-util-dynamic-skills | Generate skills from Cargo.toml dependencies |
| rs-util-fix-skill-docs | Fix generated skill docs |

## Counts

| Group | Count |
|---|---|
| Entry | 2 |
| L1 | 10 |
| L2 | 12 |
| L3 | 13 |
| L4 | 11 |
| Tools | 14 |
| **Total** | **62** |

(Generated numbers: `scripts/gen-guide.py` keeps `metadata.json` in step; the navigation catalogue lives in `skills/rs-guide/SKILL.md`.)

Related: [triggers-index.md](./triggers-index.md) · [meta-questions.md](./meta-questions.md) · [error-codes.md](./error-codes.md) · [domain-extensions.md](./domain-extensions.md) · [../_meta/layer-definitions.md](../_meta/layer-definitions.md) · [../skills/rs-router/SKILL.md](../skills/rs-router/SKILL.md)
