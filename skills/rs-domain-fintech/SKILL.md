---
name: rs-domain-fintech
description: "Use when building fintech apps. Keywords: fintech, trading, decimal, currency, financial, money, transaction, ledger, payment, exchange rate, precision, rounding, accounting"
user-invocable: false
---

# FinTech Domain

> **Layer 3: Domain Constraints**

## Domain Constraints → Design Implications

| Domain Rule | Design Constraint | Rust Implication |
|-------------|-------------------|------------------|
| Audit trail | Immutable records | Arc<T>, no mutation |
| Precision | No floating point | rust_decimal |
| Consistency | Transaction boundaries | Clear ownership |
| Compliance | Complete logging | Structured tracing |
| Reproducibility | Deterministic execution | No race conditions |

---

## Critical Constraints

### Financial Precision

```
RULE: Never use f64 for money
WHY: Floating point loses precision
RUST: Use rust_decimal::Decimal
```

### Audit Requirements

```
RULE: All transactions must be immutable and traceable
WHY: Regulatory compliance, dispute resolution
RUST: Arc<T> for sharing, event sourcing pattern
```

### Consistency

```
RULE: Money can't disappear or appear
WHY: Double-entry accounting principles
RUST: Transaction types with validated totals
```

---

## Trace Down ↓

From constraints to design (Layer 2):

```
"Need immutable transaction records"
    ↓ rs-domain-model: Model as Value Objects
    ↓ rs-ownership: Use Arc for shared immutable data

"Need precise decimal math"
    ↓ rs-type-driven: Newtype for Currency/Amount
    ↓ rust_decimal: Use Decimal type

"Need transaction boundaries"
    ↓ rs-lifecycle: RAII for transaction scope
    ↓ rs-domain-model: Aggregate boundaries
```

---

## Key Crates

| Purpose | Crate |
|---------|-------|
| Decimal math | rust_decimal |
| Date/time | chrono, time |
| UUID | uuid |
| Serialization | serde |
| Validation | validator |

## Design Patterns

| Pattern | Purpose | Implementation |
|---------|---------|----------------|
| Currency newtype | Type safety | `struct Amount(Decimal);` |
| Transaction | Atomic operations | Event sourcing |
| Audit log | Traceability | Structured logging with trace IDs |
| Ledger | Double-entry | Debit/credit balance |

## Code Pattern: Currency Type

```rust
use rust_decimal::Decimal;

#[derive(Clone, Debug, PartialEq)]
pub struct Amount {
    value: Decimal,
    currency: Currency,
}

impl Amount {
    pub fn new(value: Decimal, currency: Currency) -> Self {
        Self { value, currency }
    }

    pub fn add(&self, other: &Amount) -> Result<Amount, CurrencyMismatch> {
        if self.currency != other.currency {
            return Err(CurrencyMismatch);
        }
        Ok(Amount::new(self.value + other.value, self.currency))
    }
}
```

---

## Common Mistakes

| Mistake | Domain Violation | Fix |
|---------|-----------------|-----|
| Using f64 | Precision loss | rust_decimal |
| Mutable transaction | Audit trail broken | Immutable + events |
| String for amount | No validation | Validated newtype |
| Silent overflow | Money disappears | Checked arithmetic |

---

## Trace to Layer 1

| Constraint | Layer 2 Pattern | Layer 1 Implementation |
|------------|-----------------|------------------------|
| Immutable records | Event sourcing | Arc<T>, Clone |
| Transaction scope | Aggregate | Owned children |
| Precision | Value Object | rust_decimal newtype |
| Thread-safe sharing | Shared immutable | Arc (not Rc) |

---

## Related Skills

| When | See |
|------|-----|
| Value Object design | rs-domain-model |
| Ownership for immutable | rs-ownership |
| Arc for sharing | rs-resource |
| Error handling | rs-domain-error |
| Idempotency, outbox, sagas, ledgers across services | rs-domain-distributed |
| Databases and transactions | rs-domain-data |
