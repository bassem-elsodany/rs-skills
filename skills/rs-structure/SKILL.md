---
name: rs-structure
description: "CRITICAL: Use when deciding where code lives — before creating a file, when a function or file grows too long, when told to split or refactor, when a crate has a flat src/ or a utils.rs. Triggers: project structure, module structure, module layout, folder structure, package, sub-package, submodule, mod.rs, lib.rs vs main.rs, where should this go, split this function, function too long, file too long, too many lines, extract module, organise code, organize code, refactor into modules, group by feature, workspace, crate boundaries, pub(crate), re-export, prelude, utils.rs, helpers.rs, flat structure, god module"
user-invocable: false
---

# Project and Module Structure

> **Layer 2: Design Choices** · the answer to "split it" that says *where it goes*

## Core Question

**Where does this code live, who may see it, and what happens when it grows?**

Splitting a long function into three functions in the same flat file is not a
structure. Structure means: a module tree that mirrors the *features* of the
program, a visibility boundary at every level, and a known place for the next
piece of code.

---

## Thinking Prompt — before writing any code

1. **Which feature does this belong to?** Name the domain concept (`orders`, `auth`, `config`), not the kind (`models`, `handlers`, `utils`).
2. **Which crate?** One crate until compile times, independent versioning or reuse force a workspace (see `guides/layouts.md`).
3. **Which module path?** `src/<feature>/<aspect>.rs`. If there is no feature yet, create the directory now — not when it "gets big".
4. **What is public?** Default private; widen one step at a time (visibility ladder below).
5. **Record it** in the file's Design Contract (**Layout** on `lib.rs`/`mod.rs`, **Extend by** everywhere) — Skill(rs-design-contract).

---

## Group by feature, not by kind

```
BAD (by kind — every feature touches every file)      GOOD (by feature — a feature is one directory)
src/                                                  src/
  main.rs                                               main.rs            (wiring only)
  models.rs      ← Order, User, Invoice…                lib.rs             (pub mod + Layout contract)
  handlers.rs    ← all HTTP handlers                     orders/
  services.rs    ← all business logic                      mod.rs          (public API, re-exports)
  db.rs          ← all queries                             model.rs        (Order, OrderId, state enum)
  utils.rs       ← everything else                        service.rs      (place/cancel/settle)
  types.rs                                                repo.rs         (storage trait + impl)
  errors.rs                                               error.rs        (OrderError)
                                                        auth/ …
                                                        config/ …
                                                        shared/           (only truly cross-feature: ids, money, time)
```

A new feature = a new directory. A change to one feature touches one directory.
`shared/` (not `utils/`) holds only types used by three or more features.

---

## The size ladder — what to do when something is too long

| Signal | Action | Where the pieces go |
|---|---|---|
| function > **40–60 lines**, or two levels of nested `match`/`if` | extract private fns named by *verb* (`parse_header`, `validate_totals`) | same file, below the caller |
| function has > 5 parameters | group them into a struct (`struct SettleArgs`) or a builder | same file; the struct right above the fn |
| file > **300–400 lines**, or > ~7 `pub` items, or two unrelated verbs in its names | **promote to a directory**: `foo.rs` → `foo/mod.rs` + `foo/<aspect>.rs` | `foo/mod.rs` keeps the public API and re-exports; aspects become private submodules |
| directory > **~8 files**, or a submodule is only used by one sibling | nest: `foo/bar/` with its own `mod.rs` | the sibling that uses it |
| feature used by another binary, needs its own version, or compile times hurt | **workspace member crate** `crates/<feature>/` | `[workspace.dependencies]` for shared deps |

Thresholds are triggers for *thinking*, not laws — but crossing two at once is never fine.

### The split recipe (follow in order — `guides/split-ladder.md` has a worked example)

1. **List the responsibilities** of the long function as verbs. Each verb is a candidate fn.
2. **Extract within the file** first; keep the original fn as the orchestrator that reads top-to-bottom.
3. **If the file is now too long, promote it**: `git mv src/foo.rs src/foo/mod.rs`, then move each cohesive group of fns + their types into `src/foo/<verb-or-aspect>.rs` with `mod <aspect>;` in `mod.rs`.
4. **Narrow visibility**: items only `mod.rs` calls → `pub(super)`; items used across the crate → `pub(crate)`; re-export the real public API with `pub use` in `mod.rs`.
5. **Move tests with the code**: each new file gets its own `#[cfg(test)] mod tests`.
6. **Update the Design Contracts**: `mod.rs` gets **Layout** (one line per submodule), every new file gets a contract, **Extend by** says where the next piece goes.
7. `cargo check && cargo clippy && ${CLAUDE_PLUGIN_ROOT}/scripts/contract-check.sh` — and `${CLAUDE_PLUGIN_ROOT}/scripts/structure-check.sh` for the smells below.

---

### Restructuring an existing flat crate

Different job: inventory (`${CLAUDE_PLUGIN_ROOT}/scripts/structure-map.sh`) → cluster files by feature (types, `use` edges, names) → write the target tree into `lib.rs`'s **Layout** → move leaves-first with `git mv`, one feature per commit, `pub use` to keep paths stable → narrow visibility → contracts. Full recipe: `guides/restructure-existing.md`; command: `/rs-restructure`.

## Visibility ladder

