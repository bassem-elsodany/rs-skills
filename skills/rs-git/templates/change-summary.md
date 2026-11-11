## What and why
<One paragraph: the problem, the change, the user-visible effect. Link the decision record / issue.>

## Commits
<`git log --oneline <base>..HEAD` — each is one logical, green step.>

## How it was verified
- [ ] `cargo fmt --check` · `cargo clippy --all-targets -- -D warnings` · `cargo test`
- [ ] scenarios / integration tests: <names>   · manual check: <what you ran>
- [ ] `scripts/release-check.sh` (if release-relevant)

## Not touched (on purpose)
- `<path>` — similar issue, out of scope, tracked in <ref>

## Risks and rollback
- Risk: <…>   · Rollback: `git revert <sha>` / flag `<name>` off
- Breaking change? <no | yes — migration note + semver impact>

## Reviewer map
<Where to start reading, what is mechanical (renames/moves), what needs judgement.>
