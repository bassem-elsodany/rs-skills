# API keys, passwords, sessions

> **rs-domain-auth · guide**

## API keys

| Step | Do |
|---|---|
| generate | ≥ 128 bits from the OS CSPRNG (`getrandom`/`rand::rngs::OsRng`); format `prefix_<id>_<secret>` (prefix names the product/env, id is a lookup key, secret is never stored) |
| store | `id`, **digest of the secret** (SHA-256 is adequate for high-entropy secrets — no need for a slow KDF), scopes, owner/tenant, created/expires/last-used, status |
| verify | look up by `id`, hash the presented secret, compare with `subtle::ConstantTimeEq`; same response/timing for unknown id and wrong secret |
| show | once, at creation; never retrievable |
| operate | scopes least-privilege, expiry, rotation overlap (two active keys), instant revoke, per-key rate limits, last-used for cleanup, alert on use from new networks |
| leaks | prefix lets secret scanners find them; revoke on detection |

## Passwords (avoid owning them if an IdP can)

```rust
// argon2 crate (RustCrypto): hash on a blocking thread, store the PHC string, verify with the same crate
// let hash = tokio::task::spawn_blocking(move || Argon2::default().hash_password(pw.as_bytes(), &salt).map(|h| h.to_string())).await??;
```
- **argon2id**, parameters per current OWASP guidance (memory-hard; tune to ~100–500 ms on your hardware), unique random salt (`SaltString::generate`), PHC string stored whole (it carries algorithm + params).
- Hash and verify in `spawn_blocking` (CPU/memory heavy — rs-concurrency `async-spawn-blocking`); cap concurrent hashes (semaphore) so logins cannot starve the runtime.
- **Rehash on login** when stored params are weaker than current; support migration from legacy hashes by wrapping.
- Login endpoint: rate limit per account and IP, lockout/back-off, uniform error, no user enumeration (also on password reset).
- Never log, echo, email or put passwords in URLs; wrap in `secrecy::SecretString`.

## Sessions and cookies (server-rendered/browser flows)

| Concern | Do |
|---|---|
| session id | ≥ 128-bit random, opaque, server-side store (`tower-sessions` with a store behind a port: memory/Redis/DB) |
| cookie | `HttpOnly; Secure; SameSite=Lax` (Strict for sensitive apps); `__Host-` prefix; narrow Path/Domain; sensible lifetime |
| lifecycle | rotate id on login and privilege change; idle + absolute timeouts; logout deletes server-side |
| CSRF | SameSite + CSRF token for state-changing requests (or require a custom header); never GET for mutations |
| fixation | never accept a session id from the URL or a pre-login cookie |

## Authorisation shapes (details: rs-domain-policy)

| Model | Fits | Pitfall |
|---|---|---|
| RBAC | stable roles | role explosion; roles are not resource checks |
| ABAC | rules over attributes (tenant, classification, time) | attribute sources must be trusted and available (else deny) |
| ReBAC (Zanzibar-style: OpenFGA, SpiceDB) | sharing, hierarchies, "owner of the folder" | consistency of the relation store; check latency |
| scopes (OAuth) | coarse API capability | not object-level — still check the resource |

Always: **object-level checks** (is *this* order the caller's?), **tenant isolation** from the verified token, **deny by default**.
