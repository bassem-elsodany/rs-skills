# auth-validate-all-claims

> A valid signature proves who signed it, not that the token is meant for you
> **rs-domain-auth · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Tokens from a legitimate issuer can be expired, issued for another service (confused deputy), or lack the scope the call needs. Signature-only validation accepts all of them.

## Do

Require, with exact matching: `iss`, `aud` (contains *this* service), `exp` (required), `nbf`, plus scope/role/tenant for the operation. Leeway ≤ 60 s. A missing required claim is an error, not a default. Take the tenant and subject from the **verified** token, never from the request.

## Bad

```rust
let claims: Claims = decode_without_validation(token)?;        // "just need the sub"
if claims.sub == req.user_id { /* … */ }
```

## See Also

- [auth-jwt-pin-algorithms](auth-jwt-pin-algorithms.md)
- [rs-error-handling err-fail-closed](../../rs-error-handling/rules/err-fail-closed.md)
