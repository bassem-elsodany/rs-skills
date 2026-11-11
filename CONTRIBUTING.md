# Contributing to rs-skills

Thanks for helping. The bundle is a product refined by real use: if a skill gave weak guidance, a script misreported, or a hook got in the way, fixing it is the most valuable contribution.

## Ground rules

- **English only**, one idea per file, tables over prose, every claim checkable. Code in rules and templates **must compile** (`checks/check.sh` verifies the rule examples; for new Rust snippets, build them in a scratch crate and say so).
- **Original text only.** Don't copy third-party text unless its licence allows it; where content is reused under MIT/MPL, keep its provenance line and list it in `NOTICE.md`.
- **House format** for a skill: `SKILL.md` (frontmatter with trigger-rich `description`, *Core Question*, *Thinking Prompt*, decision tables, *Trace*, generated rules index, *Related Skills*) plus `rules/`, `guides/`, `templates/`, `scripts/` as needed. Start from `skills/rs-skill-creator/` or copy a small existing skill.
- **Rules**: `# id`, one-line `> summary`, `> **skill · rule** — source: …`, then *Why It Matters · Bad · Good · See Also*. Ids are unique across the bundle; regenerate indexes with `python3 -I scripts/gen-rule-index.py`.
- **Classify new skills** in `scripts/gen-guide.py` and regenerate the catalogue: `python3 -I scripts/gen-guide.py`.
- **Scripts** must work with macOS bash 3.2 and Linux bash, avoid GNU-only flags, default to read-only/dry-run, and never delete what they did not create.
- **No AI attribution trailers** in commits unless the maintainer asks (`skills/rs-git`); use conventional commits (`feat(rs-security-review): …`).

## Authoring standards (what well-maintained skill repositories agree on)

These follow Anthropic's plugin and skill documentation (`claude plugin validate --strict` is the authoritative check). `scripts/validate-plugin.py` enforces what it can offline; CI runs it.

- **Frontmatter first.** `SKILL.md` starts with `---`; `name` equals the directory (kebab-case, ≤ 64 chars, nothing reserved such as `claude`/`anthropic`); `description` is **third person, states the key use case first, and includes the trigger words** ("Use when …") — descriptions are always in context and truncated at 1,536 characters together with `when_to_use`; no angle brackets. Only recognised keys.
- **Value-add over reference dumps.** Teach *when and how to decide* and *why*, with the trade-off; don't paste specs. Anti-patterns come with the reason they are wrong.
- **Under 500 lines per `SKILL.md`; progressive disclosure.** Quick start and decision tables first, detail in `rules/`, `guides/`, `templates/`. SKILL.md links to depth files; depth files should not be required reading chains (cross-reference "See also" links are fine).
- **Security and audit skills include a "Rationalizations to reject" table** — the shortcuts that cause missed findings. Prescriptiveness matches risk: strict for fragile tasks, flexible for exploratory ones.
- **Paths.** Never hard-code absolute paths. In `SKILL.md` and commands use `${CLAUDE_PLUGIN_ROOT}/…` (bundle files) or `${CLAUDE_SKILL_DIR}/…` (the skill's own files) — they are substituted when the skill loads; bare `skills/…/scripts/…` only resolves from the repository root. Use forward slashes.
- **Agents** (`agents/*.md`): frontmatter with `name`, a *dispatch-oriented* `description` (when the coordinator should use it), `tools:` as a YAML **list** (agents ignore `allowed-tools`), and a `model`. Every `.md` in `agents/` is loaded as an agent — keep helper documents elsewhere (`_meta/agent-support/`).
- **Commands** (`commands/*.md`): frontmatter with `description` and `allowed-tools` scoped to what the command runs.
- **Hooks**: quote `"${CLAUDE_PLUGIN_ROOT}"`; the script must exit immediately for non-matching input (PreToolUse/PostToolUse hooks run on every Bash call — prefer shell string matching to a Python start-up), be executable, and say in its header what it can deny or ask. Document env switches in the README.
- **Manifests**: don't hand-list components that the default directory scan already finds; `version` must equal `VERSION` (installed plugins are pinned to the version string, so bump it for every release); no `CLAUDE.md` at the plugin root (it is not loaded) — operating instructions live in `AGENTS.md`, imported by `.claude/CLAUDE.md`.
- **Scripts**: macOS bash 3.2 + Linux, read-only or dry-run by default, never delete what they did not create, document network use.

## Before you open a pull request

```bash
scripts/quality-check.sh && scripts/rules-check.sh && scripts/coverage-check.sh \
  && scripts/patterns-check.sh && python3 -I scripts/gen-guide.py --check \
  && python3 -I scripts/validate-plugin.py --self-test && python3 -I scripts/validate-plugin.py . \
  && python3 tests/hook-matcher-test.py
```
Diagrams in the README are Mermaid: edit the sources in `docs/diagrams/*.mmd`, paste them into the README, and run `python3 -I scripts/check-diagrams.py` (needs `mmdc`: `npm i -g @mermaid-js/mermaid-cli`) — it renders every block and checks the sources match. If you have the Claude Code CLI: `claude plugin validate . --strict` (must say *Validation passed*; the "no icon" and "marketplace folder" notes are directory-listing information, not failures).
Also run the check that matches what you touched (`scripts/contract-check.sh`, `skills/rs-git/scripts/git-check.sh audit .`, a scratch-crate run of the scripts). Update `CHANGELOG.md` (and `VERSION` for user-visible changes — `metadata.json` is generated by `gen-guide.py`).

## Proposing a new skill

Open an issue first with: the situation an agent keeps getting wrong, a real example, what the skill would say, which existing skill is closest, and why a rule/guide in that skill is not enough. Skills that duplicate an existing one, or that only restate the Rust book, will be asked to fold into the closest skill.

## Reporting problems

Include: the prompt or command, the skill/script involved, what you expected, what happened, your OS and `bash --version`/`python3 --version`. Security problems: see [SECURITY.md](SECURITY.md).


By contributing you agree your contribution is licensed under the repository's MIT licence (the `rs-patterns` pages keep MPL-2.0).
