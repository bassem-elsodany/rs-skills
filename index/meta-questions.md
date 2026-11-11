# Core questions index

Every `rs-*` reasoning skill is organised around one core question. Ask it
before answering; the skill's Thinking Prompt expands it.

## L1 Mechanics

| Skill | Core question | Thinking direction |
|---|---|---|
| rs-ownership | Who owns this memory, and when is it freed? | ownership, borrowing, lifetimes |
| rs-resource | How do I balance determinism and flexibility? | Box, Rc, Arc, Cell, RefCell |
| rs-mutability | Where are the immutability boundaries? | mut, interior mutability |
| rs-traits | What can the compiler optimise away? | generics, traits, dispatch |
| rs-type-driven | How do types encode constraints? | type state, newtype, builder |
| rs-error-handling | Is this failure expected or exceptional? | Result, panic, recovery |
| rs-concurrency | How is concurrency safety proven at compile time? | Send, Sync, async |
| rs-unsafe | Is this unsafe block sound, and is the contract documented? | soundness, FFI |

## L2 Design

| Skill | Core question | Thinking direction |
|---|---|---|
| rs-domain-model | How do domain rules become types? | DDD |
| rs-patterns | Which proven pattern fits, and what does it trade away? | idioms, patterns, anti-patterns |
| rs-structure | Where does this code live, who may see it, and what happens when it grows? | module layout, splitting, visibility |
| rs-api-design | Will this public API still be right in two years? | compatibility, ergonomics |
| rs-performance | Where is the bottleneck in this domain? | profiling, optimisation |
| rs-ecosystem | How does this integrate with existing systems? | crates, interop |
| rs-lifecycle | What are the domain-specific resource patterns? | RAII, pools |
| rs-domain-error | What are the domain's failure and recovery strategies? | retry, fallback |
| rs-mental-model | What is the correct mental model? | learning |
| rs-anti-pattern | Is this pattern hiding a design problem? | review |

## L3 Domain

| Skill | Core question |
|---|---|
| rs-domain-* | Which constraints of this domain cannot be violated, and what do they imply for the design? |

## L4 Delivery

| Skill | Core question |
|---|---|
| rs-style | Does the code read like idiomatic Rust to the next maintainer? |
| rs-testing | How will we know it is correct — now and after the next change? |
| rs-observability | When it misbehaves in production, what will we see? |
| rs-release | Can this be released, audited and rolled back without surprises? |
| rs-design-contract | Will the next agent understand the design this file follows? |

## Quick reference by problem type

**Compiler errors** — E0382 / E0597 → rs-ownership · E0277 (Send/Sync) → rs-concurrency · E0596 → rs-mutability

**Design questions** — "which smart pointer?" → rs-resource · "generics or trait objects?" → rs-traits · "error strategy?" → rs-error-handling · "thread safety?" → rs-concurrency · "FFI design?" → rs-unsafe · "which pattern?" → rs-patterns

**Learning** — "how to think about X?" → rs-mental-model · "common mistakes?" → rs-anti-pattern

**By domain** — web → rs-error-handling, rs-concurrency, rs-ecosystem, rs-domain-web · systems → rs-ownership, rs-concurrency, rs-unsafe · embedded → rs-ownership, rs-unsafe, rs-performance, rs-domain-embedded · data → rs-traits, rs-performance, rs-ecosystem

Related: [skills-index.md](./skills-index.md) · [triggers-index.md](./triggers-index.md) · [domain-extensions.md](./domain-extensions.md) · [../_meta/reasoning-framework.md](../_meta/reasoning-framework.md) · [../_meta/layer-definitions.md](../_meta/layer-definitions.md)
