# git-conventional-messages

> Write messages as type(scope): summary, with the why in the body
> **rs-git · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

History is documentation. `fix` and `update` tell the next reader nothing; a typed, scoped subject lets tools build changelogs and lets people scan.

## Format

```
<type>(<scope>): <summary in the imperative, ≤72 chars>

<why: the problem, the choice, the trade-off — wrapped at ~72>

BREAKING CHANGE: <what consumers must change>      (when the public API breaks)
Refs: #123 | decisions/0004-mcp-sdk.md
```

- Types: `feat fix refactor perf test docs build ci chore style revert`.
- **Scope = the feature module** (`orders`, `auth`, `flex/audit-logger`) — it mirrors rs-structure, so history and code share a map.
- `BREAKING CHANGE:` footers feed semver and the CHANGELOG (rs-api-design).
- Lint: `scripts/git-check.sh msg <file>` (installed as `commit-msg` by `install-hooks`).

## Bad

`update auth.rs` · `fixes` · `WIP`

## Good

`fix(auth): reject JWTs whose kid is not in the JWKS` + a body that says what was observed and why this fix.

## See Also

- [git-atomic-green-commits](git-atomic-green-commits.md)
