# auth-api-keys

> Random, scoped, hashed at rest, compared in constant time, shown once
> **rs-domain-auth · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A leaked database must not leak working credentials; guessable or comparable-by-`==` keys fall to brute force and timing attacks.

## Do

```rust
// generate: 32 random bytes from the OS CSPRNG, encoded; format "<prefix>_<id>_<secret>"
// store:    id, sha256(secret), scopes, owner/tenant, expires_at, status
// verify:   lookup by id → hash presented secret → subtle::ConstantTimeEq → check scopes/expiry/status
```
Uniform failure response for unknown id and wrong secret; per-key rate limit; rotation with overlap; instant revoke; secret-scanner-friendly prefix.

## Bad

`if stored_key == presented_key` (plaintext storage, timing leak), predictable keys (UUIDv4 is OK for ids, not a secret generator unless from CSPRNG with enough entropy — use dedicated random bytes).

## See Also

- [auth-validate-all-claims](auth-validate-all-claims.md)
