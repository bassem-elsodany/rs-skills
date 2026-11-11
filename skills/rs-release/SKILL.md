---
name: rs-release
description: "Use when preparing Rust code for release or production — lint configuration, CI gates, MSRV, versioning, release profiles, dependency audit, Docker images, scaffolding a new crate. Triggers: release, ship, production ready, CI, GitHub Actions, GitLab CI, clippy config, lints, [lints], deny warnings, rustfmt check, MSRV, rust-version, semver, cargo-semver-checks, cargo-deny, cargo-audit, supply chain, release profile, LTO, codegen-units, strip, Docker image, binary size, version bump, changelog, publish to crates.io, cargo publish"
user-invocable: false
---

# Release Engineering

> **Layer 4: Delivery** · can this be released, audited and rolled back without surprises?
>
> Tools: `/rs-release-check` (gate) · `/rs-new-crate` (scaffold) · `${CLAUDE_PLUGIN_ROOT}/templates/release/` (CI, deny.toml, Dockerfile, profile, changelog)

## Core Question

**Can this be released, audited and rolled back without surprises?**

---

## Thinking Prompt

1. **What does CI gate on?** fmt, clippy (with the policy below), tests on MSRV *and* stable, docs build, audit.
2. **What is the MSRV and is it tested?** Declare `rust-version`, test it in CI, bump deliberately.
3. **What breaks downstream?** Every public change is checked against semver (rs-api-design compatibility table).
4. **Can we see what shipped?** Version, git SHA and build profile in `--version` and in the first log line (rs-observability).

---

## Lint policy

| Setting | Rule |
|---|---|
| `[lints]` in `Cargo.toml` (or `[workspace.lints]`), not `#![…]` scattered | `lint-cargo-metadata`, `lint-workspace-lints` |
| `clippy::correctness = "deny"`; `suspicious`, `style`, `complexity`, `perf` = "warn" | `lint-deny-correctness`, `lint-warn-suspicious`, `lint-warn-style`, `lint-warn-complexity`, `lint-warn-perf` |
| `pedantic` and `nursery`: enable selectively, never wholesale | `lint-pedantic-selective`, `lint-clippy-nursery-selected` |
| `missing_docs` warn on libraries; `unsafe_op_in_unsafe_fn` + `clippy::undocumented_unsafe_blocks` | `lint-missing-docs`, `lint-unsafe-doc` |
| `rustfmt --check` in CI; `unexpected_cfgs` checked | `lint-rustfmt-check`, `lint-cfg-check` |
| never `#![deny(warnings)]` in a published crate | rs-patterns `anti-patterns/deny-warnings.md`; use `RUSTFLAGS=-Dwarnings` in CI instead |

```toml
[lints.rust]
unsafe_code = "warn"
missing_docs = "warn"
unsafe_op_in_unsafe_fn = "warn"

[lints.clippy]
# lint GROUPS need priority = -1 so single-lint allows/denies below can override them
correctness = { level = "deny", priority = -1 }
suspicious  = { level = "warn", priority = -1 }
style       = { level = "warn", priority = -1 }
complexity  = { level = "warn", priority = -1 }
perf        = { level = "warn", priority = -1 }
pedantic    = { level = "warn", priority = -1 }   # then allow the noisy ones explicitly
module_name_repetitions = "allow"
undocumented_unsafe_blocks = "warn"
```

## Adopting the lint policy on an existing crate (brownfield)

Never land the full table and leave CI red, and never silence everything. Ratchet:

| Step | Do |
|---|---|
| 1 | `cargo fmt --all` in its own step; protect generated code with `#[rustfmt::skip]` + `#[allow(clippy::all, clippy::pedantic)]` on its `mod` line |
| 2 | Add the full `[lints]` table (same as `new-crate.sh`) |
| 3 | Measure: `cargo clippy --all-targets --message-format=short 2>&1 \| sed -E 's/^[^:]+:[0-9]+:[0-9]+: //' \| sort \| uniq -c \| sort -rn` |
| 4 | `cargo clippy --fix --allow-dirty --all-targets`, then **re-run clippy**: `--fix` expanding `use x::*` leaves unused names — delete them |
| 5 | Lints that need design work (casts, long fns, arg counts, doc backticks) → a **ratchet block** in `[lints.clippy]`: `lint = "allow"  # <phase>: <why>`. Each line names the review phase that removes it |
| 6 | Fix the rest by hand (let-else, `Option<&T>`, identical arms, `LazyLock` over `lazy_static`) |
| 7 | Gate: `cargo clippy --all-targets --locked -- -D warnings` in CI; the ratchet block may only shrink |

