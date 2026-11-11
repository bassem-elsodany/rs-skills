# Library crate

> Template — see skills/rs-structure for the rules.

```
my_lib/
  Cargo.toml
  src/
    lib.rs            //! crate docs + Design Contract (Layout) ; pub mod feature_a; pub mod feature_b; pub use …
    feature_a/ mod.rs model.rs ops.rs error.rs
    feature_b/ …
    shared/           ids.rs money.rs   (only if ≥3 features use them)
  tests/              one file per public feature (black-box)
  benches/            criterion benches
  examples/           runnable examples (doubles as docs)
```
- `lib.rs` is the table of contents: `mod` declarations, `pub use` of the API,
  crate-level docs. No logic.
- Public API is re-exported flat (`my_lib::Order`, not `my_lib::feature_a::model::Order`)
  unless the module path carries meaning for users.
