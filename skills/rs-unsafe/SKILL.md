---
name: rs-unsafe
description: "CRITICAL: Use for unsafe Rust code review and FFI. Triggers on: unsafe, raw pointer, FFI, extern, transmute, *mut, *const, union, #[repr(C)], libc, std::ffi, MaybeUninit, NonNull, SAFETY comment, soundness, undefined behavior, UB, safe wrapper, memory layout, bindgen, cbindgen, CString, CStr"
allowed-tools: ["Read", "Grep", "Glob"]
---

Display the following ASCII art exactly as shown. Do not modify spaces or line breaks:
```text
⚠️ **Unsafe Rust Checker Loaded**

     *  ^  *
    /◉\_~^~_/◉\
 ⚡/     o     \⚡
   '_        _'
   / '-----' \
```

---

# Unsafe Rust Checker

## When Unsafe is Valid

| Use Case | Example |
|----------|---------|
| FFI | Calling C functions |
| Low-level abstractions | Implementing `Vec`, `Arc` |
| Performance | Measured bottleneck with safe alternative too slow |

**NOT valid:** Escaping borrow checker without understanding why.

## Required Documentation

```rust
// SAFETY: <why this is safe>
unsafe { ... }

/// # Safety
/// <caller requirements>
pub unsafe fn dangerous() { ... }
```

## Quick Reference

| Operation | Safety Requirements |
|-----------|---------------------|
| `*ptr` deref | Valid, aligned, initialized |
| `&*ptr` | + No aliasing violations |
| `transmute` | Same size, valid bit pattern |
| `extern "C"` | Correct signature, ABI |
| `static mut` | Synchronization guaranteed |
| `impl Send/Sync` | Actually thread-safe |

## Common Errors

| Error | Fix |
|-------|-----|
| Null pointer deref | Check for null before deref |
| Use after free | Ensure lifetime validity |
| Data race | Add proper synchronization |
| Alignment violation | Use `#[repr(C)]`, check alignment |
| Invalid bit pattern | Use `MaybeUninit` |
| Missing SAFETY comment | Add `// SAFETY:` |

## Deprecated → Better

| Deprecated | Use Instead |
|------------|-------------|
| `mem::uninitialized()` | `MaybeUninit<T>` |
| `mem::zeroed()` for refs | `MaybeUninit<T>` |
| Raw pointer arithmetic | `NonNull<T>`, `ptr::add` |
| `CString::new().unwrap().as_ptr()` | Store `CString` first |
| `static mut` | `AtomicT` or `Mutex` |
| Manual extern | `bindgen` |

## FFI Crates

| Direction | Crate |
|-----------|-------|
| C → Rust | bindgen |
| Rust → C | cbindgen |
| Python | PyO3 |
| Node.js | napi-rs |

