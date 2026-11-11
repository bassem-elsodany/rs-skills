# git-host-neutral

> Use plain git; reach for the host's CLI only when the remote matches
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Not every repo is on GitHub, and some have no remote. Instructions that require `gh` fail on GitLab, Gerrit or a bare SSH repository.

## Do

- `git remote -v` first; none is valid — local history, tags and hooks still apply.
- Core flows (branch, commit, rebase, tag, bisect, format-patch) use git only.
- Host CLIs (`gh`, `glab`, `tea`, `az repos`) only when `origin` points at that host *and* the CLI is installed and authenticated; otherwise give the user the text to paste (`templates/change-summary.md`) or a patch (`git format-patch`).
- Hand-offs: PR (GitHub), MR (GitLab), change (Gerrit — keep the `Change-Id` footer), patch email — same content, different button.
- Never embed a host name, org or URL in scripts or docs that are meant to be reused.

## See Also

- [guides/publish-ready.md](../guides/publish-ready.md)
