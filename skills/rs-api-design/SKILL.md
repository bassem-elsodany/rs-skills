---
name: rs-api-design
description: "Use when designing or reviewing a public Rust API — a library crate, a shared module, anything another team or crate will call. Triggers: API design, public API, library design, ergonomics, breaking change, semver, non_exhaustive, sealed trait, must_use, From vs Into, AsRef, Borrow, FromStr, TryFrom, FromIterator, extension trait, Default impl, common traits, operator overloading, parse don't validate, type state API, rustdoc, doc comments, missing_docs, intra-doc links, # Errors section, # Panics section, # Safety section, doc examples, README docs, crate documentation"
user-invocable: false
---

# Public API Design

> **Layer 2: Design Choices** · how a crate feels to its users — and whether it can change later

## Core Question

**Will this public API still be right in two years — and does it feel like `std`?**

An API has three audiences: callers today (ergonomics), callers tomorrow
(compatibility), and readers (documentation). Each decision below serves one of
them; the rules under `rules/` give the Bad/Good pairs.

---

## Thinking Prompt

1. **Who calls this and how often?** Hot path → accept `impl AsRef<str>` / `&[T]`; one-off config → `impl Into<String>` is fine.
2. **What can change?** Every `pub` field, exhaustive enum and `impl` is a promise. Hide what you may change (`#[non_exhaustive]`, private fields, sealed traits).
3. **Does it compose with std?** Implement the common traits; conversions through `From`/`TryFrom`/`FromStr`; collections through `FromIterator`/`Extend`/`IntoIterator`.
4. **Can misuse compile?** Prefer "parse, don't validate" and type-state so wrong usage is a type error, not a runtime one.
5. **Is it documented like std?** Every public item: one-line summary, example, `# Errors` / `# Panics` / `# Safety` where applicable.

---

## API checklist

| Concern | Do | Rule |
|---|---|---|
| Types users hold | derive/impl `Debug, Clone, PartialEq, Eq, Hash, Default` where meaningful; `Display` for user-facing values | `api-common-traits`, `api-default-impl` |
| Conversions | implement `From<T>` (never `Into`); fallible → `TryFrom`; text → `FromStr`; borrowed views → `AsRef`/`AsMut` | `api-from-not-into`, `conv-tryfrom-fallible`, `conv-fromstr-parsing`, `api-impl-asref`, `conv-asmut-mutable` |
| Flexible inputs | `impl Into<String>` for owned, `impl AsRef<Path>` for borrowed | `api-impl-into` |
| Collections | `FromIterator`, `Extend`, `IntoIterator` for `&T` and `T` | `api-impl-fromiterator` |
| Construction | builder for ≥3 optional fields; `#[must_use]` on builders and pure fns | `api-builder-pattern`, `api-builder-must-use`, `api-must-use` |
| Future-proofing | `#[non_exhaustive]` on public enums/structs that will grow; private fields + accessors | `api-non-exhaustive`, rs-patterns `idioms/priv-extend.md` |
| Closed trait sets | sealed trait pattern | `api-sealed-trait` |
| Invariants in types | newtype, parse-don't-validate, type state | `api-newtype-safety`, `api-parse-dont-validate`, `api-typestate` |
| Adding methods to foreign types | extension trait | `api-extension-trait` |
| Operators | overload only when the maths is obvious (`Add` for money, not for config merging) | `api-operator-overload` |
| serde on public types | optional derives behind a `serde` feature | `api-serde-optional` |

## Documentation checklist

| Item | Rule |
|---|---|
| every public item documented; `#![warn(missing_docs)]` | `doc-all-public` |
| crate-level `//!` docs with a quick-start; README = crate docs | `doc-module-inner`, `doc-crate-readme`, `doc-cargo-metadata` |
| runnable examples; hide setup with `#` lines; use `?` with a hidden `Ok` wrapper | `doc-examples-section`, `doc-hidden-setup`, `doc-question-mark` |
| `# Errors`, `# Panics`, `# Safety` sections where they apply | `doc-errors-section`, `doc-panics-section`, `doc-safety-section` |
| intra-doc links (`[`Foo`]`, `[`Foo::bar`]`) and typed links | `doc-intra-links`, `doc-link-types` |

---

## Compatibility rules of thumb

| Change | Breaking? | Make it non-breaking by |
|---|---|---|
| add enum variant | yes | `#[non_exhaustive]` |
| add struct field | yes if constructible by literal | private fields / `#[non_exhaustive]` + constructor |
| add trait method | yes for implementors | default method body, or sealed trait |
| widen a parameter type (`&String` → `&str`, `T` → `impl Into<T>`) | usually no | — |
| change a return type | yes | new method, deprecate old |
| add a required dependency feature | yes | additive features only (rs-structure `proj-feature-additive`) |

---

## Trace Up ↑

| Situation | Trace to | Question |
|---|---|---|
| What the API models | rs-domain-model | Which domain concepts are the nouns? |
| Who the users are | rs-domain-* | What does the domain consider a safe default? |
| Release impact | rs-release | Is this a major or minor bump? |

## Trace Down ↓

```
newtype / type state / builder   ↓ rs-type-driven, rs-patterns
trait design, dyn vs generic     ↓ rs-traits
error types in the API           ↓ rs-error-handling
where the API lives (lib.rs, pub use) ↓ rs-structure
```

## Anti-Patterns

