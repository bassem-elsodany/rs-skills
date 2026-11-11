---
name: rs-domain-systems
description: "Use for low-level systems work in Rust — eBPF programs, GPU compute, io_uring and thread-per-core I/O, kernel-bypass networking, SIMD, memory-mapped files, zero-copy parsing, NUMA and CPU affinity. Triggers: eBPF, BPF, aya, XDP, kprobe, tracepoint, kernel module, verifier, GPU, CUDA, wgpu, compute shader, cudarc, io_uring, tokio-uring, glommio, monoio, thread-per-core, DPDK, AF_XDP, kernel bypass, SIMD, std::simd, std::arch, intrinsics, auto-vectorization, is_x86_feature_detected, mmap, memmap2, zero-copy, zerocopy, bytemuck, NUMA, CPU affinity, false sharing, cache line, CachePadded, Linux-only"
user-invocable: false
---

# Systems Programming — kernel, GPU, I/O and SIMD

> **Layer 3: Domain** · the places where Rust meets hardware, the kernel and `unsafe`
>
> Everything here has the same shape: **a small `unsafe`/platform-specific core, a portable safe API on top, a fallback path, a measurement that justified it, and tests on the real target.**

## Core Question

**Is the ordinary path (tokio + epoll, plain loops, CPU) measurably too slow — and if so, which single platform feature fixes it with the least `unsafe`?**

Reach for these only after profiling (rs-performance) shows the standard approach is the bottleneck. Each one narrows portability (Linux-only, a GPU, a CPU feature) and raises the review burden.

## Decision table

| Need | Use | Crates (verified 2026-11-11) | Catch |
|---|---|---|---|
| observe/modify kernel behaviour safely (tracing, XDP packet filters, security hooks) | **eBPF** | `aya` (user space loader), `aya-ebpf` (kernel-side programs), `bpf-linker`, `aya-tool` for kernel types | Linux only; the **verifier** rejects unbounded loops/unchecked pointers; kernel programs are `#![no_std]` built for a BPF target (needs `bpf-linker`, nightly features as documented by aya); needs `CAP_BPF`/root; develop and test in a Linux VM or container with the right privileges, not on macOS |
| massively parallel numeric work | **GPU compute** | `wgpu` (portable via WebGPU/Vulkan/Metal/DX12), `cudarc` (CUDA driver/runtime bindings); ML frameworks in rs-domain-ml | host↔device transfers dominate small jobs; batch; keep data on the device; validate against a CPU reference; shaders are a second language to test |
| very high I/O rates, syscall overhead matters | **io_uring** / thread-per-core runtimes | `io-uring` (low-level, tokio-rs), `tokio-uring`, `glommio`, `monoio` | Linux ≥ 5.x with feature drift; several runtime crates are infrequently released (check `sdk-scout`); buffer ownership APIs differ from tokio; default `tokio` + epoll is enough for most services |
| packet processing at line rate | AF_XDP (`xsk-rs`) → kernel-bypass (DPDK via FFI) last | `xsk-rs`; DPDK = C FFI (rs-unsafe) | needs dedicated NICs/hugepages; operations burden; prove you cannot meet the SLO with `io_uring`/XDP first |
| speed up inner loops | **SIMD** | auto-vectorisation first (check with `cargo asm`/benchmarks); `std::arch` + `is_x86_feature_detected!`; `wide`, `pulp` (portable wrappers); `memchr`/`bstr` already use SIMD; `std::simd` is nightly | always keep a scalar fallback; runtime feature detection or `cfg(target_feature)`; test both paths against each other |
| read big files / share memory | `memmap2` | `memmap2` | the file changing under you is UB (SIGBUS/torn reads) → treat as `unsafe`, map read-only files you control, or read normally |
| parse binary data without copying | `zerocopy`, `bytemuck`, `bytes` | `zerocopy`, `bytemuck` | alignment and endianness; derive the traits (don't hand-write casts); validate lengths before casting |
| avoid cache/NUMA effects | `crossbeam::utils::CachePadded`, thread pinning (`core_affinity`), per-core data | `crossbeam`, `core_affinity` | measure first; false sharing shows as flat scaling across cores |

## Rules

1. **Profile before and after** (`criterion`, flamegraph — rs-performance); keep the benchmark in the repo.
2. **Isolate the platform code**: one module/crate (`sys/`, `bpf/`, `gpu/`) with a safe API and a Design Contract naming the kernel/driver/CPU requirements. Behind a port when it replaces a portable implementation (rs-ports-adapters) — the portable one is the fake and the fallback.
3. **Feature-gate and `cfg(target_os)`**: the crate must still build and test on a laptop (`cfg(target_os = "linux")`, Cargo features); CI has a Linux job that runs the real thing (privileged container/VM), plus the portable path.
4. **Every `unsafe` block gets a `// SAFETY:` comment** and a test or Miri/loom where applicable (rs-unsafe); eBPF and GPU code run *outside* Miri — test them differently (below).
5. **Document the environment**: minimum kernel version, required capabilities, GPU/driver versions, huge pages — in the README and Design Contract; fail with a clear error at start-up when missing, not mid-flight.
6. **Test on the real target**: Linux VM/container for eBPF/io_uring (privileged only for that test job — and clean it up, rs-cleanup); GPU tests behind a feature and `#[ignore]` unless a device is present; compare results with the CPU reference.

## eBPF in practice (aya)

```
project/
  app/              user-space loader + maps reader (std, tokio)       ← safe Rust, normal tests
  app-ebpf/         kernel program (#![no_std], aya-ebpf), built for the BPF target
  app-common/       #[repr(C)] types shared by both sides (no_std)       ← zerocopy/Pod derives
```
- Share event/map structs through a `no_std` common crate; keep them `#[repr(C)]`, fixed size, no pointers.
- Bound every loop; check every pointer/length the verifier cannot prove; keep programs small, push complexity to user space.
- Ring buffer/perf buffer to stream events; user-space consumer is a normal bounded async pipeline (rs-async-patterns).
- Treat loaded programs as privileged code: least capabilities, pin only what you need, detach on shutdown.

## GPU in practice

- Upload once, dispatch many; avoid readbacks inside loops; use staging buffers; check limits (`wgpu::Limits`).
- `bytemuck::Pod` for buffer data; keep layouts (`#[repr(C)]`, alignment) identical to the shader's.
- Provide a CPU implementation and a property test asserting equality within tolerance.
- Device loss and OOM are normal errors → classified `Unavailable`, not panics.

## Trace

| Direction | Go to |
|---|---|
| ↑ Up | rs-domain-ml (GPU for inference), rs-domain-cloud-native (privileged containers, node requirements), rs-domain-embedded (no_std core shared with eBPF) |
| ↓ Down | rs-unsafe (SAFETY, FFI, repr(C)), rs-performance (profiling, SIMD, cache), rs-concurrency (atomics, false sharing), rs-resource (mmap lifetimes) |
| → Delivery | rs-testing (target-specific CI), rs-release (feature matrix, cross-build), rs-cleanup (VMs, containers, large build artefacts for BPF/GPU toolchains) |

---

## Related Skills

| When | See |
|---|---|
| `unsafe` review and FFI | rs-unsafe |
| Where the time actually goes | rs-performance |
| Making the fast path replaceable | rs-ports-adapters |
| Choosing the crate | rs-reuse-first |
