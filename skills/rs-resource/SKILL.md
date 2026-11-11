---
name: rs-resource
description: "CRITICAL: Use for smart pointers and resource management. Triggers: Box, Rc, Arc, Weak, RefCell, Cell, smart pointer, heap allocation, reference counting, RAII, Drop, should I use Box or Rc, when to use Arc vs Rc"
user-invocable: false
---

# Resource Management

> **Layer 1: Language Mechanics**

## Core Question

**What ownership pattern does this resource need?**

Before choosing a smart pointer, understand:
- Is ownership single or shared?
- Is access single-threaded or multi-threaded?
- Are there potential cycles?

---

## Error → Design Question

| Error | Don't Just Say | Ask Instead |
|-------|----------------|-------------|
| "Need heap allocation" | "Use Box" | Why can't this be on stack? |
| Rc memory leak | "Use Weak" | Is the cycle necessary in design? |
| RefCell panic | "Use try_borrow" | Is runtime check the right approach? |
| Arc overhead complaint | "Accept it" | Is multi-thread access actually needed? |

---

## Thinking Prompt

Before choosing a smart pointer:

1. **What's the ownership model?**
   - Single owner → Box or owned value
   - Shared ownership → Rc/Arc
   - Weak reference → Weak

2. **What's the thread context?**
   - Single-thread → Rc, Cell, RefCell
   - Multi-thread → Arc, Mutex, RwLock

3. **Are there cycles?**
   - Yes → One direction must be Weak
   - No → Regular Rc/Arc is fine

---

## Trace Up ↑

When pointer choice is unclear, trace to design:

```
"Should I use Arc or Rc?"
    ↑ Ask: Is this data shared across threads?
    ↑ Check: rs-concurrency (thread model)
    ↑ Check: rs-domain-* (performance constraints)
```

| Situation | Trace To | Question |
|-----------|----------|----------|
| Rc vs Arc confusion | rs-concurrency | What's the concurrency model? |
| RefCell panics | rs-mutability | Is interior mutability right here? |
| Memory leaks | rs-lifecycle | Where should cleanup happen? |

---

## Trace Down ↓

From design to implementation:

```
"Need single-owner heap data"
    ↓ Use: Box<T>

"Need shared immutable data (single-thread)"
    ↓ Use: Rc<T>

"Need shared immutable data (multi-thread)"
    ↓ Use: Arc<T>

"Need to break reference cycle"
    ↓ Use: Weak<T>

"Need shared mutable data"
    ↓ Single-thread: Rc<RefCell<T>>
    ↓ Multi-thread: Arc<Mutex<T>> or Arc<RwLock<T>>
```

---

## Quick Reference

| Type | Ownership | Thread-Safe | Use When |
|------|-----------|-------------|----------|
| `Box<T>` | Single | Yes | Heap allocation, recursive types |
| `Rc<T>` | Shared | No | Single-thread shared ownership |
| `Arc<T>` | Shared | Yes | Multi-thread shared ownership |
| `Weak<T>` | Weak ref | Same as Rc/Arc | Break reference cycles |
| `Cell<T>` | Single | No | Interior mutability (Copy types) |
| `RefCell<T>` | Single | No | Interior mutability (runtime check) |

## Decision Flowchart

```
Need heap allocation?
├─ Yes → Single owner?
│        ├─ Yes → Box<T>
│        └─ No → Multi-thread?
│                ├─ Yes → Arc<T>
│                └─ No → Rc<T>
└─ No → Stack allocation (default)

Have reference cycles?
├─ Yes → Use Weak for one direction
└─ No → Regular Rc/Arc

Need interior mutability?
├─ Yes → Thread-safe needed?
│        ├─ Yes → Mutex<T> or RwLock<T>
│        └─ No → T: Copy? → Cell<T> : RefCell<T>
└─ No → Use &mut T
```

---

## Common Errors

| Problem | Cause | Fix |
|---------|-------|-----|
| Rc cycle leak | Mutual strong refs | Use Weak for one direction |
| RefCell panic | Borrow conflict at runtime | Use try_borrow or restructure |
| Arc overhead | Atomic ops in hot path | Consider Rc if single-threaded |
| Box unnecessary | Data fits on stack | Remove Box |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Arc everywhere | Unnecessary atomic overhead | Use Rc for single-thread |
| RefCell everywhere | Runtime panics | Design clear ownership |
| Box for small types | Unnecessary allocation | Stack allocation |
| Ignore Weak for cycles | Memory leaks | Design parent-child with Weak |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| Wrapper owns a collection, callers want `&[T]` | Collections are smart pointers | `../rs-patterns/idioms/deref.md` |
| Dispatch over 2–3 types without `Box` | On-stack dynamic dispatch | `../rs-patterns/idioms/on-stack-dyn-dispatch.md` |
| Resource must be released exactly once | RAII guards | `../rs-patterns/design-patterns/behavioural/RAII.md` |
| `Deref` to reuse a field's methods | Anti-pattern: Deref polymorphism | `../rs-patterns/anti-patterns/deref.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (2)

Depth rules under `rules/` — open the one the question needs, not all of them.

**own-**

- [`own-arc-shared`](rules/own-arc-shared.md) — Use `Arc<T>` for thread-safe shared ownership
- [`own-rc-single-thread`](rules/own-rc-single-thread.md) — Use `Rc<T>` for shared ownership in single-threaded contexts

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Ownership errors | rs-ownership |
| Interior mutability details | rs-mutability |
| Multi-thread context | rs-concurrency |
| Resource lifecycle | rs-lifecycle |