| Anti-pattern | Why bad | Better |
|---|---|---|
| `pub` fields on a type that has invariants | callers break them | private + constructor/accessors |
| `impl Into<Foo> for Bar` | can't be used in generic `From` contexts | `impl From<Bar> for Foo` |
| `fn new(a, b, c, d, e, f)` | unreadable, unextendable | builder |
| returning `Box<dyn Error>` from a library | callers can't match | typed error enum (thiserror) |
| stringly-typed parameters | wrong strings compile | newtype / enum / parse |
| undocumented `unwrap`/panic paths | surprise crashes | `# Panics` section or return `Result` |

<!-- rules-index:start -->
## Rules (34)

Depth rules under `rules/` — open the one the question needs, not all of them.

**api-**

- [`api-builder-must-use`](rules/api-builder-must-use.md) — Mark builder methods with `#[must_use]` to prevent silent drops
- [`api-builder-pattern`](rules/api-builder-pattern.md) — Use Builder pattern for complex construction
- [`api-common-traits`](rules/api-common-traits.md) — Implement standard traits (Debug, Clone, PartialEq, etc.) for public types
- [`api-config-is-contract`](rules/api-config-is-contract.md) — Every option a configuration schema offers is a requirement — implement it; never narrow the schema to match missing code
- [`api-default-impl`](rules/api-default-impl.md) — Implement `Default` for types with sensible default values
- [`api-extension-trait`](rules/api-extension-trait.md) — Use extension traits to add methods to external types
- [`api-from-not-into`](rules/api-from-not-into.md) — Implement `From<T>`, not `Into<U>` - From gives you Into for free
- [`api-impl-asref`](rules/api-impl-asref.md) — Use `AsRef<T>` when you only need to borrow the inner data
- [`api-impl-fromiterator`](rules/api-impl-fromiterator.md) — Implement `FromIterator` and `Extend` for collection types, and `IntoIterator` for all three reference forms
- [`api-impl-into`](rules/api-impl-into.md) — Accept `impl Into<T>` for flexible APIs, implement `From<T>` for conversions
- [`api-must-use`](rules/api-must-use.md) — Mark types and functions with `#[must_use]` when ignoring results is likely a bug
- [`api-newtype-safety`](rules/api-newtype-safety.md) — Use newtypes to prevent mixing semantically different values
- [`api-non-exhaustive`](rules/api-non-exhaustive.md) — Use `#[non_exhaustive]` on public enums and structs for forward compatibility
- [`api-operator-overload`](rules/api-operator-overload.md) — Overload operators only when the semantics are natural and unsurprising
- [`api-parse-dont-validate`](rules/api-parse-dont-validate.md) — Parse into validated types at boundaries
- [`api-pit-of-success`](rules/api-pit-of-success.md) — Make the secure use the shortest path: safe defaults, no sentinel values, types that force the right order
- [`api-sealed-trait`](rules/api-sealed-trait.md) — Use sealed traits to prevent external implementations while allowing use
- [`api-serde-optional`](rules/api-serde-optional.md) — Make serde a feature flag, not a hard dependency for library crates
- [`api-typestate`](rules/api-typestate.md) — Use typestate pattern to encode state machine invariants in the type system

**conv-**

- [`conv-asmut-mutable`](rules/conv-asmut-mutable.md) — Accept `impl AsMut<T>` for flexible mutable borrowed inputs instead of concrete mutable references
- [`conv-fromstr-parsing`](rules/conv-fromstr-parsing.md) — Implement `FromStr` to enable `str::parse` for string-to-type conversions
- [`conv-tryfrom-fallible`](rules/conv-tryfrom-fallible.md) — Implement `TryFrom` for fallible conversions instead of ad-hoc conversion functions

**doc-**

- [`doc-all-public`](rules/doc-all-public.md) — Document all public items with `///` doc comments
- [`doc-cargo-metadata`](rules/doc-cargo-metadata.md) — Fill `Cargo.toml` metadata for published crates
- [`doc-crate-readme`](rules/doc-crate-readme.md) — Unify the README and crate root docs with `#![doc = include_str!("../README.md")]`
- [`doc-errors-section`](rules/doc-errors-section.md) — Include `# Errors` section for fallible functions
- [`doc-examples-section`](rules/doc-examples-section.md) — Include `# Examples` with runnable code
- [`doc-hidden-setup`](rules/doc-hidden-setup.md) — Use `# ` prefix to hide example setup code
- [`doc-intra-links`](rules/doc-intra-links.md) — Use intra-doc links to reference types and items
- [`doc-link-types`](rules/doc-link-types.md) — Use intra-doc links to connect related types and functions
- [`doc-module-inner`](rules/doc-module-inner.md) — Use `//!` for module-level documentation
- [`doc-panics-section`](rules/doc-panics-section.md) — Include `# Panics` section for functions that can panic
- [`doc-question-mark`](rules/doc-question-mark.md) — Use `?` in examples, not `.unwrap()`
- [`doc-safety-section`](rules/doc-safety-section.md) — Include `# Safety` section for unsafe functions

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| The pattern behind the API | rs-patterns |
| Encoding invariants | rs-type-driven |
| Module layout and re-exports | rs-structure |
| Naming | rs-style |
| Versioning and release | rs-release |
| Version tags, changelog, release commits | rs-git |
| Misuse resistance: safe defaults, sentinel values, config cliffs (`guides/sharp-edges.md`) | this skill |
| Is the code doing what the spec/GCL says? | rs-review `guides/spec-compliance.md` |
