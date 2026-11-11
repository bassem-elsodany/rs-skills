# auth-jwt-pin-algorithms

> Verify JWTs against an allow-list of algorithms you chose, never the one the token claims
> **rs-domain-auth · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

If the verifier follows the token's `alg`, an attacker can send `none` (no signature) or switch RS256 to HS256 and sign with your *public* key as the HMAC secret. Both are classic, repeatedly exploited bugs.

## Do

- Configure the validator with the exact algorithm(s) for the issuer (`ES256`, `RS256`, …), one key type per algorithm.
- Select the key by `kid` from a trusted JWKS; ignore `jku`, `x5u` and embedded `jwk` headers.
- Verify the signature **before** deserialising claims.
- Test: `alg: none`, HS256-with-public-key, unknown `kid`, tampered payload — all must be 401.

## Bad

```rust
let header = jsonwebtoken::decode_header(token)?;
let validation = Validation::new(header.alg);          // algorithm chosen by the attacker
```

## See Also

- [auth-validate-all-claims](auth-validate-all-claims.md)
