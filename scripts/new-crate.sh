#!/usr/bin/env bash
# Scaffold a production-ready crate with Design Contracts, lint policy, CI and release files.
#   scripts/new-crate.sh <name> [--lib|--bin|--service] [--ci github|gitlab|none] [--dir <parent>]
set -euo pipefail
BUNDLE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME=""; KIND=bin; CI=github; PARENT=.
while [[ $# -gt 0 ]]; do case $1 in --lib) KIND=lib; shift;; --bin) KIND=bin; shift;; --service) KIND=service; shift;; --ci) CI=$2; shift 2;; --dir) PARENT=$2; shift 2;; -*) echo "unknown flag $1"; exit 2;; *) NAME=$1; shift;; esac; done
[[ -n "$NAME" ]] || { echo "usage: new-crate.sh <name> [--lib|--bin|--service] [--ci github|gitlab|none] [--dir parent]"; exit 2; }
[[ "$NAME" =~ ^[a-z][a-z0-9_-]*$ ]] || { echo "crate names are lowercase kebab/snake: $NAME"; exit 2; }
SNAKE=${NAME//-/_}; DEST="$PARENT/$NAME"; VER=$(cat "$BUNDLE/VERSION" | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')
[[ -e "$DEST" ]] && { echo "$DEST exists"; exit 1; }
mkdir -p "$DEST/src" "$DEST/tests"
cat > "$DEST/Cargo.toml" <<TOML
[package]
name = "$NAME"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"
description = "TODO one line"
license = "MIT OR Apache-2.0"
repository = "TODO"
publish = false

[dependencies]
$( [[ $KIND != lib ]] && printf 'anyhow = "1"\nclap = { version = "4", features = ["derive"] }\ntracing = "0.1"\ntracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }\n' )
$( [[ $KIND == lib || $KIND == service ]] && printf 'thiserror = "2"\n' )
$( [[ $KIND == service ]] && printf 'tokio = { version = "1", features = ["rt-multi-thread", "macros", "signal"] }\n' )

[dev-dependencies]
proptest = "1"

[lints.rust]
unsafe_code = "warn"
missing_docs = "warn"
unsafe_op_in_unsafe_fn = "warn"
unreachable_pub = "warn"

[lints.clippy]
# groups carry priority -1 so the individual allows/denies below override them
correctness = { level = "deny", priority = -1 }
suspicious = { level = "warn", priority = -1 }
style = { level = "warn", priority = -1 }
complexity = { level = "warn", priority = -1 }
perf = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }
module_name_repetitions = "allow"
must_use_candidate = "allow"
undocumented_unsafe_blocks = "warn"

$(cat "$BUNDLE/templates/release/release-profile.toml" | grep -v '^#')

$(cat "$BUNDLE/templates/release/dev-profile.toml" | grep -v '^#')
TOML
sed -i '' '/^$/N;/^\n$/D' "$DEST/Cargo.toml" 2>/dev/null || true
CONTRACT_SK="rs-structure, rs-design-contract, rs-error-handling · rs-skills v$VER"
case $KIND in
lib)
cat > "$DEST/src/lib.rs" <<RS
//! \`$SNAKE\` — TODO one-paragraph crate summary for rustdoc's front page.
//!
//! # Design Contract
//! **Role:** Crate root; declares feature modules and re-exports the public API.
//! **Patterns:** none (wiring) · feature modules (rs-structure)
//! **Layout:** core (domain types + rules, no I/O) · error (\`Error\`)
//! **Invariants:** no I/O in this crate's \`core\`; every public item documented.
//! **Errors:** \`Error\` via thiserror; no panics on caller input.
//! **Extend by:** new feature = new directory \`src/<feature>/\` with its own mod.rs and contract; re-export here.
//! **Avoid:** utils.rs / helpers.rs; \`pub\` on items that are not re-exported here.
//! **Skills:** rs-api-design, $CONTRACT_SK

#![forbid(unsafe_code)]

mod core;
mod error;

pub use core::{Name, greet};
pub use error::Error;
RS
mkdir -p "$DEST/src/core"
cat > "$DEST/src/core/mod.rs" <<RS
//! # Design Contract
//! **Role:** Domain types and pure rules for \`$SNAKE\`.
//! **Patterns:** Newtype for validated input (rs-patterns/design-patterns/behavioural/newtype.md)
//! **Layout:** name (validated \`Name\` newtype) · greet (pure function)
//! **Invariants:** pure — no I/O, no clocks, no randomness; a \`Name\` is never empty.
//! **Extend by:** new rule = new file in this directory + \`mod\` line here; keep functions pure.
//! **Avoid:** returning \`String\` errors; use \`crate::Error\`.
//! **Skills:** rs-type-driven, rs-patterns, $CONTRACT_SK

mod greet;
mod name;

pub use greet::greet;
pub use name::Name;
RS
cat > "$DEST/src/core/name.rs" <<RS
//! # Design Contract
//! **Role:** \`Name\` — a validated, non-empty display name.
//! **Patterns:** Newtype + parse-don't-validate (rs-api-design \`api-parse-dont-validate\`)
//! **Invariants:** inner string is trimmed and non-empty; constructed only through \`Name::new\`.
//! **Errors:** \`Error::EmptyName\` on invalid input.
//! **Extend by:** add validation inside \`Name::new\`; never add a public constructor that skips it.
//! **Skills:** rs-type-driven, rs-error-handling, rs-design-contract · rs-skills v$VER

use crate::Error;

/// A validated, non-empty name.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Name(String);

impl Name {
    /// Parses and validates a name.
    ///
    /// # Errors
    /// Returns [\`Error::EmptyName\`] when \`raw\` is empty or whitespace.
    pub fn new(raw: &str) -> Result<Self, Error> {
        let trimmed = raw.trim();
        if trimmed.is_empty() {
            return Err(Error::EmptyName);
        }
        Ok(Self(trimmed.to_owned()))
    }

    /// The validated name.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_trims_and_keeps_non_empty() {
        assert_eq!(Name::new("  Ada ").unwrap().as_str(), "Ada");
    }

    #[test]
    fn new_rejects_empty_input() {
        assert_eq!(Name::new("   "), Err(Error::EmptyName));
    }
}
RS
cat > "$DEST/src/core/greet.rs" <<RS
//! # Design Contract
//! **Role:** Pure greeting rule.
//! **Patterns:** none (pure function)
//! **Invariants:** deterministic; no allocation beyond the returned \`String\`.
//! **Extend by:** new greeting forms = new functions here taking \`&Name\`.
//! **Skills:** rs-design-contract · rs-skills v$VER

