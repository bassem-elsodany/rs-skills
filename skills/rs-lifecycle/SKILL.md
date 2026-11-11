---
name: rs-lifecycle
description: "Use when designing resource lifecycles. Keywords: RAII, Drop, resource lifecycle, connection pool, lazy initialization, connection pool design, resource cleanup patterns, cleanup, scope, OnceCell, Lazy, once_cell, OnceLock, transaction, session management, when is Drop called, cleanup on error, guard pattern, scope guard"
user-invocable: false
---

# Resource Lifecycle

> **Layer 2: Design Choices**

## Core Question

**When should this resource be created, used, and cleaned up?**

Before implementing lifecycle:
- What's the resource's scope?
- Who owns the cleanup responsibility?
- What happens on error?

---

## Lifecycle Pattern → Implementation

| Pattern | When | Implementation |
|---------|------|----------------|
| RAII | Auto cleanup | `Drop` trait |
| Lazy init | Deferred creation | `OnceLock`, `LazyLock` |
| Pool | Reuse expensive resources | `r2d2`, `deadpool` |
| Guard | Scoped access | `MutexGuard` pattern |
| Scope | Transaction boundary | Custom struct + Drop |

---

## Thinking Prompt

Before designing lifecycle:

1. **What's the resource cost?**
   - Cheap → create per use
   - Expensive → pool or cache
   - Global → lazy singleton

2. **What's the scope?**
   - Function-local → stack allocation
   - Request-scoped → passed or extracted
   - Application-wide → static or Arc

3. **What about errors?**
   - Cleanup must happen → Drop
   - Cleanup is optional → explicit close
   - Cleanup can fail → Result from close

---

## Trace Up ↑

To domain constraints (Layer 3):

```
"How should I manage database connections?"
    ↑ Ask: What's the connection cost?
    ↑ Check: rs-domain-* (latency requirements)
    ↑ Check: Infrastructure (connection limits)
```

| Question | Trace To | Ask |
|----------|----------|-----|
| Connection pooling | rs-domain-* | What's acceptable latency? |
| Resource limits | rs-domain-* | What are infra constraints? |
| Transaction scope | rs-domain-* | What must be atomic? |

---

## Trace Down ↓

To implementation (Layer 1):

```
"Need automatic cleanup"
    ↓ rs-resource: Implement Drop
    ↓ rs-ownership: Clear owner for cleanup

"Need lazy initialization"
    ↓ rs-mutability: OnceLock for thread-safe
    ↓ rs-concurrency: LazyLock for sync

"Need connection pool"
    ↓ rs-concurrency: Thread-safe pool
    ↓ rs-resource: Arc for sharing
```

---

## Quick Reference

| Pattern | Type | Use Case |
|---------|------|----------|
| RAII | `Drop` trait | Auto cleanup on scope exit |
| Lazy Init | `OnceLock`, `LazyLock` | Deferred initialization |
| Pool | `r2d2`, `deadpool` | Connection reuse |
| Guard | `MutexGuard` | Scoped lock release |
| Scope | Custom struct | Transaction boundaries |

## Lifecycle Events

| Event | Rust Mechanism |
|-------|----------------|
| Creation | `new()`, `Default` |
| Lazy Init | `OnceLock::get_or_init` |
| Usage | `&self`, `&mut self` |
| Cleanup | `Drop::drop()` |

## Pattern Templates

### RAII Guard

```rust
struct FileGuard {
    path: PathBuf,
    _handle: File,
}

impl Drop for FileGuard {
    fn drop(&mut self) {
        // Cleanup: remove temp file
        let _ = std::fs::remove_file(&self.path);
    }
}
```

### Lazy Singleton

```rust
use std::sync::OnceLock;

static CONFIG: OnceLock<Config> = OnceLock::new();

fn get_config() -> &'static Config {
    CONFIG.get_or_init(|| {
        Config::load().expect("config required")
    })
}
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Resource leak | Forgot Drop | Implement Drop or RAII wrapper |
| Double free | Manual memory | Let Rust handle |
| Use after drop | Dangling reference | Check lifetimes |
| E0509 move out of Drop | Moving owned field | `Option::take()` |
| Pool exhaustion | Not returned | Ensure Drop returns |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Manual cleanup | Easy to forget | RAII/Drop |
| `lazy_static!` | External dep | `std::sync::OnceLock` |
| Global mutable state | Thread unsafety | `OnceLock` or proper sync |
| Forget to close | Resource leak | Drop impl |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| Acquire in constructor, release in `Drop`, hold while used | RAII guards | `../rs-patterns/design-patterns/behavioural/RAII.md` |
| A `finally` block | Finalisation in destructors | `../rs-patterns/idioms/dtor-finally.md` |
| Creating resources with sensible defaults | Constructor + `Default` | `../rs-patterns/idioms/ctor.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (1)

Depth rules under `rules/` — open the one the question needs, not all of them.

**mem-**

- [`mem-drop-order`](rules/mem-drop-order.md) — Know and control drop order: struct fields drop top-to-bottom, locals in reverse

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Smart pointers | rs-resource |
| Thread-safe init | rs-concurrency |
| Domain scopes | rs-domain-model |
| Error in cleanup | rs-error-handling |
| Graceful shutdown of tasks and pools | rs-async-patterns |
