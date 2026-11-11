# clean-shared-target-dir

> One shared target directory per repo; scratch work gets its own and is deleted
> **rs-cleanup · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Independent crates with their own `target/` each rebuild `serde`, `tokio`, `syn` … (here: five policy crates at 6–10 GiB each). A shared directory builds each dependency once. Spike crates dropped in the repo leave a `target/` nobody remembers.

## Bad

```
repo/policy-a/target   9 GiB
repo/policy-b/target   9 GiB
repo/policy-c/target   9 GiB     ← the same dependency tree three times
```

## Good

```toml
# repo/.cargo/config.toml
[build]
target-dir = "target"          # relative to the config's directory: one directory for every crate below it
```
```bash
# throwaway spike, anywhere
CARGO_TARGET_DIR="$SCRATCH/spike-target" cargo check ; rm -rf "$SCRATCH/spike" "$SCRATCH/spike-target"
```

Prefer a Cargo **workspace** (one `Cargo.lock`, one `target/`) when the crates are released together (rs-structure `proj-workspace-large`). Caveat: crates built for different targets (wasm `cdylib` vs host) still produce separate artefact sets inside the shared directory — that is expected.

## See Also

- [clean-slim-debuginfo](clean-slim-debuginfo.md)
