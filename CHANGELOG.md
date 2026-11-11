# Changelog

All notable changes to rs-skills. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer. Phases are described in `docs/specs/2026-11-10-rs-skills-phased-plan.md`.

## [1.6.3] - 2026-11-11

### Changed
- Per-file provenance lines removed from the 265 adapted rule files; the licence notices for adapted material now live in `NOTICE.md` (full MIT text) and, for the pattern pages, in their MPL headers, `skills/rs-patterns/SOURCES.md` and `LICENSE-MPL`.
- `checks/rule-manifest.txt` lists the rules that are compile-checked (replaces detection by provenance line); `rules-check.sh` verifies the manifest.
- `scripts/export-public.sh` leaves out the private planning data (`docs/specs`, `docs/coverage`) and fails when source names appear outside `NOTICE.md` and the MPL pages; `coverage-check.sh` skips when no matrix is present.
- The one-shot rule-landing script `scripts/distribute-rules.py` is retired; `metadata.json` no longer lists sources.

## 1.6.2 — 2026-11-11

- **Installing on other agents, verified against vendor documentation.** `scripts/install-agents.sh`: installs the skills into the shared `.agents/skills/` location read by Codex, Cursor, Gemini CLI, GitHub Copilot, OpenCode and Windsurf/Devin (and `.kiro/skills` with `--kiro`), in link or copy mode, project or user scope, with `--dry-run` and a safe `--uninstall`; keeps the bundle-level `scripts/` and `templates/` reachable (a bare folder copy loses them) and writes a managed `AGENTS.md` block with the bundle root, the meaning of `${CLAUDE_PLUGIN_ROOT}` and the five gates the hooks cannot enforce there. New `docs/other-agents.md`: per-tool locations and commands marked "documented, not tested", what to do manually without hooks. README claims corrected: `codex plugin marketplace add` is not confirmed by OpenAI's docs and was removed; Kiro's custom-agent and subdirectory-import caveats added.
- README: three Mermaid diagrams (lifecycle with commands, bundle map, request flow with hooks); sources in `docs/diagrams/`, `scripts/check-diagrams.py` renders every block with `mmdc`.
- Validator enforces the portable `description` ≤ 1024 characters (Kiro) in addition to Anthropic's rules.

## 1.6.1 — 2026-11-11

Publishing hygiene, checked against Anthropic's plugin/skill documentation, `claude plugin validate --strict` and common practice for published skill collections.

- **Script paths now resolve for installed users.** Skills, commands and hook messages used bare `skills/…/scripts/…` paths that only worked from this repository's root; they now use `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_SKILL_DIR}` (substituted when the skill loads) and hooks print absolute paths.
- **`claude plugin validate . --strict` passes.** Agents: precise dispatch descriptions, `tools:` lists and `model`; helper documents moved out of `agents/` to `_meta/agent-support/` (every `.md` there was loaded as an agent); 6 commands gained frontmatter; hook commands quote `"${CLAUDE_PLUGIN_ROOT}"`; unknown frontmatter keys (`globs`, `source`) removed; `CLAUDE.md` moved out of the plugin root (it is not loaded there) — `AGENTS.md` is the manual, `.claude/CLAUDE.md` imports it; `plugin.json` no longer hand-lists 47 of 62 skills (default scan).
- **Hooks are fast.** PreToolUse/PostToolUse hooks leave in ~4 ms for unrelated Bash calls (string match before any Python start-up).
- **`scripts/validate-plugin.py`** (+ `--self-test`): offline enforcement of the same conventions in CI and in `quality-check.sh`.
- Repo: `.gitattributes`, Dependabot for pinned Actions, authoring standards in `CONTRIBUTING.md`, validation and directory notes in `docs/PUBLISHING.md`.

## 1.6.0 — 2026-11-11

New security, fuzzing and bug-fix skills plus supporting scripts, adopted where they fit the pipeline phases. All text is original.

