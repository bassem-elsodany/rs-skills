# JWT validation checklist

> **rs-domain-auth · guide** — libraries: `jsonwebtoken` (common), `josekit` (full JOSE). Verify the API of the version you pin; the checklist is library-independent.

A JWT is *signed claims*, not a session. Accept it only after **all** of these pass, in this order:

| # | Check | Detail | Failure |
|---|---|---|---|
| 1 | **Size and shape** | reject > e.g. 8 KiB; exactly three base64url parts (JWS) | 401 |
| 2 | **Algorithm allow-list** | the verifier is configured with the algorithms *you* expect (e.g. `RS256`/`ES256`); never derive the algorithm from the token alone; reject `none`; never accept HS* where you hold an RSA *public* key (key-confusion) | 401 |
| 3 | **Key selection** | `kid` → key in a **trusted** JWKS (configured issuer URL, fetched over HTTPS, cached); ignore `jku`/`x5u`/embedded `jwk` headers from the token | 401 |
| 4 | **Signature** | verify before parsing claims into your types | 401 |
| 5 | **`iss`** | exact match of the configured issuer | 401 |
| 6 | **`aud`** | contains **this** service's audience/resource identifier (prevents token reuse across services) | 401 |
| 7 | **`exp` / `nbf` / `iat`** | `exp` required; small leeway (≤ 60 s) for clock skew | 401 |
| 8 | **Scope / roles / tenant** | required scope present; tenant claim from the token, validated against the resource | 403 |
| 9 | **Replay / revocation** (when the risk warrants) | `jti` deny-list with TTL = token lifetime; introspection for opaque tokens; token binding (mTLS/DPoP) for high-value APIs | 401 |

## JWKS handling

- Cache keys (respect `Cache-Control`, default ~10 min); on **unknown `kid`** refresh once, rate-limited (e.g. at most once per minute) so a forged `kid` cannot make you hammer the issuer.
- Keep old keys for the overlap period; support key rotation without restart.
- JWKS fetch failure with a warm cache → keep using the cache until a hard maximum age, then deny (fail closed, `err-fail-closed`); with a cold cache → deny.
- The JWKS client, cache and refresh policy live in the adapter behind an `Authenticator` port (rs-ports-adapters).

## Shape of the code

```rust
// library-independent structure; use your JWT crate's validation object for steps 2-7
pub struct Principal { pub subject: String, pub tenant: String, pub scopes: Vec<String> }

pub trait Authenticator: Send + Sync {
    fn authenticate(&self, bearer: &str) -> impl Future<Output = Result<Principal, AuthError>> + Send;
}
#[derive(Debug, thiserror::Error)]
pub enum AuthError { #[error("unauthenticated")] Unauthenticated, #[error("forbidden")] Forbidden, #[error("auth backend unavailable")] Unavailable }
// Unavailable maps to deny (503/401 as policy dictates) — never to "allow because we could not check"
```
Handlers take a `Principal` extractor; there is no code path that reaches business logic without one.

## Tests that must exist

expired · not-yet-valid · wrong issuer · wrong audience · wrong algorithm (`none`, HS256 with the public key as secret) · unknown `kid` · tampered payload · missing `exp` · oversized token · JWKS unreachable (cold and warm) · valid token with missing scope → 403 not 401.
