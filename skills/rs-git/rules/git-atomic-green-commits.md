# git-atomic-green-commits

> One logical change per commit, and every commit builds and passes
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Atomic, green commits can be reviewed one by one, reverted alone and bisected. A mixed commit ("add feature, fix sidebar, update deps") can be none of those.

## Bad

```
a1f3 wip
b2c4 stuff
c3d5 feat: task feature + refactor utils + bump deps + fix typo
```

## Good

```
d4e5 refactor(orders): extract validation into its own module
e5f6 feat(orders): cancel an open order
f6a7 test(orders): cancel is idempotent and rejects settled orders
a7b8 chore(deps): bump serde to 1.0.220
```

Each commit: tests green, one reason to exist, ~100–300 lines. Refactors and formatting never share a commit with behaviour changes. Hook: `git-check.sh install-hooks` (message lint + staged scan); the gate for green is your test run before committing.

## See Also

- [git-conventional-messages](git-conventional-messages.md)
