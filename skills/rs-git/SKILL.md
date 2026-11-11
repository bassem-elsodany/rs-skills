---
name: rs-git
description: "Use for any version-control work from design to production release — branching, commits, messages, reviews/merge requests, tags, changelogs, hotfixes, history surgery, repository hygiene — on any Git host (GitHub, GitLab, Bitbucket, Gitea, Azure DevOps, Gerrit, plain SSH, or no remote at all). Triggers: git, commit, commit message, conventional commits, branch, branching strategy, trunk-based, merge, rebase, squash, cherry-pick, revert, reset, force push, stash, worktree, bisect, blame, reflog, pull request, merge request, patch, code review hand-off, tag, release, version bump, changelog, hotfix, .gitignore, secrets in git, leaked credential, large files, LFS, git hooks, pre-commit, history rewrite, filter-repo, AI co-author trailer, attribution, repository hygiene, ready to publish, make repo public, branch protection"
user-invocable: false
---

# Git across the lifecycle — design → build → review → release → operate

> **Layer 4: Delivery** · every phase ends in a commit, a tag or a hand-off; this is how they are made
>
> Tools: `${CLAUDE_SKILL_DIR}/scripts/git-check.sh` (`audit` · `staged` · `msg` · `install-hooks`) · `guides/` (lifecycle, safety, publish-ready) · `templates/` (`.gitignore`, change summary, release checklist)
> Host-neutral on purpose: nothing here needs GitHub. The remote may be GitHub, GitLab, Bitbucket, Gitea, Azure DevOps, Gerrit, a bare repo over SSH — or absent.

## Core Question

**Could someone who was not here reconstruct what changed, why, and how to undo it — from the history alone?**

Commits are save points, branches are sandboxes, tags are promises, history is documentation. With an agent writing code fast, disciplined version control is what keeps the work reviewable and reversible.

---

## The lifecycle

| Phase | Git's job | Do | Skill link |
|---|---|---|---|
| **Design** | make decisions durable | commit the plan, decision records, `.gitignore`, `rust-toolchain.toml`, CI file **first**; pick the branching model (trunk-based by default) | rs-reuse-first (decision records), rs-structure |
| **Build** | save points | one branch per slice; **commit each verified step** (tests green); atomic, conventional commits; stage by name, never blindly | rs-style, rs-testing |
| **Review** | a readable hand-off | rebase your own branch onto the base; PR/MR/patch description from `templates/change-summary.md`; review report stays out of public history | rs-review |
| **Release** | an immutable promise | version bump + changelog in one commit; annotated tag `vX.Y.Z` that the artefact is built from; verify what the tag contains | rs-release |
| **Operate** | recover and trace | `revert` (not `reset`) on shared branches; `bisect`, `blame`, `log -S` to find causes; hotfix branch from the tag; backport with `cherry-pick -x` | rs-observability, rs-domain-error |

Per-phase commands and checklists: `guides/lifecycle.md`.

## Commits

| Rule | Detail |
|---|---|
| **Atomic** | one logical change; refactors, formatting and behaviour changes are separate commits |
| **Green** | every commit builds and passes tests, so `git bisect` works. Hook: `${CLAUDE_SKILL_DIR}/scripts/git-check.sh install-hooks` |
| **Message** | `<type>(<scope>): <summary>` — types `feat fix refactor perf test docs build ci chore style revert`; **scope = the feature module** (`feat(orders): …`, rs-structure); body explains *why*; `BREAKING CHANGE:` footer when the public API breaks (feeds semver) |
| **Size** | ~100 lines ideal, ~300 acceptable, >1000 split. Dozens of files in one commit is a smell |
| **Stage deliberately** | `git add <paths>` / `git add -p`, then `git diff --staged`. `git add -A` only after `git status` shows nothing unexpected (no `target/`, `.env`, dumps) |
| **No secrets, no artefacts** | `git-check.sh staged` blocks credentials, `target/`, `.env`, `*.pem`, files over 5 MiB. A leaked secret is **rotated first**, then removed from history with the owner's consent |
| **Attribution** | **Do not add AI attribution trailers** (`Co-Authored-By: <AI>`, `Claude-Session:`) unless the owner or the repo's convention asks. They make the assistant appear as a contributor on the host. Ask early; the commit-msg hook rejects them unless `.rs-git-allow-ai-trailers` exists. Retroactive removal rewrites history → owner's explicit yes |
| **Don't `--no-verify`** | a failing hook is a finding, not an obstacle |

