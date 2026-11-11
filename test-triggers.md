# Rust Skills Trigger Test Checklist

> Run these queries in a project that has rs-skills installed, and verify the correct skill is triggered.

## How to Test

1. Go to a Rust project directory with rs-skills plugin installed
2. Run each query below with `claude -p "query"`
3. Check if the expected skill is triggered (shown in Claude Code status line)

---

## Layer 1: Language Mechanics

## Ownership (rs-ownership)

| Query | Expected Skill |
|-------|----------------|
| `how do I fix E0382` | rs-ownership |
| `value moved after use` | rs-ownership |
| `borrowed value does not live long enough` | rs-ownership |
| `how to fix a borrow error` | rs-ownership |
| `lifetime annotation` | rs-ownership |
| `E0597 lifetime too short` | rs-ownership |

## Resource (rs-resource)

| Query | Expected Skill |
|-------|----------------|
| `Arc vs Rc difference` | rs-resource |
| `Box vs Rc vs Arc` | rs-resource |
| `choosing a smart pointer` | rs-resource |
| `shared ownership` | rs-resource |

## Mutability (rs-mutability)

| Query | Expected Skill |
|-------|----------------|
| `E0499 multiple mutable borrows` | rs-mutability |
| `E0502 borrow conflict` | rs-mutability |
| `E0596 cannot borrow as mutable` | rs-mutability |
| `Cell vs RefCell` | rs-mutability |
| `interior mutability` | rs-mutability |

## Zero-Cost (rs-traits)

| Query | Expected Skill |
|-------|----------------|
| `E0277 trait bound not satisfied` | rs-traits |
| `generic vs trait object` | rs-traits |
| `monomorphization` | rs-traits |
| `E0308 type mismatch` | rs-traits |
| `E0282 type annotations needed` | rs-traits |

## Type-Driven (rs-type-driven)

| Query | Expected Skill |
|-------|----------------|
| `newtype pattern` | rs-type-driven |
| `how to use PhantomData` | rs-type-driven |
| `type state pattern` | rs-type-driven |
| `zero-sized types ZST` | rs-type-driven |
| `marker trait` | rs-type-driven |

## Error Handling (rs-error-handling)

| Query | Expected Skill |
|-------|----------------|
| `when should I panic` | rs-error-handling |
| `Result vs Option` | rs-error-handling |
| `how to use thiserror` | rs-error-handling |
| `anyhow vs eyre` | rs-error-handling |
| `error propagation` | rs-error-handling |

## Concurrency (rs-concurrency)

| Query | Expected Skill |
|-------|----------------|
| `cannot be sent between threads` | rs-concurrency |
| `how to use async await` | rs-concurrency |
| `Send Sync trait` | rs-concurrency |
| `how to avoid deadlock` | rs-concurrency |
| `how to share data between threads` | rs-concurrency |

---

## Layer 2: Design Choices

## Domain Modeling (rs-domain-model)

| Query | Expected Skill |
|-------|----------------|
| `DDD in Rust` | rs-domain-model |
| `domain model design` | rs-domain-model |
| `aggregate root` | rs-domain-model |
| `value object vs entity` | rs-domain-model |
| `domain modelling in Rust` | rs-domain-model |

## Performance (rs-performance)

| Query | Expected Skill |
|-------|----------------|
| `Rust performance optimisation` | rs-performance |
| `how to write a benchmark` | rs-performance |
| `how to use criterion` | rs-performance |
| `cache locality` | rs-performance |
| `zero copy` | rs-performance |

## Ecosystem (rs-ecosystem)

| Query | Expected Skill |
|-------|----------------|
| `which crate do you recommend` | rs-ecosystem |
| `choosing dependencies` | rs-ecosystem |
| `compare crates` | rs-ecosystem |
| `Cargo.toml dependency management` | rs-ecosystem |
| `how to use feature flags` | rs-ecosystem |

## Lifecycle (rs-lifecycle)

| Query | Expected Skill |
|-------|----------------|
| `RAII pattern` | rs-lifecycle |
| `implementing the Drop trait` | rs-lifecycle |
| `resource drop order` | rs-lifecycle |
| `how to use scopeguard` | rs-lifecycle |
| `destructors in Rust` | rs-lifecycle |

