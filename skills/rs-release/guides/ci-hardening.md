# CI/CD hardening — pipelines are part of the supply chain

> **rs-release · guide** — GitHub Actions and GitLab CI (the same ideas apply elsewhere).

A CI job runs code (yours, your dependencies', and — on pull requests — a stranger's) with your tokens and often your cloud credentials. Treat the workflow file as security-critical code that gets reviewed like `unsafe`.

## 1. Triggers decide who can reach your secrets

| Trigger | Risk | Rule |
|---|---|---|
| `pull_request` (GitHub) / merge-request pipelines | runs the PR's code; forks get no secrets (good) | default choice for CI; keep secrets out of it |
| **`pull_request_target`**, `workflow_run`, `issue_comment`, `issues` | runs in the **base** context **with secrets**, triggered by outsiders | never check out or execute the PR head (`ref: ${{ github.event.pull_request.head.sha }}`) in these; if you must, do labelling/commenting only, with no build step |
| `push` to protected branches | trusted | release and publish jobs live here |
| `workflow_dispatch` | trusted users | validate inputs; they are strings |
| GitLab MR pipelines from forks | secrets are exposed if variables aren't protected | **protected variables** only on protected branches/tags; no secrets for fork MRs |

## 2. Least privilege

- GitHub: `permissions: { contents: read }` at the top of every workflow; add `id-token: write`, `packages: write`, `pull-requests: write` **per job** only where needed.
- Prefer **OIDC** federation (short-lived cloud credentials; GitLab `id_tokens`) over long-lived keys in secrets. For publishing to crates.io, use a scoped token (publish-only, per crate) stored as a protected/environment secret; crates.io also offers trusted publishing from GitHub Actions — check the current docs and prefer it.
- Release/publish jobs use **environments with required reviewers**; build jobs have no publish credentials.
- `actions/checkout` with `persist-credentials: false` unless a later step must push.

## 3. Injection into `run:` and scripts

`${{ github.event.pull_request.title }}`, branch names, commit messages, issue bodies are **attacker-controlled strings**. Interpolated into a shell `run:` they become code.

```yaml
# BAD
- run: echo "Building ${{ github.event.pull_request.title }}"
# GOOD: pass as data, quote it
- run: echo "Building $TITLE"
  env: { TITLE: "${{ github.event.pull_request.title }}" }
```
GitLab: don't put `$CI_MERGE_REQUEST_TITLE`/branch names into unquoted shell; quote and validate.

## 4. Pin and review third-party actions/images

- Pin actions to a **full commit SHA** (comment the version); tags and branches are mutable. Let Dependabot/Renovate bump them via reviewed PRs.
- Pin container images by **digest** for release jobs.
- Review what an action does with `GITHUB_TOKEN` and secrets; prefer a few well-known actions or plain `run:` steps with pinned tool versions (`cargo install --locked --version X`).
- Self-hosted runners: never for untrusted PRs (persistent state, network access); ephemeral runners only.

## 5. Caches and artifacts

- A cache written by an untrusted PR run can poison later trusted runs: separate cache keys for PR vs release builds, and don't restore PR-written caches in release jobs.
- Release artifacts are built **from the tag on a clean checkout**, checksummed, attested (build provenance/`cosign`), and never from a PR job (rs-git `git-tag-from-release-commit`).
- Upload logs/artifacts without secrets: mask secrets, avoid `set -x` around them, no `env` dumps.

## 6. Rust-specific

- `cargo build/test` run `build.rs` and proc-macros of every dependency (`dep-risk.py` lists them): untrusted PRs that change `Cargo.toml`/`build.rs` get a no-secrets runner (rs-security-review `sec-supply-chain-build-time-code`).
- `--locked` everywhere; `cargo deny` with `[sources]` restricted; `cargo audit`/OSV on a schedule.
- Don't `curl | sh` installers; use `cargo install --locked --version`, distro packages, or pinned actions with checksums.
- Cleanup: CI runners are ephemeral, but self-hosted or long-lived ones need `cargo sweep`/image prune (rs-cleanup).

## 7. AI agents in workflows (Claude Code Action, Codex, Gemini CLI, …)

An agent that reads issue/PR text and has tools or secrets is a prompt-injection target: attacker text reaches the prompt and the agent acts with the workflow's privileges. Audit these shapes:

| Vector | Shape | Fix |
|---|---|---|
| environment-variable intermediary | `env: BODY: ${{ github.event.issue.body }}` then the prompt reads `$BODY` — the prompt looks clean | treat every `env`/input derived from events as untrusted prompt content |
| direct expression in the prompt | `prompt: "Fix ${{ github.event.issue.body }}"` | don't interpolate event text into prompts; fetch through a sanitising step or give the agent read-only context |
| agent fetches data itself | `gh issue view`/API calls inside the agent's tools | the fetched text is untrusted too |
| `pull_request_target` + head checkout | the agent works on attacker files with your secrets | never; use `pull_request` and no secrets |
| error/log injection | agent reads CI logs containing attacker strings | don't feed raw logs back |
| shell expansion in "allowed" tools | `echo $(env)`-style abuse of an allow-listed command | allow-list exact commands, not families; no `Bash(*)`/wildcards |
| executing the agent's output | `eval`/`sh` of generated text | never execute model output without review |
| dangerous sandbox/permission flags | full-access/"yolo" modes, `--dangerously-skip-permissions` in CI | minimal tool set, read-only token, no secrets in the job, restrict who can trigger (`allowed users`) |

Principle: **an agent job gets the permissions of the least trusted person who can write to its input.**

## Checklist

- [ ] `permissions` minimal at workflow level; secrets only in jobs on trusted triggers
- [ ] no `pull_request_target`/`workflow_run` that builds untrusted code
- [ ] no `${{ event.* }}` inside `run:`/prompts; values via `env` and quoted
- [ ] actions pinned by SHA, images by digest (release jobs); updater PRs reviewed
- [ ] `persist-credentials: false`; OIDC over static keys; publish only from protected tags with environment approval
- [ ] separate caches for PR vs release; artifacts built from the tag
- [ ] `--locked`, `cargo deny` sources, scheduled `dep-risk.py`
