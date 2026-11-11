---
name: rs-guide
description: "Use when you are an agent (or a human) new to the rs-skills bundle, unsure which skill applies, or asked how the skills fit together — the navigation map: how the bundle is organised, how to read a skill, the lifecycle from design to production, the non-negotiable gates, a catalogue of every skill by layer, the commands/scripts/hooks cheat sheet and a glossary. Triggers: how do I use rs-skills, which skill, where do I start, skill index, skill map, navigation, overview of the skills, what skills exist, how are the skills organised, lifecycle, rs-skills guide, onboarding, how to read these skills, what should I load, skill order"
user-invocable: true
---

# rs-guide — how to navigate rs-skills

> **Entry** · read this once; it tells you what to load, in which order, and what you must never skip.
> Plain Markdown: any agent that can read files can follow it (see `AGENTS.md`); Claude Code loads the same files as skills.

## 1. What this bundle is (30 seconds)

A Rust skill bundle covering the **whole lifecycle — design → build → test → review → release → operate** — in four layers that answer four questions:

```
L4 Delivery   Is it shippable, reviewable, versioned, cleaned up?   (testing, review, release, git, cleanup)
L3 Domain     Why is it designed this way?                           (web, auth, policy, data, distributed, gateway, …)
L2 Design     What pattern fits — and what should I NOT build?       (reuse-first, ports-adapters, structure, patterns, …)
L1 Mechanics  How do I implement it in Rust?                         (ownership, traits, errors, async, macros, unsafe, …)
```
A compile error **enters at L1 and traces up** to the design/domain decision that caused it. A design question **enters at L2, checks L3 constraints, traces down** to L1 and ends with an L4 check.

## 2. Load order — always

1. **`rs-router`** (always first for Rust work) → it picks the layer and the entry skill.
2. The **entry skill** it names. Read its *Core Question*, *Thinking Prompt* and the table that matches your situation.
3. **Follow the Trace**: `Trace Up ↑` (which design/domain decision caused this?) and `Trace Down ↓` (which pattern/mechanic implements it?).
4. If the prompt names a **domain** (web, gateway, data, auth …) load the `rs-domain-*` skill **together with** the mechanics/design skill.
5. Before you write code: `rs-style`, `rs-structure` (where does it live), `rs-design-contract` (header in every `.rs` file).
6. Before you say "done": `rs-testing` (+ `rs-fuzzing`) → `rs-review` (+ `rs-security-review`) → `rs-release` (`/rs-release-check`) → `rs-cleanup` → `rs-git`.

Open **at most two or three depth files** per question (`rules/`, `guides/`, `patterns/`) — they are indexed from each SKILL.md.

## 3. Anatomy of a skill (how to read one)

```
skills/rs-<name>/
  SKILL.md      the decision guide: Core Question · Thinking Prompt · decision tables · rules · Trace ↑↓ · Related Skills
  rules/        one rule per file: Why It Matters · Bad · Good · See Also   (index auto-generated inside SKILL.md)
  guides/       longer how-tos (loaded on demand)         patterns/ examples/  worked material
  templates/    files to copy (compile-checked where Rust)  scripts/  tools the skill tells you to run
```
Read **top to bottom once** (it is short), then use the tables as lookups. Rule ids (`err-fail-closed`, `port-map-errors`) are stable — cite them in reviews and commits.

## 4. The lifecycle — which skill when

```
DESIGN ──────▶ BUILD ───────────▶ TEST ───────▶ REVIEW ──────▶ RELEASE ──────▶ OPERATE
```

