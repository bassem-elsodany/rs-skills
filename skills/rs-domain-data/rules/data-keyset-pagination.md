# data-keyset-pagination

> Page large result sets with a keyset (seek) cursor, not OFFSET
> **rs-domain-data · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

`OFFSET n` reads and discards `n` rows: page 10 000 is slow and unstable under concurrent inserts. A keyset cursor uses an index seek and stays consistent.

## Do

```sql
SELECT id, created_at, payload
FROM events
WHERE (created_at, id) < ($1, $2)       -- cursor from the previous page's last row
ORDER BY created_at DESC, id DESC
LIMIT $3;                               -- page size, capped server-side
```
Port type: `Page { after: Option<Cursor>, limit: u16 }`, result `{ items, next: Option<Cursor> }` with an opaque, versioned cursor (rs-ports-adapters `port-design-by-need`). Index must match the sort (`(created_at, id)`).

## See Also

- [data-short-transactions](data-short-transactions.md)
