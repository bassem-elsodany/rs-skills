# git-no-secrets-no-artefacts

> Never commit credentials, build output or large binaries
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Once pushed, a secret is compromised even if the commit is later removed; build output bloats every clone forever.

## Do

- `.gitignore` from `templates/gitignore-rust` on day one; commit `.env.example`, never `.env`.
- Pre-commit scan: `git-check.sh staged` blocks AWS/GitHub/GitLab/Slack/Google tokens, private keys, `target/`, `*.pem`, files > 5 MiB.
- **If one slips through:** rotate/revoke it **first**; then, with the owner's consent, remove it from history (`git filter-repo`) and force-push; tell everyone to re-clone.
- Large files: Git LFS or an artefact store, not git.
- A line that legitimately contains a secret-shaped string (a detector's test pattern): add `rs-git:allow-secret` on that line.

## See Also

- [git-stage-deliberately](git-stage-deliberately.md)
