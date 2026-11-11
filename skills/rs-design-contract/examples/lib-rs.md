# Example — crate root (`src/lib.rs`)

The crate summary paragraph stays first so rustdoc's front page reads well; the
contract follows after a blank `//!` line.

```rust
#![forbid(unsafe_code)]
#![warn(missing_docs)]

//! `ledgerd` — append-only ledger service with exactly-once posting.
//!
//! # Design Contract
//! **Role:** Crate root; wires `api`, `domain` and `store` and owns the runtime.
//! **Patterns:** Hexagonal ports (traits in `domain::ports`, rs-traits) · Newtype money (rs-domain-fintech)
//! **Layout:** api (transport) · domain (pure rules, ports) · store (adapters) · config
//! **Invariants:** `domain` has no I/O and no `tokio`; only `store` touches the database.
//! **Ownership:** `AppState` is `Arc`-shared and immutable after start-up (rs-concurrency).
//! **Errors:** `LedgerError` (thiserror) at the boundary; `anyhow` only in `main.rs`.
//! **Extend by:** new capability = port trait in `domain/ports.rs` + adapter file in `store/`; never call the DB from `api`.
//! **Avoid:** `Decimal` → `f64` conversions anywhere (rs-domain-fintech); `unwrap()` outside tests.
//! **Skills:** rs-domain-fintech, rs-traits, rs-concurrency, rs-error-handling · rs-skills v0.3

pub mod api;
pub mod domain;
pub mod store;
```
