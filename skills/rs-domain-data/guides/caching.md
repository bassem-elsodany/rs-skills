# Caching patterns

> **rs-domain-data · guide** — the single-flight example compiles (tokio 1)

Rule zero: measure first. A cache is a second copy of the truth with its own failure modes; add it for a measured bottleneck, behind a port (`Cache`/`SessionCache`, rs-ports-adapters) so Redis ↔ in-process ↔ none is a config change.

## Pattern chooser

| Pattern | Flow | Pros | Cons / failure mode |
|---|---|---|---|
| **cache-aside** | read: cache → miss → load source → fill | simple, source stays authoritative | stale after writes; stampede on popular misses |
| **read-through** | cache layer loads on miss | callers only see the cache | the cache needs loader code |
| **write-through** | write cache + source together | reads see writes | write latency; ordering/partial failure |
| **write-behind** | write cache, flush later | fast writes | loss on crash — avoid unless acceptable |
| **refresh-ahead / stale-while-revalidate** | serve stale, refresh in background | smooth latency | complexity; bounded staleness must be stated |

## Keys and values

- Key = `namespace:version:tenant:id[:variant]`. Include **tenant** (leaks otherwise) and a **schema/version** component so a format change doesn't poison entries.
- Bound size (`max_capacity`, weigher) and value size; compress or store IDs, not graphs.
- Serialize with a versioned format; treat deserialize failure as a miss.

## Staleness and invalidation

| Strategy | When |
|---|---|
| TTL only | staleness of N seconds is acceptable — the common case |
| **TTL + jitter** (±10–20%) | many keys created together expire together → synchronized herd |
| event-driven invalidation (publish on write) | freshness matters; always keep a TTL as the safety net |
| versioned keys / epoch counters | invalidate a whole class cheaply (`policy:v{epoch}:…`) |
| **negative caching** | "not found" results cached with a short TTL to absorb scans |

## Stampede protection — single flight

Concurrent misses on one key must trigger **one** load:

```rust
use std::{collections::HashMap, future::Future, hash::Hash, sync::{Arc, Mutex}, time::{Duration, Instant}};
use tokio::sync::OnceCell;

pub struct Cache<K, V> {
    ttl: Duration,
    entries: Mutex<HashMap<K, (Instant, V)>>,
    inflight: Mutex<HashMap<K, Arc<OnceCell<V>>>>,
}

impl<K: Hash + Eq + Clone, V: Clone> Cache<K, V> {
    pub fn new(ttl: Duration) -> Self { Self { ttl, entries: Mutex::default(), inflight: Mutex::default() } }

    fn fresh(&self, k: &K) -> Option<V> {
        let map = self.entries.lock().expect("cache lock");
        map.get(k).filter(|(at, _)| at.elapsed() < self.ttl).map(|(_, v)| v.clone())
    }

    pub async fn get_or_load<F, Fut>(&self, k: K, load: F) -> V
    where F: FnOnce() -> Fut, Fut: Future<Output = V> {
        if let Some(v) = self.fresh(&k) { return v; }
        let slot = {
            let mut inflight = self.inflight.lock().expect("inflight lock");
            inflight.entry(k.clone()).or_insert_with(|| Arc::new(OnceCell::new())).clone()
        };                                                   // lock released before any await
        let v = slot.get_or_init(load).await.clone();
        self.entries.lock().expect("cache lock").insert(k.clone(), (Instant::now(), v.clone()));
        self.inflight.lock().expect("inflight lock").remove(&k);
        v
    }
}
```
For production prefer `moka` (`future::Cache::get_with` does single-flight, supports TTL, TTI, size bounds and eviction listeners) — this snippet shows the mechanism; don't maintain your own (rs-reuse-first). Errors from the loader must **not** be cached for long (or at all).

## Redis (and Valkey) specifics

| Topic | Guidance |
|---|---|
| role | cache/session/rate-limit store; a source of truth only if persistence (AOF), replication and eviction `noeviction` are chosen on purpose |
| eviction | `maxmemory` + `allkeys-lru`/`allkeys-lfu` for a cache; `volatile-*` only if some keys must never be evicted |
| commands | `SCAN` not `KEYS`; pipeline/`MGET` batches; avoid big values and hot keys; set TTL with the write (`SET k v EX 300`) |
| locks | `SET k token NX PX ttl` is an *efficiency* lock; it is not safe for correctness (expiry, clock/pause) — use fencing tokens or the database (rs-domain-distributed) |
| connections | one multiplexed/managed connection per process (`redis` `ConnectionManager`), reconnect with backoff; treat unavailability as a miss, not an error, for pure caches |
| cluster | key hash tags only when multi-key operations need co-location |

## Failure modes to test

Cache down (requests still succeed, just slower, with a circuit breaker so you don't hammer a dead cache); source down (serve stale within a stated limit or fail clearly); poison entry (bad value deserialises as a miss); thundering herd after restart (warm up or jitter); memory growth (bounded).
