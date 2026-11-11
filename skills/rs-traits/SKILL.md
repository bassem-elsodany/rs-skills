---
name: rs-traits
description: "CRITICAL: Use for generics, traits, zero-cost abstraction. Triggers: E0277, E0308, E0599, generic, trait, impl, dyn, where, monomorphization, static dispatch, dynamic dispatch, impl Trait, trait bound not satisfied"
user-invocable: false
---

# Zero-Cost Abstraction

> **Layer 1: Language Mechanics**

## Core Question

**Do we need compile-time or runtime polymorphism?**

Before choosing between generics and trait objects:
- Is the type known at compile time?
- Is a heterogeneous collection needed?
- What's the performance priority?

---

## Error → Design Question

| Error | Don't Just Say | Ask Instead |
|-------|----------------|-------------|
| E0277 | "Add trait bound" | Is this abstraction at the right level? |
| E0308 | "Fix the type" | Should types be unified or distinct? |
| E0599 | "Import the trait" | Is the trait the right abstraction? |
| E0038 | "Make object-safe" | Do we really need dynamic dispatch? |

---

## Thinking Prompt

Before adding trait bounds:

1. **What abstraction is needed?**
   - Same behavior, different types → trait
   - Different behavior, same type → enum
   - No abstraction needed → concrete type

2. **When is type known?**
   - Compile time → generics (static dispatch)
   - Runtime → trait objects (dynamic dispatch)

3. **What's the trade-off priority?**
   - Performance → generics
   - Compile time → trait objects
   - Flexibility → depends

---

## Trace Up ↑

When type system fights back:

```
E0277 (trait bound not satisfied)
    ↑ Ask: Is the abstraction level correct?
    ↑ Check: rs-domain-model (what behavior is being abstracted?)
    ↑ Check: rs-type-driven (should use newtype?)
```

| Persistent Error | Trace To | Question |
|-----------------|----------|----------|
| Complex trait bounds | rs-domain-model | Is the abstraction right? |
| Object safety issues | rs-type-driven | Can typestate help? |
| Type explosion | rs-performance | Accept dyn overhead? |

---

## Trace Down ↓

From design to implementation:

```
"Need to abstract over types with same behavior"
    ↓ Types known at compile time → impl Trait or generics
    ↓ Types determined at runtime → dyn Trait

"Need collection of different types"
    ↓ Closed set → enum
    ↓ Open set → Vec<Box<dyn Trait>>

"Need to return different types"
    ↓ Same type → impl Trait
    ↓ Different types → Box<dyn Trait>
```

---

## Quick Reference

| Pattern | Dispatch | Code Size | Runtime Cost |
|---------|----------|-----------|--------------|
| `fn foo<T: Trait>()` | Static | +bloat | Zero |
| `fn foo(x: &dyn Trait)` | Dynamic | Minimal | vtable lookup |
| `impl Trait` return | Static | +bloat | Zero |
| `Box<dyn Trait>` | Dynamic | Minimal | Allocation + vtable |

## Syntax Comparison

```rust
// Static dispatch - type known at compile time
fn process(x: impl Display) { }      // argument position
fn process<T: Display>(x: T) { }     // explicit generic
fn get() -> impl Display { }         // return position

// Dynamic dispatch - type determined at runtime
fn process(x: &dyn Display) { }      // reference
fn process(x: Box<dyn Display>) { }  // owned
```

## Error Code Reference

| Error | Cause | Quick Fix |
|-------|-------|-----------|
| E0277 | Type doesn't impl trait | Add impl or change bound |
| E0308 | Type mismatch | Check generic params |
| E0599 | No method found | Import trait with `use` |
| E0038 | Trait not object-safe | Use generics or redesign |

---

## Decision Guide

| Scenario | Choose | Why |
|----------|--------|-----|
| Performance critical | Generics | Zero runtime cost |
| Heterogeneous collection | `dyn Trait` | Different types at runtime |
| Plugin architecture | `dyn Trait` | Unknown types at compile |
| Reduce compile time | `dyn Trait` | Less monomorphization |
| Small, known type set | `enum` | No indirection |

