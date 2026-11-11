# policy-default-deny

> Only an explicit Permit passes; NotApplicable and Indeterminate deny
> **rs-domain-policy · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Two-valued `bool` decisions force a choice on "no rule matched" and "the engine failed" — and the convenient choice is `true`. Four-valued decisions make the distinction visible; a single `enforce` function makes the answer deny.

## Do

```rust
pub fn enforce(d: &Decision) -> bool { matches!(d, Decision::Permit) }     // nothing else passes
```
- `Authorizer::decide` is total: any error, timeout or missing attribute becomes `Decision::Indeterminate(reason)`.
- Test: empty policy set, missing attribute, engine timeout → denied.

## Bad

```rust
let allowed = engine.evaluate(&req).unwrap_or(true);       // fail-open
```

## See Also

- [policy-explicit-combining](policy-explicit-combining.md)
- [rs-error-handling err-fail-closed](../../rs-error-handling/rules/err-fail-closed.md)
