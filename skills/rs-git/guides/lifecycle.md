# Git by lifecycle phase

> **rs-git · guide** — host-neutral. Replace "PR" with MR / patch / Gerrit change as your host calls it.

## Design

```bash
git init -b main                              # or clone; check `git remote -v` — none is fine
# first commits: structure before code
#   .gitignore (templates/gitignore-rust), rust-toolchain.toml, Cargo.toml, deny.toml, CI file, docs/decisions/
git add .gitignore rust-toolchain.toml && git commit -m "chore: ignore build output, pin toolchain"
skills/rs-git/scripts/git-check.sh install-hooks     # message lint + staged-secret scan for every clone
```
- Decide: branching model (trunk-based default), merge style (keep atomic commits vs squash), tag scheme (`vX.Y.Z`; `crate-vX.Y.Z` in workspaces), who may force-push (nobody on shared branches).
- Commit decision records (`docs/decisions/NNNN-*.md`, rs-reuse-first) with the change that implements them.
- Reports that contain internal findings (`rs-reviews/`) live in the project's private docs folder — gitignored when the repo is public (see rs-review).

## Build

```bash
git switch -c feat/orders-cancel                     # branch from an up-to-date base
# ... implement one slice, run its tests ...
git status; git add src/orders/cancel.rs tests/orders_cancel.rs
git diff --staged                                     # read what you are about to save
git commit -m "feat(orders): cancel an open order"    # hook lints the message and scans the diff
```
| Moment | Do |
|---|---|
| step verified (tests pass) | commit — a save point |
| step broke things | `git restore <file>` / `git revert <sha>` — never leave a red `HEAD` on the branch you share |
| mid-way idea | `git stash push -m "wip: …"` (look at `git stash list` later); don't mix it into the commit |
| base moved | on your own branch: `git fetch && git rebase origin/main` (resolve, `cargo test`, continue) |
| need a spike | worktree or scratch dir; delete it; `target/` hygiene → rs-cleanup |

Commit order for a feature: types/ports → implementation → tests → docs. Refactors that enable the feature go first, in their own commits.

## Review (hand-off)

1. `git fetch && git rebase origin/main`; `cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test`.
2. `git log --oneline origin/main..HEAD` — the story reads in order; squash only fixup noise (`git rebase -i` is interactive: when unavailable, use `git reset --soft <base>` + recommit in logical slices with the user's consent).
3. Write the description from `templates/change-summary.md`: what/why, how verified, **what I didn't touch**, risks. Works pasted into any PR/MR, a Gerrit change or an email patch (`git format-patch origin/main`).
4. Findings from review: new commits (`fix(…): address review — …`) or fixups that are autosquashed before merge — not force-pushed over a branch the reviewer has already commented on, unless they agree.
5. rs-review's report lists the commit range and the `git-check.sh audit` result.

## Release

```bash
git switch main && git pull --ff-only
scripts/release-check.sh --strict                              # gate (/rs-release-check)
cargo semver-checks                                            # libraries
# edit Cargo.toml version + CHANGELOG.md (human-written, grouped, with BREAKING/MSRV notes)
git commit -am "chore(release): v1.4.0"
git tag -a v1.4.0 -m "v1.4.0"            # -s to sign
cargo package --list | less              # nothing secret or huge ships
cargo publish --dry-run                  # libraries
git push origin main v1.4.0              # branch AND tag
```
- Build release artefacts **from the tag** on a clean tree; the binary reports version + short SHA (rs-observability).
- Release notes = the CHANGELOG section (any host's release object, or only the tag).
- Pre-1.0 and 1.x rules: breaking → major (0.x: minor), additive → minor, fix → patch. `git log v1.3.0..HEAD --oneline` + `cargo semver-checks` decide, not intuition.

## Operate

| Situation | Do |
|---|---|
| bad commit on a shared branch | `git revert <sha>` (new commit) — never reset/force-push |
| find the culprit | `git bisect start; git bisect bad; git bisect good <tag>; git bisect run cargo test -q <name>` |
| who/why for a line | `git blame -w -C <file>`, then `git log -S'symbol' -- <file>` |
| hotfix | `git switch -c hotfix/1.4.1 v1.4.0`; fix; `chore(release): v1.4.1`; tag; merge/cherry-pick back to `main` with `cherry-pick -x` |
| lost work | `git reflog` — almost nothing is lost until gc (`guides/safety.md`) |
| repo got heavy | `git count-objects -vH`; find big blobs; LFS or `git filter-repo` **with the owner's consent** |
