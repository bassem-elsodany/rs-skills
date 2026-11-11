---
description: Repository hygiene audit for any Git host: secrets, tracked artefacts, big files, message style, attribution policy, hooks
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/skills/rs-git/scripts/git-check.sh:*)
---

# /rs-git-check

```
/rs-git-check [audit | staged | install-hooks] [dir] [--range A..B] [--strict]
```

1. Run `${CLAUDE_PLUGIN_ROOT}/skills/rs-git/scripts/git-check.sh ${ARGUMENTS:-audit}`.
2. Fix ERRORs first (credentials: **rotate before anything else**; tracked artefacts: `git rm --cached` + .gitignore). WARNs are judgement calls.
3. History problems (AI trailers, secrets in history) need a rewrite + force-push: **stop and ask the owner** (Skill(rs-git) `guides/safety.md`).
4. Offer `install-hooks` so every commit is linted and scanned (it sets `core.hooksPath` in the repo).
