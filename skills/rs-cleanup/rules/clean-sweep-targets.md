# clean-sweep-targets

> `target/` never shrinks by itself — sweep it at the end of build-heavy work
> **rs-cleanup · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Every change to a crate or its flags produces new hash-named files in `target/debug/deps`; old ones stay forever. A project accumulated 289 000 files / 176 GiB there. Deleting the whole directory is safe but costs a full rebuild; `cargo sweep` removes only what has not been used recently.

## Do

```bash
cargo install cargo-sweep                 # once
cargo sweep --time 7                      # in each project: artefacts not used for 7 days
cargo sweep --installed                   # artefacts of toolchains that are no longer installed
# over budget even after that:
cargo clean                               # full reset of this target/ — minutes to rebuild
```
`skills/rs-cleanup/scripts/cleanup.sh plan|apply` runs sweep for every `target/` below a directory and falls back to removing `incremental/` when cargo-sweep is missing.

## When

- end of any task that ran builds/tests/clippy more than a few times;
- when `disk-guard.sh status` shows a `target/` above budget (default 15 GiB total);
- weekly on long-lived projects (a calendar reminder or a scheduled agent — rs-git/CI doc).

## See Also

- [clean-shared-target-dir](clean-shared-target-dir.md)
