# auth-argon2id-blocking

> Hash passwords with argon2id on the blocking pool, rehash on login, rate-limit attempts
> **rs-domain-auth · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Fast hashes (SHA-*, MD5) are brute-forceable; memory-hard argon2id is designed for passwords. But it is deliberately heavy — run inline in an async handler it stalls the executor and lets a few logins starve everything.

## Do

- `argon2` crate, argon2id, parameters from current OWASP guidance tuned to ~100–500 ms; PHC string stored whole.
- `tokio::task::spawn_blocking` for hash/verify; bound concurrency with a `Semaphore`.
- On successful login, if stored params are weaker than current → rehash and update.
- Rate-limit per account and IP; uniform error for unknown user/wrong password; same cost path for both (verify against a dummy hash when the user is unknown).

## Bad

```rust
async fn login(...) { let ok = argon2.verify_password(pw, &hash).is_ok(); /* blocks the runtime thread for 200 ms */ }
```

## See Also

- [rs-concurrency async-spawn-blocking](../../rs-concurrency/rules/async-spawn-blocking.md)
