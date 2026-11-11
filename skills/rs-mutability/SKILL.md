---
name: rs-mutability
description: "CRITICAL: Use for mutability issues. Triggers: E0596, E0499, E0502, cannot borrow as mutable, already borrowed as immutable, mut, &mut, interior mutability, Cell, RefCell, Mutex, RwLock"
user-invocable: false
---

# Mutability

> **Layer 1: Language Mechanics**

## Core Question

**Why does this data need to change, and who can change it?**

Before adding interior mutability, understand:
- Is mutation essential or accidental complexity?
- Who should control mutation?
- Is the mutation pattern safe?

---

## Error → Design Question

| Error | Don't Just Say | Ask Instead |
|-------|----------------|-------------|
| E0596 | "Add mut" | Should this really be mutable? |
| E0499 | "Split borrows" | Is the data structure right? |
| E0502 | "Separate scopes" | Why do we need both borrows? |
| RefCell panic | "Use try_borrow" | Is runtime check appropriate? |

---

## Thinking Prompt

Before adding mutability:

1. **Is mutation necessary?**
   - Maybe transform → return new value
   - Maybe builder → construct immutably

2. **Who controls mutation?**
   - External caller → `&mut T`
   - Internal logic → interior mutability
   - Concurrent access → synchronized mutability

3. **What's the thread context?**
   - Single-thread → Cell/RefCell
   - Multi-thread → Mutex/RwLock/Atomic

---

## Trace Up ↑

When mutability conflicts persist:

```
E0499/E0502 (borrow conflicts)
    ↑ Ask: Is the data structure designed correctly?
    ↑ Check: rs-domain-model (should data be split?)
    ↑ Check: rs-concurrency (is async involved?)
```

| Persistent Error | Trace To | Question |
|-----------------|----------|----------|
| Repeated borrow conflicts | rs-domain-model | Should data be restructured? |
| RefCell in async | rs-concurrency | Is Send/Sync needed? |
| Mutex deadlocks | rs-concurrency | Is the lock design right? |

---

## Trace Down ↓

From design to implementation:

```
"Need mutable access from &self"
    ↓ T: Copy → Cell<T>
    ↓ T: !Copy → RefCell<T>

"Need thread-safe mutation"
    ↓ Simple counters → AtomicXxx
    ↓ Complex data → Mutex<T> or RwLock<T>

"Need shared mutable state"
    ↓ Single-thread: Rc<RefCell<T>>
    ↓ Multi-thread: Arc<Mutex<T>>
```

---

## Borrow Rules

```
At any time, you can have EITHER:
├─ Multiple &T (immutable borrows)
└─ OR one &mut T (mutable borrow)

Never both simultaneously.
```

## Quick Reference

| Pattern | Thread-Safe | Runtime Cost | Use When |
|---------|-------------|--------------|----------|
| `&mut T` | N/A | Zero | Exclusive mutable access |
| `Cell<T>` | No | Zero | Copy types, no refs needed |
| `RefCell<T>` | No | Runtime check | Non-Copy, need runtime borrow |
| `Mutex<T>` | Yes | Lock contention | Thread-safe mutation |
| `RwLock<T>` | Yes | Lock contention | Many readers, few writers |
| `Atomic*` | Yes | Minimal | Simple types (bool, usize) |

## Error Code Reference

| Error | Cause | Quick Fix |
|-------|-------|-----------|
| E0596 | Borrowing immutable as mutable | Add `mut` or redesign |
| E0499 | Multiple mutable borrows | Restructure code flow |
| E0502 | &mut while & exists | Separate borrow scopes |

---

## Interior Mutability Decision

| Scenario | Choose |
|----------|--------|
| T: Copy, single-thread | `Cell<T>` |
| T: !Copy, single-thread | `RefCell<T>` |
| T: Copy, multi-thread | `AtomicXxx` |
| T: !Copy, multi-thread | `Mutex<T>` or `RwLock<T>` |
| Read-heavy, multi-thread | `RwLock<T>` |
| Simple flags/counters | `AtomicBool`, `AtomicUsize` |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| RefCell everywhere | Runtime panics | Clear ownership design |
| Mutex for single-thread | Unnecessary overhead | RefCell |
| Ignore RefCell panic | Hard to debug | Handle or restructure |
| Lock inside hot loop | Performance killer | Batch operations |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| Move a value out of `&mut self` / swap an enum variant in place | `mem::take` / `mem::replace` | `../rs-patterns/idioms/mem-replace.md` |
| Build mutably, then only read | Temporary mutability | `../rs-patterns/idioms/temporary-mutability.md` |
| E0499 / E0502 on fields of one big struct | Struct decomposition | `../rs-patterns/design-patterns/structural/compose-structs.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (3)

Depth rules under `rules/` — open the one the question needs, not all of them.

**own-**

- [`own-mutex-interior`](rules/own-mutex-interior.md) — Use `Mutex<T>` for interior mutability across threads
- [`own-refcell-interior`](rules/own-refcell-interior.md) — Use `RefCell<T>` for interior mutability in single-threaded code
- [`own-rwlock-readers`](rules/own-rwlock-readers.md) — Use `RwLock<T>` when reads significantly outnumber writes

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Smart pointer choice | rs-resource |
| Thread safety | rs-concurrency |
| Data structure design | rs-domain-model |
| Anti-patterns | rs-anti-pattern |