| Phase | Ask | Load | Run | Produce |
|---|---|---|---|---|
| **Design** | Does a standard/SDK already exist? What can change later? Where does it live? | `rs-reuse-first` → `rs-ports-adapters` → `rs-structure` → `rs-domain-*` → `rs-patterns` / `rs-api-design` / `rs-domain-model` | `sdk-scout.sh` · `/rs-new-crate` | decision records, port list, module layout, first commits (`rs-git`) |
| **Build** | How is it implemented, owned, typed, failed-closed, concurrent? | L1 skills via the router; `rs-error-handling`, `rs-async-patterns`, `rs-macros-const`; `rs-style`; `rs-design-contract` | `/rs-contract-check` · `port-check.py` | code + Design Contracts, atomic commits |
| **Test** | Is every Invariant proven, every adapter contract-tested, failures simulated, parsers fuzzed, tests mutation-checked? | `rs-testing`, `rs-fuzzing` (+ `rs-domain-distributed` for simulation) | `cargo test` · contract suites · `cargo fuzz` · `cargo mutants --in-diff` | tests, fuzz regressions; containers and corpora cleaned (`rs-cleanup`) |
| **Review** | What must change, in what order, and can a developer follow it? Is it exploitable? | `rs-review` (+ `rs-security-review`, `rs-anti-pattern`, `rs-unsafe`) | `/rs-review` · `/rs-diff-review` · `/rs-security-review` | `rs-reviews/<day>/` report, work log, tick-boxes |
| **Release** | Gates green, dependencies and CI trustworthy, versioned, tagged, reproducible? | `rs-release`, `rs-git`, `rs-api-design` | `/rs-release-check` · `/rs-dep-risk` · `git-check.sh audit --public` | CHANGELOG, tag, artefacts from the tag |
| **Operate** | What is running, what broke, how to trace, fix at the invariant and roll back? | `rs-bugfix`, `rs-observability`, `rs-domain-error`, `rs-domain-cloud-native`, `rs-git` (revert/bisect) | `disk-guard.sh status` · `git bisect run` | failing-test-first fixes, variants hunted, hotfix branches |

## 5. Non-negotiable gates (each has a skill, a script and a hook)

| # | Gate | Rule | Skill · tool |
|---|---|---|---|
| 1 | **Router first** | no Rust answer from memory | `rs-router` · routing hook |
| 2 | **Reuse before build** | implementing a protocol/standard/vendor API? find the official/de-facto SDK first — never draft it | `rs-reuse-first` · `sdk-scout.sh` · "before you build" hook |
| 3 | **Decouple what can change** | databases, caches, queues, SDKs, downstream services sit behind a port with adapters + contract tests | `rs-ports-adapters` · `port-check.py` |
| 4 | **Structure before code** | feature modules, never a flat `src/` or `utils.rs` | `rs-structure` · `structure-check.sh` |
| 5 | **Design Contract in every `.rs` file** | read it before editing, update it with the design | `rs-design-contract` · contract hooks |
| 6 | **Fail closed** | errors in filters/auth/policy deny | `rs-error-handling` (`err-fail-closed`), `rs-domain-policy` |
| 7 | **Tests prove the Invariants** | one test per contract Invariant; adapters pass one contract suite | `rs-testing` |
| 8 | **Review leaves a readable report** | day folder, TL;DR, cards, work log | `rs-review` |
| 9 | **Release gate is the definition of done** | fmt/clippy/tests/docs/deny/semver/contracts | `rs-release` · `release-check.sh` |
| 10 | **Clean up what you create** | measure disk, label images, remove spikes, report | `rs-cleanup` · disk hooks |
| 11 | **Security-review code that touches untrusted input; fuzz parsers** | threat model first, traced findings, triage verdicts; fuzz harness for every decoder | `rs-security-review` · `rs-fuzzing` · `rust-caps.sh` |
| 12 | **Fix bugs test-first, at the invariant, then hunt variants** | red test → invariant fix → variant search → proof | `rs-bugfix` |
| 13 | **Version control discipline** | atomic conventional commits, no secrets, no force-push on shared branches, no AI trailers unless asked | `rs-git` · `git-check.sh` |

## 6. Which entry point for which situation?