## Domain Error (rs-domain-error)

| Query | Expected Skill |
|-------|----------------|
| `retry strategy` | rs-domain-error |
| `circuit breaker implementation` | rs-domain-error |
| `error recovery patterns` | rs-domain-error |
| `retry with backoff` | rs-domain-error |
| `classifying errors` | rs-domain-error |

## Mental Model (rs-mental-model)

| Query | Expected Skill |
|-------|----------------|
| `how to learn Rust` | rs-mental-model |
| `how to think in Rust` | rs-mental-model |
| `moving from Java to Rust` | rs-mental-model |
| `ownership mental model` | rs-mental-model |
| `why is Rust designed this way` | rs-mental-model |

## Anti-Pattern (rs-anti-pattern)

| Query | Expected Skill |
|-------|----------------|
| `common Rust mistakes` | rs-anti-pattern |
| `code smell Rust` | rs-anti-pattern |
| `Rust anti-patterns` | rs-anti-pattern |
| `what not to do in Rust` | rs-anti-pattern |
| `clone overuse` | rs-anti-pattern |

---

## Core Skills

## Unsafe (rs-unsafe)

| Query | Expected Skill |
|-------|----------------|
| `how to write unsafe code` | rs-unsafe |
| `FFI bindings` | rs-unsafe |
| `SAFETY comment` | rs-unsafe |
| `raw pointer` | rs-unsafe |
| `how to call C functions` | rs-unsafe |

## Version/Crate (rs-learner)

| Query | Expected Skill |
|-------|----------------|
| `latest tokio version` | rs-learner |
| `what's new in Rust 1.85` | rs-learner |
| `serde documentation` | rs-learner |
| `crate info` | rs-learner |

## Code Style (rs-style)

| Query | Expected Skill |
|-------|----------------|
| `Rust naming conventions` | rs-style |
| `clippy warning` | rs-style |
| `rustfmt configuration` | rs-style |
| `P.NAM.01` | rs-style |

## Router (rs-router)

| Query | Expected Skill |
|-------|----------------|
| `analyse the intent of this Rust question` | rs-router |
| `Rust question intent analysis` | rs-router |
| `what kind of Rust question is this` | rs-router |

## Layer 3: Domain Constraints

## Domains

| Query | Expected Skill |
|-------|----------------|
| `kubernetes operator in Rust` | rs-domain-cloud-native |
| `decimal precision for money` | rs-domain-fintech |
| `machine learning tensor in Rust` | rs-domain-ml |
| `IoT sensor` | rs-domain-iot |
| `axum web server` | rs-domain-web |
| `clap CLI argument` | rs-domain-cli |
| `no_std embedded` | rs-domain-embedded |

---

## Quick Test Commands

```bash
# Layer 1: Language Mechanics
claude -p "how do I fix E0382"           # rs-ownership
claude -p "E0499 multiple mutable borrows" # rs-mutability
claude -p "newtype pattern"              # rs-type-driven
claude -p "Send Sync trait"              # rs-concurrency

# Layer 2: Design Choices
claude -p "DDD in Rust"                  # rs-domain-model
claude -p "how to write a benchmark"              # rs-performance
claude -p "which crate do you recommend"                # rs-ecosystem
claude -p "RAII pattern"                 # rs-lifecycle
claude -p "circuit breaker implementation"          # rs-domain-error
claude -p "how to learn Rust"                   # rs-mental-model
claude -p "common Rust mistakes"                # rs-anti-pattern

# Core Skills
claude -p "how to write unsafe code"             # rs-unsafe
claude -p "latest tokio version"                # rs-learner
claude -p "Rust naming conventions"                 # rs-style

# Layer 3: Domains
claude -p "axum web server"              # rs-domain-web
claude -p "decimal precision for money"              # rs-domain-fintech
```

## Expected Behavior

When a skill triggers correctly, you should see:
1. The skill name in Claude Code's status line
2. Response content that matches the skill's expertise
3. References to patterns/rules from that skill

## Troubleshooting

If skills don't trigger:
1. Ensure rs-skills plugin is installed: `claude /plugins`
2. Check plugin path is correct
3. Verify SKILL.md files have `description:` field with keywords
4. Try more specific keywords from the skill description
