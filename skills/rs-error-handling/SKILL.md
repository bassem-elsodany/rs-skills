---
name: rs-error-handling
description: "CRITICAL: Use for error handling. Triggers: Result, Option, Error, ?, unwrap, expect, panic, anyhow, thiserror, when to panic vs return Result, custom error, error propagation"
user-invocable: false
---

# Error Handling

> **Layer 1: Language Mechanics**

## Core Question

**Is this failure expected or a bug?**

Before choosing error handling strategy:
- Can this fail in normal operation?
- Who should handle this failure?
- What context does the caller need?

---

## Error → Design Question

| Pattern | Don't Just Say | Ask Instead |
|---------|----------------|-------------|
| unwrap panics | "Use ?" | Is None/Err actually possible here? |
| Type mismatch on ? | "Use anyhow" | Are error types designed correctly? |
| Lost error context | "Add .context()" | What does the caller need to know? |
| Too many error variants | "Use Box<dyn Error>" | Is error granularity right? |

---

## Thinking Prompt

Before handling an error:

1. **What kind of failure is this?**
   - Expected → Result<T, E>
   - Absence normal → Option<T>
   - Bug/invariant → panic!
   - Unrecoverable → panic!

2. **Who handles this?**
   - Caller → propagate with ?
   - Current function → match/if-let
   - User → friendly error message
   - Programmer → panic with message

3. **What context is needed?**
   - Type of error → thiserror variants
   - Call chain → anyhow::Context
   - Debug info → anyhow or tracing

---

## Trace Up ↑

When error strategy is unclear:

```
"Should I return Result or Option?"
    ↑ Ask: Is absence/failure normal or exceptional?
    ↑ Check: rs-domain-model (what does domain say?)
    ↑ Check: rs-domain-* (error handling requirements)
```

| Situation | Trace To | Question |
|-----------|----------|----------|
| Too many unwraps | rs-domain-model | Is the data model right? |
| Error context design | rs-domain-error | What recovery is needed? |
| Library vs app errors | rs-ecosystem | Who are the consumers? |

---

## Trace Down ↓

From design to implementation:

```
"Expected failure, library code"
    ↓ Use: thiserror for typed errors

"Expected failure, application code"
    ↓ Use: anyhow for ergonomic errors

"Absence is normal (find, get, lookup)"
    ↓ Use: Option<T>

"Bug or invariant violation"
    ↓ Use: panic!, assert!, unreachable!

"Need to propagate with context"
    ↓ Use: .context("what was happening")
```

---

## Quick Reference

| Pattern | When | Example |
|---------|------|---------|
| `Result<T, E>` | Recoverable error | `fn read() -> Result<String, io::Error>` |
| `Option<T>` | Absence is normal | `fn find() -> Option<&Item>` |
| `?` | Propagate error | `let data = file.read()?;` |
| `unwrap()` | Dev/test only | `config.get("key").unwrap()` |
| `expect()` | Invariant holds | `env.get("HOME").expect("HOME set")` |
| `panic!` | Unrecoverable | `panic!("critical failure")` |

## Security filters: fail closed

In a gateway, auth or inspection filter, **"the check could not run" must deny, never forward**.
Every `Err(_) => continue`, `let _ = write(..)`, `unwrap_or(false)` on a matcher, or parse-to-`Null`
is a potential bypass. Model the failure as a type the caller must handle
(`Result<Filtered, Unfilterable>`, `BodyWrite::{Replaced, FallbackBlocked, Failed}`), reply with a
constant, content-free error, log the reason, and test each branch. Rule: [`err-fail-closed`](rules/err-fail-closed.md).

## Library vs Application

| Context | Error Crate | Why |
|---------|-------------|-----|
| Library | `thiserror` | Typed errors for consumers |
| Application | `anyhow` | Ergonomic error handling |
| Mixed | Both | thiserror at boundaries, anyhow internally |

## Decision Flowchart

```
Is failure expected?
├─ Yes → Is absence the only "failure"?
│        ├─ Yes → Option<T>
│        └─ No → Result<T, E>
│                 ├─ Library → thiserror
│                 └─ Application → anyhow
└─ No → Is it a bug?
        ├─ Yes → panic!, assert!
        └─ No → Consider if really unrecoverable

Use ? → Need context?
├─ Yes → .context("message")
└─ No → Plain ?
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `unwrap()` panic | Unhandled None/Err | Use `?` or match |
| Type mismatch | Different error types | Use `anyhow` or `From` |
| Lost context | `?` without context | Add `.context()` |
| `cannot use ?` | Missing Result return | Return `Result<(), E>` |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| `.unwrap()` everywhere | Panics in production | `.expect("reason")` or `?` |
| Ignore errors silently | Bugs hidden | Handle or propagate |
| `panic!` for expected errors | Bad UX, no recovery | Result |
| Box<dyn Error> everywhere | Lost type info | thiserror |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| Errors must cross a C boundary | FFI idiomatic errors | `../rs-patterns/idioms/ffi/errors.md` |
| `Option` inside iterator pipelines | Iterating over `Option` | `../rs-patterns/idioms/option-iter.md` |
| Cleanup must run on every exit path, including panic | Finalisation in destructors | `../rs-patterns/idioms/dtor-finally.md` |
| Fallible function consumed its argument | Return consumed arg on error | `../rs-patterns/idioms/return-consumed-arg-on-error.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (13)

Depth rules under `rules/` — open the one the question needs, not all of them.

**err-**

- [`err-anyhow-app`](rules/err-anyhow-app.md) — Use `anyhow` for application error handling
- [`err-context-chain`](rules/err-context-chain.md) — Add context with `.context()` or `.with_context()`
- [`err-custom-type`](rules/err-custom-type.md) — Define custom error types for domain-specific failures
- [`err-doc-errors`](rules/err-doc-errors.md) — Document error conditions with `# Errors` section in doc comments
- [`err-expect-bugs-only`](rules/err-expect-bugs-only.md) — Use `expect()` only for invariants that indicate bugs, not user errors
- [`err-fail-closed`](rules/err-fail-closed.md) — In a security filter, every error path must deny — never forward what it could not check
- [`err-from-impl`](rules/err-from-impl.md) — Implement `From<E>` for error conversions to enable `?` operator
- [`err-lowercase-msg`](rules/err-lowercase-msg.md) — Start error messages lowercase, no trailing punctuation
- [`err-no-unwrap-prod`](rules/err-no-unwrap-prod.md) — Avoid `unwrap()` in production code; use `?`, `expect()`, or handle errors
- [`err-question-mark`](rules/err-question-mark.md) — Use `?` operator for clean propagation
- [`err-result-over-panic`](rules/err-result-over-panic.md) — Return `Result<T, E>` instead of panicking for recoverable errors
- [`err-source-chain`](rules/err-source-chain.md) — Preserve error chains with `#[source]` or `source()` method
- [`err-thiserror-lib`](rules/err-thiserror-lib.md) — Use `thiserror` for library error types

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Domain error strategy | rs-domain-error |
| Crate boundaries | rs-ecosystem |
| Type-safe errors | rs-type-driven |
| Mental models | rs-mental-model |
