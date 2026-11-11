# Analytics, time-series and event stores (ClickHouse-class)

> **rs-domain-data · guide** — columnar OLAP stores answer "aggregate millions of rows" fast and are bad at "update one row"

| Fact | Consequence for the Rust adapter |
|---|---|
| inserts are cheapest in **large batches** (thousands+ rows per insert) | buffer in the adapter, flush by size **or** time (`chunks_timeout`, rs-async-patterns `streams-and-backpressure`); many tiny inserts overwhelm the server (parts merges) — or use the server's async-insert feature deliberately |
| data is **append-only**; `UPDATE`/`DELETE` are heavy mutations | model corrections as new rows (versioned/tombstone) and read the latest; use engines with merge-time dedup/collapse (e.g. `ReplacingMergeTree`) knowing dedup is **eventual** — deduplicate at query time (`FINAL`/`argMax`) when exactness matters |
| the **sort/primary key** is the main performance decision | choose it from the common filters (tenant, time, entity); partition by month/day for TTL and drops, not for query speed |
| schema evolves by adding columns | additive changes only; keep readers tolerant of missing columns |
| consistency is **eventual / at-least-once** | make ingestion idempotent (event ids, dedup keys); the port documents "may see duplicates for N seconds" |
| TTL and retention are first-class | model retention in the table definition and the Design Contract |

## Pattern: audit/event log in an analytics store

```
service ──append(events)──▶ port AuditStore ──▶ adapter: buffer + batch insert ──▶ ClickHouse
                              └─▶ memory adapter (tests)          └─▶ other engine (swap drill)
reads:  daily_counts(range), events_for(actor, range)  — intent-shaped queries, adapter owns the SQL
```
- Ingestion path: bounded channel → batcher task (flush on size/interval/shutdown) → insert with retry (classified transient errors) → on permanent failure, dead-letter to a file/queue; **flush on graceful shutdown** (rs-async-patterns).
- Idempotency: include a unique event id; the same batch may be retried.
- Backpressure: if the store is slow, the bounded channel makes producers wait — decide whether audit loss is allowed (usually not: fail closed or spill to disk).
- Verify with the official driver (`clickhouse` crate, rs-reuse-first) and a contract suite (`audit_store_contract` in `skills/rs-ports-adapters/templates/ports-adapters`).

## Other engines behind the same port

`DuckDB`/Parquet files (embedded analytics, tests), `datafusion` + object storage (lakehouse), Druid/Pinot (real-time OLAP), Postgres + partitioning/TimescaleDB (moderate volume, simpler ops). The port should not mention any of them.
