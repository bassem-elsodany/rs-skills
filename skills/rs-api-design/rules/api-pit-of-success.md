# api-pit-of-success

> Make the secure use the shortest path: safe defaults, no sentinel values, types that force the right order
> **rs-api-design · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Callers copy the first example and take defaults. If correctness depends on remembering a rule, someone will forget it — and if a zero, an empty value or a typo silently disables a protection, it will ship.

## Do

```rust
pub struct Timeout(Duration);
impl Timeout { pub fn new(d: Duration) -> Result<Self, ConfigError> { if d.is_zero() { Err(ConfigError::ZeroTimeout) } else { Ok(Self(d)) } } }

#[derive(Deserialize)] #[serde(deny_unknown_fields)]
pub struct ClientConfig { pub timeout: Timeout, pub tls: TlsMode }   // enum, no `verify: bool`

pub enum TlsMode { Verify, #[doc = "Disables certificate checks. Tests only."] DangerouslySkipVerification }
```
- Defaults = safest values; "off" switches have alarming names and never appear in examples.
- Reject `0`/empty/`None` where they would mean "unlimited/unchecked"; validate combinations in `build()`.
- Newtypes for keys, nonces, ids; type state for verified/unverified.
- Review with `guides/sharp-edges.md` before publishing an API or config schema.

## Bad

`fn verify(token: &str, alg: &str, verify_signature: bool)` — three ways to be insecure in one signature.

## See Also

- [api-config-is-contract](api-config-is-contract.md)
- [rs-type-driven](../../rs-type-driven/SKILL.md)