| You have… | Start at |
|---|---|
| a compiler error `E0xxx` | `rs-router` error table → L1 skill → trace up |
| "how should I design X?" / "which pattern?" | `rs-patterns`, `rs-structure`, `rs-domain-model`; check the L3 domain |
| "implement <protocol/SDK/standard/product client>" | **`rs-reuse-first` first**, then `rs-ports-adapters` |
| "talk to a DB / Redis / ClickHouse / queue / API" | `rs-ports-adapters` + `rs-domain-data`; SDK via `rs-reuse-first` |
| "login / JWT / OAuth / permissions / policies" | `rs-domain-auth`, `rs-domain-policy` |
| "services call each other / retries / events" | `rs-domain-distributed`, `rs-domain-error`, `rs-async-patterns` |
| "gateway / proxy-wasm / Flex policy / MCP gateway" | `rs-domain-gateway` (+ auth, policy, reuse-first) |
| "make it faster / smaller" | `rs-performance`; low-level → `rs-domain-systems` |
| "split this / where does this go" | `rs-structure` |
| "review this" / "review this MR" | `/rs-review`; a change set: `/rs-diff-review` |
| "is this secure / exploitable / audit it" | `rs-security-review` (threat model first), `rs-fuzzing` for parsers |
| "fix this bug / it used to work / same bug elsewhere" | `rs-bugfix` (failing test first; variants; bisect) |
| "are my tests good?" | `rs-fuzzing` (`guides/mutation-testing.md`) |
| "are my dependencies / CI safe?" | `/rs-dep-risk`, `rs-release` (`guides/ci-hardening.md`) |
| "ready to ship?" | `/rs-release-check`, `rs-release`, `rs-git` |
| "disk is full / images / target dir" | `rs-cleanup` |
| "commit / branch / tag / revert" | `rs-git` |
| "what changed in Rust / crate versions" | `rs-learner` (agents: rs-changelog, crate-researcher) |
| "I don't know Rust well / why does Rust…" | `rs-mental-model` |

## 7. Commands, scripts and hooks (cheat sheet)

| Command | Does |
|---|---|
| `/rs-new-crate` | scaffold a production-ready crate (contracts, lints, CI, Dockerfile, slim dev profile) |
| `/rs-review` | review → day folder report + work log + indexes |
| `/rs-release-check` | the pre-release gate |
| `/rs-contract-check` · `/rs-restructure` | headers present? · restructure a flat crate in compiling steps |
| `/rs-sdk-scout` | search crates.io + GitHub for the standard SDK before building |
| `/rs-ports-check` | vendor code outside adapters? |
| `/rs-git-check` | repository hygiene audit (any Git host) |
| `/rs-security-review` | threat-model-first security review: capability probe, `sec-*` passes, triage |
| `/rs-diff-review` | differential review of a branch/MR: risk, removed checks, blast radius, test gaps, reading order |
| `/rs-dep-risk` | supply-chain risk report for Cargo dependencies (crates.io + OSV; `--offline` local census) |
| `/rs-cleanup` | disk status and tiered cleanup (dry-run first) |

| Script (under `scripts/` or `skills/<skill>/scripts/`) | Purpose |
|---|---|
| `quality-check.sh` · `rules-check.sh` · `coverage-check.sh` · `patterns-check.sh` · `gen-guide.py --check` | bundle self-checks (run before committing the bundle) |
| `contract-check.sh` · `structure-check.sh` · `port-check.py` · `release-check.sh` | project checks |
| `sdk-scout.sh` | market search for SDKs (rs-reuse-first) |
| `disk-guard.sh` · `cleanup.sh` | disk budget and cleanup (rs-cleanup) |
| `git-check.sh` | git hygiene, staged-secret scan, message lint, hooks installer (rs-git) |
| `review-report.sh` · `review-log.sh` · `review-index.py` · `risk-scan.py` · `diff-review.py` | review machine pass (`--diff <base>`), work log, indexes, risk candidates, differential review |
| `rust-caps.sh` | which security passes apply to this crate (rs-security-review) |
| `dep-risk.py` | dependency supply-chain report (rs-release) |
| `sync-local.sh` | copy the working tree into every installed Claude profile |