- **New `rs-security-review`** : threat-model-first procedure; `rust-caps.sh` capability probe that switches passes on and off; **16 `sec-*` bug-class rules** for what we did not cover (recursion-depth DoS, resource exhaustion, panic on input incl. UTF-8 slicing and release-mode overflow, path traversal, filesystem TOCTOU, drop panic/skip, `Ord/Eq/Hash` contracts and key mutation, lock/atomic hazards, serialization integrity and determinism, lossy conversions, pointer exposure, unflushed writers, zeroize, constant-time compare, build-time supply-chain code) — with gates, compile-verified fixes and false-positive notes; `guides/triage.md` (verdict taxonomy, seven dismissal tests, six gates, severity by threat model, duplicate merging). Memory-safety classes stay in `rs-unsafe` (already 54 rules).
- **`rs-review`**: `scripts/diff-review.py` (differential review: risk triage, removed checks + `git log -S` history, added hazards, blast radius, test gaps, **reading order**; `review-report.sh --diff <base>`; `/rs-diff-review`); guides `context-building.md` (assumptions marked `nothing found`), `spec-compliance.md` (requirement verdicts: implemented/partial/contradicted/absent/stronger-than-spec/undecidable — for GCL ↔ code), `differential-review.md`; fix-loop discipline (ledger, round cap, escalation, scope guard); reviewer **rationalizations to reject**; `rust-caps` section in every machine pass; step 9 security hunt.
- **New `rs-fuzzing`** : cargo-fuzz workflow, harness-as-pure-function with a **compile-checked template** (parse/encode round trip, `Arbitrary`, corpus-replay test on stable), oracles beyond "doesn't crash", obstacles/dictionaries, sanitizers/Miri/coverage, CI smoke + scheduled fuzzing, **mutation testing with cargo-mutants**.
- **New `rs-bugfix`** : failing-test-first loop with a before/after/control proof table, fix at the invariant, **variant analysis** (five steps, abstraction ladder, Rust tools), regression hunt with `git bisect run`, revert-vs-fix table, bug-report template.
- **`rs-release`**: `scripts/dep-risk.py` (Cargo supply-chain report from `cargo metadata` + crates.io + OSV: yanked, advisories, owners, age, **build-time code census**, git/path/wildcard sources, coverage section; `--offline`; refuses to print an empty "clean" report) + `/rs-dep-risk`; `guides/ci-hardening.md` (triggers, least privilege, `${{ }}` injection, pinning, caches, Rust specifics, **AI-agent workflow attack vectors**); CI templates hardened (`permissions`, `persist-credentials: false`, concurrency, timeouts, opt-in fuzz/dep-risk jobs); release gate gains a dependency-source census; rules `rel-supply-chain-evidence`, `rel-ci-least-privilege`.
- **`rs-api-design`**: `guides/sharp-edges.md` + rule `api-pit-of-success` (dangerous defaults, sentinel zeros, config cliffs, primitive-vs-semantic types, three misusers).
- **`rs-git`**: publish-ready — secrets in history → fresh repo vs rewrite, `gitleaks`/`trufflehog`, `SECURITY.md`; `git-check.sh audit --public`.
- **`rs-cleanup`**: `guides/devcontainer.md` (sandbox + named volumes as a disk boundary), tool-artefact disk notes (fuzz corpora, `mutants.out`, sanitizer targets), rationalizations table. **"Rationalizations to reject"** tables added to rs-reuse-first, rs-ports-adapters, rs-cleanup, rs-review, rs-security-review, rs-bugfix.
- Hooks/router/guide: fifth "before you build" gate (security / bugs), matcher widened, catalogue and metadata regenerated (62 skills, 402 rules, 31 commands).

## 1.5.0 — 2026-11-11

Seven improvements requested after real use on a gateway-policy project; 12 new skills (47 → 59), 4 new commands, 3 new hooks.

**1. Git across the lifecycle — new `rs-git`** (host-neutral: GitHub, GitLab, Bitbucket, Gitea, Azure DevOps, Gerrit, plain SSH, no remote). Covers (audit-first, `.gitignore` hygiene, confirm-before-history-rewrite, release/tag discipline, verify instead of trusting exit codes, attribution policy, branch-protection levels) and commit/branch discipline (atomic commits, trunk-based, worktrees, save points, change summaries), mapped onto design → build → review → release → operate. `scripts/git-check.sh` (`audit` · `staged` · `msg` · `install-hooks`): staged-secret scan, tracked artefacts, big files, conventional-commit lint, **AI-trailer policy (none unless the owner opts in)**. Guides: lifecycle, safety (destructive-op recovery), publish-ready. Discoverability/marketing is out of scope.