```
private            default — the item is an implementation detail of this file
pub(super)         the parent module orchestrates it (mod.rs calling its aspects)
pub(crate)         another feature in this crate needs it; still not API
pub + pub use      part of the crate's API, re-exported from lib.rs or the feature's mod.rs
```
Widen only when a compile error asks you to. `pub` on a struct's fields is a
separate decision (rs-patterns `idioms/priv-extend.md`).

## Reference layouts

| Shape | When | File |
|---|---|---|
| Library crate | reusable logic, no `main` | `${CLAUDE_PLUGIN_ROOT}/templates/project-layout/lib.md` |
| Binary with lib | any CLI/tool: `main.rs` ≤ 50 lines, everything testable in `lib.rs` | `${CLAUDE_PLUGIN_ROOT}/templates/project-layout/bin.md` |
| Service (hexagonal) | HTTP/gRPC services: `api/` → `domain/` ← `infra/`, `app.rs` wiring | `${CLAUDE_PLUGIN_ROOT}/templates/project-layout/service.md` |
| Workspace | several binaries, shared core, or long compile times | `${CLAUDE_PLUGIN_ROOT}/templates/project-layout/workspace.md` |

Details and the rules behind them: `guides/layouts.md`, `guides/visibility.md`.

---

## Anti-Patterns

| Anti-pattern | Why bad | Better |
|---|---|---|
| `utils.rs`, `helpers.rs`, `common.rs`, `misc.rs` | a dumping ground grows forever; nothing is findable | put each helper next to its single user; `shared/<topic>.rs` only for ≥3 users |
| `types.rs` / `models.rs` god module | every feature depends on every type | types live in their feature's `model.rs` |
| flat `src/` with 15+ files | no boundaries, no ownership | feature directories |
| 1,500-line `main.rs` | untestable, un-navigable | `main.rs` parses args and calls `lib::run` |
| everything `pub` | API surface = whole crate | visibility ladder |
| helpers / types / logic in `mod.rs` | mixes API with implementation | `mod.rs` = `mod` lines, `pub use`, docs, Layout contract, and at most the feature's thin public orchestrator fn (a readable sequence of calls) |
| `super::super::super::x` | the tree is wrong | move `x` to `shared/` or the common ancestor |
| splitting a fn into `step1`, `step2`, `part_a` | names say nothing | name by verb and object: `parse_header`, `apply_discounts` |
| nesting > 3 directories deep | paths unreadable | widen: promote a subtree to a feature or a crate |

---

## Trace Up ↑

| Situation | Trace to | Question |
|---|---|---|
| Which features exist? | rs-domain-model | What are the bounded contexts / aggregates? |
| Service shape | rs-domain-web, rs-domain-cloud-native | What must stay stateless / replaceable? |
| Crate boundaries | rs-ecosystem, rs-patterns `design-patterns/structural/small-crates.md` | Small crate or module? |

## Trace Down ↓

```
feature module       ↓ rs-design-contract (Layout + Extend by)
visibility           ↓ rs-type-driven (private fields, non_exhaustive)
big struct won't split ↓ rs-patterns design-patterns/structural/compose-structs.md
borrow trouble after split ↓ rs-ownership
```

<!-- rules-index:start -->
## Rules (13)

Depth rules under `rules/` — open the one the question needs, not all of them.

**proj-**

- [`proj-bin-dir`](rules/proj-bin-dir.md) — Put multiple binaries in src/bin/
- [`proj-build-rs-minimal`](rules/proj-build-rs-minimal.md) — Keep `build.rs` minimal, deterministic, and idempotent
- [`proj-feature-additive`](rules/proj-feature-additive.md) — Design Cargo features to be strictly additive
- [`proj-flat-small`](rules/proj-flat-small.md) — Keep small projects flat
- [`proj-lib-main-split`](rules/proj-lib-main-split.md) — Keep `main.rs` minimal, logic in `lib.rs`
- [`proj-mod-by-feature`](rules/proj-mod-by-feature.md) — Organize modules by feature, not type
- [`proj-mod-rs-dir`](rules/proj-mod-rs-dir.md) — Use mod.rs for multi-file modules
- [`proj-prelude-module`](rules/proj-prelude-module.md) — Create prelude module for common imports
- [`proj-pub-crate-internal`](rules/proj-pub-crate-internal.md) — Use pub(crate) for internal APIs
- [`proj-pub-super-parent`](rules/proj-pub-super-parent.md) — Use pub(super) for parent-only visibility
- [`proj-pub-use-reexport`](rules/proj-pub-use-reexport.md) — Use pub use for clean public API
- [`proj-workspace-deps`](rules/proj-workspace-deps.md) — Use workspace dependency inheritance for consistent versions across crates
- [`proj-workspace-large`](rules/proj-workspace-large.md) — Use workspaces for large projects

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| Recording the layout | rs-design-contract |
| Naming modules and files | rs-style |
| The function is long *because* of error handling | rs-error-handling |
| Workspace deps, features, MSRV | rs-ecosystem, rs-release |
| Where ports and adapters live (`adapters/<product>/`) | rs-ports-adapters |
| Commit scope = the feature module | rs-git |

Sub-files: `guides/split-ladder.md` · `guides/restructure-existing.md` · `guides/layouts.md` · `guides/visibility.md`. Tools: `${CLAUDE_PLUGIN_ROOT}/scripts/structure-check.sh`, `${CLAUDE_PLUGIN_ROOT}/scripts/structure-map.sh`, `/rs-restructure`.
