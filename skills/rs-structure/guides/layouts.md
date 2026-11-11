# Reference layouts and the rules behind them

## Library crate

```
my_lib/
  Cargo.toml
  src/
    lib.rs            //! crate docs + Design Contract (Layout) ; pub mod feature_a; pub mod feature_b; pub use …
    feature_a/ mod.rs model.rs ops.rs error.rs
    feature_b/ …
    shared/           ids.rs money.rs   (only if ≥3 features use them)
  tests/              one file per public feature (black-box)
  benches/            criterion benches
  examples/           runnable examples (doubles as docs)
```
- `lib.rs` is the table of contents: `mod` declarations, `pub use` of the API,
  crate-level docs. No logic.
- Public API is re-exported flat (`my_lib::Order`, not `my_lib::feature_a::model::Order`)
  unless the module path carries meaning for users.

## Binary with a library (every CLI/tool)

```
my_tool/
  src/
    main.rs           ≤ 50 lines: parse args, call my_tool::run(cli), map error → exit code
    lib.rs            pub fn run(cli: Cli) -> Result<()>; pub mod cli; mod commands; mod config; …
    cli.rs            clap derive types only
    commands/         one file per subcommand
    config/
  src/bin/            extra binaries, each a thin main over the same lib
```
Everything in `lib.rs` is testable; `main.rs` is not (rs-domain-cli for exit
codes and config precedence).

## Service (hexagonal / ports and adapters)

```
my_service/
  src/
    main.rs           runtime, tracing init, call app::run
    app.rs            wiring: build adapters, inject into domain services, start server
    api/              transport: http/ (routes, handlers, dto, extractors) grpc/ …
    domain/           pure: model/ service/ ports.rs (traits the domain needs), error.rs — no tokio, no sqlx
    infra/            adapters implementing domain::ports: store/postgres.rs, cache/redis.rs, clients/…
    config/
  tests/              api-level tests with in-memory adapters
```
Dependency direction: `api` → `domain` ← `infra`; `app.rs` is the only file
that knows all three. The Design Contract of `domain/mod.rs` states the
"no I/O" invariant.

## Workspace

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

## Module file conventions

- 2018 style (`foo.rs` + `foo/bar.rs`) or `foo/mod.rs` — pick one per crate.
  This bundle's templates use `mod.rs` because the directory then contains
  everything about the feature.
- A `mod.rs` holds `mod` lines, `pub use`, docs and the Layout contract — plus, at most, the feature's thin public orchestrator (as in `split-ladder.md`); no helpers, no types.
- File names are nouns or stage verbs; never `utils`, `helpers`, `common`, `misc`, `stuff`.
