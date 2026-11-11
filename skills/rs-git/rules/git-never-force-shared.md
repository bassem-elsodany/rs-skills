# git-never-force-shared

> Never force-push or rewrite history that others may have
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Force-pushing a shared branch silently discards teammates' commits and breaks every clone. Even on your own branch the safe form matters.

## Do

- Shared branches (`main`, `release/*`, anything pushed for review): only forward commits and `git revert`.
- Your own unpublished or private branch after a rebase: `git push --force-with-lease` (fails if the remote moved) — and say you did.
- Before any rewrite: note the old tip (`git rev-parse HEAD`); the reflog is the undo.
- History surgery (`filter-repo`, BFG, amend of a pushed commit): owner's explicit yes, written plan, backup mirror clone.
- Host-side protection (no force-push, no deletion on the default branch) is part of publish-ready (`guides/publish-ready.md`); read the setting back rather than trusting an exit code.

## See Also

- [guides/safety.md](../guides/safety.md)
