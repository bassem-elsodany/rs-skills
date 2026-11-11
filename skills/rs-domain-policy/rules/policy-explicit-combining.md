# policy-explicit-combining

> Name the combining algorithm; never rely on rule order by accident
> **rs-domain-policy · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

When several rules apply, the result depends on how they combine. "First match wins" in an unordered `HashMap` or a `Vec` someone later sorted changes who gets access.

## Do

- The policy set declares `deny-overrides` (default for guardrails), `permit-overrides`, `first-applicable` (ordered, order documented) or `only-one-applicable`.
- Under `deny-overrides`, an `Indeterminate` rule must prevent a `Permit` (the failed rule might have denied).
- Test each algorithm with a table, including conflicting rules and failing rules.

## Bad

```rust
for rule in rules { if let Some(d) = rule.eval(&req) { return d; } }    // implicit first-applicable; reorder = new policy
```

## See Also

- [policy-default-deny](policy-default-deny.md)
