# const-assert-invalid-config

> Turn invalid compile-time configuration into build errors
> **rs-macros-const · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A capacity that must be a power of two, a buffer that must fit a page, constants that must be ordered — discovering that at runtime means a crash in production; at compile time it is a red build.

## Do

```rust
const _: () = assert!(MIN_TIMEOUT_MS < MAX_TIMEOUT_MS);
const _: () = assert!(size_of::<Header>() == 16, "Header layout changed — wire format break");

impl<const N: usize> Ring<N> {
    const OK: () = assert!(N.is_power_of_two(), "capacity must be a power of two");
    pub fn new() -> Self { let () = Self::OK; /* … */ todo!() }   // referencing the const forces evaluation
}
```
Keep a runtime `Result`-returning constructor for values that arrive from config (parse, don't validate).

## See Also

- [rs-type-driven](../../rs-type-driven/SKILL.md)