| Hook | Fires | Does |
|---|---|---|
| routing (`UserPromptSubmit`) | Rust prompts | forces router-first, layered reasoning |
| gates (`UserPromptSubmit`) | Rust project + protocol/vendor/build/git/security/bug prompts | the five "before you build" gates |
| contract (`PostToolUse` Write/Edit/Bash) | `.rs` changes | a file without a Design Contract is rejected |
| disk preflight (`PreToolUse` Bash) | `cargo build/test`, `docker build` | denies on a full disk; asks before destructive Docker commands |
| disk stop (`Stop`) | end of session | blocks finishing while disk budgets are exceeded |

## 8. Skill catalogue (generated — `${CLAUDE_PLUGIN_ROOT}/scripts/gen-guide.py`)

<!-- catalog:start -->
### Entry — Start here

| Skill | Core question | Ships |
|---|---|---|
| `rs-router` | Which layer does this question enter at, and which skill answers it first? | patterns, examples |
| `rs-guide` | Which skill do I open, in which order, and what must I never skip? |  |

### L1 — Mechanics — how do I implement it?

| Skill | Core question | Ships |
|---|---|---|
| `rs-ownership` | Who should own this data, and for how long? | 9 rules, patterns, examples |
| `rs-resource` | What ownership pattern does this resource need? | 2 rules |
| `rs-mutability` | Why does this data need to change, and who can change it? | 3 rules |
| `rs-traits` | Do we need compile-time or runtime polymorphism? | 13 rules |
| `rs-type-driven` | How can the type system prevent invalid states? | 18 rules |
| `rs-error-handling` | Is this failure expected or a bug? | 13 rules, patterns, examples |
| `rs-concurrency` | Is this CPU-bound or I/O-bound, and what's the sharing model? | 22 rules, patterns, examples |
| `rs-async-patterns` | Who owns this state, who may wait for whom, and what happens when the program is told to stop? | 4 rules, guides |
| `rs-macros-const` | Can plain code (a function, a generic, a trait, a `const`) do this? If not, which is the smallest tool that can? | 4 rules, guides |
| `rs-unsafe` | Is this unsafe block sound, and is the safety argument written down? | 54 rules, examples, checklists |

### L2 — Design — what pattern fits, and what should I not build?

| Skill | Core question | Ships |
|---|---|---|
| `rs-reuse-first` | Has someone already built, and keeps maintaining, the thing I am about to write? | 7 rules, templates, scripts, registry |
| `rs-ports-adapters` | If this product were replaced next year — Redis by something else, ClickHouse by another engine, one SDK by a newer one — how many files would change? | 12 rules, templates |
| `rs-structure` | Where does this code live, who may see it, and what happens when it grows? | 13 rules, guides |
| `rs-patterns` | Which proven Rust solution fits this recurring problem — and what does it trade away? | 50 pattern pages |
| `rs-api-design` | Will this public API still be right in two years — and does it feel like `std`? | 34 rules, guides |
| `rs-domain-model` | What is this concept's role in the domain? |  |
| `rs-domain-error` | Who needs to handle this error, and how should they recover? |  |
| `rs-ecosystem` | What's the right crate for this job, and how should it integrate? | 8 rules |
| `rs-lifecycle` | When should this resource be created, used, and cleaned up? | 1 rules |
| `rs-performance` | What's the bottleneck, and is optimization worth it? | 45 rules, patterns |
| `rs-anti-pattern` | Is this pattern hiding a design problem? | 15 rules, patterns |
| `rs-mental-model` | What's the right way to think about this Rust concept? | patterns |