## Branches and integration

- **Trunk-based by default:** `main` is always releasable; branches live 1–3 days; incomplete work hides behind a flag rather than a long branch. Release branches only to stabilise while `main` moves on.
- Names: `feat/<module>-<slug>`, `fix/<slug>`, `chore/<slug>`, `release/x.y`, `hotfix/x.y.z`.
- **Rebase your own, merge shared:** `git rebase <base>` on a branch only you use; never rebase or force-push a branch others have pulled. Squash-merge only if the team's convention says so — otherwise keep the atomic commits.
- **Worktrees for parallel agents** (`git worktree add ../proj-feat feat/x`): independent directories, one branch each. Each has its own `target/` unless you share one (rs-cleanup `clean-shared-target-dir`); remove the worktree after merge and `git worktree prune`.
- Submodules: avoid; prefer crates/workspaces. Large binaries: Git LFS or out of the repo.

## Releases (details: `guides/lifecycle.md#release`)

1. Gate green: `/rs-release-check` (fmt, clippy, tests, docs, deny, semver-checks) and a clean tree.
2. Bump the version (`Cargo.toml`), write the CHANGELOG entry for humans (Added/Changed/Fixed/Deprecated/Removed/Security), commit: `chore(release): vX.Y.Z`.
3. **Annotated tag from that commit**: `git tag -a vX.Y.Z -m "…"` (signed with `-s` when the team signs). Workspaces: `<crate>-vX.Y.Z`.
4. Verify what ships: `cargo package --list`, `cargo publish --dry-run`; verify the tag contents, don't trust exit codes.
5. Push the branch **and** the tag; create the host's release object from the changelog (any host — or just the tag).
6. Version number is derived from the tag/Cargo.toml in one place; a breaking change under a minor bump is a bug (rs-api-design).

## Never (without the owner's explicit yes)

`push --force` to a shared branch · rewrite published history · `reset --hard` / `clean -fd` / `checkout .` on uncommitted work you did not make · delete a remote branch or tag · amend a pushed commit · add AI trailers · commit `.env`/keys/`target/`. See `guides/safety.md` for the recovery path of each.

## Trace

| Direction | Go to |
|---|---|
| ↑ Up | rs-release (what a release must contain) · rs-review (what the hand-off must show) |
| ↓ Down | rs-cleanup (worktrees, `target/` in repos) · rs-structure (module = commit scope) |
| → Delivery | `/rs-git-check` in the release gate; rs-review reports `git-check.sh audit` output |

<!-- rules-index:start -->
## Rules (9)

Depth rules under `rules/` — open the one the question needs, not all of them.

**git-**

- [`git-atomic-green-commits`](rules/git-atomic-green-commits.md) — One logical change per commit, and every commit builds and passes
- [`git-attribution-policy`](rules/git-attribution-policy.md) — No AI attribution trailers unless the owner asks — ask early
- [`git-conventional-messages`](rules/git-conventional-messages.md) — Write messages as type(scope): summary, with the why in the body
- [`git-host-neutral`](rules/git-host-neutral.md) — Use plain git; reach for the host's CLI only when the remote matches
- [`git-never-force-shared`](rules/git-never-force-shared.md) — Never force-push or rewrite history that others may have
- [`git-no-secrets-no-artefacts`](rules/git-no-secrets-no-artefacts.md) — Never commit credentials, build output or large binaries
- [`git-stage-deliberately`](rules/git-stage-deliberately.md) — Stage named paths, read the staged diff, then commit
- [`git-tag-from-release-commit`](rules/git-tag-from-release-commit.md) — Release = version + changelog commit, annotated tag, artefact built from the tag
- [`git-worktrees-for-parallel`](rules/git-worktrees-for-parallel.md) — Use worktrees for parallel agents, then remove them

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| Public launch polish — README with screenshots, topics, distribution, community posting | a launch/discoverability skill of your own (rs-git covers only the host-neutral git parts: `guides/publish-ready.md`) |
| Versioning rules and CI gates | rs-release |
| What counts as a breaking change | rs-api-design |
| Decision records for dependencies | rs-reuse-first |
