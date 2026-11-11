# Example — ordinary module (`src/store/postgres.rs`)

```rust
//! # Design Contract
//! **Role:** Postgres adapter implementing `domain::ports::LedgerStore`.
//! **Patterns:** Adapter over a port trait (rs-traits) · RAII transaction guard (rs-patterns/design-patterns/behavioural/RAII.md)
//! **Invariants:** every write happens inside `Tx`; `Tx` rolls back on drop unless `commit()` ran.
//! **Ownership:** `PgStore` owns the pool; `Tx<'_>` borrows a connection for its lifetime.
//! **Errors:** maps `sqlx::Error` → `StoreError` at this boundary only; no `sqlx` types escape.
//! **Concurrency:** `PgStore: Send + Sync`; one `Tx` per task; never hold `Tx` across `await` on user code.
//! **Extend by:** add a method to the `LedgerStore` trait first, then implement it here.
//! **Avoid:** raw SQL string formatting (use bound parameters); `clone()` of row data to escape borrows.
//! **Skills:** rs-traits, rs-patterns, rs-lifecycle, rs-concurrency, rs-error-handling · rs-skills v0.3

use crate::domain::ports::LedgerStore;
```

A `none` example for plain data:

```rust
//! # Design Contract
//! **Role:** Wire-format DTOs for the `/v1/postings` endpoint.
//! **Patterns:** none (plain data) · serde derives (rs-ecosystem)
//! **Invariants:** DTOs never carry domain types; conversion lives in `api::convert`.
//! **Extend by:** add an `Option<T>` field with `#[serde(default)]`; never rename a field without a new version.
//! **Skills:** rs-ecosystem, rs-domain-web · rs-skills v0.3
```
