# rel-ci-least-privilege

> CI gets the least privilege and the least trust: minimal token permissions, no secrets for untrusted code, pinned third-party actions
> **rs-release · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A workflow is code executed with your credentials. Over-broad `GITHUB_TOKEN` permissions, `pull_request_target` checkouts of PR code, `${{ }}` injection into `run:`, and mutable action tags are how repositories get compromised.

## Do

```yaml
permissions: { contents: read }                      # per job: widen only where needed
on: { pull_request: {} }                              # not pull_request_target for builds
steps:
  - uses: actions/checkout@<full-sha>  # v4.x
    with: { persist-credentials: false }
  - run: echo "title: $TITLE"
    env: { TITLE: "${{ github.event.pull_request.title }}" }   # data, not code
```
Publish only from protected tags with an approved environment; OIDC over static keys; pin images by digest in release jobs. Full list: `guides/ci-hardening.md`.

## See Also

- [rel-supply-chain-evidence](rel-supply-chain-evidence.md)
