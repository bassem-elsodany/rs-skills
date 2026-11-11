# macro-hygienic-paths

> Use `$crate::` and `::std::` paths inside macro bodies
> **rs-macros-const · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Macro hygiene covers local variables, not items. A body that says `Vec::new()` breaks where the caller shadows `Vec`; one that says `MyType` breaks outside your crate.

## Bad

```rust
#[macro_export]
macro_rules! make { () => { Config::default() } }          // only works where Config is imported
```

## Good

```rust
#[macro_export]
macro_rules! make { () => { $crate::Config::default() } }
#[macro_export]
macro_rules! names { ($($s:expr),*) => { ::std::vec![$(::std::string::String::from($s)),*] } }
```
Proc macros: emit `::my_crate::Trait`, and test in a module that shadows common names.

## See Also

- [macro-trybuild-tests](macro-trybuild-tests.md)
