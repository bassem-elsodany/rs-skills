# Relational databases from Rust

> **rs-domain-data · guide**

## Connection pool

```rust
// sqlx (names stable across 0.7–0.9; check the docs of the version you pin)
let pool = sqlx::postgres::PgPoolOptions::new()
    .max_connections(10)                              // per instance; instances × this ≤ DB limit − headroom
    .acquire_timeout(std::time::Duration::from_secs(3))   // fail fast instead of queueing forever
    .connect(&database_url).await?;
```
- Build the pool once in the composition root; pass `Clone` handles to adapters (rs-ports-adapters). Close it on shutdown after in-flight work drains (rs-async-patterns).
- Symptoms of a mis-sized pool: acquire timeouts under load (too small or slow queries), "too many connections" on the server (too large × instances).
- Set per-session defaults with an `after_connect` hook: `SET statement_timeout = '5s'`, `SET lock_timeout = '2s'`, `SET TIME ZONE 'UTC'`.

## Transactions

```rust
let mut tx = pool.begin().await?;
sqlx::query("UPDATE accounts SET balance = balance - $1 WHERE id = $2 AND balance >= $1")
    .bind(amount).bind(from).execute(&mut *tx).await?;
sqlx::query("UPDATE accounts SET balance = balance + $1 WHERE id = $2").bind(amount).bind(to).execute(&mut *tx).await?;
tx.commit().await?;                                   // dropped without commit = rollback
```
- Keep them short; no HTTP calls, no `sleep`, no user interaction inside.
- Isolation: default (Postgres `READ COMMITTED`) is enough for most; use `SERIALIZABLE` + retry loop when invariants span rows (and handle `40001`), or lock explicitly (`SELECT … FOR UPDATE`, consistent lock order to avoid deadlocks).
- Optimistic concurrency for user edits: `version` column, `UPDATE … WHERE id=$1 AND version=$2`, treat 0 rows as `Conflict`.
- Map errors at the adapter boundary: unique violation → `Conflict`, serialization/deadlock/connection reset → transient `Unavailable`, statement timeout → `Timeout` (rs-ports-adapters `port-map-errors`).

## Queries

| Do | Because |
|---|---|
| `EXPLAIN (ANALYZE, BUFFERS)` any query that runs on a large table, in review | the planner, not intuition, tells you about seq scans |
| index for the query: composite order = equality columns first, then range/sort; partial indexes for hot subsets | unused or wrong indexes only cost writes |
| select named columns, not `SELECT *` | schema changes and wide rows |
| batch: `WHERE id = ANY($1)` with a `&[i64]` bind; `UNNEST` for bulk inserts; `COPY` for very large loads | one round trip instead of N |
| keyset pagination | `OFFSET 100000` scans and discards 100000 rows |
| compile-time-checked queries (`query!`) for the adapter's SQL; commit `.sqlx/` (offline data) | schema drift becomes a build error |
| count queries sparingly (`COUNT(*)` is a scan on big tables) | use estimates or maintain counters |

## Migrations — expand / migrate / contract

| Step | Example: rename `users.name` → `full_name` | Release |
|---|---|---|
| 1 expand | add nullable `full_name`; write to both columns | deploy N |
| 2 migrate | backfill in batches; verify | job |
| 3 switch | read from `full_name`; stop writing `name` | deploy N+1 |
| 4 contract | drop `name` | deploy N+2 |

- Old and new code run together during a rolling deploy: every migration must be compatible with the **previous** release.
- Never edit an applied migration; add a new one. Embed with `sqlx::migrate!()` or run with `sqlx migrate run` / `refinery` / `diesel migration run` in a **separate release step** (a migration job, not "whoever starts first").
- Dangerous DDL: adding a column with a volatile default or `NOT NULL` without default on a big table, non-concurrent index creation, type changes (rewrite), long `ALTER` under load → use `lock_timeout`, `CREATE INDEX CONCURRENTLY` (not in a transaction), and batch backfills.
- Test migrations: apply on a copy of production-shaped data; test up from the previous schema in CI.

## Testing

- `#[sqlx::test]` creates an isolated database per test (needs a reachable server); or testcontainers (rs-testing, rs-cleanup — remove the container).
- Contract suite for the repository port runs against the real engine and the in-memory fake (rs-ports-adapters `port-contract-tests`).
- Assert query counts for N+1-prone paths (a counting wrapper around the pool, or `tracing` events from sqlx at `debug`).
