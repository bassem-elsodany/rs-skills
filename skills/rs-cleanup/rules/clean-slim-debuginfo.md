# clean-slim-debuginfo

> Dev builds keep line tables only; dependencies get no debug info
> **rs-cleanup · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Full DWARF debug information is the largest part of a debug `target/` and slows linking. Line tables keep panics and backtraces readable; a debugger still steps through your code.

## Do

```toml
[profile.dev]
debug = "line-tables-only"
[profile.dev.package."*"]
debug = false
[profile.test]
debug = "line-tables-only"
```
(`templates/release/dev-profile.toml`; `scripts/new-crate.sh` adds it.) Raise `debug` to `true` temporarily for a crate you are stepping through in a debugger.

Also: `incremental = false` for CI and one-shot builds (`CARGO_INCREMENTAL=0`), and `cargo check` instead of `cargo build` when you only need to know it compiles.

## See Also

- [clean-sweep-targets](clean-sweep-targets.md)
