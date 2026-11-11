# Sharp edges — is the easy path the safe path?

> **rs-api-design · guide** — for public APIs, config schemas and library ergonomics. rs-skills original.

An API is a security control: if using it correctly requires remembering a rule, reading a caveat or understanding cryptography, it will be used wrongly under deadline pressure. Review every public surface against **three misusers**: the **attacker** (controls an input), the **rushed developer** (takes the first example that compiles) and the **confused developer** (swaps two arguments, guesses what `0` means).

## The pit of success

Secure usage must be the **shortest** path: the default, the only option, or the one the types force. "It's documented" is not a defence — make the wrong thing hard to write or impossible to compile.

## Audit checklist (each with the Rust-idiomatic fix)

| Sharp edge | Smell | Fix |
|---|---|---|
| **Algorithm/mode chosen by the caller (or the data)** | `algorithm: &str`, `Algorithm` enum with weak members, header-selected verification (`alg: none`) | expose one safe default (`verify_es256`); enums without weak variants; pin allowed algorithms in the *verifier's* config (rs-domain-auth `auth-jwt-pin-algorithms`) |
| **Zero/empty/None disables protection** | `timeout: 0` = infinite? `max_attempts: 0` = unlimited? `Option<Key>` `None` = unauthenticated? | reject at construction (`NonZeroU32`, `Duration` newtype with minimum, `Result` from `build()`); never let a sentinel mean "off" |
| **Dangerous `Default`** | `impl Default` yields `verify_tls: false`, empty allow-list = allow all | defaults are the safest values; "off" switches have long, ugly names (`dangerously_…`) and are `#[doc(hidden)]`-free in docs, loud in logs |
| **Primitive instead of semantic types** | `fn sign(key: &[u8], nonce: &[u8], msg: &[u8])` — all swappable | newtypes (`SigningKey`, `Nonce`, `Message`) with private fields and checked constructors (rs-type-driven); type state for "verified vs unverified" |
| **Stringly-typed modes and config** | `mode: String`, typos silently accepted, `"fasle"` truthy | enums with `deny_unknown_fields`; validate whole config at start-up and **fail** (rs-ecosystem `serde-deny-unknown-fields`) |
| **Config cliffs** | one flag disables everything; combinations that silently weaken (`allow_http` + `follow_redirects`) | validate combinations in `build()`; refuse dangerous pairs; log effective security posture at start-up |
| **Silent failure / lenient parsing** | `parse().unwrap_or_default()`, ignoring unknown fields on security data, returning `Ok` with a warning | strict by default, typed errors, `#[must_use]` on results; opt-in `lenient()` named for what it risks |
| **Comparison that looks identical** | `==` on MACs/tokens vs constant-time | the verify function does the comparison; don't expose the bytes for the caller to compare (rs-security-review `sec-constant-time-compare`) |
| **Order/lifecycle footguns** | must call `init()` before `use()`, must not reuse a nonce | builder → typestate so out-of-order calls don't compile; consume `self` for one-shot values (nonce, token) |
| **Ambient authority** | global state, `env::var` read deep inside, process-wide singletons | pass capabilities explicitly (a `&Dir`, a `Client`), read env at the composition root (rs-ports-adapters) |
| **Build-profile-dependent behaviour** | integer overflow panics in debug, wraps in release; `debug_assert!` as validation | `checked_*` in the API, `overflow-checks` in release for services; validation never in `debug_assert!` |
| **Resource ownership leaks** | `into_raw`/`mem::forget` patterns, handles without `Drop` | RAII wrappers; explicit `close()` returning `Result` plus best-effort `Drop` (rs-security-review `sec-drop-panic-and-skip`) |
| **`unsafe` in the public API** | safe fn that can cause UB with bad arguments | make it `unsafe fn` with a `# Safety` section, or validate and keep the `unsafe` inside |
| **Path/string conveniences** | `fn open(p: &str)` joins and trusts | take `&Path`/a validated newtype; document traversal behaviour; offer a rooted type (`cap-std`) |
| **Process-global mutation** | `std::env::set_var` (unsafe in edition 2024), `static mut`, global locale/time zone | configuration objects, not globals |

## Deliverable

A short table in the review: `| Surface | Misuser | Sharp edge | Evidence (file:line) | Fix |`. Severity follows the consequence: an off-by-default security switch that is on by default in the example code is High; ergonomics without security impact is Low.

## Questions to ask of any option

What happens with `0`, `""`, `None`, `-1`, `u32::MAX`? Is the default the most secure choice? Can one value turn protection off? Does a typo fail loudly? What does the *first Stack Overflow answer* for this API look like, and is it safe?
