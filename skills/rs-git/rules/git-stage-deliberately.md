# git-stage-deliberately

> Stage named paths, read the staged diff, then commit
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

`git add -A` / `git commit -a` sweeps in whatever the build, the editor and earlier experiments left behind: `target/`, `.env`, scratch files, a 200 MB dump.

## Do

```bash
git status                         # what exists
git add src/orders/cancel.rs tests/orders_cancel.rs     # or: git add -p
git diff --staged                  # what will be saved — read it
git commit
```

`git add -A` is acceptable only right after `git status` showed nothing unexpected and `.gitignore` covers the build output.

## See Also

- [git-no-secrets-no-artefacts](git-no-secrets-no-artefacts.md)