use super::Name;

/// Builds a greeting for \`name\`.
#[must_use]
pub fn greet(name: &Name) -> String {
    format!("Hello, {}!", name.as_str())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greet_uses_the_validated_name() {
        let name = Name::new("Ada").unwrap();
        assert_eq!(greet(&name), "Hello, Ada!");
    }
}
RS
cat > "$DEST/src/error.rs" <<RS
//! # Design Contract
//! **Role:** The crate's public error type.
//! **Patterns:** thiserror enum, one variant per failure class (rs-error-handling \`err-thiserror-lib\`)
//! **Invariants:** \`#[non_exhaustive]\` so variants can be added in minor releases; messages are lowercase, no trailing period.
//! **Extend by:** add a variant + \`#[error]\` message; map foreign errors with \`#[from]\` only at this boundary.
//! **Skills:** rs-error-handling, rs-api-design, rs-design-contract · rs-skills v$VER

/// Errors produced by this crate.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
#[non_exhaustive]
pub enum Error {
    /// The provided name was empty.
    #[error("name must not be empty")]
    EmptyName,
}
RS
cat > "$DEST/tests/public_api.rs" <<RS
//! Black-box tests through the public API only.
use $SNAKE::{Error, Name, greet};

#[test]
fn greeting_round_trip() {
    let name = Name::new("Grace").expect("valid name");
    assert_eq!(greet(&name), "Hello, Grace!");
}

#[test]
fn empty_name_is_an_error() {
    assert_eq!(Name::new("").unwrap_err(), Error::EmptyName);
}
RS
;;
bin|service)
cat > "$DEST/src/main.rs" <<RS
//! \`$NAME\` binary entry point.
//!
//! # Design Contract
//! **Role:** Parse CLI args, install tracing, call \`$SNAKE::run\`, map errors to exit codes. Nothing else.
//! **Patterns:** thin main over a library (rs-structure \`proj-lib-main-split\`)
//! **Invariants:** no business logic here; stays under 50 lines; exit code 1 on error, 2 on usage.
//! **Errors:** \`anyhow::Error\` printed as a chain to stderr.
//! **Extend by:** new flags go in \`cli.rs\`; new behaviour goes in the library.
//! **Skills:** rs-domain-cli, rs-observability, $CONTRACT_SK

use clap::Parser;
use $SNAKE::cli::Cli;

