# Publishing checklist (maintainers)

Nothing in this repository pushes anywhere. This is the manual, host-neutral path from "prepared" to "public". Replace *host* with GitHub, GitLab, Gitea, Codeberg, … — nothing below needs a host CLI.

## 0. State of preparation

| Item | Status |
|---|---|
| README (overview, install, commands, hooks, safety, limits), SECURITY, CONTRIBUTING, LICENSE (MIT), NOTICE (third-party + studied sources) | done |
| CI workflow for the bundle's own checks (`.github/workflows/ci.yml`), PR and issue templates | done (GitHub syntax; port to your host's CI if different) |
| No tracked caches/artefacts, no credentials, no personal strings (apart from the licence holder) | verified by `scripts/export-public.sh` |
| Name check | no crate named `rs-skills` on crates.io; search your host for collisions before creating the repo |
| History | **publish a fresh single commit** (`scripts/export-public.sh`); keep this repository as the private archive |

## 1. Decide, once

- **Repository name and owner** (renaming later breaks clone URLs and the `claude plugin marketplace add <owner>/<repo>` instruction in the README).
- **Public author identity** — name plus the host's noreply e-mail if you want to keep your inbox private. Pass them to the export script; do not rely on your global git config.
- **Maintainer contact** for `SECURITY.md` (private vulnerability reporting on the host, or an address) — also check `.claude-plugin/plugin.json` carries what you want public (`author`, optional `homepage`/`repository`).

## 1b. Validate against the official rules

```bash
claude plugin validate . --strict          # authoritative: manifests, agents, commands, hooks, skills layout
python3 -I scripts/validate-plugin.py .    # offline equivalent used in CI (+ --self-test)
```
Both must pass before exporting. At publish time also set `homepage` and `repository` in `.claude-plugin/plugin.json` (the host URL — they are not known until the repository exists; `homepage` must parse as a URL or the plugin fails to load). Installed plugins are pinned to the `version` string: bump `VERSION` (and regenerate with `scripts/gen-guide.py`) for every release.

**Optional — Anthropic's plugin directory:** the validator notes a missing icon (a square PNG or JPEG, 512–2048 px, < 2 MB, referenced by `icon` in `plugin.json` or at `.claude-plugin/icon.png`) and the directory reads `documentationUrl`, `supportUrl`, `privacyPolicyUrl`, `termsOfServiceUrl` from `plugin.json`. None are needed for a normal GitHub-hosted marketplace.

## 2. Build the clean copy

```bash
scripts/export-public.sh --out ~/dist/rs-skills --name "Your Name" --email "<id>+<user>@users.noreply.<host>" --repo bassem-elsodany/rs-skills
cd ~/dist/rs-skills && git log --stat | head      # one commit, your chosen identity, no remote
```
`--repo` replaces every `bassem-elsodany/rs-skills` placeholder in the README/docs with the real repository and sets `homepage`/`repository` in `plugin.json` (use `--host` for a non-GitHub host). The script refuses a dirty tree and a non-empty target, exports tracked files only, commits once, and verifies the result (hygiene audit, personal-string scan, bundle checks). Install `gitleaks` or `trufflehog` and scan as a last gate: `gitleaks git .` / `trufflehog git file://$PWD`.

## 3. Create the repository, push

```bash
# create an EMPTY repository on the host (no README/licence — they already exist), then:
cd ~/dist/rs-skills
git remote add origin <url>
git push -u origin main
```

## 4. On the host (cannot be done from git)

- Description (one line, e.g. "Rust skill bundle for coding agents: design → production") and topics: `rust`, `claude-code`, `agent-skills`, `ai-agents`, `code-review`, `rust-lang`, `developer-tools`.
- **Protect `main`**: no force-push, no deletion; optionally require the CI check and a pull request (decide the friction level deliberately — see `skills/rs-git/guides/publish-ready.md`).
- Enable secret scanning / push protection and private vulnerability reporting.
- Confirm CI is green once, then (and only then) add a status badge to the README.
- Release: tag `v1.6.1` (annotated) from the published commit, release notes = the `CHANGELOG.md` section.

## 5. Verify as a stranger

```bash
git clone <url> /tmp/rs-skills-check && cd /tmp/rs-skills-check
scripts/quality-check.sh && python3 -I scripts/gen-guide.py --check
claude plugin marketplace add /tmp/rs-skills-check && claude plugin install rs-skills@rs-skills   # in a throw-away profile
```
Then start a Claude Code session in a Rust project and check that the routing banner and `/rs-sdk-scout` work. Remove the temporary clone afterwards.

## 6. After publishing

- Future work: develop in the private archive or in the public repo — pick one source of truth, and keep `scripts/sync-local.sh` pointed at it.
- Watch for issues about guidance quality (CONTRIBUTING.md explains what a good report contains); keep `registry/standards.md` dated and re-verified.
