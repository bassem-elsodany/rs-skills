# Release checklist — vX.Y.Z

- [ ] Working tree clean, on the release base (`main` or `release/x.y`), up to date (`git pull --ff-only`)
- [ ] `/rs-release-check --strict` green (fmt, clippy, tests MSRV+stable, docs, deny, contracts, structure)
- [ ] `cargo semver-checks` clean for libraries; version bump matches (breaking → major; 0.x minor)
- [ ] CHANGELOG entry written for humans (Added / Changed / Fixed / Deprecated / Removed / Security; BREAKING and MSRV notes)
- [ ] `chore(release): vX.Y.Z` commit contains only version + changelog (+ lockfile)
- [ ] `git tag -a vX.Y.Z -m "vX.Y.Z"` (signed if the team signs); tag points at that commit
- [ ] `cargo package --list` shows nothing secret/huge; `cargo publish --dry-run` ok
- [ ] artefacts built from the tag on a clean tree; `--version` prints version + SHA
- [ ] `git push origin <branch> vX.Y.Z`; host release object from the changelog (optional)
- [ ] fresh-environment install/run of the published artefact works
- [ ] `scripts/git-check.sh audit` has no errors; `rs-cleanup` report done (worktrees, images, target/)