---

## Object Safety

A trait is object-safe if it:
- Doesn't have `Self: Sized` bound
- Doesn't return `Self`
- Doesn't have generic methods
- Uses `where Self: Sized` for non-object-safe methods

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Over-generic everything | Compile time, complexity | Concrete types when possible |
| `dyn` for known types | Unnecessary indirection | Generics |
| Complex trait hierarchies | Hard to understand | Simpler design |
| Ignore object safety | Limits flexibility | Plan for dyn if needed |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| Swap an algorithm behind a trait | Strategy | `../rs-patterns/design-patterns/behavioural/strategy.md` |
| Many algorithms over one heterogeneous tree | Visitor | `../rs-patterns/design-patterns/behavioural/visitor.md` |
| Actions as values (undo, queues) | Command | `../rs-patterns/design-patterns/behavioural/command.md` |
| A tiny language for a repetitive problem | Interpreter | `../rs-patterns/design-patterns/behavioural/interpreter.md` |
| Rebuild a tree node by node | Fold | `../rs-patterns/design-patterns/creational/fold.md` |
| Behaviour differs per type, not per value | Generics as type classes | `../rs-patterns/functional/generics-type-classes.md` |
| `where` clause with `Fn` + output bounds is unreadable | Custom trait for bounds | `../rs-patterns/design-patterns/structural/trait-for-bounds.md` |
| `dyn` without allocation for a few variants | On-stack dynamic dispatch | `../rs-patterns/idioms/on-stack-dyn-dispatch.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (13)

Depth rules under `rules/` — open the one the question needs, not all of them.

**closure-**

- [`closure-fn-trait-bounds`](rules/closure-fn-trait-bounds.md) — Require the least restrictive `Fn` trait a callback needs (`FnOnce` ⊇ `FnMut` ⊇ `Fn`)
- [`closure-impl-fn-return`](rules/closure-impl-fn-return.md) — Return closures as `impl Fn`/`FnMut`/`FnOnce`, not `Box<dyn Fn>`
- [`closure-static-vs-dyn`](rules/closure-static-vs-dyn.md) — Accept `impl Fn` (generic) for hot callbacks; use `&dyn Fn`/`Box<dyn Fn>` to cut code size or to store them

**const-**

- [`const-block`](rules/const-block.md) — Use inline `const { }` blocks for compile-time evaluation and assertions
- [`const-fn`](rules/const-fn.md) — Make functions `const fn` when they can run at compile time
- [`const-generics`](rules/const-generics.md) — Parameterize over values with const generics `<const N: usize>`
- [`const-vs-static`](rules/const-vs-static.md) — Use `const` for an inlined value and `static` for a single addressed instance

**trait-**

- [`trait-associated-type-vs-generic`](rules/trait-associated-type-vs-generic.md) — Use an associated type when each impl has exactly one output type; use a generic parameter when a type can implement the trait for many input types
- [`trait-blanket-impl`](rules/trait-blanket-impl.md) — Use a blanket impl `impl<T: Bound> Trait for T` to give behaviour to every type that satisfies a bound
- [`trait-coherence-newtype`](rules/trait-coherence-newtype.md) — Respect the orphan rule; wrap a foreign type in a newtype to implement a foreign trait on it
- [`trait-default-methods`](rules/trait-default-methods.md) — Define a trait in terms of a few required methods plus defaulted ones built on top of them
- [`trait-dyn-vs-generic`](rules/trait-dyn-vs-generic.md) — Choose static dispatch (generics / `impl Trait`) vs dynamic dispatch (`dyn Trait`) deliberately
- [`trait-object-safety`](rules/trait-object-safety.md) — Keep a trait dyn-compatible (object-safe) when you need `dyn Trait`

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Type-driven design | rs-type-driven |
| Domain abstraction | rs-domain-model |
| Performance concerns | rs-performance |
| Send/Sync bounds | rs-concurrency |
