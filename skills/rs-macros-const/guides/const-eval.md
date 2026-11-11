# `const fn`, const generics and compile-time checks

> **rs-macros-const · guide** — examples compile (Rust 1.85+)

## What runs at compile time

- `const` / `static` initialisers and `const fn` calls inside them; array lengths; const-generic arguments; `const { … }` blocks (inline const).
- `const fn` can do arithmetic, loops, `if`/`match`, call other `const fn`, use many `core` methods (`is_power_of_two`, `checked_*`, slice indexing); it cannot allocate or use trait methods on generics (check the current stable list on docs.rs/the Rust reference).

```rust
pub const fn kib(n: usize) -> usize { n * 1024 }
pub const BUF: usize = kib(64);
```

## Const generics — sizes in the type

```rust
/// Fixed-capacity ring of N items; N must be a power of two — enforced at BUILD time.
pub struct Ring<T: Copy + Default, const N: usize> { buf: [T; N], head: usize }

impl<T: Copy + Default, const N: usize> Ring<T, N> {
    const MASK: usize = {
        assert!(N.is_power_of_two(), "Ring capacity must be a power of two");   // compile error for Ring<_, 3>
        N - 1
    };
    pub fn new() -> Self { let _ = Self::MASK; Self { buf: [T::default(); N], head: 0 } }
    pub fn push(&mut self, v: T) { self.buf[self.head & Self::MASK] = v; self.head = self.head.wrapping_add(1); }
}
```
- The associated-const assert only fires if the const is *used* — reference it in `new()` (`let _ = Self::MASK;`).
- Stable const generics accept integers, `bool`, `char` (not arbitrary types or expressions like `{N + 1}` in types). For arithmetic on type-level numbers use `typenum`/`generic-array`, or restructure.
- Each distinct `N` is a separate monomorphisation: code size grows — don't const-generic everything.

## Compile-time validation patterns

| Need | Tool |
|---|---|
| invariant between constants | `const _: () = assert!(A < B);` |
| size/alignment of a type (FFI, layout) | `const _: () = assert!(size_of::<T>() == 16);` |
| trait bound holds for a type | `static_assertions::assert_impl_all!(T: Send, Sync)` (crate is unmaintained since 2019 but stable) or a generic fn call in a `const _` |
| validated literals (non-empty names, bounded numbers) | a `const fn new(..) -> Self` with `assert!` or `match … { _ => panic!(…) }`, used in `const` position → build error; runtime path returns `Result` (rs-type-driven "parse, don't validate") |
| lookup tables | `const TABLE: [u8; 256] = build_table();` computed by a `const fn` loop |
| embed files / generated data | `include_str!`, `include_bytes!`, `build.rs` |

## Limits to know

- const evaluation has a step limit (`long_running_const_eval` lint) — keep tables small or generate in `build.rs`.
- `const fn` in traits and many `core` APIs are still being stabilised: check the target MSRV (rs-release) before relying on a newer const feature.
- Floating point in `const fn` has restrictions on older compilers; check MSRV.