### L3 — Domain — why is it designed this way?

| Skill | Core question | Ships |
|---|---|---|
| `rs-domain-web` | How do requests flow through a stateless service — routing, extractors, state, middleware — within latency limits? | guides |
| `rs-domain-auth` | Can an attacker, or a bug, make this code say "yes" when it should say "no" — including when something fails? | 5 rules, guides |
| `rs-domain-policy` | Is the decision made in one place, from explicit policy, with a default of deny, and can we later prove why it was made? | 5 rules, guides, templates |
| `rs-domain-data` | What must be true about this data at rest and in motion — consistent, durable, fast, or cheap — and which store gives exactly that and no more? | 5 rules, guides |
| `rs-domain-distributed` | If this call times out, what do I know — and is it safe to try again? | 6 rules, guides |
| `rs-domain-gateway` | If this filter cannot do its job on this request, what reaches the upstream or the client? (nothing unchecked) |  |
| `rs-domain-cloud-native` | Will this run, scale, stop and be observed correctly as a container in a cluster (12-factor, health, shutdown)? |  |
| `rs-domain-fintech` | Can every amount, rounding and state change be exact, auditable and reproducible? |  |
| `rs-domain-cli` | Is the command-line contract (args, config precedence, output, exit codes) clear and scriptable? |  |
| `rs-domain-embedded` | What must hold with no heap, no OS and real-time deadlines (no_std, interrupts, HALs)? |  |
| `rs-domain-iot` | How does this behave offline, on a flaky link, on constrained power (MQTT, telemetry, edge)? |  |
| `rs-domain-ml` | Where do memory, device placement and numerics dominate (tensors, inference, GPU)? |  |
| `rs-domain-systems` | Is the ordinary path (tokio + epoll, plain loops, CPU) measurably too slow — and if so, which single platform feature fixes it with the least `unsafe`? |  |

### L4 — Delivery — is it shippable, reviewable, cleaned up?

| Skill | Core question | Ships |
|---|---|---|
| `rs-design-contract` | Will the next agent (or human) understand — and keep — the design this file was built with? | examples |
| `rs-style` | Does the code follow Rust naming, formatting and lint conventions? | 29 rules |
| `rs-testing` | How will we know this is correct — today, and after someone else changes it? | 16 rules |
| `rs-fuzzing` | What input — or what code change — would make this program misbehave, and would anything in our pipeline notice? | 3 rules, guides, templates |
| `rs-observability` | When this misbehaves at 3 a.m., what will the on-call engineer see — and is it enough to act without redeploying? | 8 rules |
| `rs-git` | Could someone who was not here reconstruct what changed, why, and how to undo it — from the history alone? | 9 rules, guides, templates, scripts |
| `rs-review` | Can this code ship — and if not, exactly what must change, where, and why? | guides, templates, scripts |
| `rs-security-review` | Within the stated threat model, can a party who is not supposed to be able to do so make this code crash, stall, leak, forge or escalate — and can I show how? | 16 rules, guides, scripts |
| `rs-bugfix` | What invariant was broken, can I show it failing, and where else does the same root cause live? | guides, templates |
| `rs-release` | Can this be released, audited and rolled back without surprises? | 16 rules, guides, scripts |
| `rs-cleanup` | What did my commands leave on this machine, and is any of it still needed? | 7 rules, guides, scripts |

### Tools — Navigation, research and maintenance

