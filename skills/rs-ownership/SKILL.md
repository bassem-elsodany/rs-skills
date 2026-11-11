---
name: rs-ownership
description: "CRITICAL: Use for ownership/borrow/lifetime issues. Triggers: E0382, E0597, E0506, E0507, E0515, E0716, E0106, value moved, borrowed value does not live long enough, cannot move out of, use of moved value, ownership, borrow, lifetime, 'a, 'static, move, clone, Copy"
user-invocable: false
---

# Ownership & Lifetimes

> **Layer 1: Language Mechanics**

## Core Question

**Who should own this data, and for how long?**

Before fixing ownership errors, understand the data's role:
- Is it shared or exclusive?
- Is it short-lived or long-lived?
- Is it transformed or just read?

---

## Error → Design Question

| Error | Don't Just Say | Ask Instead |
|-------|----------------|-------------|
| E0382 | "Clone it" | Who should own this data? |
| E0597 | "Extend lifetime" | Is the scope boundary correct? |
| E0506 | "End borrow first" | Should mutation happen elsewhere? |
| E0507 | "Clone before move" | Why are we moving from a reference? |
| E0515 | "Return owned" | Should caller own the data? |
| E0716 | "Bind to variable" | Why is this temporary? |
| E0106 | "Add 'a" | What is the actual lifetime relationship? |

---

## Thinking Prompt

Before fixing an ownership error, ask:

1. **What is this data's domain role?**
   - Entity (unique identity) → owned
   - Value Object (interchangeable) → clone/copy OK
   - Temporary (computation result) → maybe restructure

2. **Is the ownership design intentional?**
   - By design → work within constraints
   - Accidental → consider redesign

3. **Fix symptom or redesign?**
   - If Strike 3 (3rd attempt) → escalate to Layer 2

---

## Trace Up ↑

When errors persist, trace to design layer:

```
E0382 (moved value)
    ↑ Ask: What design choice led to this ownership pattern?
    ↑ Check: rs-domain-model (is this Entity or Value Object?)
    ↑ Check: rs-domain-* (what constraints apply?)
```

| Persistent Error | Trace To | Question |
|-----------------|----------|----------|
| E0382 repeated | rs-resource | Should use Arc/Rc for sharing? |
| E0597 repeated | rs-domain-model | Is scope boundary at right place? |
| E0506/E0507 | rs-mutability | Should use interior mutability? |

---

## Trace Down ↓

From design decisions to implementation:

```
"Data needs to be shared immutably"
    ↓ Use: Arc<T> (multi-thread) or Rc<T> (single-thread)

"Data needs exclusive ownership"
    ↓ Use: move semantics, take ownership

"Data is read-only view"
    ↓ Use: &T (immutable borrow)
```

---

## Quick Reference

| Pattern | Ownership | Cost | Use When |
|---------|-----------|------|----------|
| Move | Transfer | Zero | Caller doesn't need data |
| `&T` | Borrow | Zero | Read-only access |
| `&mut T` | Exclusive borrow | Zero | Need to modify |
| `clone()` | Duplicate | Alloc + copy | Actually need a copy |
| `Rc<T>` | Shared (single) | Ref count | Single-thread sharing |
| `Arc<T>` | Shared (multi) | Atomic ref count | Multi-thread sharing |
| `Cow<T>` | Clone-on-write | Alloc if mutated | Might modify |

## Error Code Reference

| Error | Cause | Quick Fix |
|-------|-------|-----------|
| E0382 | Value moved | Clone, reference, or redesign ownership |
| E0597 | Reference outlives owner | Extend owner scope or restructure |
| E0506 | Assign while borrowed | End borrow before mutation |
| E0507 | Move out of borrowed | Clone or use reference |
| E0515 | Return local reference | Return owned value |
| E0716 | Temporary dropped | Bind to variable |
| E0106 | Missing lifetime | Add `'a` annotation |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| `.clone()` everywhere | Hides design issues | Design ownership properly |
| Fight borrow checker | Increases complexity | Work with the compiler |
| `'static` for everything | Restricts flexibility | Use appropriate lifetimes |
| Leak with `Box::leak` | Memory leak | Proper lifetime design |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| `&String`, `&Vec<T>`, `&Box<T>` in a signature | Borrowed types for arguments | `../rs-patterns/idioms/coercion-arguments.md` |
| Closure needs only some variables moved | Pass variables to closure | `../rs-patterns/idioms/pass-var-to-closure.md` |
| Fallible function consumed its argument | Return consumed arg on error | `../rs-patterns/idioms/return-consumed-arg-on-error.md` |
| One large struct blocks independent borrows | Struct decomposition | `../rs-patterns/design-patterns/structural/compose-structs.md` |
| Tempted to `.clone()` away E0382 / E0502 | Anti-pattern: clone to satisfy the borrow checker | `../rs-patterns/anti-patterns/borrow_clone.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

## Advanced lifetimes

`for<'a>` / "not general enough", GATs, `T: 'static` and `tokio::spawn`, `dyn Trait + 'a`, variance (`&mut` invariance), self-referential data: `patterns/advanced-lifetimes.md`.

---

<!-- rules-index:start -->
## Rules (9)

Depth rules under `rules/` — open the one the question needs, not all of them.

**closure-**

- [`closure-disjoint-capture`](rules/closure-disjoint-capture.md) — Capture only what you use; lean on edition-2021 disjoint closure captures
- [`closure-move-capture`](rules/closure-move-capture.md) — Use `move` for closures that outlive the current scope; clone before `move` to keep the original

**own-**

- [`own-borrow-over-clone`](rules/own-borrow-over-clone.md) — Prefer `&T` borrowing over `.clone()`
- [`own-clone-explicit`](rules/own-clone-explicit.md) — Use explicit `Clone` for types where copying has meaningful cost
- [`own-copy-small`](rules/own-copy-small.md) — Implement `Copy` for small, simple types
- [`own-cow-conditional`](rules/own-cow-conditional.md) — Use `Cow<'a, T>` for conditional ownership
- [`own-lifetime-elision`](rules/own-lifetime-elision.md) — Rely on lifetime elision rules; add explicit lifetimes only when required
- [`own-move-large`](rules/own-move-large.md) — Move large types instead of copying; use `Box` if moves are expensive
- [`own-slice-over-vec`](rules/own-slice-over-vec.md) — Accept `&[T]` not `&Vec<T>`, `&str` not `&String`

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Need smart pointers | rs-resource |
| Need interior mutability | rs-mutability |
| Data is domain entity | rs-domain-model |
| Learning ownership concepts | rs-mental-model |