Cross-compiled crates (wasm `cdylib`, embedded): build the real target in CI too — host `cargo test` passing does not prove the artefact links. For proxy-wasm, newer `rust-lld` needs `[target.wasm32-wasip1] rustflags = ["-C", "link-arg=--allow-undefined"]` in `.cargo/config.toml` so host functions become imports.

## MSRV

| Do | Rule |
|---|---|
| `rust-version = "1.xx"` in `Cargo.toml`; CI job on that toolchain; `cargo msrv` to verify | `proj-msrv-declare` |
| bump MSRV only in a minor release and say so in the changelog | — |

## Release profile

```toml
[profile.release]
lto = "thin"            # or "fat" for final binaries
codegen-units = 1
strip = "symbols"
panic = "abort"         # services: only if you never catch_unwind
```
Rules: rs-performance `opt-lto-release`, `opt-codegen-units`; `perf-release-profile`.

## CI gates (templates: `../../templates/release/github-ci.yml`, `gitlab-ci.yml`)

| Job | Runs | Fails when |
|---|---|---|
| fmt + clippy | `cargo fmt --check`, `cargo clippy --all-targets --all-features` with `RUSTFLAGS=-Dwarnings` | any warning under the policy |
| test (MSRV + stable) | `cargo test --all-targets --all-features`, `--no-default-features`, `--locked` | tests fail on either toolchain |
| docs | `cargo doc --no-deps` with `RUSTDOCFLAGS=-Dwarnings` | broken intra-doc links, HTML-tag typos in `//!` |
| contracts + structure | `${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh`, `${CLAUDE_PLUGIN_ROOT}/scripts/structure-check.sh --strict` | a file without a Design Contract, a `utils.rs`, a 400-line file |
| supply chain | `cargo deny check` (`deny.toml`: licences, advisories, bans, sources) | yanked/vulnerable dep, disallowed licence, git dep |
| semver (PRs) | `cargo semver-checks` | public API breaks without a major bump |
| release (tags) | `cargo build --release --locked`, `--version` smoke | binary does not build or report its version |

## Supply chain

> Tools: `${CLAUDE_SKILL_DIR}/scripts/dep-risk.py` (crates.io + OSV: yanked, advisories, owners, age, **build-time code census**, git/path/wildcard sources; `--offline` for the local census) · `guides/ci-hardening.md` · rules `rel-supply-chain-evidence`, `rel-ci-least-privilege` · build-time code risk: rs-security-review `sec-supply-chain-build-time-code`


| Do | Why |
|---|---|
| commit `Cargo.lock` for binaries; build with `--locked` in CI | reproducible builds |
| `cargo deny check` with an allow-list of licences and `wildcards = "deny"` | legal + hygiene |
| `cargo audit` or deny's advisories in CI *and* on a schedule | new RUSTSEC advisories arrive between commits |
| `unknown-registry`/`unknown-git = "deny"` | no surprise sources |
| pin GitHub Actions by commit SHA / CI images by digest; minimal `permissions`; no secrets for untrusted PRs (`guides/ci-hardening.md`) | the pipeline is part of the supply chain |

## Versioning and changelog

| Rule | Detail |
|---|---|
| SemVer; `0.x` minors may break | breaking table: rs-api-design |
| `cargo semver-checks` before every release | catches accidental breaks |
| `CHANGELOG.md` (Keep a Changelog) with **BREAKING** and MSRV-bump markers | `${CLAUDE_PLUGIN_ROOT}/templates/release/CHANGELOG.md` |
| `--version` prints version + git SHA; first log line repeats it | `rs-observability` — know what is running |
| tag `vX.Y.Z` builds the artefact; never build releases from a dirty tree | — |

