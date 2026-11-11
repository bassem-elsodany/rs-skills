# Restructuring an existing flat crate

You inherit `src/` with 25 files, a `utils.rs`, a 1,400-line `main.rs`, and
every feature touching every file. Do **not** rewrite. Move code in small,
compiling steps.

## 0. Freeze behaviour

`cargo test` green, `cargo clippy` baseline saved, a git branch. Every step
below ends with `cargo check` green and a commit.

**Pin what outsiders see before you move code** — "it compiles" is not "it behaves the same".
Write characterisation tests (or at least a checked list) for every client-visible string and
shape the crate produces: error/reason codes and messages, header and property names, log
prefixes, cache keys and formats, record field names. In a crate with few tests this is the
first commit of the restructure. While splitting, extract those producers into small pure
functions and test them there (`reason codes per path`, `block body JSON`, `identity headers
in order`). If two code paths emit *different* values for the same event, do not "unify" them
in the restructure — check the external contract (other implementations, docs, consumers)
first; it may be intentional.

## 1. Inventory

```
scripts/structure-map.sh .      # files, line counts, pub items, which files `use` which
```
Write the table down (the command prints Markdown). Mark each file with the
*feature* it mostly serves; a file serving three features is a candidate for
`shared/` or for splitting.

## 2. Cluster by feature

Three signals, in order of strength:
1. **Types** — which struct/enum a file's functions take and return; files
   that revolve around `Order`/`OrderId` belong to `orders`.
2. **`use` edges** — files that only import each other form a cluster.
3. **Names** — `order_handler.rs`, `order_repo.rs` → `orders/`.

Resolve the leftovers: `utils.rs` functions go next to their *single* caller;
functions with ≥3 callers in different features go to `shared/<topic>.rs`
(`shared/time.rs`, `shared/ids.rs`), never `shared/utils.rs`.

## 3. Write the target tree before moving anything

```
src/
  lib.rs                 pub mod orders; pub mod auth; pub mod config; mod shared;
  main.rs                ≤ 50 lines → calls crate::run
  orders/  mod.rs  model.rs  service.rs  repo.rs  handler.rs  error.rs
  auth/    mod.rs  model.rs  service.rs  token.rs  error.rs
  config/  mod.rs  load.rs  validate.rs
  shared/  mod.rs  ids.rs  money.rs  time.rs
```
Put it in the Design Contract of `lib.rs` as **Layout** — it is the plan and
the documentation at once.

## 4. Move in order: leaves first

1. **`shared/`** first (nothing depends on the move order of leaves).
2. **One feature at a time**: `mkdir src/orders && git mv src/order_model.rs src/orders/model.rs …`;
   create `orders/mod.rs` with `mod` lines and `pub use` of what the rest of
   the crate used before. Fix `use` paths; `cargo check`; commit.
3. **`main.rs` last**: extract `pub fn run(cli: Cli) -> Result<()>` into
   `lib.rs`; `main.rs` becomes parse-args → `run` → exit code.

Keep public paths stable with `pub use` re-exports in `lib.rs` so downstream
code (and your tests) keep compiling; remove the compatibility re-exports in a
later, separate commit.

## 5. Narrow visibility

Items that moved inside a feature: drop `pub` → `pub(super)`/`pub(crate)`
until `cargo check` complains. Add `#![warn(unreachable_pub)]` to `lib.rs`.

## 6. Contracts and checks

Every new `mod.rs` and file gets a Design Contract; `lib.rs` gets **Layout**.
Then:
```
cargo check && cargo clippy --all-targets && cargo test
scripts/contract-check.sh .
scripts/structure-check.sh .
```

## Rules of thumb while moving

- Never move and edit logic in the same commit — a move commit is reviewable, a mixed one is not.
- If a file resists clustering, split it first (`split-ladder.md`), then move the halves.
- Two features that share many private items are one feature — merge them, or extract the shared core as its own module with a contract.
- Stop at three directory levels; go wider, or go to a workspace crate.
