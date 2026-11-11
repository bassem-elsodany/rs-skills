---
name: rs-domain-auth
description: "Use when implementing or reviewing authentication and authorisation in Rust services — JWT validation, OAuth 2.0/2.1, OIDC, API keys, password hashing, sessions and cookies, token revocation, multi-tenant identity, MCP server authorisation, service-to-service auth. Triggers: authentication, authorization, authn, authz, login, JWT, JWKS, kid, jsonwebtoken, josekit, bearer token, OAuth, OAuth2, OIDC, OpenID Connect, PKCE, client credentials, refresh token, scope, audience, issuer, API key, password hash, argon2, bcrypt, session, cookie, SameSite, CSRF, RBAC, ABAC, ReBAC, tenant isolation, BOLA, IDOR, token revocation, mTLS, DPoP, MCP authorization, protected resource metadata, resource indicators, 401, 403"
user-invocable: false
---

# Authentication and Authorisation

> **Layer 3: Domain** · who is calling, and what may they do — decided once, enforced everywhere, failing closed
>
> Depth: `guides/jwt-validation.md` · `guides/oauth-oidc-mcp.md` · `guides/keys-passwords-sessions.md` · decisions → **rs-domain-policy** · libraries → **rs-reuse-first** (never hand-roll tokens or crypto)

## Core Question

**Can an attacker, or a bug, make this code say "yes" when it should say "no" — including when something fails?**

Authentication (**who**) and authorisation (**what may they do**) are different questions with different failure modes. Both default to *deny*.

## Thinking Prompt

1. **Who are the principals** — end users, services, agents/tools acting for users? What credential does each present (OIDC token, client-credentials token, API key, mTLS cert)?
2. **Where is identity verified** — once at the edge/gateway or in each service? Never trust a header you did not verify or that a client could have set.
3. **Where is authorisation decided** — one policy decision point (rs-domain-policy), enforced at **every** resource access (object-level), not only at the route?
4. **What happens on error** — missing key, expired JWKS cache, policy engine unreachable, malformed token: all deny (`err-fail-closed`).
5. **How are credentials revoked and rotated** — keys, signing keys (JWKS overlap), refresh tokens, API keys?
6. **What is logged** — decisions and principal ids yes; tokens, secrets, passwords never (`obs-no-sensitive-data`).

## Choosing the mechanism

| Situation | Use | Not |
|---|---|---|
| browser users | OIDC authorisation-code flow **with PKCE**, server-side session cookie (`HttpOnly; Secure; SameSite`) | tokens in `localStorage`, implicit flow |
| SPA/mobile calling APIs | authorisation code + PKCE; short-lived access token; refresh-token rotation | long-lived bearer tokens |
| service → service | OAuth client-credentials (JWT or opaque) or mTLS; audience-restricted tokens | shared static secrets in env files |
| third-party/automation access | API keys: random, hashed at rest, scoped, revocable | JWTs minted by hand |
| humans with passwords (if unavoidable) | `argon2id` via the `argon2` crate, in `spawn_blocking`; rate-limited login | MD5/SHA-1/plain SHA-256, bcrypt-only for new systems without a reason |
| MCP server/gateway | OAuth-protected resource (protected-resource metadata, resource indicators); see `guides/oauth-oidc-mcp.md` | accepting any token with a valid signature but wrong audience |
| fine-grained rules (roles, attributes, relationships) | a policy engine behind a PDP (rs-domain-policy) | scattered `if user.role == "admin"` |

## Rules

| Rule | Detail |
|---|---|
| **Pin algorithms; verify signature before reading claims** | never accept `alg: none`, never let the token choose HS vs RS (`auth-jwt-pin-algorithms`) |
| **Validate every claim that matters** | `iss`, `aud`, `exp`, `nbf`, signature key by `kid` from a trusted JWKS, plus tenant/scope (`auth-validate-all-claims`) |
| **Constant-time comparison** for secrets and MACs | `subtle::ConstantTimeEq`, not `==` |
| **Hash API keys; show once** | store a digest (SHA-256 is fine for 128+ bit random keys), a short public id for lookup (`auth-api-keys`) |
| **Passwords: argon2id, blocking-pool, rehash-on-login** | never log, never email, uniform "invalid credentials" |
| **Short access tokens, revocable refresh** | minutes, not days; deny-list/introspection for emergencies; rotate signing keys with JWKS overlap |
| **Object-level authorisation on every access** | BOLA/IDOR is the top API vulnerability: check the *resource*, not only the *route*; tenant comes from the verified token, never from the request body |
| **Uniform, minimal errors** | 401 (who are you) vs 403 (not allowed) vs 404 for hidden resources; same message/timing for unknown user vs wrong password; no claims or policy detail in bodies |
| **Secrets in typed wrappers** | `secrecy::SecretString`, `zeroize`; no `Debug` that prints tokens |
| **Don't write crypto** | `jsonwebtoken`/`josekit`, `oauth2`/`openidconnect`, `rustls`, RustCrypto/`ring`/`aws-lc-rs` (rs-reuse-first registry) |

## Trace

| Direction | Go to |
|---|---|
| ↑ Up | rs-domain-gateway (identity at the edge, properties between policies), rs-domain-policy (decisions), rs-domain-cloud-native (secrets, mTLS) |
| ↓ Down | rs-error-handling (`err-fail-closed`), rs-type-driven (`Authenticated<T>`/`Principal` types so unauthenticated data cannot reach handlers), rs-ports-adapters (`Authenticator` port with fakes), rs-concurrency (hashing off the async threads) |
| → Delivery | rs-testing (negative tests: expired, wrong aud, wrong alg, missing kid, tampered), rs-observability (decision logs), rs-review (security & contract pass) |

<!-- rules-index:start -->
## Rules (5)

Depth rules under `rules/` — open the one the question needs, not all of them.

**auth-**

- [`auth-api-keys`](rules/auth-api-keys.md) — Random, scoped, hashed at rest, compared in constant time, shown once
- [`auth-argon2id-blocking`](rules/auth-argon2id-blocking.md) — Hash passwords with argon2id on the blocking pool, rehash on login, rate-limit attempts
- [`auth-jwt-pin-algorithms`](rules/auth-jwt-pin-algorithms.md) — Verify JWTs against an allow-list of algorithms you chose, never the one the token claims
- [`auth-object-level-checks`](rules/auth-object-level-checks.md) — Authorise the resource, not just the route; take the tenant from the verified identity
- [`auth-validate-all-claims`](rules/auth-validate-all-claims.md) — A valid signature proves who signed it, not that the token is meant for you

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| Authorisation decisions, PDP/PEP, policy engines | rs-domain-policy |
| Fail-closed filters and gateways | rs-domain-gateway, rs-error-handling |
| HTTP middleware ordering | rs-domain-web (`guides/middleware.md`) |
| Picking the library | rs-reuse-first |
| Secrets in memory (zeroize/secrecy), constant-time comparison | rs-security-review (`sec-zeroize-secrets`, `sec-constant-time-compare`) |
| API/config misuse resistance | rs-api-design `guides/sharp-edges.md` |
