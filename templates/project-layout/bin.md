# Binary with a library (every CLI/tool)

> Template — see skills/rs-structure for the rules.

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
