# Destructive operations — what they cost and how to recover

> **rs-git · guide** — look at what will be lost *before* running anything in the left column.

| Command | What it destroys | Before | Recover |
|---|---|---|---|
| `git reset --hard` | uncommitted changes (tracked) | `git status`, `git stash push -u` | stash if you made one; otherwise gone — the reflog cannot restore never-committed work |
| `git clean -fd[x]` | untracked (and with `x` ignored) files | `git clean -nd` (dry run) | not recoverable |
| `git checkout .` / `git restore .` | working-tree edits | `git diff` | not recoverable |
| `git branch -D` | unmerged branch pointer | `git log <br> --not main` | `git reflog` → `git branch <name> <sha>` |
| `git stash drop/clear` | stashed work | `git stash show -p` | `git fsck --unreachable \| grep commit` |
| `git push --force` | remote history others may have | **don't on shared branches**; own branch only, and `--force-with-lease` | the remote reflog if the host keeps one; teammates' clones |
| `git rebase` (own branch) | nothing, rewrites local commits | note the old tip: `git rev-parse HEAD` | `git reflog` → `git reset --hard ORIG_HEAD` |
| `git commit --amend` on a pushed commit | the published commit | is it pushed? `git branch -r --contains HEAD` | don't — make a new commit |
| `git filter-repo`, BFG | history, on every branch/tag | **owner's explicit yes**; fresh mirror clone as backup | the backup |
| `git tag -d` + push `:tag` | a release promise | has anyone built from it? | recreate at the same sha |

## Rules

1. If you did not create the uncommitted change, you do not delete it. Ask.
2. Prefer the reversible twin: `revert` over `reset`, `restore --staged` over `reset`, `stash` over `checkout .`.
3. Before history surgery: tell the owner it is a rewrite plus force-push, that every existing clone will diverge, and wait for a yes. After: re-add the remote if the tool removed it, push, then **verify** (grep for the removed text, case-insensitively, and read each hit — a false positive can be a filename).
4. A leaked secret: **rotate/revoke first** (history rewrite does not un-leak it), then clean history if the owner agrees.
5. `git reflog` is your undo log (default 90 days for reachable, 30 for unreachable): `git reflog`, then `git reset --hard HEAD@{n}` or `git branch rescue <sha>`.