fn main() -> std::process::ExitCode {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();
    let cli = Cli::parse();
    match $SNAKE::run(&cli) {
        Ok(()) => std::process::ExitCode::SUCCESS,
        Err(err) => {
            tracing::error!(error = ?err, "fatal");
            eprintln!("error: {err:#}");
            std::process::ExitCode::FAILURE
        }
    }
}
RS
cat > "$DEST/src/lib.rs" <<RS
//! \`$SNAKE\` — TODO one-paragraph summary.
//!
//! # Design Contract
//! **Role:** Crate root; declares feature modules and exposes \`run\` to the thin binary.
//! **Patterns:** lib + thin main (rs-structure) · feature modules
//! **Layout:** cli (argument types only) · app (wiring, \`run\`) · \`<feature>/\` per domain concept
//! **Invariants:** \`cli\` has no logic; \`app\` is the only module that knows every feature.
//! **Errors:** features return typed errors; \`run\` converts to \`anyhow\` at the boundary.
//! **Extend by:** new feature = \`src/<feature>/mod.rs\` + contract, wired in \`app.rs\`; never in main.rs.
//! **Avoid:** utils.rs; logic in \`cli.rs\`; \`unwrap()\` outside tests.
//! **Skills:** rs-domain-cli, rs-observability, $CONTRACT_SK

#![forbid(unsafe_code)]

mod app;
pub mod cli;

pub use app::run;
RS
cat > "$DEST/src/cli.rs" <<RS
//! # Design Contract
//! **Role:** Command-line surface of \`$NAME\` (clap derive types only).
//! **Patterns:** none (plain data) · clap derive (rs-domain-cli)
//! **Invariants:** no logic, no I/O; every flag documented via doc comments (they become --help).
//! **Extend by:** add a field or subcommand here; handle it in \`app.rs\`.
//! **Skills:** rs-domain-cli, rs-design-contract · rs-skills v$VER

use clap::Parser;

/// TODO: one-line description shown in --help.
#[derive(Debug, Parser)]
#[command(version, about)]
pub struct Cli {
    /// Who to greet.
    #[arg(long, default_value = "world")]
    pub name: String,
}
RS
cat > "$DEST/src/app.rs" <<RS
//! # Design Contract
//! **Role:** Wiring: turn \`&Cli\` into feature calls; owns the run lifecycle.
//! **Patterns:** composition root (rs-structure service layout \`app.rs\`)
//! **Invariants:** the only module that imports every feature; no feature imports \`app\`.
//! **Errors:** converts feature errors into \`anyhow::Error\` with context.
//! **Extend by:** wire a new feature here; keep \`run\` a readable sequence of calls.
//! **Skills:** rs-error-handling, rs-observability, rs-design-contract · rs-skills v$VER

use crate::cli::Cli;

/// Runs the program for the parsed command line.
///
/// # Errors
/// Returns an error when a feature fails; the message chain explains where.
#[tracing::instrument(skip_all, fields(name = %cli.name))]
pub fn run(cli: &Cli) -> anyhow::Result<()> {
    let name = cli.name.trim();
    anyhow::ensure!(!name.is_empty(), "name must not be empty");
    println!("Hello, {name}!");
    tracing::info!("greeted");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn run_rejects_empty_name() {
        let cli = Cli { name: "  ".into() };
        assert!(run(&cli).is_err());
    }
}
RS
cat > "$DEST/tests/cli.rs" <<RS
//! Black-box test of the library entry point.
use $SNAKE::cli::Cli;

#[test]
fn run_succeeds_for_a_name() {
    let cli = Cli { name: "Ada".into() };
    $SNAKE::run(&cli).expect("run succeeds");
}
RS
;;
esac
cp "$BUNDLE/templates/release/deny.toml" "$DEST/deny.toml"
cp "$BUNDLE/templates/release/CHANGELOG.md" "$DEST/CHANGELOG.md"
[[ $KIND != lib ]] && sed "s/APP_NAME/$NAME/g" "$BUNDLE/templates/release/Dockerfile" > "$DEST/Dockerfile" && cp "$BUNDLE/templates/release/dockerignore" "$DEST/.dockerignore"
case $CI in github) mkdir -p "$DEST/.github/workflows"; cp "$BUNDLE/templates/release/github-ci.yml" "$DEST/.github/workflows/ci.yml";; gitlab) cp "$BUNDLE/templates/release/gitlab-ci.yml" "$DEST/.gitlab-ci.yml";; esac
printf 'target/\n' > "$DEST/.gitignore"
(cd "$DEST" && cargo generate-lockfile -q 2>/dev/null) || echo "note: Cargo.lock not generated (offline?) — run cargo generate-lockfile"
printf '# %s\n\nTODO. Generated by rs-skills `new-crate.sh` (%s). Every `.rs` file carries a Design Contract; run `scripts/release-check.sh` before shipping.\n' "$NAME" "$KIND" > "$DEST/README.md"
echo "created $DEST ($KIND, ci=$CI)"; find "$DEST" -type f | sort | sed "s|^$DEST/|  |"