| Skill | Core question | Ships |
|---|---|---|
| `rs-learner` | What is the latest Rust version / crate version / language feature, from live sources? |  |
| `rs-daily` | What happened in the Rust ecosystem today / this week / this month? |  |
| `rs-code-navigator` | Where is this symbol defined and used (LSP)? |  |
| `rs-call-graph` | Who calls this function, and what does it call (LSP call hierarchy)? |  |
| `rs-symbol-analyzer` | What structs, traits and functions make up this project (LSP symbols)? |  |
| `rs-trait-explorer` | Who implements this trait, and which traits does this type implement? |  |
| `rs-refactor-helper` | What breaks if I rename/move/extract this, and in which order is it safe (LSP)? |  |
| `rs-deps-visualizer` | How do the project's dependencies relate (ASCII graph)? |  |
| `rs-meta-parallel` | (experimental) What does an L1/L2/L3 parallel analysis of this question say? |  |
| `rs-skill-creator` | How do I turn crate or std documentation into a skill in the house format? |  |
| `rs-util-actionbook` | (internal) actionbook MCP selectors used by documentation research. |  |
| `rs-util-agent-browser` | (internal) agent-browser CLI workflows used by the research agents. |  |
| `rs-util-dynamic-skills` | (internal) generate/sync/clean skills for the project's dependencies. |  |
| `rs-util-fix-skill-docs` | (internal) check and repair generated skill documentation references. |  |
<!-- catalog:end -->

## 9. Glossary

| Term | Meaning |
|---|---|
| **Layer L1–L4 / Trace ↑↓** | mechanics, design, domain, delivery; Trace Up asks "which decision caused this?", Trace Down "how is it implemented?" |
| **Design Contract** | the `//! # Design Contract` block that opens every `.rs` file: Role, Patterns, Invariants, Extend by, Avoid, Skills |
| **Reuse gate** | the `rs-reuse-first` procedure: name → in-tree → registry → market search → evaluate → decide → isolate → report |
| **Port / adapter / composition root** | a trait you own in business language / an implementation per product / the one place that picks adapters from config |
| **Contract suite** | a generic test every adapter of a port must pass (the in-memory fake defines the semantics) |
| **Fail closed** | on error, deny/stop; never forward or allow |
| **Decision record** | `decisions/NNNN-*.md`: need, candidates, choice, gaps, isolation, consequences |
| **P1–P6** | review fix phases: Safety → Hygiene → Structure → Design → Tests → Release; **X-n** = cross-crate finding |
| **Card** | a review finding: what's wrong · why it matters · fix · tick-box |
| **Work log** | the day's `work-log.md`: what the reviewing agent did, step by step, with evidence |
| **Threat model** | who the attacker is (`REMOTE`, `LOCAL_UNPRIVILEGED`, `BOTH`); decides reachability and severity |
| **Triage verdict** | `TRUE_POSITIVE` · `LIKELY_TP` · `LIKELY_FP` · `FALSE_POSITIVE` · `OUT_OF_SCOPE` · `HARDENING` (reported Low) |
| **Variant** | another place with the same root cause as a known bug |
| **Harness** | a pure function in the library that a fuzz target, tests and corpus replay all call |
| **Cleanup report** | created / removed / reclaimed / left in place, with disk numbers |
| **Tier (cleanup)** | `safe` (regenerable) → `more` → `all`; volumes only with the user's word |
| **Rule id** | stable name of a depth rule (`async-bound-every-queue`); cite it |

## 10. Keeping the bundle healthy (for maintainers)

`${CLAUDE_PLUGIN_ROOT}/scripts/quality-check.sh && ${CLAUDE_PLUGIN_ROOT}/scripts/rules-check.sh && ${CLAUDE_PLUGIN_ROOT}/scripts/coverage-check.sh && ${CLAUDE_PLUGIN_ROOT}/scripts/patterns-check.sh && python3 -I ${CLAUDE_PLUGIN_ROOT}/scripts/gen-guide.py --check`, then bump `VERSION` + `CHANGELOG.md`, commit (no AI trailers), `${CLAUDE_PLUGIN_ROOT}/scripts/sync-local.sh --all`. Add a skill with `rs-skill-creator`, classify it in `${CLAUDE_PLUGIN_ROOT}/scripts/gen-guide.py`, regenerate. Real use is the test suite: when a skill or script fails or gives weak output, fix the bundle in the same session.
