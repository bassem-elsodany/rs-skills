# Layer 2 Skills Test Scenarios

> Layer 2: Design Choices

## rs-type-driven

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `newtype pattern` | rs-type-driven | wrapper, type safety |
| `how to use PhantomData` | rs-type-driven | marker, lifetime |
| `type state pattern` | rs-type-driven | state machine, compile-time |
| `zero-sized types ZST` | rs-type-driven | zero-sized, marker |

### Test Commands

```bash
claude -p "newtype pattern"
claude -p "how to use PhantomData"
```

---

## rs-domain-model

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `DDD in Rust` | rs-domain-model | aggregate, entity |
| `domain model design` | rs-domain-model | value object, repository |
| `domain modelling in Rust` | rs-domain-model | bounded context |
| `aggregate root` | rs-domain-model | invariant, consistency |

### Test Commands

```bash
claude -p "DDD in Rust"
claude -p "domain modelling in Rust"
```

---

## rs-performance

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `Rust performance optimisation` | rs-performance | profiling, bottleneck |
| `how to write a benchmark` | rs-performance | criterion, bench |
| `how to use criterion` | rs-performance | black_box, throughput |
| `zero copy` | rs-performance | Cow, bytes |

### Test Commands

```bash
claude -p "Rust performance optimisation"
claude -p "how to write a benchmark"
```

---

## rs-ecosystem

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `which crate do you recommend` | rs-ecosystem | crates.io, popularity |
| `choosing dependencies` | rs-ecosystem | maintenance, features |
| `Cargo.toml dependency management` | rs-ecosystem | version, workspace |
| `how to use feature flags` | rs-ecosystem | optional, cfg |

### Test Commands

```bash
claude -p "which crate do you recommend"
claude -p "how to use feature flags"
```

---

## rs-lifecycle

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `RAII pattern` | rs-lifecycle | Drop, scope |
| `implementing the Drop trait` | rs-lifecycle | destructor, cleanup |
| `resource drop order` | rs-lifecycle | drop order, field |
| `how to use scopeguard` | rs-lifecycle | defer, guard |

### Test Commands

```bash
claude -p "RAII pattern"
claude -p "implementing the Drop trait"
```

---

## rs-domain-error

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `retry strategy` | rs-domain-error | backoff, exponential |
| `circuit breaker implementation` | rs-domain-error | state, threshold |
| `error recovery patterns` | rs-domain-error | fallback, graceful |
| `classifying errors` | rs-domain-error | transient, permanent |

### Test Commands

```bash
claude -p "retry strategy"
claude -p "circuit breaker implementation"
```

---

## rs-mental-model

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `how to learn Rust` | rs-mental-model | ownership, mindset |
| `how to think in Rust` | rs-mental-model | borrow checker, mental model |
| `moving from Java to Rust` | rs-mental-model | comparison, transition |
| `why is Rust designed this way` | rs-mental-model | rationale, philosophy |

### Test Commands

```bash
claude -p "how to learn Rust"
claude -p "how to think in Rust"
```

---

## rs-anti-pattern

| Query | Expected Skill | Expected Elements |
|-------|----------------|-------------------|
| `common Rust mistakes` | rs-anti-pattern | pitfall, mistake |
| `code smell Rust` | rs-anti-pattern | refactor, improve |
| `Rust anti-patterns` | rs-anti-pattern | avoid, better |
| `clone overuse` | rs-anti-pattern | unnecessary, performance |

### Test Commands

```bash
claude -p "common Rust mistakes"
claude -p "clone overuse"
```

---

## Validation Checklist

- [ ] All Layer 2 skills trigger correctly
- [ ] Design-related queries route properly
- [ ] Chinese keywords work
- [ ] No conflicts with Layer 1 skills
