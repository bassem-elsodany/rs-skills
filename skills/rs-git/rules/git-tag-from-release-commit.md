# git-tag-from-release-commit

> Release = version + changelog commit, annotated tag, artefact built from the tag
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A tag is a promise that a version equals exactly this tree. Hand-edited versions, lightweight tags and builds from a dirty tree break the promise.

## Do

```bash
git commit -am "chore(release): v1.4.0"    # Cargo.toml version + CHANGELOG (+ Cargo.lock) only
git tag -a v1.4.0 -m "v1.4.0"              # annotated; -s when signing
cargo package --list && cargo publish --dry-run
git push origin main v1.4.0
```
- One source of truth for the version; the binary prints version + short SHA.
- Workspaces with independent crates: `<crate>-vX.Y.Z`.
- Never move or delete a pushed tag — release a new patch instead.

## See Also

- [rs-release](../../rs-release/SKILL.md)
