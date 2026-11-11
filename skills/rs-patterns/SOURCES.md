# Sources — rs-patterns

The pages under `idioms/`, `design-patterns/`, `anti-patterns/`, `functional/`
and `principles/` are reproduced from **Rust Design Patterns** by the
rust-unofficial authors — <https://rust-unofficial.github.io/patterns/>,
repository <https://github.com/rust-unofficial/patterns>, commit `36fdd17`
(2026-09-21) — under the Mozilla Public License 2.0 (`LICENSE-MPL`).

## Modifications (MPL-2.0 §3.3 notice)

Each page is the upstream text with these changes only:

1. a two-line header block after the title (category, *Use when*, *Traces to*
   rs-skills, source path);
2. book-internal links rewritten to the paths below; external links unchanged;
3. chapter index pages renamed `README.md`; `intro.md` moved to
   `principles/introduction.md`; the book's `SUMMARY.md` and `translations.md`
   are summarised here instead of copied (a Simplified Chinese translation is
   maintained at <https://fomalhauthmj.github.io/patterns/>).

`SKILL.md` (the catalogue and decision guide) is original rs-skills material, MIT.

## Page map

| Upstream (`src/`) | Here |
|---|---|
| `SUMMARY.md` | `SOURCES.md` |
| `additional_resources/design-principles.md` | `principles/design-principles.md` |
| `additional_resources/index.md` | `principles/additional-resources.md` |
| `anti_patterns/borrow_clone.md` | `anti-patterns/borrow_clone.md` |
| `anti_patterns/deny-warnings.md` | `anti-patterns/deny-warnings.md` |
| `anti_patterns/deref.md` | `anti-patterns/deref.md` |
| `anti_patterns/index.md` | `anti-patterns/README.md` |
| `functional/generics-type-classes.md` | `functional/generics-type-classes.md` |
| `functional/index.md` | `functional/README.md` |
| `functional/optics.md` | `functional/optics.md` |
| `functional/paradigms.md` | `functional/paradigms.md` |
| `idioms/coercion-arguments.md` | `idioms/coercion-arguments.md` |
| `idioms/concat-format.md` | `idioms/concat-format.md` |
| `idioms/ctor.md` | `idioms/ctor.md` |
| `idioms/default.md` | `idioms/default.md` |
| `idioms/deref.md` | `idioms/deref.md` |
| `idioms/dtor-finally.md` | `idioms/dtor-finally.md` |
| `idioms/ffi/accepting-strings.md` | `idioms/ffi/accepting-strings.md` |
| `idioms/ffi/errors.md` | `idioms/ffi/errors.md` |
| `idioms/ffi/intro.md` | `idioms/ffi/README.md` |
| `idioms/ffi/passing-strings.md` | `idioms/ffi/passing-strings.md` |
| `idioms/index.md` | `idioms/README.md` |
| `idioms/mem-replace.md` | `idioms/mem-replace.md` |
| `idioms/on-stack-dyn-dispatch.md` | `idioms/on-stack-dyn-dispatch.md` |
| `idioms/option-iter.md` | `idioms/option-iter.md` |
| `idioms/pass-var-to-closure.md` | `idioms/pass-var-to-closure.md` |
| `idioms/priv-extend.md` | `idioms/priv-extend.md` |
| `idioms/return-consumed-arg-on-error.md` | `idioms/return-consumed-arg-on-error.md` |
| `idioms/rustdoc-init.md` | `idioms/rustdoc-init.md` |
| `idioms/temporary-mutability.md` | `idioms/temporary-mutability.md` |
| `intro.md` | `principles/introduction.md` |
| `patterns/behavioural/RAII.md` | `design-patterns/behavioural/RAII.md` |
| `patterns/behavioural/command.md` | `design-patterns/behavioural/command.md` |
| `patterns/behavioural/interpreter.md` | `design-patterns/behavioural/interpreter.md` |
| `patterns/behavioural/intro.md` | `design-patterns/behavioural/README.md` |
| `patterns/behavioural/newtype.md` | `design-patterns/behavioural/newtype.md` |
| `patterns/behavioural/strategy.md` | `design-patterns/behavioural/strategy.md` |
| `patterns/behavioural/visitor.md` | `design-patterns/behavioural/visitor.md` |
| `patterns/creational/builder.md` | `design-patterns/creational/builder.md` |
| `patterns/creational/fold.md` | `design-patterns/creational/fold.md` |
| `patterns/creational/intro.md` | `design-patterns/creational/README.md` |
| `patterns/ffi/export.md` | `design-patterns/ffi/export.md` |
| `patterns/ffi/intro.md` | `design-patterns/ffi/README.md` |
| `patterns/ffi/wrappers.md` | `design-patterns/ffi/wrappers.md` |
| `patterns/index.md` | `design-patterns/README.md` |
| `patterns/structural/compose-structs.md` | `design-patterns/structural/compose-structs.md` |
| `patterns/structural/intro.md` | `design-patterns/structural/README.md` |
| `patterns/structural/small-crates.md` | `design-patterns/structural/small-crates.md` |
| `patterns/structural/trait-for-bounds.md` | `design-patterns/structural/trait-for-bounds.md` |
| `patterns/structural/unsafe-mods.md` | `design-patterns/structural/unsafe-mods.md` |
| `refactoring/index.md` | `principles/refactoring.md` |
| `translations.md` | `SOURCES.md` |
