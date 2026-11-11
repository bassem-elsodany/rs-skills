---
description: Heavy-weight security, soundness and concurrency audit of a Rust crate (cargo-audit, Miri, geiger, lockbud via os-checker)
---

# /audit

Heavy-weight audit for release-critical code. For everyday review use `/rs-review`; for the release gate use `/rs-release-check`.

```
/audit [security | safety | concurrency | full]
```

| Situation | Use |
|---|---|
| day-to-day development, PR review | `/rs-review` |
| before a release | `/rs-release-check`, then `/audit security` |
| reviewing `unsafe` code | `/audit safety` (plus `/unsafe-review`) |
| reviewing concurrent code | `/audit concurrency` |
| safety-critical project | `/audit full` |

## Modes

### security (default) — known vulnerabilities and unsafe exposure

| Tool | Checks |
|---|---|
| `cargo audit` / `cargo deny check advisories` | RUSTSEC advisories in the dependency tree |
| `cargo geiger` | how much `unsafe` each dependency brings in |

### safety — correctness of `unsafe` code (needs nightly)

| Tool | Checks |
|---|---|
| `cargo +nightly miri test` | undefined behaviour under the test suite |
| `rudra` | memory-safety bug patterns |
| `cargo geiger` | unsafe statistics |

### concurrency

| Tool | Checks |
|---|---|
| `lockbud` | deadlocks and double locks |
| `atomvchecker` | atomicity violations |

### full — every available checker (slowest).

## Reading the results (os-checker skills, if installed)

`os-checker-checkers` (what each tool finds) · `os-checker-cli` (invocation) · `os-checker-diagnostics` (interpreting output) · `os-checker-setup` (installing tools).

| Priority | Diagnostic | Action |
|---|---|---|
| Critical | Miri, Rudra, Audit, Cargo | fix before release |
| High | Lockbud (probably), semver violation | should fix |
| Medium | Lockbud (possibly), Atomvchecker | review |
| Low | Geiger, Outdated | informational |

## Example output

```
Security Audit Report
═══════════════════════════════════════════
[1/2] cargo audit — 2 vulnerabilities
  CRITICAL RUSTSEC-2024-0001: memory corruption in foo 1.2.3 → upgrade to 1.2.4
  HIGH     RUSTSEC-2024-0002: DoS in bar 2.0.0 → upgrade to 2.0.1
[2/2] cargo geiger — unsafe in dependencies
  libc 127 · tokio 45 · your-crate 3
═══════════════════════════════════════════
Recommended: 1. update foo (CRITICAL)  2. update bar (HIGH)  3. review own unsafe with /unsafe-check
```

## Installing the tools

```bash
cargo install cargo-audit cargo-deny cargo-geiger --locked
rustup +nightly component add miri
cargo install os-checker          # full suite incl. lockbud, rudra, atomvchecker
```

## Batch audit across repositories

```bash
cat > audit-config.json <<'JSON'
{ "org/repo1": {}, "org/repo2": {} }
JSON
os-checker run --config audit-config.json --emit results.json
```

Related: `/rs-review` (contracts, structure, rules, clippy) · `/rs-release-check` (release gate) · `/unsafe-check` · `/unsafe-review`.