Claude knows unsafe Rust. Focus on SAFETY comments and soundness.

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| Return errors to C | FFI idiomatic errors (integer codes, sentinels) | `../rs-patterns/idioms/ffi/errors.md` |
| Receive `*const c_char` | Accepting strings | `../rs-patterns/idioms/ffi/accepting-strings.md` |
| Hand strings to C | Passing strings | `../rs-patterns/idioms/ffi/passing-strings.md` |
| Design a C-callable API | Object-based APIs | `../rs-patterns/design-patterns/ffi/export.md` |
| Several related types cross the boundary | Type consolidation into wrappers | `../rs-patterns/design-patterns/ffi/wrappers.md` |
| `unsafe` spreading through a module | Contain unsafety in small modules | `../rs-patterns/design-patterns/structural/unsafe-mods.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (54)

Depth rules under `rules/` — open the one the question needs, not all of them.

**ffi-**

- [`ffi-01-no-string-direct`](rules/ffi-01-no-string-direct.md) — Avoid Passing Strings Directly to C from Public Rust API
- [`ffi-02-read-ffi-docs`](rules/ffi-02-read-ffi-docs.md) — Read Documentation Carefully When Using std::ffi Types
- [`ffi-03-drop-for-c-ptr`](rules/ffi-03-drop-for-c-ptr.md) — Implement Drop for Rust Types Wrapping Memory-Managing C Pointers
- [`ffi-04-panic-boundary`](rules/ffi-04-panic-boundary.md) — Handle Panics When Crossing FFI Boundaries
- [`ffi-05-portable-types`](rules/ffi-05-portable-types.md) — Use Portable Type Aliases from std or libc
- [`ffi-06-string-abi`](rules/ffi-06-string-abi.md) — Ensure C-ABI Compatibility for Strings Between Rust and C
- [`ffi-07-no-drop-external`](rules/ffi-07-no-drop-external.md) — Do Not Implement Drop for Types Passed to External Code
- [`ffi-08-error-handling`](rules/ffi-08-error-handling.md) — Handle Errors Properly in FFI
- [`ffi-09-ref-not-ptr`](rules/ffi-09-ref-not-ptr.md) — Use References Instead of Raw Pointers When Calling Safe C Functions
- [`ffi-10-thread-safety`](rules/ffi-10-thread-safety.md) — Exported Rust Functions Must Be Designed for Thread-Safety
- [`ffi-11-packed-ub`](rules/ffi-11-packed-ub.md) — Be Careful with UB When Referencing #[repr(packed)] Struct Fields
- [`ffi-12-invariant-doc`](rules/ffi-12-invariant-doc.md) — Document Invariant Assumptions for C-Provided Parameters
- [`ffi-13-data-layout`](rules/ffi-13-data-layout.md) — Ensure Consistent Data Layout for Custom Types
- [`ffi-14-stable-layout`](rules/ffi-14-stable-layout.md) — Types Used in FFI Should Have Stable Layout
- [`ffi-15-validate-external`](rules/ffi-15-validate-external.md) — Validate Non-Robust External Values
- [`ffi-16-closure-to-c`](rules/ffi-16-closure-to-c.md) — Separate Data and Code When Passing Rust Closures to C
- [`ffi-17-opaque-types`](rules/ffi-17-opaque-types.md) — Use Dedicated Opaque Type Pointers Instead of c_void for C Opaque Types
- [`ffi-18-no-trait-objects`](rules/ffi-18-no-trait-objects.md) — Avoid Passing Trait Objects to C Interfaces

**general-**

- [`general-01-no-abuse`](rules/general-01-no-abuse.md) — Do Not Abuse Unsafe to Escape Compiler Safety Checks
- [`general-02-not-for-perf`](rules/general-02-not-for-perf.md) — Do Not Blindly Use Unsafe for Performance
- [`general-03-no-alias`](rules/general-03-no-alias.md) — Do Not Create Aliases for Types/Methods Named "Unsafe"

**io-**

- [`io-01-raw-handle`](rules/io-01-raw-handle.md) — Ensure I/O Safety When Using Raw Handles

**mem-**

- [`mem-01-repr-layout`](rules/mem-01-repr-layout.md) — Choose Appropriate Data Layout for Struct/Tuple/Enum
- [`mem-02-no-other-process`](rules/mem-02-no-other-process.md) — Do Not Modify Memory Variables of Other Processes or Dynamic Libraries
- [`mem-03-no-auto-drop-foreign`](rules/mem-03-no-auto-drop-foreign.md) — Do Not Let String/Vec Auto-Drop Other Process's Memory
- [`mem-04-reentrant`](rules/mem-04-reentrant.md) — Prefer Reentrant Versions of C-API or Syscalls
- [`mem-05-bitfield-crates`](rules/mem-05-bitfield-crates.md) — Use Third-Party Crates for Bitfields
- [`mem-06-maybeuninit`](rules/mem-06-maybeuninit.md) — Use MaybeUninit<T> for Uninitialized Memory

**ptr-**

- [`ptr-01-no-thread-share`](rules/ptr-01-no-thread-share.md) — Do Not Share Raw Pointers Across Threads
- [`ptr-02-prefer-nonnull`](rules/ptr-02-prefer-nonnull.md) — Prefer NonNull<T> Over *mut T
- [`ptr-03-phantomdata`](rules/ptr-03-phantomdata.md) — Use PhantomData<T> for Variance and Ownership with Pointer Generics
- [`ptr-04-alignment`](rules/ptr-04-alignment.md) — Do Not Dereference Pointers Cast to Misaligned Types
- [`ptr-05-no-const-to-mut`](rules/ptr-05-no-const-to-mut.md) — Do Not Manually Convert Immutable Pointer to Mutable
- [`ptr-06-prefer-cast`](rules/ptr-06-prefer-cast.md) — Prefer pointer::cast Over `as` for Pointer Casting

**safety-**

- [`safety-01-panic-safety`](rules/safety-01-panic-safety.md) — Be Aware of Memory Safety Issues from Panics
- [`safety-02-verify-invariants`](rules/safety-02-verify-invariants.md) — Unsafe Code Authors Must Verify Safety Invariants
- [`safety-03-no-uninit-api`](rules/safety-03-no-uninit-api.md) — Do Not Expose Uninitialized Memory in Public APIs
- [`safety-04-double-free`](rules/safety-04-double-free.md) — Avoid Double-Free from Panic Safety Issues
- [`safety-05-send-sync`](rules/safety-05-send-sync.md) — Consider Safety When Manually Implementing Auto Traits
- [`safety-06-no-raw-ptr-api`](rules/safety-06-no-raw-ptr-api.md) — Do Not Expose Raw Pointers in Public APIs
- [`safety-07-unsafe-pair`](rules/safety-07-unsafe-pair.md) — Provide Unsafe Counterparts for Performance Alongside Safe Methods
- [`safety-08-no-mut-from-immut`](rules/safety-08-no-mut-from-immut.md) — Mutable Return from Immutable Parameter is Wrong
- [`safety-09-safety-comment`](rules/safety-09-safety-comment.md) — Add SAFETY Comment Before Any Unsafe Block
- [`safety-10-safety-doc`](rules/safety-10-safety-doc.md) — Add Safety Section in Docs for Public Unsafe Functions
- [`safety-11-assert-not-debug`](rules/safety-11-assert-not-debug.md) — Use assert! Instead of debug_assert! in Unsafe Functions

**union-**

- [`union-01-avoid-except-ffi`](rules/union-01-avoid-except-ffi.md) — Avoid Union Except for C Interop
- [`union-02-no-cross-lifetime`](rules/union-02-no-cross-lifetime.md) — Do Not Use Union Variants Across Different Lifetimes

**unsafe-**

- [`unsafe-extern-block`](rules/unsafe-extern-block.md) — In Rust 2024, wrap `extern` blocks in `unsafe extern { }` and annotate each item as `safe` or `unsafe`.
- [`unsafe-maybeuninit`](rules/unsafe-maybeuninit.md) — Use `MaybeUninit<T>` for uninitialized memory; never use `mem::uninitialized()` or `mem::zeroed()` for types with validity invariants.
- [`unsafe-minimize-scope`](rules/unsafe-minimize-scope.md) — Keep `unsafe` blocks as small as possible — mark only the operation that requires unsafety, not the surrounding safe code.
- [`unsafe-miri-ci`](rules/unsafe-miri-ci.md) — Run `cargo miri test` in CI for every crate that contains `unsafe` code.
- [`unsafe-no-mangle-unsafe`](rules/unsafe-no-mangle-unsafe.md) — In Rust 2024, write `#[unsafe(no_mangle)]`, `#[unsafe(export_name = "...")]`, and `#[unsafe(link_section = "...")]` — not the bare attribute forms.
- [`unsafe-safety-comment`](rules/unsafe-safety-comment.md) — Write a `// SAFETY:` comment above every `unsafe` block and a `# Safety` section in every `unsafe fn`.
- [`unsafe-send-sync-manual`](rules/unsafe-send-sync-manual.md) — Document the invariants when manually implementing `Send` or `Sync`; prefer letting the compiler derive them automatically.

<!-- rules-index:end -->
