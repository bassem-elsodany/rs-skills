# Rust Skills Tests

## Overview

This directory contains test scenarios for validating rs-skills functionality.

## Directory Structure

```
tests/
├── README.md
├── scenarios/              # Test scenarios by category
│   ├── ownership.md        # ownership/resource tests
│   ├── layer2-skills.md    # m05, L2 skills design skills
│   ├── domain-skills.md    # Layer 3 domain skills
│   ├── unsafe.md           # rs-unsafe tests
│   ├── routing.md          # rs-router tests
│   └── agents.md           # Agent integration tests
│
├── pressure-scenarios/     # Edge case tests
│   ├── rs-ownership/
│   ├── rs-error-handling/
│   └── rs-concurrency/
│
└── validation/             # Validation scripts
    └── validate-skills.sh
```

## Quick Test Reference

See `test-triggers.md` in project root for complete trigger test checklist.

## Running Tests

### Manual Testing

Use the test scenarios as prompts:

```bash
# Layer 1: Language Mechanics
claude -p "how do I fix E0382"           # rs-ownership
claude -p "E0499 multiple mutable borrows" # rs-mutability
claude -p "newtype pattern"              # rs-type-driven
claude -p "Send Sync trait"              # rs-concurrency

# Layer 2: Design Choices
claude -p "DDD in Rust"                  # rs-domain-model
claude -p "how do I write a benchmark"              # rs-performance
claude -p "RAII pattern"                 # rs-lifecycle
claude -p "common Rust mistakes"                # rs-anti-pattern

# Layer 3: Domain Constraints
claude -p "axum web server"              # rs-domain-web
claude -p "decimal precision for money"              # rs-domain-fintech
claude -p "no_std embedded"              # rs-domain-embedded

# Core Skills
claude -p "how do I write unsafe code"             # rs-unsafe
claude -p "latest tokio version"                # rs-learner
```

### Validation Script

```bash
./tests/validation/validate-skills.sh
```

## Test Categories

### 1. Layer 1 - Language Mechanics (L1 skills)
- Ownership, borrowing, lifetimes
- Resource management
- Mutability
- Zero-cost abstraction
- Type-driven design
- Error handling
- Concurrency

### 2. Layer 2 - Design Choices (L2 skills)
- Domain modeling
- Performance optimization
- Ecosystem integration
- Resource lifecycle
- Domain error patterns
- Mental models
- Anti-patterns

### 3. Layer 3 - Domain Constraints
- rs-domain-fintech
- rs-domain-web
- rs-domain-cli
- rs-domain-embedded
- rs-domain-cloud-native
- rs-domain-iot
- rs-domain-ml

### 4. Core Skills
- rs-router
- rs-learner
- rs-style
- rs-unsafe

### 5. Agent Integration
- crate-researcher
- rs-changelog
- docs-researcher
- clippy-researcher

## Coverage Summary

| Category | Skills | Tested |
|----------|--------|--------|
| Layer 1 | 7 | 7/7 |
| Layer 2 | 7 | 7/7 |
| Layer 3 | 7 | 7/7 |
| Core | 4 | 4/4 |
| **Total** | **25** | **25/25** |

## Adding New Tests

1. Create scenario file in `tests/scenarios/`
2. Include:
   - Test prompt
   - Expected skill trigger
   - Expected response elements
3. Update `test-triggers.md` in project root
4. Update validation script if needed
