# clean-measure-first

> Measure disk before a heavy task and after it; a number, not a feeling
> **rs-cleanup · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Disk fills silently across many sessions. Without a baseline nobody can say what a task cost, and the first sign of trouble is "no space left on device" in the middle of a build.

## Do

```bash
skills/rs-cleanup/scripts/disk-guard.sh status        # free space, every target/, caches, Docker
skills/rs-cleanup/scripts/disk-guard.sh preflight     # exit 1 below RS_MIN_FREE_GB
```

- Run `status` at the start of any build-heavy task and at the end; the difference goes in the Cleanup report.
- A `target/` with more than ~20 000 files in `debug/deps` is full of stale artefacts → `cargo sweep`.
- Treat "Docker reclaimable" as a budget (images + build cache); volumes are reported, never counted as reclaimable.

## See Also

- [clean-report](clean-report.md)
