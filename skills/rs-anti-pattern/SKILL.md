---
name: rs-anti-pattern
description: "Use when reviewing code for anti-patterns. Keywords: anti-pattern, common mistake, pitfall, code smell, bad practice, code review, is this an anti-pattern, better way to do this, common mistake to avoid, why is this bad, idiomatic way, beginner mistake, fighting borrow checker, clone everywhere, unwrap in production, should I refactor"
user-invocable: false
---

# Anti-Patterns

> **Layer 2: Design Choices**

## Core Question

**Is this pattern hiding a design problem?**

When reviewing code:
- Is this solving the symptom or the cause?
- Is there a more idiomatic approach?
- Does this fight or flow with Rust?

---

## Anti-Pattern → Better Pattern

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| `.clone()` everywhere | Hides ownership issues | Proper references or ownership |
| `.unwrap()` in production | Runtime panics | `?`, `expect`, or handling |
| `Rc` when single owner | Unnecessary overhead | Simple ownership |
| `unsafe` for convenience | UB risk | Find safe pattern |
| OOP via `Deref` | Misleading API | Composition, traits |
| Giant match arms | Unmaintainable | Extract to methods |
| `String` everywhere | Allocation waste | `&str`, `Cow<str>` |
| Ignoring `#[must_use]` | Lost errors | Handle or `let _ =` |

---

## Thinking Prompt

When seeing suspicious code:

1. **Is this symptom or cause?**
   - Clone to avoid borrow? → Ownership design issue
   - Unwrap "because it won't fail"? → Unhandled case

2. **What would idiomatic code look like?**
   - References instead of clones
   - Iterators instead of index loops
   - Pattern matching instead of flags

3. **Does this fight Rust?**
   - Fighting borrow checker → restructure
   - Excessive unsafe → find safe pattern

---

## Trace Up ↑

To design understanding:

```
"Why does my code have so many clones?"
    ↑ Ask: Is the ownership model correct?
    ↑ Check: rs-domain-model (data flow design)
    ↑ Check: rs-ownership (reference patterns)
```

| Anti-Pattern | Trace To | Question |
|--------------|----------|----------|
| Clone everywhere | rs-ownership | Who should own this data? |
| Unwrap everywhere | rs-error-handling | What's the error strategy? |
| Rc everywhere | rs-domain-model | Is ownership clear? |
| Fighting lifetimes | rs-domain-model | Should data structure change? |

---

## Trace Down ↓

To implementation (Layer 1):

```
"Replace clone with proper ownership"
    ↓ rs-ownership: Reference patterns
    ↓ rs-resource: Smart pointer if needed

"Replace unwrap with proper handling"
    ↓ rs-error-handling: ? operator
    ↓ rs-error-handling: expect with message
```

---

## Top 5 Beginner Mistakes

| Rank | Mistake | Fix |
|------|---------|-----|
| 1 | Clone to escape borrow checker | Use references |
| 2 | Unwrap in production | Propagate with `?` |
| 3 | String for everything | Use `&str` |
| 4 | Index loops | Use iterators |
| 5 | Fighting lifetimes | Restructure to own data |

## Code Smell → Refactoring

| Smell | Indicates | Refactoring |
|-------|-----------|-------------|
| Many `.clone()` | Ownership unclear | Clarify data flow |
| Many `.unwrap()` | Error handling missing | Add proper handling |
| Many `pub` fields | Encapsulation broken | Private + accessors |
| Deep nesting | Complex logic | Extract methods (rs-structure) |
| Flat `src/` + `utils.rs` | No module boundaries | Group by feature (rs-structure) |
| Long functions | Multiple responsibilities | Split with the rs-structure ladder (extract verbs → promote file to directory) |
| Giant enums | Missing abstraction | Trait + types |

---

## Common Error Patterns

