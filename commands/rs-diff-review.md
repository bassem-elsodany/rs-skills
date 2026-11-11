---
description: Differential review of a change set (branch, PR/MR, commit range): risk triage, removed checks and their history, blast radius, test gaps, reading order
allowed-tools: Bash(python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/rs-review/scripts/diff-review.py:*), Bash(git:*)
---

# /rs-diff-review

```
/rs-diff-review [--base <ref>] [--head <ref>] [--out file.md]
```

1. Run `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/rs-review/scripts/diff-review.py $ARGUMENTS` (default base = the remote default branch).
2. Read the HIGH files fully, in the printed **reading order**; for every red flag ask "what attack did the removed check stop?" (`git log -S`, `git blame`).
3. Triage candidates with Skill(rs-security-review) `guides/triage.md`; write cards into the day report (Skill(rs-review), `--diff`).
4. State coverage honestly: what was not read, which heuristics found nothing (not a clearance).
