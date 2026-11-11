# Using rs-skills with other coding agents

> What carries over: the **guidance** (skills, rules, guides, templates, helper scripts). What does not: Claude Code's **hooks** (routing, "before you build" gates, disk guards, Design Contract checks), **slash commands** and **agents**. `scripts/install-agents.sh` writes the gates into your `AGENTS.md` so the agent applies them by hand, and every script can be run directly.

## The short version

```bash
git clone https://github.com/bassem-elsodany/rs-skills.git ~/src/rs-skills
cd /path/to/your/project
~/src/rs-skills/scripts/install-agents.sh --agents-md          # project scope: ./.agents/skills + a managed block in ./AGENTS.md
# or for every project of your user:
~/src/rs-skills/scripts/install-agents.sh --scope user --agents-md ~/AGENTS.md
```
Restart (or reload skills in) the agent. Remove everything the script created with the same command plus `--uninstall`.

| Option | Meaning |
|---|---|
| `--scope project` (default) / `user` | `./.agents/skills` or `~/.agents/skills` |
| `--mode link` (default) / `copy` | symlink each skill into the clone (keep the clone in place) · copy the skills **and** the bundle support files (`scripts/`, `templates/`, `_meta/`, `index/`) into `<dest>/../rs-skills-bundle` (self-contained, cross-skill links between rule files do not resolve) |
| `--kiro` | also install into `.kiro/skills` (Kiro's location) |
| `--agents-md [FILE]` | write (or refresh) a managed block telling the agent the bundle root, how to read `${CLAUDE_PLUGIN_ROOT}`, and the five gates |
| `--dry-run` · `--uninstall` | preview · remove only what this script created |

The script never overwrites a path it did not create. Tested by the maintainer on macOS in throw-away directories: link and copy modes, project and user scope, dry run, repeated runs, refusal to overwrite a foreign folder, uninstall.

## Why not just copy the `skills/` folders?

Skill-folder installers (including the open `skills` CLI) copy each skill directory on its own. In rs-skills a skill's *own* files (`rules/`, `guides/`, `templates/`, its `scripts/`) come along, but the **bundle-level** files do not: `scripts/release-check.sh`, `contract-check.sh`, `port-check.py`, the shared `templates/`, and the links between skills. Skill text writes those paths as `${CLAUDE_PLUGIN_ROOT}/…`, which only Claude Code substitutes. The installer keeps the bundle root reachable and tells the agent what the variable means.

## Per tool — what the official documentation says

Facts below come from each vendor's documentation (read 2026-11-11). **Nothing here was run inside those agents** — only Node/Cursor happen to exist on the maintainer's machine and no agent was driven. Treat the tool-specific rows as "documented", not "tested", and check the linked docs when versions move.

| Tool | Where it discovers skills | Requirements and notes |
|---|---|---|
| **Codex** (CLI/app) | project `.agents/skills` (current directory up to the repo root), user `~/.agents/skills`, admin `/etc/codex/skills`, built-ins | `SKILL.md` needs `name` and `description`; new skills are picked up automatically (restart if one does not appear). Plugins are installed from the `/plugins` browser. **Not confirmed in OpenAI's docs:** `codex plugin marketplace add` and loading Claude marketplaces — other repositories report them; use the folder install above unless you have verified them |
| **Cursor** | project `.agents/skills`, `.cursor/skills`; user `~/.agents/skills`, `~/.cursor/skills`; also reads `.claude/skills` and `.codex/skills` | `name` must be lowercase/hyphens and **match the folder name**; invoke by typing `/` in Agent chat or let the agent choose. Cursor's own plugin import expects `.cursor-plugin/marketplace.json` (this repo does not ship one) — use the folder install |
| **Gemini CLI** | workspace `.gemini/skills` or `.agents/skills`; user `~/.gemini/skills` or `~/.agents/skills` | `gemini skills install <git-url-or-local-dir> [--path <subdir>] [--scope user\|workspace]`; in session `/skills list`, `/skills reload`. The docs note Gemini CLI was replaced by Antigravity CLI for some account types from 2026-06-18 — follow Google's current guidance for your account |
| **GitHub Copilot** (VS Code/JetBrains agent mode, CLI, cloud agent) | project `.github/skills`, `.claude/skills`, `.agents/skills`; personal `~/.copilot/skills`, `~/.agents/skills` | skills can also be installed with `gh skill` from a GitHub repository (see GitHub's docs for the exact syntax — not run here) |
| **OpenCode** | project `.opencode/skills`, `.claude/skills`, `.agents/skills`; global `~/.config/opencode/skills`, `~/.claude/skills`, `~/.agents/skills` | the model loads a skill through the `skill` tool by id (derived from the path); control with `skill` permissions in `opencode.json`; `@skill-id` loads one by hand |
| **Windsurf / Devin** | workspace `.devin/skills`, `.agents/skills`, legacy `.windsurf/skills`; global `~/.config/devin/skills`, `~/.agents/skills` | `/skill-name` invokes one; `AGENTS.md` (workspace root and parent directories) is treated as always-on rules — which is where the installer's managed block lands |
| **Kiro** | workspace `.kiro/skills`, global `~/.kiro/skills` | `description` ≤ 1024 characters (all rs-skills descriptions comply; `validate-plugin.py` enforces it); **custom agents do not load skills by default** — add `skill://.kiro/skills/*/SKILL.md` to the agent's `resources`; the UI import takes one skill *subdirectory* of a GitHub repo, not the repo root — use the installer with `--kiro` for all 62 |
| **skills CLI** (`npx skills`) | installs into `.agents/skills/<name>` (project) or globally with `-g`; reports support for dozens of agents | documented: `npx skills add <owner>/<repo> [--skill <name>] [-a <agent>] [-g]`, Node ≥ 22.20. **Not run by the maintainer** (the environment blocked executing downloaded code). It copies skill folders only, so you lose the bundle-level scripts — prefer `install-agents.sh` for the full set, or use the CLI for guidance-only |

### Portability rules this repository enforces

`scripts/validate-plugin.py` (CI) checks what every tool above needs: `name` equals the folder name, lowercase/digits/hyphens ≤ 64 characters, `description` present and ≤ 1024 characters, frontmatter on the first line. Claude-only frontmatter keys (`user-invocable`, `argument-hint`, `allowed-tools`, …) are ignored by other tools.

## What to do manually without hooks

| Claude Code hook | Do this instead |
|---|---|
| routing | start a Rust task by reading `rs-guide/SKILL.md` and `rs-router/SKILL.md` (the managed `AGENTS.md` block says so) |
| "before you build" gates | the five gates are in the managed block; the first is `<root>/skills/rs-reuse-first/scripts/sdk-scout.sh "<standard>" --github` |
| Design Contract check | `<root>/scripts/contract-check.sh <crate>` |
| disk guards | `<root>/skills/rs-cleanup/scripts/disk-guard.sh status` before builds; `cleanup.sh plan` after |
| pre-release | `<root>/scripts/release-check.sh <crate> --strict` |

`<root>` is the clone (link mode) or `…/rs-skills-bundle` (copy mode).
