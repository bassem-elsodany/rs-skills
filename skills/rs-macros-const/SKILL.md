---
name: rs-macros-const
description: "Use when writing or reviewing macros, derive/proc macros, build scripts or compile-time computation — macro_rules!, declarative vs procedural macros, derive macros, attribute macros, syn/quote, hygiene, trybuild tests, cargo expand, const fn, const generics, const evaluation, compile-time assertions, type-level programming, build.rs code generation. Triggers: macro, macro_rules, declarative macro, procedural macro, proc-macro, derive macro, attribute macro, syn, quote, proc_macro2, darling, hygiene, cargo expand, trybuild, build.rs, codegen, const fn, const generics, const eval, const assert, static_assertions, typenum, generic-array, compile-time, type-level, repetition $(...)*, token tree, macro expansion error"
user-invocable: false
---

# Macros and Compile-time Computation

> **Layer 1/2: Mechanics + Design** · code that writes code, and code that runs before the program does
>
> Depth: `guides/macro-rules.md` · `guides/proc-macros.md` · `guides/const-eval.md`

## Core Question

**Can plain code (a function, a generic, a trait, a `const`) do this? If not, which is the smallest tool that can?**

Macros are the last resort in the abstraction ladder: they hide control flow, produce poor error messages, defeat IDE navigation and slow compiles. Use the lowest rung that works.

## The ladder (stop at the first that fits)

| Rung | Use when | Notes |
|---|---|---|
| 1. function | behaviour only | |
| 2. generics + traits | behaviour over types | zero-cost, great errors (rs-traits) |
| 3. `const fn` / `const` items / const generics | values or sizes known at compile time | `guides/const-eval.md` |
| 4. `macro_rules!` | variadic arguments, repeating a pattern over items, tiny DSL, reducing boilerplate impls for many types | `guides/macro-rules.md` |
| 5. `#[derive]` proc-macro | trait impl derivable from a struct's shape | `guides/proc-macros.md` |
| 6. attribute / function-like proc macro | rewriting items, DSLs that must parse real syntax | high cost; own crate |
| 7. `build.rs` codegen | generating Rust from external schemas (protobuf, OpenAPI, GCL), embedding assets | keep it minimal (rs-structure `proj-build-rs-minimal`); generated code is exempt from Design Contracts — mark it `@generated` |

Before writing rung 5–7, **search for an existing derive/crate** (rs-reuse-first): `serde`, `thiserror`, `clap`, `strum`, `derive_more`, `bon`/`typed-builder`, `prost-build`/`tonic-build`, `utoipa`.

## Thinking Prompt

1. What does the call site look like, and what error does a user get when they misuse it?
2. Is the expansion hygienic — does it use absolute paths (`::std::…`, `$crate::…`) so it works in any scope?
3. How is it tested — expansion output, passing cases, **failing cases** (`trybuild`)?
4. Will a reader understand it without expanding it? (`cargo expand` is for debugging, not for reading.)
5. Does it belong in its own crate (proc-macros must), with a Design Contract stating the grammar it accepts?

## Rules of thumb

| Do | Don't |
|---|---|
| `$crate::path` and `::core::…` paths in macro bodies | rely on the caller's imports |
| keep a macro small and delegate to a generic function (`fn imp(...)`) — less code bloat, better errors | put logic in the macro body |
| emit `compile_error!` / `syn::Error::to_compile_error()` with a span on the offending token | `panic!` in a proc macro (opaque error) |
| document the grammar (examples) in the macro's docs and Design Contract | invent syntax that resembles but differs from Rust |
| test failing inputs with `trybuild` (`.stderr` snapshots) | only test the happy path |
| use `syn`/`quote`/`proc-macro2` (verify the current major — `syn` is at 3.x at the time of writing) and `darling` for attribute parsing | parse tokens by hand |
| use `const` assertions (`const { assert!(…) }`) to fail builds for invalid configuration | find out at runtime |

## Debugging

`cargo expand` (needs nightly or the `cargo-expand` tool), `RUSTFLAGS="-Zmacro-backtrace"` on nightly, `trace_macros!`, minimal reproductions in a scratch crate (rs-cleanup: delete it).

## Trace

| Direction | Go to |
|---|---|
| ↑ Up | rs-api-design (a derive is public API), rs-structure (proc-macro crates live in the workspace as `<name>-macros`) |
| ↓ Down | rs-traits (what the macro should have been), rs-type-driven (const generics, type state), rs-unsafe (macro-generated unsafe) |
| → Delivery | rs-testing (`trybuild`), rs-review (generated code exempt, hand-written macros reviewed) |

<!-- rules-index:start -->
## Rules (4)

Depth rules under `rules/` — open the one the question needs, not all of them.

**const-**

- [`const-assert-invalid-config`](rules/const-assert-invalid-config.md) — Turn invalid compile-time configuration into build errors

**macro-**

- [`macro-hygienic-paths`](rules/macro-hygienic-paths.md) — Use `$crate::` and `::std::` paths inside macro bodies
- [`macro-prefer-generics`](rules/macro-prefer-generics.md) — Reach for a function, generic or `const` before a macro
- [`macro-trybuild-tests`](rules/macro-trybuild-tests.md) — Test what a macro rejects, not only what it accepts

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| Traits and generics first | rs-traits |
| Type-level design (type state, newtypes) | rs-type-driven |
| `build.rs` conventions | rs-structure |
| Existing derives and crates | rs-reuse-first |
