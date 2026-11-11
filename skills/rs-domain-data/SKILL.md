---
name: rs-domain-data
description: "Use when working with databases, caches or analytics stores from Rust — choosing sqlx/diesel/sea-orm, connection pools, transactions, migrations, query performance, N+1, pagination, caching patterns (cache-aside, write-through, TTL, invalidation, stampede), Redis, ClickHouse, time-series and append-only event stores. Triggers: database, SQL, Postgres, MySQL, SQLite, sqlx, diesel, sea-orm, ORM, connection pool, deadpool, bb8, transaction, isolation level, deadlock, migration, schema change, expand contract, index, N+1, pagination, keyset, OFFSET, query performance, EXPLAIN, statement timeout, cache, caching, Redis, Valkey, moka, TTL, cache-aside, write-through, invalidation, stampede, thundering herd, ClickHouse, analytics, OLAP, batch insert, time series, event store, outbox"
user-invocable: false
---

# Data — databases, caches and analytics stores

> **Layer 3: Domain** · why a data-heavy service is designed the way it is
>
> Depth: `guides/database.md` · `guides/caching.md` · `guides/analytics-stores.md`. Always combine with **rs-ports-adapters** (every store sits behind a port) and **rs-reuse-first** (official driver, not hand-written wire protocol).

## Core Question

**What must be true about this data at rest and in motion — consistent, durable, fast, or cheap — and which store gives exactly that and no more?**

## Thinking Prompt

1. **System of record?** One store owns each fact. Caches, search indexes and analytics copies are *derived* and must be rebuildable.
2. **Consistency need:** read-your-writes? serialisable? "eventually, within N seconds"? Name it — it decides cache and replication design.
3. **Access pattern:** point lookups, range scans, aggregations over millions of rows, append-only events? Pick the store for the pattern (row store, cache, columnar).
4. **Failure behaviour:** what does the caller see when the store is slow, down, or returns a conflict? (timeouts, classified errors, retry budget — rs-domain-error)
5. **Change:** how will the schema evolve while the old and new versions run side by side? (expand/contract)
6. **Replaceability:** port + memory fake + contract tests (rs-ports-adapters) — the product may change, the contract won't.

## Choosing the access layer (relational)

| Need | Choice | Notes |
|---|---|---|
| async, plain SQL, compile-time-checked queries, migrations built in | **`sqlx`** (`query!`, `query_as!`, `migrate!`, `#[sqlx::test]`) | checked macros need `DATABASE_URL` or `cargo sqlx prepare` (offline data committed) |
| compile-time schema DSL, mature, sync (or `diesel-async`) | `diesel` (+ `diesel_migrations`) | strong type safety; steeper learning curve |
| ORM-style models and relations, async | `sea-orm` (+ `sea-orm-migration`) | generated entities; keep them in the adapter, not the domain |
| bare driver | `tokio-postgres`, `rusqlite` | when you need control; pool with `deadpool-postgres`/`bb8` |
| non-relational | `mongodb` (official), `redis`, `clickhouse` (official), `object_store` | registry: rs-reuse-first `registry/standards.md` |

Whatever you pick: **entities in the adapter, domain types in the domain** (rs-ports-adapters `port-row-types`).

## Rules that prevent most incidents

| Rule | Detail |
|---|---|
| **Timeouts everywhere** | pool acquire timeout, connect timeout, statement timeout (`statement_timeout`), overall request deadline; a missing timeout is an outage amplifier |
| **Pool sized deliberately** | `max_connections` across *all* instances ≤ the DB's limit (leave headroom); small pools + queueing beat huge pools; behind PgBouncer in transaction mode avoid session state and check prepared-statement support |
| **Transactions are short** and never span network calls or user think-time; no `.await` on unrelated I/O inside one; retry only the *whole* transaction on serialization failure (`40001`) / deadlock (`40P01`) with backoff |
| **No N+1** | load children with one batched query (`WHERE id = ANY($1)` in Postgres / `IN (…)`) or a join; dataloader for GraphQL; test with query-count assertions |
| **Keyset pagination** for large/unbounded lists (`WHERE (created_at, id) < ($1,$2) ORDER BY … LIMIT n`); `OFFSET` degrades linearly |
| **Parameterised queries only** | never `format!` values into SQL (injection); identifiers from an allow-list |
| **Idempotent writes** | `INSERT … ON CONFLICT DO NOTHING/UPDATE` with a natural or client-supplied key; the basis of safe retries (rs-domain-distributed) |
| **Money and time** | `NUMERIC`/`rust_decimal` (never float); `timestamptz` stored in UTC |
| **Migrations: expand → migrate → contract** | additive change first, backfill, switch code, drop later; never edit an applied migration; indexes with `CREATE INDEX CONCURRENTLY` (outside a transaction); set `lock_timeout` for DDL |
| **Test against the real engine** | `#[sqlx::test]` or testcontainers; remove containers afterwards (rs-cleanup) |

## Caching in one table (details `guides/caching.md`)

| Pattern | Use when | Watch |
|---|---|---|
| **cache-aside** (read: cache → miss → load → fill) | default for read-heavy data | stampede (single-flight), stale reads after writes |
| **write-through** | reads must see writes at once | write latency, partial failure ordering |
| **write-behind** | very write-heavy, loss tolerable | data loss on crash — rarely acceptable |
| **TTL + jitter** | bounded staleness | synchronized expiry → herd; add random jitter |
| **explicit invalidation** (events, versioned keys) | strict freshness | missed invalidation = stale forever → TTL as a safety net |
| **negative caching** | many lookups for non-existent keys | short TTL |
| **in-process (`moka`)** vs **shared (Redis)** | per-instance hot set vs cross-instance | in-process invalidation across instances needs events; Redis adds a network hop and a failure mode |

**Never cache authorization decisions without a version/epoch in the key** (rs-domain-policy) and never use a cache as the source of truth unless it is configured and operated as a database.

## Trace

| Direction | Go to |
|---|---|
| ↑ Up | rs-domain-fintech (money, ledgers), rs-domain-cloud-native (connections per pod, secrets), rs-domain-distributed (idempotency, outbox, consistency) |
| ↓ Down | rs-ports-adapters (port/adapter, contract tests), rs-error-handling + rs-domain-error (classification, retry), rs-concurrency (never hold a lock across `.await`), rs-lifecycle (pools, shutdown) |
| → Delivery | rs-testing (real DB in tests), rs-observability (query latency, pool wait metrics), rs-performance (profiling queries before Rust), rs-cleanup (containers/volumes) |

<!-- rules-index:start -->
## Rules (5)

Depth rules under `rules/` — open the one the question needs, not all of them.

**cache-**

- [`cache-stampede-and-jitter`](rules/cache-stampede-and-jitter.md) — Single-flight on miss, jitter on TTL, bound the size

**data-**

- [`data-keyset-pagination`](rules/data-keyset-pagination.md) — Page large result sets with a keyset (seek) cursor, not OFFSET
- [`data-migrations-expand-contract`](rules/data-migrations-expand-contract.md) — Change schemas in compatible steps so old and new code can run together
- [`data-short-transactions`](rules/data-short-transactions.md) — Keep transactions short, on one store, with no foreign I/O inside
- [`data-timeouts-everywhere`](rules/data-timeouts-everywhere.md) — Every store call has a deadline: connect, pool acquire, statement, and overall request

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| Making the store replaceable | rs-ports-adapters |
| Picking the driver | rs-reuse-first |
| Money and decimals | rs-domain-fintech |
| Retry and recovery | rs-domain-error |
