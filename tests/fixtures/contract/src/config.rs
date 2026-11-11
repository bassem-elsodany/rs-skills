//! # Design Contract
//! **Role:** Parses CLI configuration and validates it before anything else runs.
//! **Patterns:** Builder (rs-patterns/design-patterns/creational/builder.md) · Newtype ids (rs-type-driven)
//! **Invariants:** `Config` is immutable after `build()`; every path is absolute.
//! **Ownership:** `Config` owns its strings; callers receive `&str`.
//! **Errors:** `ConfigError` via thiserror; never panics on user input.
//! **Extend by:** add a field to `ConfigBuilder` with a default; do NOT add boolean flags.
//! **Avoid:** `Deref` for inheritance (rs-anti-pattern).
//! **Skills:** rs-patterns, rs-type-driven, rs-error-handling · rs-skills v0.3

pub struct Config { pub name: String }
