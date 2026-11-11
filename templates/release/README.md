# Release templates (rs-release)

| File | Copy to | Purpose |
|---|---|---|
| `github-ci.yml` | `.github/workflows/ci.yml` | fmt · clippy · tests on MSRV+stable · docs · cargo-deny · semver-checks · Design Contract + structure checks |
| `gitlab-ci.yml` | `.gitlab-ci.yml` | the same gates for GitLab |
| `deny.toml` | repo root | licences, advisories, bans, sources policy |
| `Dockerfile` | repo root (replace `APP_NAME`) | cargo-chef cached build → distroless non-root runtime |
| `release-profile.toml` | append to `Cargo.toml` | LTO, codegen-units, strip, debug line tables |
| `CHANGELOG.md` | repo root | Keep a Changelog skeleton with BREAKING/MSRV conventions |

`scripts/new-crate.sh` copies the relevant ones; `scripts/release-check.sh` verifies the result.
