# macro-prefer-generics

> Reach for a function, generic or `const` before a macro
> **rs-macros-const · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Macros hide control flow, give poor errors and defeat tooling. Generics and `const fn` are checked by the compiler with real spans and show up in IDE navigation.

## Bad

```rust
macro_rules! max_of { ($a:expr, $b:expr) => { if $a > $b { $a } else { $b } }; }   // evaluates args twice, no types
```

## Good

```rust
fn max_of<T: PartialOrd>(a: T, b: T) -> T { if a > b { a } else { b } }            // or std::cmp::max
```

A macro is justified for: variadic arguments, repeating an impl over many types, a small DSL, or something that must see tokens (`stringify!`, `file!`, `concat!`). Delegate the body to a generic helper.

## See Also

- [macro-hygienic-paths](macro-hygienic-paths.md)
