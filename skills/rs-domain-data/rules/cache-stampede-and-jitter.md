# cache-stampede-and-jitter

> Single-flight on miss, jitter on TTL, bound the size
> **rs-domain-data · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A hot key expiring makes every request hit the source at once; keys created together expire together. Both turn a cache into an outage trigger.

## Do

- One load per key per instance: `moka::future::Cache::get_with` or the single-flight pattern in `guides/caching.md`.
- `ttl = base + random(0..base/5)`.
- Bound entries (`max_capacity`), value size and negative-cache TTL.
- A cache failure is a miss (circuit-break the cache), never a request failure — unless the cache is the store.
- Never cache an authorization decision without the policy version in the key (rs-domain-policy).

## See Also

- [data-timeouts-everywhere](data-timeouts-everywhere.md)
