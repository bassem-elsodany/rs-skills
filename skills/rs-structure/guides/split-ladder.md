# The split ladder — a worked example

Start: `src/import.rs`, 620 lines; `pub fn import_csv(path, db, opts) -> Result<Report>` is 140 lines.

## Step 1 — responsibilities as verbs

Reading the function top to bottom: *open and detect encoding* → *parse rows* →
*validate each row against the schema* → *deduplicate* → *write in batches* →
*build the report*. Six verbs, one function.

## Step 2 — extract within the file

```rust
pub fn import_csv(path: &Path, db: &Db, opts: &ImportOptions) -> Result<Report, ImportError> {
    let reader = open_reader(path, opts.encoding)?;
    let rows = parse_rows(reader, opts.delimiter)?;
    let valid = validate_rows(rows, &opts.schema)?;
    let unique = dedupe(valid, opts.key_columns());
    let written = write_batches(db, unique, opts.batch_size)?;
    Ok(Report::new(written))
}
```
The orchestrator is now 8 lines and reads like the list above. The file is
still 620 lines — too long — so:

## Step 3 — promote the file to a directory

```
git mv src/import.rs src/import/mod.rs
src/import/
  mod.rs        pub fn import_csv, pub use ImportOptions/Report/ImportError, `mod` lines, Layout contract
  options.rs    ImportOptions + builder                (what the caller configures)
  reader.rs     open_reader, encoding detection        (I/O in, nothing else)
  parse.rs      parse_rows, Row, parse errors
  validate.rs   validate_rows, Schema rules
  dedupe.rs     dedupe, key extraction
  write.rs      write_batches, batch sizing
  report.rs     Report
  error.rs      ImportError (thiserror), From impls for each stage
```
Rule of thumb: one *stage* or one *concept* per file; the error type gets its
own file because every stage adds a variant.

## Step 4 — visibility

```rust
// src/import/mod.rs
mod dedupe; mod error; mod options; mod parse; mod reader; mod report; mod validate; mod write;
pub use error::ImportError;
pub use options::{ImportOptions, ImportOptionsBuilder};
pub use report::Report;

pub fn import_csv(...) -> Result<Report, ImportError> { /* orchestrator */ }
```
Inside `parse.rs`: `pub(super) fn parse_rows(...)` — only `mod.rs` calls it.
`Row` is `pub(super)` too, unless `validate.rs` needs it, which is still inside
`import` so `pub(super)` suffices.

## Step 5 — tests move with the code

`parse.rs` gets `#[cfg(test)] mod tests { use super::*; … }` with the row
parsing cases that used to live at the bottom of `import.rs`. Integration tests
in `tests/import.rs` keep exercising `import_csv` only.

## Step 6 — Design Contracts

```rust
//! # Design Contract            (src/import/mod.rs)
//! **Role:** CSV import pipeline: open → parse → validate → dedupe → write → report.
//! **Patterns:** Pipeline of pure stages (rs-structure) · Builder for options (rs-patterns/design-patterns/creational/builder.md)
//! **Layout:** reader (I/O in) · parse · validate · dedupe · write (I/O out) · report · error · options
//! **Invariants:** only `reader` and `write` perform I/O; stages take owned `Vec<Row>` and return owned.
//! **Errors:** `ImportError` with one variant per stage; no `anyhow` inside the pipeline.
//! **Extend by:** a new stage = a new file + a call in `import_csv` + an `ImportError` variant.
//! **Avoid:** adding helpers to `mod.rs`; `pub` on stage functions (keep `pub(super)`).
//! **Skills:** rs-structure, rs-patterns, rs-error-handling, rs-design-contract · rs-skills v0.3
```

## Step 7 — verify

```
cargo check && cargo clippy --all-targets
scripts/contract-check.sh .        # every new file has a contract
scripts/structure-check.sh .       # no file > 400 lines, no fn > 60 lines, no utils.rs
```

## When *not* to split

- A 70-line `match` over an enum with one line per arm is one responsibility; leave it.
- A file of 350 lines that is one type's `impl` with cohesive methods is fine.
- Do not create a directory for a feature with a single 60-line file — promote when the second aspect appears.
