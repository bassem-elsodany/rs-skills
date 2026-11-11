# Workspace

> Template — see skills/rs-structure for the rules.

```
my_project/
  Cargo.toml          [workspace] members = ["crates/*", "apps/*"]; [workspace.dependencies]; [workspace.lints]
  crates/
    core/             domain types and logic, no I/O
    storage/          adapters
    api-types/        shared DTOs (if several apps/clients)
  apps/
    server/           binary
    cli/              binary
  xtask/              build automation instead of shell scripts (optional)
```
When to go workspace: two binaries share code · a part needs its own release
cadence · incremental compile times hurt · a crate must be `no_std` or have
different features. Not before.