**2. SDK first — new `rs-reuse-first`.** A gate that runs *before* implementing any standard, protocol or vendor API: `sdk-scout.sh` (crates.io + GitHub, flags OFFICIAL?/STALE/IN-TREE), a dated registry of standards → official/de-facto crates (MCP → `rmcp`, verified on crates.io), evaluation scorecard, decision-record template, hand-roll-as-last-resort rules. Router, hooks (new "before you build" gate hook), `rs-ecosystem`, `rs-domain-gateway` and the review's **reinvention scan** (JSON-RPC envelopes, SSE framing, JWT splitting, OAuth, own pools/caches…) all enforce it.

**3. Developer-friendly review reports (`rs-review` 2.0).** One **folder per day** (`rs-reviews/YYYY-MM-DD/`) with a generated day `README.md` and a root index; each report opens with a TL;DR and three "start here" links, findings are readable **cards** (what's wrong · why it matters · fix with code · tick-box) instead of six-column prose tables, front matter feeds the indexes, a **work log** (`review-log.sh`) records what the agent did step by step, and `review-index.py` recounts fix progress. New judgement steps: reuse & decoupling, housekeeping. Legacy flat reports are still found as "previous".

**4. Ports & adapters — new `rs-ports-adapters`.** Repository/adapter beyond databases: everything a licence, price or better product could replace (Redis, ClickHouse, queues, search, SDKs, identity, LLM providers, clocks). Rules (port-no-vendor-in-domain, design-by-need, map-errors, row-types, contract-tests, select-at-root, async-and-dyn, no-generic-repository, uow-transactions, swap-drill, yagni, volatility-inventory), a **compile-checked template crate** (port, memory fake, vendor adapter, contract suite, enum-dispatch composition root) and `scripts/port-check.py` (vendor crates outside adapters, SQL in business code, cfg-selected backends, vendor derives). Release gate and review machine pass run it.

**5. Gap analysis** → new skills with original, compile-verified content: `rs-async-patterns` (actors, shutdown/supervision, streams/backpressure, Pin), `rs-macros-const` (macro_rules, proc-macros, const eval) + `rs-ownership/patterns/advanced-lifetimes.md` (HRTB, GAT, `'static`, variance), `rs-domain-data` (DB, cache, analytics stores), `rs-domain-auth` (JWT/OAuth/OIDC/MCP, keys, passwords, sessions), `rs-domain-policy` (PDP/PEP, engines, decision core template), `rs-domain-distributed` (idempotency, outbox, sagas, consensus, simulation testing), `rs-domain-systems` (eBPF, GPU, io_uring, SIMD, mmap), `rs-domain-web/guides/middleware.md`. Not adopted: Chinese-language skills, the thin duplicates of skills we already have (error, ownership, traits …), coroutine/DPDK specifics beyond a pointer.

**6. Navigation — new `rs-guide`** (and `AGENTS.md`/`CLAUDE.md`/README entry points): load order, anatomy of a skill, lifecycle table, the 11 non-negotiable gates, "which entry for which situation", commands/scripts/hooks cheat sheet, a **generated catalogue** of every skill (`scripts/gen-guide.py`, `--check` in CI), glossary.

**7. Cleanup — new `rs-cleanup`.** Born from a measured 204 GB `target/` (289 000 stale files in `debug/deps`) + 20 GB Docker build cache. `disk-guard.sh` (status · preflight · over), `cleanup.sh` (plan/apply, tiers safe/more/all, dry-run default, volumes only with `--volumes`, labelled-only container/image removal), a **PreToolUse hook** (denies builds on a full disk; asks the user before `docker system prune --volumes`, `volume rm`, `compose down -v`, `prune -a`), a **Stop hook** (blocks finishing while budgets are exceeded; fires once), `.dockerignore` and slim-debuginfo dev-profile templates (added by `new-crate.sh`), Dockerfile labels, a required **Cleanup report**. `review-report.sh` and `release-check.sh` no longer litter `/tmp` and report disk budgets.

Other: `release-check.sh` gains ports/git/disk rows; `risk-scan.py` gains reinvention candidates; routing hook matcher widened; `metadata.json` generated.

## 1.4.1 — 2026-11-11

- rs-review `risk-scan.py`, re-validated against the original (unfixed) gateway-policy code — it now flags all the fail-open and property-contract issues found by hand, and nothing on the fixed code:
  - multi-line fail-open check (`Err(..) => { …; return Flow::Continue }` split by rustfmt);
  - property reads/writes matched on whole files (rustfmt-proof), including `read_prop(&stream, &[..])`, `either(a, b)` second key, and keys written through a variable plus tuple tables;
  - non-workspace layouts: sibling crates (`<policy>/<policy>-flex/`) are scanned together as one pipeline;
  - host attributes (`request.`, `source.`, `destination.`, …) never reported as unwritten;
  - tighter `reflect` (reply-building lines only, not loggers or fn signatures) and discarded-result checks (bare `let _ =` on writes/sends only).

## 1.4.0 — 2026-11-11

Lessons from fixing four proxy-wasm gateway policies folded into the skills (not just the scripts).

- **New skill `rs-domain-gateway`** (47 skills): proxy-wasm / Envoy / Flex PDK — phase discipline, the five fail-open shapes, inter-policy property contracts, SSE framing, single-threaded VM, `--allow-undefined`, wasm build in CI, generated config, workspace layout, testing with host-trait fakes. Routed from rs-router and the prompt hook.
- **rs-review: Security & contract pass** (procedure step 3.6 + checklist) and `scripts/risk-scan.py`, a candidate list in every report: fail-open shapes, discarded write results, casts, PII in logs, reflected content, stream properties read but never written across the workspace, config-schema options never mentioned in code. (The first Flex review missed 14 High/Medium issues this pass catches.)
- **rs-review: reports go in `rs-reviews/` inside the project's existing docs folder** (`docs/private` → `docs/internal` → `docs`, nearest ancestor; `docs/rs-reviews` only when there is none) — `scripts/review-dir.sh`. No more bare `reviews/` folders.
- New rules: `err-fail-closed` (rs-error-handling + skill section), `api-config-is-contract` (never narrow a config schema to match code), `obs-no-reflect-untrusted`, `test-env-bound-integration`.
- rs-structure `restructure-existing`: pin client-visible output with characterisation tests before moving code; don't "unify" differing outputs without checking the external contract.
- Hooks: the routing hook now filters prompts itself (Claude Code ignores `matcher` on UserPromptSubmit, so it fired on every prompt); new PostToolUse **Bash** hook checks Design Contracts on `.rs` files changed through shell commands (sed/python edits bypassed the Write/Edit hook).

## 1.3.4 — 2026-11-11

- rs-review `review-report.sh`: *previous report* is the latest report **of the same scope** (was the latest of any scope in a shared `--out` dir); the tests row sums all suites (was the last suite only, e.g. the ignored integration tests).

## 1.3.3 — 2026-11-11

- `release-check.sh`: finds `Cargo.lock` at the workspace root and reads the effective edition (`edition.workspace = true`) for workspace members (both were false warnings).

## 1.3.2 — 2026-11-11

- `contract-check.sh`: only the crate-root `build.rs` is exempt; a module file named `build.rs` under `src/` needs a contract (it was silently skipped). Fixture added.

## 1.3.1 — 2026-11-10

- `contract-check.sh` / rs-design-contract: generated code is exempt (`generated/` directory or `@generated` / "do not edit" marker). Fixture `tests/fixtures/contract/generated-crate`. Found on the Flex policies (PDK `cargo anypoint config-gen`).

## 1.3.0 — 2026-11-10

- rs-release: **brownfield lint adoption** recipe (fmt → full table → measure → `clippy --fix` + unused-import cleanup → ratchet block with phase notes → `-D warnings` gate) and the cross-target build note (proxy-wasm `--allow-undefined`). Learned on the Flex policies P2.
- rs-review: overview **Progress** table; findings discovered while fixing are added to their phase.

## 1.2.1 — 2026-11-10

- rs-review `review-report.sh`: new **target build** check row (`--target`, auto-detected from `.cargo/config.toml` or a wasm `cdylib` Makefile). Found when proxy-wasm gateway policies passed host tests but their `wasm32-wasip1` release build failed to link on Rust 1.99.

## 1.2.0 — 2026-11-10

- rs-review reports are organised as a **fix plan by phase** (P1 Safety & correctness → P2 Hygiene & gates → P3 Structure & contracts → P4 Design & idioms → P5 Tests → P6 Release), each with its own table, effort and exit criterion; IDs are `P<phase>-<n>`. No more single flat findings table.
- New `templates/overview.md` for multi-crate scopes (per-crate matrix + phases + cross-crate `X-n` rows).
- Added the missing `templates/example-report.md` referenced by SKILL.md.

## 1.1.1 — 2026-11-10

- rs-review `review-report.sh`: rustfmt row counts files (not hunks); clippy row counts short-format diagnostics and fails when any exist; correct report path with absolute `--out`. Found while reviewing the Flex policies.

## [1.1.0] — 2026-11-10

### Added
- `rs-review` skill (user-invocable `/rs-review`): every review writes `reviews/YYYY-MM-DD-<scope>.md` from a fixed template — verdict (Block / Fix before merge / Ship), severity counts, 8 area scores, findings table with `file:line` and a cited rule or contract line, Design Contract drift, structure moves, status of the previous report's findings, automated checks. `scripts/review-report.sh` fills the automated part (contracts, structure, fmt, clippy, tests, docs, release gate) and links the previous report.

### Changed
- `/rs-review` command replaced by the skill. The `rs-daily` command is renamed `/rs-news` (it clashed with the `rs-daily` skill).

## [1.0.0] — 2026-11-10 — Phase 5: Polish

### Changed
- All ported text is English: Chinese trigger keywords removed from 32 skill descriptions; `/audit`, test checklists and scenarios, achievement scripts and router sub-files translated.
- rs-structure: `mod.rs` may hold the feature's thin public orchestrator (resolves a conflict found by the split behaviour test).
- Behaviour test results recorded in the spec (§11).

## [0.5.0] — 2026-11-10 — Phase 4: Production & release

### Added
- `rs-release` expanded: CI gate table, supply-chain rules, versioning/changelog rules, container image guidance, full pre-release checklist, scaffolding.
- `templates/release/`: GitHub Actions and GitLab CI pipelines (fmt, clippy, tests on MSRV+stable, docs, contracts+structure, cargo-deny, semver-checks, tagged release), `deny.toml`, cargo-chef + distroless `Dockerfile`, release profile, `CHANGELOG.md` skeleton.
- `scripts/release-check.sh` — the definition of done: metadata (MSRV, `[lints]`, edition, no `deny(warnings)`), fmt, clippy, tests (all features / none), docs with warnings denied, Design Contracts, structure smells, and cargo-deny/audit/semver-checks/msrv when installed (WARN with install hint otherwise; `--strict` makes WARN fail).
- `scripts/new-crate.sh` — scaffolds `--lib`, `--bin` (lib + thin main) or `--service` crates with a Design Contract in every file, feature-module layout, tests, lint policy with correct group priorities, release profile, `deny.toml`, `CHANGELOG.md`, CI, Dockerfile. Verified: all three kinds pass `release-check.sh --no-net`.
- Commands: `/rs-new-crate`, `/rs-release-check`; `/rs-review` rewritten in English as the rs-skills review flow (contracts → structure → anti-patterns → rules → clippy).
- `contract-check.sh` now flags bare `<placeholder>` text in contracts (breaks `cargo doc -Dwarnings`); the Design Contract skill documents the rustdoc gotcha.

## [0.4.0] — 2026-11-10 — Phase 3: Rules depth

### Added
- All 265 upstream rules distributed into `skills/<rs-skill>/rules/` per the coverage matrix in `docs/coverage/` (ids kept, provenance line added, cross-rule links rewritten) via `scripts/distribute-rules.py`; generated `## Rules` sections in 18 skills via `scripts/gen-rule-index.py`.
- New skills: `rs-api-design` (L2: API checklist, documentation checklist, compatibility table; `api-`, `conv-`, `doc-` rules), `rs-testing` (L4: pyramid, decision guide, production checklist; `test-` rules), `rs-observability` (L4: spans/fields/levels, where instrumentation goes; `obs-` rules), `rs-release` (L4 skeleton: lint policy, MSRV, release profile; `lint-` + `proj-msrv-declare` rules — expanded in Phase 4).
- `checks/` compile-check harness ported (pinned Rust 1.95.0, baseline gate) and `scripts/rules-check.sh` (265 landed, unique ids, links resolve, indexes current).
- Router, `CLAUDE.md`, hook, indexes updated; 45 skills.

## [0.3.0] — 2026-11-10 — Phase 2: Design Contract + Structure

### Added
- `rs-structure` (L2): where code lives and what to do when it grows — group-by-feature module layout (vs by kind), the size/split ladder (function → file → module directory → feature → workspace crate) with a step-by-step split recipe and worked example, the visibility ladder, reference layouts (library, binary+lib, hexagonal service, workspace) as `templates/project-layout/`, structure anti-patterns (`utils.rs`, god `types.rs`, flat `src/`, fat `main.rs`, logic in `mod.rs`), and `scripts/structure-check.sh`. upstream `proj-*` rules are remapped here for Phase 3.
- Design Contract gains an optional **Layout** field (module map on `lib.rs`/`mod.rs`); **Extend by** must name where new code goes.
- Restructuring existing crates: `guides/restructure-existing.md` (inventory → cluster by feature → target tree → leaves-first `git mv` → visibility → contracts), `scripts/structure-map.sh` (per-file lines / pub items / `use` edges / feature guess as a Markdown table) and the `/rs-restructure` command.
- First depth rules land early: the 13 upstream `proj-*` rules under `rs-structure/rules/` via the Phase-3 tooling `scripts/distribute-rules.py` (provenance line + link rewriting) and `scripts/gen-rule-index.py` (generated `## Rules` section between markers, `--check` mode).
- `rs-design-contract` (L4): the convention that every `.rs` file under `src/` starts with a ≤12-line `//! # Design Contract` module doc block (Role, Patterns, Invariants, Ownership, Errors, Concurrency, Extend by, Avoid, Skills), read before editing and updated with the design. Examples for `lib.rs`, modules, plain data, and the edit flow; template in `templates/design-contract/`.
- `scripts/contract-check.sh`: finds missing/invalid blocks, enforces the line limit and required fields, resolves every `rs-*` skill and `rs-patterns/…` page named; exempts `tests/`, `benches/`, `examples/`, `build.rs`, pure `mod.rs`. Fixtures in `tests/fixtures/contract/`.
- `/rs-contract-check` command and a `PostToolUse` hook on `Write`/`Edit` of `*.rs` that reminds the agent when a file was written without a contract.
- Router, `CLAUDE.md` and the prompt hook now carry the Design Contract rule.

## [0.2.0] — 2026-11-10 — Phase 1: Patterns book

### Added
- `rs-patterns` (L2): the complete pattern catalogue — 18 idioms (incl. 3 FFI), 14 design patterns (behavioural 6, creational 2, structural 4, FFI 2), 3 anti-patterns, 3 functional-programming chapters, design principles, refactoring and resources — 52 pages reproduced under MPL-2.0 with `SOURCES.md` page map and `LICENSE-MPL`. Each page gets a header (category, *Use when*, *Traces to* rs-skills, source) and rewritten internal links.
- `rs-patterns/SKILL.md`: original catalogue with a symptom → pattern decision guide, a stop-list of anti-patterns, Trace Up/Down tables.
- "Related patterns" tables in rs-ownership, rs-resource, rs-mutability, rs-traits, rs-type-driven, rs-error-handling, rs-ecosystem, rs-lifecycle, rs-mental-model, rs-anti-pattern, rs-unsafe and rs-style.
- Router rows for pattern vocabulary and conflict resolution (`newtype`, `builder`, `RAII`, `anti-pattern`, `FFI`).

## [0.1.0] — 2026-11-10 — Phase 0: Foundation

### Added
- New plugin `rs-skills` (prefix `rs-`), own marketplace manifest, MIT licence, `NOTICE.md` crediting the upstream sources.
- All 38 upstream skills ported and renamed (`m01-ownership` → `rs-ownership`, `m04-zero-cost` → `rs-traits`, `m09-domain` → `rs-domain-model`, `unsafe-checker` → `rs-unsafe`, `coding-guidelines` → `rs-style`, `core-*` → `rs-util-*`, `rust-*` → `rs-*`), with their agents (10), commands (21), templates, tests and scripts; every cross-reference rewritten.
- Four-layer model: L4 Delivery (ship) added above the upstream Mechanics / Design / Domain layers — `_meta/layer-definitions.md`, `rs-router`, `CLAUDE.md`, indexes.
- English-only hook matcher with Rust-specific triggers (design pattern, builder, newtype, RAII, tracing, MSRV, release, …) and `tests/hook-matcher-test.py` (21 cases).
- Coverage matrix (`docs/coverage/*.tsv`, 400 rows) mapping every upstream item to its destination and phase, with `scripts/coverage-check.sh`.
- `scripts/sync-local.sh` to refresh the installed plugin cache from the working copy.

### Removed (relative to the upstream skill set)
- Chinese / Japanese trigger keywords and READMEs; the `m[XX][YYY]` numbering system (`index/tech-categories.md`).
