# `macro_rules!` — declarative macros

> **rs-macros-const · guide** — examples compile (Rust 2024)

## Anatomy

```rust
macro_rules! name {
    ($arg:expr, $($rest:expr),* $(,)?) => { /* expansion */ };   // pattern => template
}
```
Fragment specifiers: `expr`, `ident`, `ty`, `pat`, `tt` (any token tree), `item`, `block`, `stmt`, `path`, `literal`, `meta`, `vis`. Repetition: `$( … ),*` (zero or more), `+` (one or more), `?` (optional); allow a trailing comma with `$(,)?`.

## Worked examples

```rust
/// Variadic constructor: strings!["a", "b"]
#[macro_export]
macro_rules! strings {
    ($($s:expr),* $(,)?) => { ::std::vec![$(::std::string::String::from($s)),*] };
}

/// Boilerplate for newtype ids — one place for derives, conversions, Display.
#[macro_export]
macro_rules! id_type {
    ($(#[$m:meta])* $name:ident($inner:ty)) => {
        $(#[$m])*
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
        pub struct $name($inner);
        impl $name {
            #[must_use] pub const fn new(v: $inner) -> Self { Self(v) }
            #[must_use] pub const fn get(self) -> $inner { self.0 }
        }
        impl ::core::fmt::Display for $name {
            fn fmt(&self, f: &mut ::core::fmt::Formatter<'_>) -> ::core::fmt::Result { ::core::write!(f, "{}", self.0) }
        }
    };
}
id_type!(/// Order identifier.
         OrderId(u64));
```

## Hygiene and paths

- Local variables in a macro body do not clash with the caller's (hygiene) — but **items and paths are not hygienic**: always write `::std::…`, `::core::…`, `$crate::…`.
- Export with `#[macro_export]`; call as `crate_name::macro!`. Prefer `pub(crate) use name;` for internal macros.
- A macro that needs a type from your crate: `$crate::Type`, never `Type`.

## Style

- One rule per input shape, most specific first; add an internal rule `(@inner …)` for recursion instead of a second macro.
- Tail-recursion limit is 128 by default; use repetition rather than recursion for lists.
- If the body gets long, expand to a call of a generic function — smaller binaries, readable errors, debuggable.
- Document the accepted grammar in the macro's rustdoc with a compile-checked example.
