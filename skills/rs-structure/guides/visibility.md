# Visibility ladder and re-exports

| Level | Meaning | Use when |
|---|---|---|
| (private) | this module and its children | default — always start here |
| `pub(super)` | parent module | `mod.rs` orchestrates aspect files |
| `pub(in crate::feature)` | a subtree | two siblings inside one feature share it |
| `pub(crate)` | whole crate | another feature needs it; still not API |
| `pub` | API (if reachable through `pub mod`/`pub use`) | downstream users need it |

Rules:
- `pub` inside a private module is **not** public API; it becomes API only when
  re-exported. Use this: write `pub` on items, keep the module private, choose
  the API in `mod.rs` with `pub use`.
- Re-export flat: users write `crate::Order`, not `crate::orders::model::Order`.
- A `prelude` module (`pub mod prelude { pub use … }`) only for libraries whose
  users need 5+ items on every use; never in binaries.
- `pub` struct fields: see rs-patterns `idioms/priv-extend.md` (`#[non_exhaustive]`, private fields).
- Lint it: `#![warn(unreachable_pub)]` in `lib.rs` catches `pub` that is not actually reachable.
