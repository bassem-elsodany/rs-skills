# api-config-is-contract

> Every option a configuration schema offers is a requirement — implement it; never narrow the schema to match missing code
> **rs-api-design · rule** — source: rs-skills, learned on the MCP Flex gateway policies (2026-11)

## Why It Matters

For a plugin, policy or service, the configuration schema (GCL, JSON Schema, OpenAPI, CRD,
`clap` args) **is** the public API. Users pick values from it; tooling renders forms from it.
An enum value the code silently does not handle is a broken promise, and removing it from the
schema is a breaking change that hides the bug instead of fixing it.

Real case: a JWT policy offered `RS256 … PS512` in its schema, but always verified with
RSA-256 — every non-RS256 setting rejected every token. Narrowing the schema was rejected by
the owner; the fix was to implement ES512 and PS* natively.

## Bad

```yaml
# schema offers it…
allowedJwtSigningMethods: { enum: [RS256, ES512, PS256] }
```
```rust
// …code ignores it
SignatureValidator::new(SigningAlgorithm::Rsa, SigningKeyLength::Len256, pem)
```

## Good

- One total mapping from every schema value to an implementation (`match` with no `_` arm),
  so a new schema value fails to compile until it is handled.
- When a dependency lacks a feature the schema offers, implement it (another crate, own code) and test it.
- A value that truly cannot be supported is removed only with the owner's agreement, a major
  version bump and a migration note — never as a quiet "fix".
- Audit: every schema property is read by the code, and every enum value appears in a `match`.

## See Also

- [api-non-exhaustive](api-non-exhaustive.md), [api-parse-dont-validate](api-parse-dont-validate.md)
- rs-review — the *config surface* step of the Security & contract pass