## Container image (`${CLAUDE_PLUGIN_ROOT}/templates/release/Dockerfile`)

cargo-chef dependency layer → `cargo build --release --locked` → distroless `nonroot` runtime with only the binary. Pin the Rust image to the MSRV. Set `RUST_LOG`; never bake secrets into the image.

## Pre-release checklist

- [ ] `cargo fmt --check`, `cargo clippy --all-targets --all-features` clean under the policy above
- [ ] `cargo test --all-targets` on MSRV and stable; `--no-default-features` too
- [ ] `cargo doc --no-deps` with `RUSTDOCFLAGS=-Dwarnings`
- [ ] `cargo deny check` clean (`deny.toml`), `cargo semver-checks` clean for libraries
- [ ] version bumped per semver; CHANGELOG entry; Design Contracts current (`${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh`); `${CLAUDE_PLUGIN_ROOT}/scripts/structure-check.sh --strict` clean
- [ ] `${CLAUDE_PLUGIN_ROOT}/scripts/release-check.sh --strict` green — that is the definition of done

## Scaffolding (`${CLAUDE_PLUGIN_ROOT}/scripts/new-crate.sh`, `/rs-new-crate`)

A new crate starts production-ready: edition 2024, `rust-version`, the lint policy above, release profile, feature-module layout with a Design Contract in every file, tests, `deny.toml`, `CHANGELOG.md`, CI file, Dockerfile (binaries). Kinds: `--lib`, `--bin` (lib + thin main), `--service` (adds tokio).

<!-- rules-index:start -->
## Rules (16)

Depth rules under `rules/` — open the one the question needs, not all of them.

**lint-**

- [`lint-cargo-metadata`](rules/lint-cargo-metadata.md) — Enable clippy::cargo for published crates
- [`lint-cfg-check`](rules/lint-cfg-check.md) — Enable `unexpected_cfgs` and declare known cfgs to catch feature-gate typos
- [`lint-clippy-nursery-selected`](rules/lint-clippy-nursery-selected.md) — Enable high-value `clippy::nursery` lints selectively, not the whole group
- [`lint-deny-correctness`](rules/lint-deny-correctness.md) — `#![deny(clippy::correctness)]`
- [`lint-missing-docs`](rules/lint-missing-docs.md) — Warn on missing documentation for public items
- [`lint-pedantic-selective`](rules/lint-pedantic-selective.md) — Enable clippy::pedantic selectively
- [`lint-rustfmt-check`](rules/lint-rustfmt-check.md) — Run cargo fmt --check in CI
- [`lint-unsafe-doc`](rules/lint-unsafe-doc.md) — Require documentation for unsafe blocks
- [`lint-warn-complexity`](rules/lint-warn-complexity.md) — Enable clippy::complexity for simpler code
- [`lint-warn-perf`](rules/lint-warn-perf.md) — Enable clippy::perf for performance improvements
- [`lint-warn-style`](rules/lint-warn-style.md) — Enable clippy::style for idiomatic code
- [`lint-warn-suspicious`](rules/lint-warn-suspicious.md) — Enable clippy::suspicious for likely bugs
- [`lint-workspace-lints`](rules/lint-workspace-lints.md) — Configure lints at workspace level for consistent enforcement

**proj-**

- [`proj-msrv-declare`](rules/proj-msrv-declare.md) — Declare `rust-version` (MSRV) in Cargo.toml and test it in CI

**rel-**

- [`rel-ci-least-privilege`](rules/rel-ci-least-privilege.md) — CI gets the least privilege and the least trust: minimal token permissions, no secrets for untrusted code, pinned third-party actions
- [`rel-supply-chain-evidence`](rules/rel-supply-chain-evidence.md) — Measure dependency risk; report unassessable as unassessable, never as clean

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| What is a breaking change | rs-api-design |
| Release-time structure (workspaces, features) | rs-structure, rs-ecosystem |
| Perf flags | rs-performance |
| Deploy constraints | rs-domain-cloud-native |
| Tags, hooks, branch and release flow on any Git host | rs-git |
| Disk, Docker image and `target/` hygiene around builds | rs-cleanup |
| Choosing the official SDK; recording the decision | rs-reuse-first |
