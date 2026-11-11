# Security policy

`rs-skills` is a set of Markdown skills, shell/Python helper scripts and Claude Code hooks. Some of them run commands on your machine (hooks, `cleanup.sh`, `git-check.sh install-hooks`, `sdk-scout.sh`, `dep-risk.py`), so security reports are welcome.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem. Report it privately through the host's private vulnerability reporting ("Report a vulnerability" under the repository's Security tab). Include the file, the command or prompt that triggers it, what you expected and what happened, and your platform.

You can expect an acknowledgement within a few days and a fix or a written assessment within 30 days. Credit is given in the changelog unless you prefer otherwise.

## What is in scope

- scripts or hooks that delete, overwrite or exfiltrate data, or run attacker-controlled input as code (shell/regex/JSON injection through prompts, file names, commit messages, crate names);
- hooks that can be made to deny or allow actions they should not (`rs-disk-preflight-hook.sh`, `rs-disk-stop-hook.sh`, the contract hooks);
- the destructive-command guard failing to ask before volume- or image-deleting Docker commands;
- network behaviour that sends more than public crate names, versions and search terms (`sdk-scout.sh`, `dep-risk.py`);
- secrets accidentally contained in the repository.

## Out of scope

- the content of the *guidance* (a rule you disagree with) — open a normal issue;
- vulnerabilities in third-party tools the skills mention (cargo-deny, cargo-fuzz, …) — report them upstream;
- findings that need an attacker who already controls your shell or your `~/.claude` directory.

## Hardening notes for users

- Read a hook before enabling it: `hooks/hooks.json` lists every hook and `.claude/hooks/*.sh` are short.
- Hooks can be switched off with environment variables (`RS_GATES=off`, `RS_DISK_GUARD=off`) — see the README.
- `cleanup.sh` is a dry run unless you say `apply`; it never removes named volumes and only removes containers/images labelled `rs-skills.created-by=agent` in its labelled tiers.
