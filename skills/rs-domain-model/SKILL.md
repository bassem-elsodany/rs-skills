---
name: rs-domain-model
description: "CRITICAL: Use for domain modeling. Triggers: domain model, DDD, domain-driven design, entity, value object, aggregate, repository pattern, business rules, validation, invariant"
user-invocable: false
---

# Domain Modeling

> **Layer 2: Design Choices**

## Core Question

**What is this concept's role in the domain?**

Before modeling in code, understand:
- Is it an Entity (identity matters) or Value Object (interchangeable)?
- What invariants must be maintained?
- Where are the aggregate boundaries?

---

## Domain Concept → Rust Pattern

| Domain Concept | Rust Pattern | Ownership Implication |
|----------------|--------------|----------------------|
| Entity | struct + Id | Owned, unique identity |
| Value Object | struct + Clone/Copy | Shareable, immutable |
| Aggregate Root | struct owns children | Clear ownership tree |
| Repository | trait (a **port**) | Abstracts persistence — and any other changeable product; adapters per product, contract-tested: **rs-ports-adapters** |
| Domain Event | enum | Captures state changes |
| Service | impl block / free fn | Stateless operations |

---

## Thinking Prompt

Before creating a domain type:

1. **What's the concept's identity?**
   - Needs unique identity → Entity (Id field)
   - Interchangeable by value → Value Object (Clone/Copy)

2. **What invariants must hold?**
   - Always valid → private fields + validated constructor
   - Transition rules → type state pattern

3. **Who owns this data?**
   - Single owner (parent) → owned field
   - Shared reference → Arc/Rc
   - Weak reference → Weak

---

## Trace Up ↑

To domain constraints (Layer 3):

```
"How should I model a Transaction?"
    ↑ Ask: What domain rules govern transactions?
    ↑ Check: rs-domain-fintech (audit, precision requirements)
    ↑ Check: Business stakeholders (what invariants?)
```

| Design Question | Trace To | Ask |
|-----------------|----------|-----|
| Entity vs Value Object | rs-domain-* | What makes two instances "the same"? |
| Aggregate boundaries | rs-domain-* | What must be consistent together? |
| Validation rules | rs-domain-* | What business rules apply? |

---

## Trace Down ↓

To implementation (Layer 1):

```
"Model as Entity"
    ↓ rs-ownership: Owned, unique
    ↓ rs-type-driven: Newtype for Id

"Model as Value Object"
    ↓ rs-ownership: Clone/Copy OK
    ↓ rs-type-driven: Validate at construction

"Model as Aggregate"
    ↓ rs-ownership: Parent owns children
    ↓ rs-resource: Consider Rc for shared within aggregate
```

---

## Quick Reference

| DDD Concept | Rust Pattern | Example |
|-------------|--------------|---------|
| Value Object | Newtype | `struct Email(String);` |
| Entity | Struct + ID | `struct User { id: UserId, ... }` |
| Aggregate | Module boundary | `mod order { ... }` |
| Repository | Trait (port) + adapters | `trait UserRepo { fn find(...) }` in the feature; `adapters/postgres/`, `adapters/memory/` (rs-ports-adapters) |
| Domain Event | Enum | `enum OrderEvent { Created, ... }` |

## Pattern Templates

### Value Object

```rust
struct Email(String);

impl Email {
    pub fn new(s: &str) -> Result<Self, ValidationError> {
        validate_email(s)?;
        Ok(Self(s.to_string()))
    }
}
```

### Entity

```rust
struct UserId(Uuid);

struct User {
    id: UserId,
    email: Email,
    // ... other fields
}

impl PartialEq for User {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id  // Identity equality
    }
}
```

### Aggregate

```rust
mod order {
    pub struct Order {
        id: OrderId,
        items: Vec<OrderItem>,  // Owned children
        // ...
    }

    impl Order {
        pub fn add_item(&mut self, item: OrderItem) {
            // Enforce aggregate invariants
        }
    }
}
```

---

## Common Mistakes

| Mistake | Why Wrong | Better |
|---------|-----------|--------|
| Primitive obsession | No type safety | Newtype wrappers |
| Public fields with invariants | Invariants violated | Private + accessor |
| Leaked aggregate internals | Broken encapsulation | Methods on root |
| String for semantic types | No validation | Validated newtype |

---

## Related Skills

| When | See |
|------|-----|
| Type-driven implementation | rs-type-driven |
| Ownership for aggregates | rs-ownership |
| Domain error handling | rs-domain-error |
| Specific domain rules | rs-domain-* |
| Repository / persistence boundary, swapping stores, anti-corruption layer | rs-ports-adapters |
| Which store: databases, caches, analytics | rs-domain-data |
