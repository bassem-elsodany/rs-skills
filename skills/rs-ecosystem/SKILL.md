---
name: rs-ecosystem
description: "Use when integrating crates or ecosystem questions. Keywords: E0425, E0433, E0603, crate, cargo, dependency, feature flag, workspace, which crate to use, using external C libraries, creating Python extensions, PyO3, wasm, WebAssembly, bindgen, cbindgen, napi-rs, cannot find, private, crate recommendation, best crate for, Cargo.toml, features"
user-invocable: false
---

## Current Dependencies (Auto-Injected)

!`grep -A 100 '^\[dependencies\]' Cargo.toml 2>/dev/null | head -30 || echo "No Cargo.toml found"`

---

# Ecosystem Integration

> **Layer 2: Design Choices**

## Core Question

**What's the right crate for this job, and how should it integrate?**

**Before implementing a standard, protocol, file format or vendor API yourself — STOP: run the rs-reuse-first gate** (`${CLAUDE_PLUGIN_ROOT}/skills/rs-reuse-first/scripts/sdk-scout.sh "<standard>" --github`). The official or de-facto SDK comes first; hand-rolling needs a written reason. (Example: an MCP server is built on `rmcp`, never on a hand-drafted JSON-RPC layer.)

Before adding dependencies:
- Is there a standard solution?
- What's the maintenance status?
- What's the API stability?

---

## Integration Decision → Implementation

| Need | Choice | Crates |
|------|--------|--------|
| Serialization | Derive-based | serde, serde_json |
| Async runtime | tokio or async-std | tokio (most popular) |
| HTTP client | Ergonomic | reqwest |
| HTTP server | Modern | axum, actix-web |
| Database | SQL or ORM | sqlx, diesel |
| CLI parsing | Derive-based | clap |
| Error handling | App vs lib | anyhow, thiserror |
| Logging | Facade | tracing, log |

---

## Thinking Prompt

Before adding a dependency:

1. **Is it well-maintained?**
   - Recent commits?
   - Active issue response?
   - Breaking changes frequency?

2. **What's the scope?**
   - Do you need the full crate or just a feature?
   - Can feature flags reduce bloat?

3. **How does it integrate?**
   - Trait-based or concrete types?
   - Sync or async?
   - What bounds does it require?

---

## Trace Up ↑

To domain constraints (Layer 3):

```
"Which HTTP framework should I use?"
    ↑ Ask: What are the performance requirements?
    ↑ Check: rs-domain-web (latency, throughput needs)
    ↑ Check: Team expertise (familiarity with framework)
```

| Question | Trace To | Ask |
|----------|----------|-----|
| Framework choice | rs-domain-* | What constraints matter? |
| Library vs build | rs-domain-* | What's the deployment model? |
| API design | rs-domain-* | Who are the consumers? |

---

## Trace Down ↓

To implementation (Layer 1):

```
"Integrate external crate"
    ↓ rs-traits: Trait bounds and generics
    ↓ rs-error-handling: Error type compatibility

"FFI integration"
    ↓ rs-unsafe: Safety requirements
    ↓ rs-lifecycle: Resource cleanup
```

---

## Quick Reference

### Language Interop

| Integration | Crate/Tool | Use Case |
|-------------|------------|----------|
| C/C++ → Rust | `bindgen` | Auto-generate bindings |
| Rust → C | `cbindgen` | Export C headers |
| Python ↔ Rust | `pyo3` | Python extensions |
| Node.js ↔ Rust | `napi-rs` | Node addons |
| WebAssembly | `wasm-bindgen` | Browser/WASI |

### Cargo Features

| Feature | Purpose |
|---------|---------|
| `[features]` | Optional functionality |
| `default = [...]` | Default features |
| `feature = "serde"` | Conditional deps |
| `[workspace]` | Multi-crate projects |

## Error Code Reference

| Error | Cause | Fix |
|-------|-------|-----|
| E0433 | Can't find crate | Add to Cargo.toml |
| E0603 | Private item | Check crate docs |
| Feature not enabled | Optional feature | Enable in `features` |
| Version conflict | Incompatible deps | `cargo update` or pin |
| Duplicate types | Different crate versions | Unify in workspace |

---

## Crate Selection Criteria

| Criterion | Good Sign | Warning Sign |
|-----------|-----------|--------------|
| Maintenance | Recent commits | Years inactive |
| Community | Active issues/PRs | No response |
| Documentation | Examples, API docs | Minimal docs |
| Stability | Semantic versioning | Frequent breaking |
| Dependencies | Minimal, well-known | Heavy, obscure |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| `extern crate` | Outdated (2018+) | Just `use` |
| `#[macro_use]` | Global pollution | Explicit import |
| Wildcard deps `*` | Unpredictable | Specific versions |
| Too many deps | Supply chain risk | Evaluate necessity |
| Vendoring everything | Maintenance burden | Trust crates.io |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| How big should a crate be? | Prefer small crates | `../rs-patterns/design-patterns/structural/small-crates.md` |
| Evolving a public struct/enum without a breaking release | `#[non_exhaustive]` + private fields | `../rs-patterns/idioms/priv-extend.md` |
| `#![deny(warnings)]` in a published crate | Anti-pattern: deny(warnings) | `../rs-patterns/anti-patterns/deny-warnings.md` |
| Doc examples with heavy setup | Easy doc initialisation | `../rs-patterns/idioms/rustdoc-init.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (8)

Depth rules under `rules/` — open the one the question needs, not all of them.

**serde-**

- [`serde-custom-with`](rules/serde-custom-with.md) — Customize a field's (de)serialization with `with` / `serialize_with` / `deserialize_with`
- [`serde-default-compat`](rules/serde-default-compat.md) — Use `#[serde(default)]` for optional and backward-compatible fields
- [`serde-deny-unknown-fields`](rules/serde-deny-unknown-fields.md) — Reject unexpected keys with `#[serde(deny_unknown_fields)]`
- [`serde-enum-representation`](rules/serde-enum-representation.md) — Choose enum tagging deliberately: externally, internally, adjacently tagged, or untagged
- [`serde-flatten`](rules/serde-flatten.md) — Inline nested structs or capture extra keys with `#[serde(flatten)]`
- [`serde-rename-all`](rules/serde-rename-all.md) — Match the external naming convention with `#[serde(rename_all = ...)]`
- [`serde-skip-empty`](rules/serde-skip-empty.md) — Omit empty fields with `skip_serializing_if`
- [`serde-try-from-validate`](rules/serde-try-from-validate.md) — Validate while deserializing with `#[serde(try_from = "Raw")]`

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Error type design | rs-error-handling |
| Trait integration | rs-traits |
| FFI safety | rs-unsafe |
| Resource management | rs-lifecycle |
| Market search before implementing a standard or vendor API | rs-reuse-first |
