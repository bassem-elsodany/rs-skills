# rs-skills — operating manual for coding agents

> Lost? Read `skills/rs-guide/SKILL.md` — load order, lifecycle, gates, catalogue of every skill.

## 1. rs-router first, always

For ANY Rust question — compile errors, design, "how do I…", code writing,
review, release — invoke `rs-router` before anything else. Do not answer from
memory, do not web-search first, do not jump straight to a specialised skill.

Signals: Rust, cargo, crate, rustc, `Cargo.toml`, `*.rs`, `E0xxx`, any prompt
while working inside a Rust project.

```
User question
  → Skill(rs-router)              identify entry layer (L1 / L2 / L3 / L4)
  → Skill(rs-<entry skill>)       the skill the router picks
  → Trace Up ↑ / Trace Down ↓     load the skills the Trace tables point at
  → answer with the reasoning chain
```

## 1b. Gates before you build (every task, in this order)

| Gate | When | Do |
|---|---|---|
| **Reuse first** | implementing a standard, protocol, file format or vendor/product API (MCP, JSON-RPC, OAuth/JWT, gRPC, Kafka, Redis, ClickHouse, S3, Kubernetes …) | `Skill(rs-reuse-first)` **before designing**: run `skills/rs-reuse-first/scripts/sdk-scout.sh "<standard>" --github`, use the official/de-facto SDK (e.g. MCP → `rmcp`), report what you found. Never draft a protocol from memory |
| **Decouple** | code touches a DB, cache, queue, search/analytics engine, SDK, downstream service, LLM provider | `Skill(rs-ports-adapters)`: a port you own, adapters per product, contract tests; `python3 -I scripts/port-check.py` must be clean |
| **Clean up** | building, testing, running containers, building images | `Skill(rs-cleanup)`: `disk-guard.sh status` first, label what you create, finish with `cleanup.sh plan/apply` and a Cleanup report; never prune volumes without the user |
| **Security / bugs** | code parses, filters, authorises or deserialises untrusted input; asked to review/audit; asked to fix a bug | `Skill(rs-security-review)`: threat model first, `scripts/rust-caps.sh`, the `sec-*` classes, then **triage** each candidate; `Skill(rs-fuzzing)` for parsers/decoders; `Skill(rs-bugfix)`: failing test first, fix the invariant, hunt variants, prove. Review a change set with `diff-review.py` |
| **Version control** | commit, branch, tag, revert, history | `Skill(rs-git)`: atomic conventional commits, stage by name, no secrets/artefacts, no force-push on shared branches, **no AI co-author trailers unless the owner asks** |

## 2. Negotiation check (before loading any skill)

| Prompt contains | Do |
|---|---|
| compare, vs, versus, difference between | **Negotiation**: load every candidate skill, state confidence and gaps |
| best practice, recommend, should I | **Negotiation** |
| domain keyword + error (e.g. "axum handler E0277") | load BOTH the L1 skill and the `rs-domain-*` skill |
| two or more technologies (tokio and async-std) | **Negotiation** |

Negotiation output (required when triggered):

```markdown
## Negotiation Analysis
**Query type:** Comparative | Cross-domain | Synthesis | Ambiguous
### Sources
- <skill>: confidence HIGH|MEDIUM|LOW — gaps: …
## Synthesised answer
…
**Overall confidence:** …  **Disclosed gaps:** …
```

## 3. The four layers

| Layer | Question | Skills |
|---|---|---|
| L4 Delivery | Is it shippable? | rs-design-contract, rs-review, rs-security-review, rs-style, rs-testing, rs-fuzzing, rs-observability, rs-bugfix, rs-release, rs-git, rs-cleanup |
| L3 Domain | Why is it designed this way? | rs-domain-web, rs-domain-auth, rs-domain-policy, rs-domain-data, rs-domain-distributed, rs-domain-gateway, rs-domain-cloud-native, rs-domain-fintech, rs-domain-cli, rs-domain-embedded, rs-domain-iot, rs-domain-ml, rs-domain-systems |
| L2 Design | What pattern fits? | rs-reuse-first, rs-ports-adapters, rs-structure, rs-patterns, rs-api-design, rs-domain-model, rs-performance, rs-ecosystem, rs-lifecycle, rs-domain-error, rs-mental-model, rs-anti-pattern |
| L1 Mechanics | How do I implement it? | rs-ownership, rs-resource, rs-mutability, rs-traits, rs-type-driven, rs-error-handling, rs-concurrency, rs-async-patterns, rs-macros-const, rs-unsafe |

