---
name: rs-type-driven
description: "CRITICAL: Use for type-driven design. Triggers: type state, PhantomData, newtype, marker trait, builder pattern, make invalid states unrepresentable, compile-time validation, sealed trait, ZST"
user-invocable: false
---

# Type-Driven Design

> **Layer 1: Language Mechanics**

## Core Question

**How can the type system prevent invalid states?**

Before reaching for runtime checks:
- Can the compiler catch this error?
- Can invalid states be unrepresentable?
- Can the type encode the invariant?

---

## Error → Design Question

| Pattern | Don't Just Say | Ask Instead |
|---------|----------------|-------------|
| Primitive obsession | "It's just a string" | What does this value represent? |
| Boolean flags | "Add an is_valid flag" | Can states be types? |
| Optional everywhere | "Check for None" | Is absence really possible? |
| Validation at runtime | "Return Err if invalid" | Can we validate at construction? |

---

## Thinking Prompt

Before adding runtime validation:

1. **Can the type encode the constraint?**
   - Numeric range → bounded types or newtypes
   - Valid states → type state pattern
   - Semantic meaning → newtype

2. **When is validation possible?**
   - At construction → validated newtype
   - At state transition → type state
   - Only at runtime → Result with clear error

3. **Who needs to know the invariant?**
   - Compiler → type-level encoding
   - API users → clear type signatures
   - Runtime only → documentation

---

## Trace Up ↑

When type design is unclear:

```
"Need to validate email format"
    ↑ Ask: Is this a domain value object?
    ↑ Check: rs-domain-model (Email as Value Object)
    ↑ Check: rs-domain-* (validation requirements)
```

| Situation | Trace To | Question |
|-----------|----------|----------|
| What types to create | rs-domain-model | What's the domain model? |
| State machine design | rs-domain-model | What are valid transitions? |
| Marker trait usage | rs-traits | Static or dynamic dispatch? |

---

## Trace Down ↓

From design to implementation:

```
"Need type-safe wrapper for primitives"
    ↓ Newtype: struct UserId(u64);

"Need compile-time state validation"
    ↓ Type State: Connection<Connected>

"Need to track phantom type parameters"
    ↓ PhantomData: PhantomData<T>

"Need capability markers"
    ↓ Marker Trait: trait Validated {}

"Need gradual construction"
    ↓ Builder: Builder::new().field(x).build()
```

---

## Quick Reference

| Pattern | Purpose | Example |
|---------|---------|---------|
| Newtype | Type safety | `struct UserId(u64);` |
| Type State | State machine | `Connection<Connected>` |
| PhantomData | Variance/lifetime | `PhantomData<&'a T>` |
| Marker Trait | Capability flag | `trait Validated {}` |
| Builder | Gradual construction | `Builder::new().name("x").build()` |
| Sealed Trait | Prevent external impl | `mod private { pub trait Sealed {} }` |

## Pattern Examples

### Newtype

```rust
struct Email(String);  // Not just any string

impl Email {
    pub fn new(s: &str) -> Result<Self, ValidationError> {
        // Validate once, trust forever
        validate_email(s)?;
        Ok(Self(s.to_string()))
    }
}
```

### Type State

```rust
struct Connection<State>(TcpStream, PhantomData<State>);

struct Disconnected;
struct Connected;
struct Authenticated;

impl Connection<Disconnected> {
    fn connect(self) -> Connection<Connected> { ... }
}

impl Connection<Connected> {
    fn authenticate(self) -> Connection<Authenticated> { ... }
}
```

---

## Decision Guide

| Need | Pattern |
|------|---------|
| Type safety for primitives | Newtype |
| Compile-time state validation | Type State |
| Lifetime/variance markers | PhantomData |
| Capability flags | Marker Trait |
| Gradual construction | Builder |
| Closed set of impls | Sealed Trait |
| Zero-sized type marker | ZST struct |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Boolean flags for states | Runtime errors | Type state |
| String for semantic types | No type safety | Newtype |
| Option for uninitialized | Unclear invariant | Builder |
| Public fields with invariants | Invariant violation | Private + validated new() |

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| Wrapper for safety, semantics or a foreign trait impl | Newtype | `../rs-patterns/design-patterns/behavioural/newtype.md` |
| Many optional fields, no default arguments | Builder | `../rs-patterns/design-patterns/creational/builder.md` |
| Add fields/variants later without breaking users | `#[non_exhaustive]` + private fields | `../rs-patterns/idioms/priv-extend.md` |
| Types need an obvious empty value | Constructor + `Default` | `../rs-patterns/idioms/ctor.md` |
| Behaviour differs per type | Generics as type classes | `../rs-patterns/functional/generics-type-classes.md` |
| Composable access to nested data | Functional optics | `../rs-patterns/functional/optics.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (18)

Depth rules under `rules/` — open the one the question needs, not all of them.

**num-**

- [`num-cast-try-from`](rules/num-cast-try-from.md) — Avoid `as` for narrowing casts; use `From` for widening and `TryFrom` for narrowing
- [`num-float-compare`](rules/num-float-compare.md) — Don't compare floats with `==`; use a tolerance, and `total_cmp` for ordering
- [`num-nonzero`](rules/num-nonzero.md) — Use `NonZero*` types to forbid zero and unlock the niche optimization
- [`num-overflow-explicit`](rules/num-overflow-explicit.md) — Handle integer overflow explicitly: `checked_`/`saturating_`/`wrapping_`/`overflowing_`
- [`num-saturating-clamp`](rules/num-saturating-clamp.md) — Bound values with `clamp` and saturating arithmetic

**type-**

- [`type-deref-coercion`](rules/type-deref-coercion.md) — Implement `Deref`/`DerefMut` only for smart-pointer and transparent wrapper types
- [`type-display-vs-debug`](rules/type-display-vs-debug.md) — Use `Display` for user-facing output and `Debug` for diagnostics; never swap them
- [`type-enum-states`](rules/type-enum-states.md) — Use enums for mutually exclusive states
- [`type-generic-bounds`](rules/type-generic-bounds.md) — Add trait bounds only where needed, prefer where clauses for readability
- [`type-never-diverge`](rules/type-never-diverge.md) — Use `!` (never type) for functions that never return
- [`type-newtype-ids`](rules/type-newtype-ids.md) — Wrap IDs in newtypes: `UserId(u64)`
- [`type-newtype-validated`](rules/type-newtype-validated.md) — Use newtypes to enforce validation at construction time
- [`type-no-stringly`](rules/type-no-stringly.md) — Avoid stringly-typed APIs; use enums, newtypes, or validated types
- [`type-numeric-fmt`](rules/type-numeric-fmt.md) — Implement `LowerHex`, `UpperHex`, `Octal`, and `Binary` for numeric newtypes
- [`type-option-nullable`](rules/type-option-nullable.md) — Use `Option<T>` for values that might not exist
- [`type-phantom-marker`](rules/type-phantom-marker.md) — Use `PhantomData` to express type relationships without runtime cost
- [`type-repr-transparent`](rules/type-repr-transparent.md) — Use `#[repr(transparent)]` for newtypes in FFI contexts
- [`type-result-fallible`](rules/type-result-fallible.md) — Use `Result<T, E>` for operations that can fail

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Domain modeling | rs-domain-model |
| Trait design | rs-traits |
| Error handling in constructors | rs-error-handling |
| Anti-patterns | rs-anti-pattern |
