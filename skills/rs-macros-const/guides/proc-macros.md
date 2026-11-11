# Procedural macros — derive, attribute, function-like

> **rs-macros-const · guide**

## Setup

```toml
# my-crate-macros/Cargo.toml
[lib]
proc-macro = true
[dependencies]
syn = { version = "…", features = ["full"] }   # verify the current major with sdk-scout; 2.x and 3.x differ
quote = "1"
proc-macro2 = "1"
darling = "…"           # attribute parsing, optional
```
A proc-macro crate exports only macros; the runtime types it refers to live in a normal crate that re-exports the macro (`my-crate` + `my-crate-macros`).

## A derive, step by step

1. Parse: `let input = syn::parse_macro_input!(tokens as syn::DeriveInput);`
2. Validate the shape and **report errors on spans**: `syn::Error::new_spanned(field, "…").to_compile_error().into()`.
3. Generate with `quote!`, referring to your runtime crate by absolute path (`::my_crate::Trait`).
4. Handle generics: `let (impl_g, ty_g, where_c) = input.generics.split_for_impl();`.
5. Keep the generated code small and delegate to runtime helpers.

```rust
use proc_macro::TokenStream;
use quote::quote;

#[proc_macro_derive(Describe)]
pub fn describe(tokens: TokenStream) -> TokenStream {
    let input = syn::parse_macro_input!(tokens as syn::DeriveInput);
    let name = &input.ident;
    let (impl_g, ty_g, where_c) = input.generics.split_for_impl();
    quote! {
        impl #impl_g ::my_crate::Describe for #name #ty_g #where_c {
            fn describe() -> &'static str { stringify!(#name) }
        }
    }.into()
}
```

## Testing (non-negotiable)

| Test | Tool |
|---|---|
| expansion compiles and behaves | a normal integration test that `#[derive]`s on sample types |
| misuse produces a *good* error | `trybuild`: `tests/ui/*.rs` + `*.stderr` snapshots; review the stderr diff like a code change |
| expansion text (debugging) | `cargo expand`, or `macrotest` for snapshotting expansions |

## Pitfalls

- `panic!` in a proc macro gives an opaque "proc macro panicked" — return a `compile_error!` with a span.
- Forgetting generics/lifetimes/where clauses → works on the demo struct, fails on real code.
- Name collisions in generated code: prefix helpers (`__my_crate_…`) and use fully-qualified paths.
- Compile time: keep `syn` features minimal (`"derive"` instead of `"full"` when enough); heavy macros slow every dependent build.
- Before writing one: is there a derive already (`derive_more`, `strum`, `bon`, `thiserror`)? (rs-reuse-first)
