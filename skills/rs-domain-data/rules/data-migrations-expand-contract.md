# data-migrations-expand-contract

> Change schemas in compatible steps so old and new code can run together
> **rs-domain-data · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Rolling deploys run two versions at once. A migration that renames or drops a column breaks the version still running.

## Do

1. **Expand:** add the new column/table (nullable, no heavy default); code writes both.
2. **Migrate:** backfill in batches; verify counts.
3. **Switch:** code reads the new shape.
4. **Contract:** drop the old shape in a later release.

Run migrations as a separate release step; never edit an applied migration; `CREATE INDEX CONCURRENTLY`; set `lock_timeout`; test "previous schema → new migrations" in CI.

## Bad

```sql
ALTER TABLE users RENAME COLUMN name TO full_name;   -- instantly breaks every running instance
```

## See Also

- [data-timeouts-everywhere](data-timeouts-everywhere.md)