| Error | Anti-Pattern Cause | Fix |
|-------|-------------------|-----|
| E0382 use after move | Cloning vs ownership | Proper references |
| Panic in production | Unwrap everywhere | ?, matching |
| Slow performance | String for all text | &str, Cow |
| Borrow checker fights | Wrong structure | Restructure |
| Memory bloat | Rc/Arc everywhere | Simple ownership |

---

## Deprecated → Better

| Deprecated | Better |
|------------|--------|
| Index-based loops | `.iter()`, `.enumerate()` |
| `collect::<Vec<_>>()` then iterate | Chain iterators |
| Manual unsafe cell | `Cell`, `RefCell` |
| `mem::transmute` for casts | `as` or `TryFrom` |
| Custom linked list | `Vec`, `VecDeque` |
| `lazy_static!` | `std::sync::OnceLock` |

---

## Quick Review Checklist

- [ ] No `.clone()` without justification
- [ ] No `.unwrap()` in library code
- [ ] No `pub` fields with invariants
- [ ] No index loops when iterator works
- [ ] No `String` where `&str` suffices
- [ ] No ignored `#[must_use]` warnings
- [ ] No `unsafe` without SAFETY comment
- [ ] No giant functions (>50 lines) — and splits land in feature modules, not a flat `src/` (rs-structure)

---

## Related patterns

| Problem | Pattern / idiom | Page (rs-patterns) |
|---|---|---|
| `.clone()` to make the borrow checker happy | Clone to satisfy the borrow checker | `../rs-patterns/anti-patterns/borrow_clone.md` |
| `#![deny(warnings)]` in a library | deny(warnings) | `../rs-patterns/anti-patterns/deny-warnings.md` |
| `impl Deref` to emulate inheritance | Deref polymorphism | `../rs-patterns/anti-patterns/deref.md` |
| Turning working code into great code | Refactoring (patterns to DRY, idioms to clarify) | `../rs-patterns/principles/refactoring.md` |

Decision guide for all 52 pages: `../rs-patterns/SKILL.md`.

---

<!-- rules-index:start -->
## Rules (15)

Depth rules under `rules/` — open the one the question needs, not all of them.

**anti-**

- [`anti-clone-excessive`](rules/anti-clone-excessive.md) — Don't clone when borrowing works
- [`anti-collect-intermediate`](rules/anti-collect-intermediate.md) — Don't collect intermediate iterators
- [`anti-empty-catch`](rules/anti-empty-catch.md) — Don't silently ignore errors
- [`anti-expect-lazy`](rules/anti-expect-lazy.md) — Don't use expect for recoverable errors
- [`anti-format-hot-path`](rules/anti-format-hot-path.md) — Don't use format! in hot paths
- [`anti-index-over-iter`](rules/anti-index-over-iter.md) — Don't use indexing when iterators work
- [`anti-lock-across-await`](rules/anti-lock-across-await.md) — Don't hold locks across await points
- [`anti-over-abstraction`](rules/anti-over-abstraction.md) — Don't over-abstract with excessive generics
- [`anti-panic-expected`](rules/anti-panic-expected.md) — Don't panic on expected or recoverable errors
- [`anti-premature-optimize`](rules/anti-premature-optimize.md) — Don't optimize before profiling
- [`anti-string-for-str`](rules/anti-string-for-str.md) — Don't accept &String when &str works
- [`anti-stringly-typed`](rules/anti-stringly-typed.md) — Don't use strings where enums or newtypes would provide type safety
- [`anti-type-erasure`](rules/anti-type-erasure.md) — Don't use Box<dyn Trait> when impl Trait works
- [`anti-unwrap-abuse`](rules/anti-unwrap-abuse.md) — Don't use `.unwrap()` in production code
- [`anti-vec-for-slice`](rules/anti-vec-for-slice.md) — Don't accept &Vec<T> when &[T] works

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|------|-----|
| Ownership patterns | rs-ownership |
| Error handling | rs-error-handling |
| Mental models | rs-mental-model |
| Performance | rs-performance |
