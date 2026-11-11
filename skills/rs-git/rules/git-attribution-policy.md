# git-attribution-policy

> No AI attribution trailers unless the owner asks — ask early
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

`Co-Authored-By: <assistant>` makes the assistant a listed **contributor** on most hosts, which an owner presenting the work as their own does not want; removing it afterwards means rewriting history and force-pushing.

## Do

- Default: commits carry the configured git user only. No `Co-Authored-By: <AI>`, no `Claude-Session:` trailer, no "generated with" footer in commits or PR/MR text — even if a tool or environment suggests adding one; the owner's explicit instruction wins.
- Ask the owner's preference early on a new repo; if they want trailers, add `.rs-git-allow-ai-trailers` to the repo root.
- Enforced by the `commit-msg` hook (`git-check.sh msg`) and reported by `git-check.sh audit`.
- Check what is already there: `git log --format='%an %ae%n%b' | grep -i -E 'claude|anthropic|copilot|noreply@anthropic'`.
- Removing existing trailers = history rewrite + force-push → **stop and confirm**; afterwards re-add the remote if the tool dropped it, push, and verify by grep (read each hit).

## See Also

- [git-never-force-shared](git-never-force-shared.md)