## 4. Routing table (summary — rs-router has the full one)

| Intent | Skill |
|---|---|
| ownership / borrow / lifetime / E0382 E0597 E0506 E0507 E0515 E0716 E0106 | rs-ownership |
| Box / Rc / Arc / Weak / smart pointers | rs-resource |
| mut / Cell / RefCell / Mutex / E0596 E0499 E0502 | rs-mutability |
| generics / traits / dyn / impl Trait / E0277 E0308 E0599 E0038 | rs-traits |
| newtype / type state / PhantomData / builder / sealed trait | rs-type-driven |
| Result / Option / ? / panic / anyhow / thiserror | rs-error-handling |
| async / await / tokio / Send / Sync / threads / channels | rs-concurrency |
| unsafe / FFI / raw pointers / transmute / bindgen | rs-unsafe |
| design pattern / idiom / anti-pattern / builder / newtype / visitor / strategy / RAII guard | rs-patterns |
| where should this go / split / too long / module layout / workspace / pub(crate) | rs-structure |
| domain model / DDD / entities / value objects | rs-domain-model |
| performance / benchmark / profiling / allocation | rs-performance |
| crates / dependencies / features / workspace / serde / E0433 | rs-ecosystem |
| RAII / Drop / lifecycle / pools / lazy init | rs-lifecycle |
| domain errors / retry / circuit breaker / recovery | rs-domain-error |
| learning / mental model / "why does Rust…" | rs-mental-model |
| anti-pattern / code smell / common mistake / review | rs-anti-pattern |
| public API / library design / breaking change / rustdoc | rs-api-design |
| review / code review / PR review / review report | rs-review |
| naming / formatting / style / pattern matching / macros | rs-style |
| tests / mocks / proptest / benchmarks | rs-testing |
| logging / tracing / metrics | rs-observability |
| release / CI / lints / MSRV / semver | rs-release |
| design contract / file header / new module / extend this file | rs-design-contract |
| latest Rust / crate versions / what's new | rs-learner (agents: rs-changelog, crate-researcher) |
| web, HTTP, axum · CLI, clap · k8s, gRPC · fintech · embedded · IoT · ML | the matching rs-domain-* skill |

## 5. Writing code

- **Structure first (non-negotiable):** before creating a file, decide its feature module with `rs-structure` (group by feature, never a flat `src/` or `utils.rs`); when a function or file is too long, follow the rs-structure split ladder — extract verbs, promote the file to a directory, narrow visibility — not three functions in the same flat file.
- **Design Contract (non-negotiable):** every `.rs` file you create under `src/` starts with a `//! # Design Contract` block (Role, Patterns, Invariants, Extend by, Skills; ≤12 lines). Before editing any `.rs` file, read its contract and follow **Extend by** / **Avoid**; update the contract in the same edit if the design changes. Skill: `rs-design-contract`. Check: `/rs-contract-check`.
- Always load `rs-style` before writing or reviewing code; `rs-testing` when adding behaviour (every Design Contract **Invariant** gets a test); `rs-release` before declaring anything done.
- Depth lives in each skill's `rules/` (265 rules): open the two or three the question needs, never all.
- Commands: `/rs-sdk-scout` (market search), `/rs-ports-check`, `/rs-git-check`, `/rs-cleanup`, `/rs-security-review`, `/rs-diff-review`, `/rs-dep-risk`, `/rs-new-crate` to start a crate, `/rs-review` to review (always writes a Markdown report to `rs-reviews/` inside the project's docs folder, e.g. `docs/private/rs-reviews/`), `/rs-release-check` before saying "done", `/rs-restructure` for a flat crate, `/rs-contract-check` for headers.
- New `Cargo.toml` defaults:

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

## 6. Live data

| Need | Agent |
|---|---|
| Rust release info | rs-changelog |
| crate version / info | crate-researcher |
| API docs | docs-researcher |
| clippy lint details | clippy-researcher |

Fall back to WebSearch only when every agent fails.


---
Plugin users: the skills, commands and hooks carry these rules into your session; this manual is for agents working *in* this repository and for agents that read `AGENTS.md`.
