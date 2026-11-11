# data-timeouts-everywhere

> Every store call has a deadline: connect, pool acquire, statement, and overall request
> **rs-domain-data · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A slow database without timeouts turns into piled-up tasks, exhausted pools and a cascading outage. A timeout converts "slow" into a handled error.

## Do

```rust
let pool = PgPoolOptions::new()
    .max_connections(10)
    .acquire_timeout(Duration::from_secs(3))
    .after_connect(|conn, _| Box::pin(async move {
        sqlx::query("SET statement_timeout = '5s'").execute(&mut *conn).await?;
        Ok(())
    }))
    .connect(&url).await?;
// plus an overall deadline per request: tokio::time::timeout(deadline, work)
```
Map the timeout to `StoreErrorKind::Timeout` (transient) in the adapter; the caller's retry budget decides what happens next (rs-domain-error).

## See Also

- [data-short-transactions](data-short-transactions.md)
