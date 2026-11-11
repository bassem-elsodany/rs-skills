//! # Design Contract
//! **Role:** <one sentence — what this file is responsible for>
//! **Patterns:** <Pattern (rs-skill or rs-patterns/<path>.md)> · <…> | none (plain data)
//! **Layout:** <submodule — role> · <submodule — role>              (lib.rs / mod.rs only)
//! **Invariants:** <what must always hold>
//! **Ownership:** <who owns what; what is borrowed>            (if non-trivial)
//! **Errors:** <error type; propagation; panic policy>          (if it can fail)
//! **Concurrency:** <Send/Sync, locks, cancellation>            (if shared)
//! **Extend by:** <sanctioned way to add behaviour>; do NOT <unsanctioned way>
//! **Avoid:** <forbidden shortcut> (<rs-skill that explains why>)
//! **Skills:** <rs-*, rs-*> · rs-skills v0.3
