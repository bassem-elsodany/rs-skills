---
name: rs-patterns
description: "Use when choosing a design pattern, idiom or anti-pattern in Rust. Triggers: design pattern, idiom, idiomatic, anti-pattern, builder, newtype, RAII guard, strategy pattern, visitor, command pattern, interpreter, fold, type class, optics, lens, composition over inheritance, Deref polymorphism, mem::take, mem::replace, non_exhaustive, private fields, Default trait, constructor, borrowed types for arguments, pass to closure, on-stack dynamic dispatch, finalisation in destructors, small crates, custom trait for bounds, FFI object-based API, FFI wrappers, FFI errors, accepting strings, passing strings, clone to satisfy borrow checker, deny(warnings), design principles, SOLID, YAGNI, which pattern should I use, is there an idiom for"
user-invocable: false
---

# Design Patterns, Idioms and Anti-Patterns

> **Layer 2: Design Choices** · catalogue of the Rust Design Patterns book, 52 pages in sub-files

## Core Question

**Which proven Rust solution fits this recurring problem — and what does it trade away?**

Before reaching for a pattern:
- Does a language feature already make it unnecessary? (YAGNI — Rust's traits, enums, closures and `Drop` replace many classic patterns)
- Is this an idiom (community norm — follow unless you have a reason), a pattern (a trade-off — justify it) or an anti-pattern (stop)?
- Which layer-1 mechanic does it rest on? (see *Traces to* on every page)

---

## Thinking Prompt

1. **Name the recurring problem**, not the solution: "many optional fields", "release on every exit path", "fight with the borrow checker on one big struct".
2. **Look it up in the Decision Guide** below; open only that page.
3. **Read its Advantages / Disadvantages** and write the trade-off into the Design Contract of the file you are changing.
4. **Check the anti-patterns** — is the "obvious" fix one of them?

---

## Decision Guide — symptom → pattern

| You observe… | Reach for | Page |
|---|---|---|
| Many optional fields; constructors multiplying; no default args | **Builder** | `design-patterns/creational/builder.md` |
| A type needs an obvious empty value, or generic "constructible" | **Default** + **Constructor** | `idioms/default.md`, `idioms/ctor.md` |
| `&String` / `&Vec<T>` / `&Box<T>` in a signature | **Borrowed types for arguments** | `idioms/coercion-arguments.md` |
| Need to move a field out of `&mut self` / change an enum variant in place | **`mem::take` / `mem::replace`** | `idioms/mem-replace.md` |
| Something must happen on every exit path, including panic | **Finalisation in destructors** / **RAII guard** | `idioms/dtor-finally.md`, `design-patterns/behavioural/RAII.md` |
| A resource must be released exactly once; lock must be held while used | **RAII guard** | `design-patterns/behavioural/RAII.md` |
| Want "inheritance" to reuse methods | **Composition + traits**, *never* `Deref` | `anti-patterns/deref.md`, `principles/design-principles.md` |
| Wrapper type for safety, semantics, or to impl a foreign trait | **Newtype** | `design-patterns/behavioural/newtype.md` |
| Swap an algorithm; inject behaviour; dependency inversion | **Strategy** | `design-patterns/behavioural/strategy.md` |
| Undo/redo, queued operations, actions as data | **Command** | `design-patterns/behavioural/command.md` |
| Many algorithms over one heterogeneous tree (AST) | **Visitor**; to rebuild the tree, **Fold** | `design-patterns/behavioural/visitor.md`, `design-patterns/creational/fold.md` |
| A tiny language solves a repetitive problem | **Interpreter** | `design-patterns/behavioural/interpreter.md` |
| Behaviour differs per type; runtime branches on a tag | **Generics as type classes** | `functional/generics-type-classes.md` |
| `where` clause with `Fn` + output bounds is unreadable | **Custom trait for bounds** | `design-patterns/structural/trait-for-bounds.md` |
| One big struct blocks independent borrows | **Struct decomposition** | `design-patterns/structural/compose-structs.md` |
| Dispatch over 2–3 types without `Box` | **On-stack dynamic dispatch** | `idioms/on-stack-dyn-dispatch.md` |
| Move *some* variables into a closure | **Pass variables to closure** | `idioms/pass-var-to-closure.md` |
| Fallible function consumes its argument | **Return consumed arg on error** | `idioms/return-consumed-arg-on-error.md` |
| Build then only read a variable | **Temporary mutability** | `idioms/temporary-mutability.md` |
| Add fields/variants later without a breaking change | **`#[non_exhaustive]` + private fields** | `idioms/priv-extend.md` |
| `Option` in iterator pipelines | **Iterating over Option** | `idioms/option-iter.md` |
| Wrapper owns a collection; callers want slices | **Collections are smart pointers** | `idioms/deref.md` |
| Mixed literal/non-literal string building | **`format!`** | `idioms/concat-format.md` |
| Doc example needs long setup | **Easy doc initialisation** | `idioms/rustdoc-init.md` |
| Nested data access/update, serde-like APIs | **Functional optics** | `functional/optics.md` |
| Exposing a C API | **Object-based API** + **wrappers** + **integer errors** | `design-patterns/ffi/export.md`, `design-patterns/ffi/wrappers.md`, `idioms/ffi/errors.md` |
| Strings across FFI | **Accepting** / **Passing strings** | `idioms/ffi/accepting-strings.md`, `idioms/ffi/passing-strings.md` |
| `unsafe` spreading through a module | **Contain unsafety in small modules** | `design-patterns/structural/unsafe-mods.md` |
| How big should a crate be? | **Prefer small crates** | `design-patterns/structural/small-crates.md` |

## Stop — anti-patterns

| You are about to… | Why it bites | Page |
|---|---|---|
| `.clone()` to make E0382 / E0502 go away | hides the ownership design problem; cost compounds | `anti-patterns/borrow_clone.md` |
| `#![deny(warnings)]` in a library | a new rustc lint breaks every downstream build | `anti-patterns/deny-warnings.md` |
| `impl Deref` to inherit a field's methods | lies to readers, breaks trait coherence expectations | `anti-patterns/deref.md` |

---

## Catalogue

| Chapter | Pages | Index |
|---|---|---|
| Idioms (18) | borrowed args, `format!`, constructor, `Default`, collections as smart pointers, destructors, `mem::take`, on-stack dispatch, FFI ×3, `Option` iter, pass to closure, `#[non_exhaustive]`, rustdoc init, temporary mutability, return consumed arg | `idioms/README.md` |
| Behavioural (6) | Command, Interpreter, Newtype, RAII guards, Strategy, Visitor | `design-patterns/behavioural/README.md` |
| Creational (2) | Builder, Fold | `design-patterns/creational/README.md` |
| Structural (4) | struct decomposition, small crates, contain unsafety, custom traits for bounds | `design-patterns/structural/README.md` |
| FFI patterns (2) | object-based APIs, type consolidation into wrappers | `design-patterns/ffi/README.md` |
| Anti-patterns (3) | clone for borrowck, `deny(warnings)`, `Deref` polymorphism | `anti-patterns/README.md` |
| Functional (3) | paradigms, generics as type classes, optics | `functional/README.md` |
| Principles | introduction & YAGNI, design principles (SOLID…), refactoring, further resources | `principles/` |

Every page keeps the book's shape — Description → Example → Motivation → Advantages → Disadvantages → Discussion → See also — plus a header naming the `rs-*` skills it traces to.

---

## Trace Up ↑

```
"Which pattern?"  ↑ Ask: what domain constraint makes this problem recur?
                  ↑ rs-domain-model (is the pattern modelling a domain concept?)
                  ↑ rs-domain-* (does the domain forbid the trade-off, e.g. allocation in embedded?)
```

| Situation | Trace to | Question |
|---|---|---|
| Pattern models a business concept | rs-domain-model | Entity, value object or service? |
| Pattern adds allocation / indirection | rs-performance, rs-domain-embedded | Is the cost acceptable here? |
| Pattern shapes a public API | rs-ecosystem | Will downstream crates survive the next change? |
| Choosing between patterns | rs-mental-model | Which mental model is the team using? |

## Trace Down ↓

```
Builder / Newtype / non_exhaustive   ↓ rs-type-driven
Strategy / Visitor / Command / Fold  ↓ rs-traits (static vs dynamic dispatch)
RAII / destructors                   ↓ rs-lifecycle, rs-resource
mem::take / temporary mutability     ↓ rs-mutability
borrowed args / struct decomposition ↓ rs-ownership
FFI idioms and patterns              ↓ rs-unsafe
return consumed arg / Option iter    ↓ rs-error-handling
```

---

## Related Skills

| When | See |
|---|---|
| The pattern smells wrong | rs-anti-pattern |
| Implementing the trait machinery | rs-traits |
| Encoding the pattern in types | rs-type-driven |
| The pattern crosses an FFI boundary | rs-unsafe |
| Naming and style of the result | rs-style |
| Ports & adapters / repository / anti-corruption layer | rs-ports-adapters |

Provenance: `SOURCES.md` (Rust Design Patterns, MPL-2.0).
