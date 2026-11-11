#![forbid(unsafe_code)]

//! Fixture crate for contract-check.
//!
//! # Design Contract
//! **Role:** Crate root; wires `config` and `store`.
//! **Patterns:** none (plain wiring)
//! **Invariants:** no I/O in this file.
//! **Extend by:** add a `pub mod`; keep wiring here only.
//! **Skills:** rs-design-contract · rs-skills v0.3

pub mod config;
pub mod store;
pub mod util;
