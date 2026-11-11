# git-worktrees-for-parallel

> Use worktrees for parallel agents, then remove them
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Parallel agents on one working directory trample each other. Worktrees give each branch its own directory — but each one carries a full `target/` unless you share it.

## Do

```bash
git worktree add ../proj-feat-x feat/x           # one directory per branch
CARGO_TARGET_DIR=$PWD/../shared-target cargo check   # optional: share one target (builds serialise on the lock)
# ... work, merge ...
git worktree remove ../proj-feat-x && git worktree prune
```
- Remove worktrees (and their `target/`) when the branch merges — rs-cleanup.
- Don't check out the same branch in two worktrees.

## See Also

- [rs-cleanup clean-shared-target-dir](../../rs-cleanup/rules/clean-shared-target-dir.md)
