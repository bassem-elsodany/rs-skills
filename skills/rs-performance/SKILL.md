---
name: rs-performance
description: "CRITICAL: Use for performance optimization. Triggers: performance, optimization, benchmark, profiling, flamegraph, criterion, slow, fast, allocation, cache, SIMD, make it faster"
user-invocable: false
---

# Performance Optimization

> **Layer 2: Design Choices**

## Core Question

**What's the bottleneck, and is optimization worth it?**

Before optimizing:
- Have you measured? (Don't guess)
- What's the acceptable performance?
- Will optimization add complexity?

---

## Performance Decision → Implementation

| Goal | Design Choice | Implementation |
|------|---------------|----------------|
| Reduce allocations | Pre-allocate, reuse | `with_capacity`, object pools |
| Improve cache | Contiguous data | `Vec`, `SmallVec` |
| Parallelize | Data parallelism | `rayon`, threads |
| Avoid copies | Zero-copy | References, `Cow<T>` |
| Reduce indirection | Inline data | `smallvec`, arrays |

---

## Thinking Prompt

Before optimizing:

1. **Have you measured?**
   - Profile first → flamegraph, perf
   - Benchmark → criterion, cargo bench
   - Identify actual hotspots

2. **What's the priority?**
   - Algorithm (10x-1000x improvement)
   - Data structure (2x-10x)
   - Allocation (2x-5x)
   - Cache (1.5x-3x)

3. **What's the trade-off?**
   - Complexity vs speed
   - Memory vs CPU
   - Latency vs throughput

---

## Trace Up ↑

To domain constraints (Layer 3):

```
"How fast does this need to be?"
    ↑ Ask: What's the performance SLA?
    ↑ Check: rs-domain-* (latency requirements)
    ↑ Check: Business requirements (acceptable response time)
```

| Question | Trace To | Ask |
|----------|----------|-----|
| Latency requirements | rs-domain-* | What's acceptable response time? |
| Throughput needs | rs-domain-* | How many requests per second? |
| Memory constraints | rs-domain-* | What's the memory budget? |

---

## Trace Down ↓

To implementation (Layer 1):

```
"Need to reduce allocations"
    ↓ rs-ownership: Use references, avoid clone
    ↓ rs-resource: Pre-allocate with_capacity

"Need to parallelize"
    ↓ rs-concurrency: Choose rayon or threads
    ↓ rs-concurrency: Consider async for I/O-bound

"Need cache efficiency"
    ↓ Data layout: Prefer Vec over HashMap when possible
    ↓ Access patterns: Sequential over random access
```

---

## Quick Reference

| Tool | Purpose |
|------|---------|
| `cargo bench` | Micro-benchmarks |
| `criterion` | Statistical benchmarks |
| `perf` / `flamegraph` | CPU profiling |
| `heaptrack` | Allocation tracking |
| `valgrind` / `cachegrind` | Cache analysis |

## Optimization Priority

```
1. Algorithm choice     (10x - 1000x)
2. Data structure       (2x - 10x)
3. Allocation reduction (2x - 5x)
4. Cache optimization   (1.5x - 3x)
5. SIMD/Parallelism     (2x - 8x)
```

## Common Techniques

| Technique | When | How |
|-----------|------|-----|
| Pre-allocation | Known size | `Vec::with_capacity(n)` |
| Avoid cloning | Hot paths | Use references or `Cow<T>` |
| Batch operations | Many small ops | Collect then process |
| SmallVec | Usually small | `smallvec::SmallVec<[T; N]>` |
| Inline buffers | Fixed-size data | Arrays over Vec |

---

## Common Mistakes

| Mistake | Why Wrong | Better |
|---------|-----------|--------|
| Optimize without profiling | Wrong target | Profile first |
| Benchmark in debug mode | Meaningless | Always `--release` |
| Use LinkedList | Cache unfriendly | `Vec` or `VecDeque` |
| Hidden `.clone()` | Unnecessary allocs | Use references |
| Premature optimization | Wasted effort | Make it work first |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Clone to avoid lifetimes | Performance cost | Proper ownership |
| Box everything | Indirection cost | Stack when possible |
| HashMap for small sets | Overhead | Vec with linear search |
| String concat in loop | O(n^2) | `String::with_capacity` or `format!` |

---

<!-- rules-index:start -->
## Rules (45)

Depth rules under `rules/` — open the one the question needs, not all of them.

**coll-**

- [`coll-binaryheap`](rules/coll-binaryheap.md) — Use `BinaryHeap` for a priority queue or repeated max-extraction
- [`coll-map-choice`](rules/coll-map-choice.md) — Pick the map by access pattern: `HashMap` (fast, unordered), `BTreeMap` (sorted / range queries), `IndexMap` (insertion order)
- [`coll-seq-choice`](rules/coll-seq-choice.md) — Default to `Vec`; use `VecDeque` for queue/deque behaviour; avoid `LinkedList`
- [`coll-set-membership`](rules/coll-set-membership.md) — Use `HashSet`/`BTreeSet` for membership tests and dedup, not linear `Vec::contains`

**mem-**

- [`mem-arena-allocator`](rules/mem-arena-allocator.md) — Use arena allocators for batch allocations
- [`mem-arrayvec`](rules/mem-arrayvec.md) — Use `ArrayVec<T, N>` for fixed-capacity collections that never heap-allocate
- [`mem-assert-type-size`](rules/mem-assert-type-size.md) — Use static assertions to guard against accidental type size growth
- [`mem-avoid-format`](rules/mem-avoid-format.md) — Avoid `format!()` when string literals work
- [`mem-box-large-variant`](rules/mem-box-large-variant.md) — Box large enum variants to reduce overall enum size
- [`mem-boxed-slice`](rules/mem-boxed-slice.md) — Use `Box<[T]>` instead of `Vec<T>` for fixed-size heap data
- [`mem-clone-from`](rules/mem-clone-from.md) — Use `clone_from()` to reuse allocations when repeatedly cloning
- [`mem-compact-string`](rules/mem-compact-string.md) — Use compact string types for memory-constrained string storage
- [`mem-reuse-collections`](rules/mem-reuse-collections.md) — Clear and reuse collections instead of creating new ones in loops
- [`mem-smaller-integers`](rules/mem-smaller-integers.md) — Use appropriately-sized integers to reduce memory footprint
- [`mem-smallvec`](rules/mem-smallvec.md) — Use `SmallVec` for usually-small collections
- [`mem-take-replace`](rules/mem-take-replace.md) — Use `mem::take` / `mem::replace` to move a value out of a `&mut` without cloning
- [`mem-thinvec`](rules/mem-thinvec.md) — Use `ThinVec<T>` for nullable collections with minimal overhead
- [`mem-with-capacity`](rules/mem-with-capacity.md) — Use `with_capacity()` when size is known
- [`mem-write-over-format`](rules/mem-write-over-format.md) — Use `write!()` into existing buffers instead of `format!()` allocations
- [`mem-zero-copy`](rules/mem-zero-copy.md) — Use zero-copy patterns with slices and `Bytes`

**opt-**

- [`opt-bounds-check`](rules/opt-bounds-check.md) — Use iterators and patterns that eliminate bounds checks in hot paths
- [`opt-cache-friendly`](rules/opt-cache-friendly.md) — Organize data for cache-efficient access patterns
- [`opt-codegen-units`](rules/opt-codegen-units.md) — Set `codegen-units = 1` for maximum optimization in release builds
- [`opt-cold-unlikely`](rules/opt-cold-unlikely.md) — Mark unlikely code paths with `#[cold]` to help compiler optimization
- [`opt-inline-always-rare`](rules/opt-inline-always-rare.md) — Use `#[inline(always)]` sparingly—only for critical hot paths proven by profiling
- [`opt-inline-never-cold`](rules/opt-inline-never-cold.md) — Use `#[inline(never)]` and `#[cold]` for error paths and rarely-executed code
- [`opt-inline-small`](rules/opt-inline-small.md) — Use `#[inline]` for small hot functions
- [`opt-likely-hint`](rules/opt-likely-hint.md) — Use code structure to hint at likely branches; use intrinsics on nightly
- [`opt-lto-release`](rules/opt-lto-release.md) — Enable LTO in release builds
- [`opt-pgo-profile`](rules/opt-pgo-profile.md) — Use Profile-Guided Optimization (PGO) for maximum performance
- [`opt-simd-portable`](rules/opt-simd-portable.md) — Use portable SIMD for vectorized operations across architectures
- [`opt-target-cpu`](rules/opt-target-cpu.md) — Use `target-cpu=native` for maximum performance on known deployment targets

**perf-**

- [`perf-ahash`](rules/perf-ahash.md) — Use a faster hasher (`ahash` / `FxHashMap`) when DoS resistance is not needed
- [`perf-black-box-bench`](rules/perf-black-box-bench.md) — Use black_box in benchmarks
- [`perf-chain-avoid`](rules/perf-chain-avoid.md) — Avoid chain in hot loops
- [`perf-collect-into`](rules/perf-collect-into.md) — Use collect_into for reusing containers
- [`perf-collect-once`](rules/perf-collect-once.md) — Don't collect intermediate iterators
- [`perf-drain-reuse`](rules/perf-drain-reuse.md) — Use drain to reuse allocations
- [`perf-entry-api`](rules/perf-entry-api.md) — Use entry API for map insert-or-update
- [`perf-extend-batch`](rules/perf-extend-batch.md) — Use extend for batch insertions
- [`perf-io-buffering`](rules/perf-io-buffering.md) — Wrap `Read`/`Write` in `BufReader`/`BufWriter` for many small operations
- [`perf-iter-lazy`](rules/perf-iter-lazy.md) — Keep iterators lazy, collect only when needed
- [`perf-iter-over-index`](rules/perf-iter-over-index.md) — Prefer iterators over manual indexing
- [`perf-profile-first`](rules/perf-profile-first.md) — Profile before optimizing
- [`perf-release-profile`](rules/perf-release-profile.md) — Optimize release profile settings

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Reducing clones | rs-ownership |
| Concurrency options | rs-concurrency |
| Smart pointer choice | rs-resource |
| Domain requirements | rs-domain-* |
| SIMD, io_uring, GPU, NUMA, mmap | rs-domain-systems |
