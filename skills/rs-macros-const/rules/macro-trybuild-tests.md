# macro-trybuild-tests

> Test what a macro rejects, not only what it accepts
> **rs-macros-const · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A macro's error messages are part of its API. Without failing-case tests, a refactor silently turns a clear "field `x` must be pub" into "proc macro panicked".

## Do

```rust
// tests/ui.rs
#[test]
fn ui() {
    let t = trybuild::TestCases::new();
    t.pass("tests/ui/pass/*.rs");
    t.compile_fail("tests/ui/fail/*.rs");     // each has a .stderr snapshot; review diffs like code
}
```
- One failing case per validation the macro performs.
- Keep samples minimal; run `TRYBUILD=overwrite cargo test` deliberately when messages change, then read the diff.
- Pin the toolchain used for snapshots (rustc changes diagnostics) — `rust-toolchain.toml`.
- `trybuild` compiles test crates: set `CARGO_TARGET_DIR` for CI caches and clean `target/tests` (rs-cleanup).

## See Also

- [macro-prefer-generics](macro-prefer-generics.md)
