---
name: rs-design-contract
description: "CRITICAL: Use whenever creating or editing a Rust source file. Every .rs file written with rs-skills carries a Design Contract header (module doc block) that records the patterns it follows, its invariants and how to extend it, so later agents follow the same design. Triggers: design contract, file header, module doc, //!, new .rs file, create module, add a module, refactor this file, extend this file, what pattern does this file use, lib.rs, main.rs, mod.rs"
user-invocable: false
---

# Design Contract

> **Layer 4: Delivery** · the one convention that makes every other skill stick

## Core Question

**Will the next agent (or human) understand — and keep — the design this file was built with?**

A file written with a pattern in mind and no record of it is a file whose
pattern dies at the next edit. The Design Contract is a ≤12-line module doc
block, kept with the code, read by rustdoc, that says *what this file is, which
patterns it follows, what must stay true, and how to extend it*.

---

## The rule

| When | Do |
|---|---|
| **Creating** a `.rs` file under `src/` | Write a Design Contract as the file's module doc (`//!`) before any code |
| **Editing** a `.rs` file | Read its Design Contract first; follow **Extend by** and respect **Avoid**; if the change alters the design, update the contract in the same edit |
| **Reviewing** | Check code against its contract; a mismatch is a finding, whichever side is wrong |
| `tests/`, `benches/`, `build.rs`, pure `mod.rs` re-export files, generated code (`generated/` dir or an `@generated` / "do not edit" marker) | Exempt (contract optional); for generated modules add `#[rustfmt::skip]` and a lint `allow` on the `mod` line instead |

---

## The template

```rust
//! # Design Contract
//! **Role:** Parses CLI configuration and validates it before anything else runs.
//! **Patterns:** Builder (rs-patterns/design-patterns/creational/builder.md) · Newtype ids (rs-type-driven)
//! **Invariants:** `Config` is immutable after `build()`; every path is absolute; no I/O here.
//! **Ownership:** `Config` owns its strings; callers receive `&str`, never clones.
//! **Errors:** `ConfigError` via thiserror; never panics on user input.
//! **Extend by:** add a field to `ConfigBuilder` with a default; do NOT add boolean flags.
//! **Avoid:** `Deref` for inheritance; `unwrap()` outside tests (rs-anti-pattern).
//! **Skills:** rs-patterns, rs-type-driven, rs-error-handling · rs-skills v0.3
```

| Field | Required | Content |
|---|---|---|
| **Role** | yes | one sentence, what this file is responsible for — and implicitly what it is not |
| **Patterns** | yes | pattern names with the rs-skill (and page path for rs-patterns) that explains them; `none (plain data)` is a valid answer. Name boundaries explicitly: `Port AuditStore; adapters in adapters/` (rs-ports-adapters), and a standard implemented on an SDK: `MCP via rmcp 3.x (decisions/0004)` or, for a hand-rolled subset, `hand-rolled subset of <spec> <version> (decisions/NNNN)` (rs-reuse-first) |
| **Invariants** | yes | what must always hold; the things a test would assert |
| **Layout** | on `lib.rs` / `mod.rs` | one entry per submodule with its role — the module map (rs-structure) |
| **Ownership** | if non-trivial | who owns what, what is borrowed, `Arc`/`Rc` decisions |
| **Errors** | if the file can fail | error type, propagation policy, panic policy |
| **Concurrency** | if shared across threads/tasks | Send/Sync expectations, locks, cancellation |
| **Extend by** | yes | the sanctioned way to add behaviour *and where it goes* (which module/file), and the unsanctioned one |
| **Avoid** | recommended | shortcuts explicitly forbidden here, with the skill that says why |
| **Skills** | yes | the rs-* skills that shaped the file, then `rs-skills vX.Y` |

Rules: the block is rustdoc — wrap placeholders like `` `<feature>/` `` in backticks or `cargo doc -Dwarnings` fails on "unclosed HTML tag"; at most **12 lines** from `# Design Contract` to the end of the block;
every `rs-*` name must be a real skill; every `rs-patterns/...` path must exist;
plain language — no code except identifiers.

---

## Placement

```rust
// SPDX / licence comment (optional)
#![forbid(unsafe_code)]                  // crate attributes may precede

//! Short crate or module summary paragraph (lib.rs / main.rs: keep rustdoc's
//! first paragraph human-friendly).
//!
//! # Design Contract
//! **Role:** …
//! …

use std::path::PathBuf;                  // code starts after the block
```

For ordinary modules the contract may be the very first lines. Keep it in the
`//!` run at the top; the checker looks only there.

---

## Thinking Prompt — filling the fields

1. **Role** — if you cannot say it in one sentence, the file does too much (rs-anti-pattern: long files, giant enums).
2. **Patterns** — name only what you actually used (including the ports you define and the SDKs you wrap); look them up in `rs-patterns/SKILL.md` and write the trade-off you accepted into **Invariants** or **Avoid**.
3. **Extend by** — imagine the next feature request; which edit would keep the design, which would break it? Name the file or module the new code belongs in (rs-structure) — "add a handler" is not an answer, "add `orders/handlers/<verb>.rs` and register it in `orders/mod.rs`" is.
4. **Avoid** — the shortcut *you* were tempted by while writing it.

---

## Reading a contract before editing

```
read header → does the change fit "Extend by"?
   yes → implement; update Invariants/Patterns only if they changed
   no  → stop: either the request needs a design change (update the contract
         deliberately and say so) or the request is wrong for this file
```
Never silently violate **Avoid**. If you must, change the contract line and
explain why in the commit.

---

## Verification

| Tool | What it checks |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh [path]` | every non-exempt `.rs` has a block; ≤12 lines; required fields present; `rs-*` names and `rs-patterns/` paths resolve |
| `/rs-contract-check` | the same, as a slash command |
| `PostToolUse` hook on `Write`/`Edit` of `*.rs` | reminds you immediately if a file you just wrote has no contract |

---

## Trace Up ↑ / Trace Down ↓

| Field | Comes from |
|---|---|
| Role, Invariants | rs-domain-model, rs-domain-* |
| Patterns | rs-patterns, rs-type-driven, rs-traits |
| Layout, Extend by (where) | rs-structure |
| Ownership, Concurrency | rs-ownership, rs-resource, rs-concurrency |
| Errors | rs-error-handling, rs-domain-error |
| Avoid | rs-anti-pattern |

## Related Skills

| When | See |
|---|---|
| Choosing the patterns to record | rs-patterns |
| Deciding the module map (Layout) and where new code goes | rs-structure |
| Naming and doc style of the block | rs-style |
| What the reviewer checks | rs-anti-pattern |

Examples: `examples/lib-rs.md`, `examples/module.md`, `examples/edit-flow.md`. Template: `${CLAUDE_PLUGIN_ROOT}/templates/design-contract/`.
