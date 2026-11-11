# Publish-ready repository — the host-neutral part

> **rs-git · guide** — host-neutral publish-readiness checks; discoverability (stars, topics, social preview, community posts) is out of scope here.

Audit first, change second: read the repo and report in one paragraph what you found. Then, for a repository that others will clone or depend on:

| Check | Do | Verify by |
|---|---|---|
| README matches the code | read the code before describing a feature; rewrite in place, don't patch | run the quick-start commands from a fresh clone |
| LICENSE | ask the owner which licence — never default silently; copyright holder from `git config user.name`; mirror it in `Cargo.toml` (`license`) | `cargo deny check licenses` |
| `.gitignore` | `target/`, IDE/OS files, `.env*`, local tooling, planning docs | `git-check.sh audit` |
| Secrets | none tracked, none in history | `git-check.sh audit`; host's secret scanner |
| Builds from scratch | declared toolchain only, `--locked` | fresh clone → `cargo build --locked && cargo test` |
| No build-machine assumptions baked into artefacts | no `localhost` URLs, absolute paths, dev secrets compiled in; resolve at runtime from config/env | run the built artefact from a different host / container |
| CI exists and is green | one job per independently-buildable component; badge **only after** a green run | the host's run list |
| Default branch protected | at least: no force-push, no deletion. Optional steps up: required checks (gate PR merges only), required review (what actually stops direct pushes), and whether admins are bound — each is a different friction level; explain before applying | read the setting back, don't trust the command's exit code (GitHub: branch-protection API; GitLab: protected branches; Gitea/Bitbucket/Azure: equivalent settings) |
| Releases | semver tags + notes from the CHANGELOG; artefacts built from the tag; multi-arch / multi-platform when users run more than one | download and run the published artefact as a stranger would |
| Attribution | decide early whether AI trailers/bot identities may appear; default none | `git log --format='%an %ae%n%b'` shows no assistant identity |
| History | no giant blobs, no credentials, sensible messages | `git-check.sh audit` |

## If the history ever contained secrets — decide *before* going public

A repository that has **ever** held credentials, client data or customer-derived fixtures should not simply be flipped public: history rewriting (`filter-repo`, BFG) misses forks, clones, caches, CI logs/artifacts and release assets, and revocation does not remove leaked infrastructure names, internal URLs or patterns.

1. Ask the owner whether the project ever handled secrets or confidential material (including test fixtures derived from real data).
2. Scan the **full history** with a dedicated tool — `gitleaks git .` or `trufflehog git file://.` — rather than eyeballing; also check what else becomes public with the repo: CI logs and artifacts, old releases, issues/PRs, the wiki.
3. If anything real is found: **rotate/revoke first**, then prefer a **fresh repository** (copy the current tree, commit, archive the old repo privately) over rewriting history. A rewrite needs the owner's explicit yes and still leaves forks/caches (`guides/safety.md`).
4. After going public: enable the host's secret scanning and push protection, and keep `git-check.sh install-hooks` active.

## Files an outsider expects

`README.md` (what, install, one runnable example, how to contribute, licence), `LICENSE`, **`SECURITY.md`** (how to report a vulnerability — a contact or the host's private reporting; table stakes for security tooling), `CONTRIBUTING.md` when you want contributions, a changelog, CI. For Rust: API docs build (`cargo doc`, docs.rs for published crates) and are linked from the README/`Cargo.toml` `documentation`. Treat unchecked items as discussion prompts, not hard failures — a research prototype needs less than a flagship library. `git-check.sh audit --public` prints this checklist for the repo.

Container publishing reminders (registry-neutral): build multi-arch; check the package is *public* if intended; an unversioned `:latest` is not self-updating — compose needs `pull_policy: always` or an explicit pull.

For the discoverability half — README hero screenshot, topics, social preview, awesome-lists and community posting rules — use a dedicated launch skill.
