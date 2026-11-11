# data-short-transactions

> Keep transactions short, on one store, with no foreign I/O inside
> **rs-domain-data · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Open transactions hold locks and pool connections. An HTTP call or `sleep` inside one makes the slowest dependency the lock-holder for everyone.

## Do / Don't

- Compute and fetch first, then `begin` → writes → `commit`.
- Retry the **whole** transaction on serialization failure / deadlock (`40001`/`40P01`), with backoff and a cap.
- Lock rows in a consistent order; prefer `SELECT … FOR UPDATE SKIP LOCKED` for queue-like tables.
- Cross-store consistency: outbox (rs-ports-adapters `port-uow-transactions`, rs-domain-distributed), not a transaction spanning DB + broker.

## Bad

```rust
let mut tx = pool.begin().await?;
let rate = http.get(fx_url).await?;             // network call while holding locks
sqlx::query("UPDATE …").execute(&mut *tx).await?;
```

## See Also

- [data-timeouts-everywhere](data-timeouts-everywhere.md)
