---
name: rs-domain-gateway
description: "Use when building or reviewing API-gateway policies and proxy filters in Rust — proxy-wasm, Envoy wasm filters, MuleSoft Flex Gateway PDK policies, Kong/APISIX wasm plugins, MCP gateways. Keywords: proxy-wasm, proxy_wasm, wasm filter, Envoy filter, Flex Gateway, PDK, pdk::hl, gateway policy, request filter, response filter, headers state, body state, StreamProperties, set_body, policy violation, cdylib, wasm32-wasip1, GCL, policy definition, inter-policy contract, fail closed, MCP gateway, JSON-RPC over HTTP, SSE"
user-invocable: false
---

# Gateway Policy Domain (proxy-wasm · Envoy · Flex PDK)

> **Layer 3: Domain Constraints** · learned on four production MCP gateway policies (2026-11)

## Core Question

**If this filter cannot do its job on this request, what reaches the upstream or the client?**
The answer must always be "nothing unchecked".

## Domain Constraints → Design Implications

| Domain rule | Design constraint | Rust implication |
|---|---|---|
| A filter sits in the security path | "could not check" must deny | `Result<Checked, Unfilterable>` types, `err-fail-closed` |
| Request and response are **phases** (headers → body) | headers are writable only in the headers phase | decide status codes before `into_body_state()`; body-phase blocks keep the status (JSON-RPC errors) |
| The host holds the stream until each phase is consumed | every early return must still transition the state | consume headers first, then branch |
| Streams may never end (SSE, long poll) | never buffer a body you cannot finish | check `content-type` before reading a body |
| Rewritten bodies go to the same client | keep the upstream framing | split / re-wrap SSE `data:` frames |
| Filters run single-threaded per worker | no thread sharing inside the VM | `Rc`, `LazyLock<RwLock<…>>` only for process-wide maps |
| Host functions are wasm **imports** | the linker must not reject them | `.cargo/config.toml`: `[target.wasm32-wasip1] rustflags = ["-C", "link-arg=--allow-undefined"]` |
| The artefact is a `cdylib` wasm | host tests do not prove it links | build `--release --target wasm32-wasip1` in CI |
| Policies form a pipeline | they talk through stream properties / headers | one documented key contract; writers and readers checked together |
| Config schema (GCL, JSON Schema) is the user API | offered = must work | `api-config-is-contract`; parse once into `Settings` at configure |
| Shared caches survive restarts and span workers | keys and formats are deployment state | SHA-256 keys, TTL stamped in the entry, stable cache names |

---

## Critical Constraints

### Phase discipline

```text
on_request:  into_headers_state ──► (read headers, decide 401/403, set headers) ──► into_body_state ──► (read/patch body)
on_response: into_headers_state ──► (status, set :status 502 if needed, drop content-length) ──► into_body_state ──► set_body
```

- Setting a header after `into_body_state()` traps the VM (`unreachable`) on Flex — the response dies.
- A body-phase decision cannot change the status: return a JSON-RPC error body (`error.code = -32001`) with 200.
- `RequestData::Break | Cancel` in `on_response`: still consume the headers state.

### Fail closed — the five shapes to hunt

| Shape | Fix |
|---|---|
| `Err(_) => return Flow::Continue(())` after parse/filter failure | deny with a constant, content-free reply; log the reason |
| `let _ = body.set_body(..)` | match the `Result`; on `Err` write a fixed fallback block body |
| `regex.is_match(s).unwrap_or(false)` | `unwrap_or(true)` — engine error counts as a match |
| non-JSON body parsed to `Null` and then "scanned" | scan the raw text; if you cannot scrub, block |
| a method/route on a pass-through list | prove it cannot read protected data, or check it |

### Inter-policy contract

- Write the key table once (lib.rs docs of the writer) and read **exactly** those keys.
- Writers must also record **deny / hold** decisions (`authz.gap2_result = DENIED | CONSENT_REQUIRED`), not only allow — downstream audit otherwise reports holds as allowed.
- Identity read from request headers in a policy that runs **before** identity verification is client-supplied: label it `claimed`. "Validated" means the verifier published it (e.g. `identity.*`).
- rs-review's risk scan lists properties read but never written across the workspace.

### Replies and logs

- Never reflect blocked/matched content or upstream bodies to the caller (`obs-no-reflect-untrusted`).
- Log prefix contract: `[policyId:<id>][requestId|cid:<id>][phase][OUTCOME] key=value`; ids yes, e-mails/claims/tokens no.

### Generated code and workspace

- `cargo anypoint config-gen` output: `#[rustfmt::skip]` + `#[allow(clippy::all, clippy::pedantic)]` on the `mod generated;` line; never edit by hand (rs-design-contract exempts it).
- Several policies → one Cargo workspace with shared deps/lints/profile, a small shared crate for identical helpers, and per-policy `.cargo/config.toml` `target-dir = "target"` so PDK Makefiles keep their paths.

---

## Trace Down ↓

| Constraint | Pattern | Skill |
|---|---|---|
| fail closed | outcome enums, fallback writer | rs-error-handling `err-fail-closed` |
| phase-split logic | functional core / imperative shell: pure `filter_body(bytes) -> Result<…>` + thin PDK shell | rs-patterns, rs-structure |
| config | `Settings::parse` once, enums for actions, no `as` casts | rs-type-driven, rs-api-design |
| big filters | `request/`, `response/`, `checks/` feature modules, ≤ 60-line orchestrators | rs-structure |
| contracts | Design Contract Invariants name the fail-closed rules | rs-design-contract |

## Testing

| Layer | How |
|---|---|
| Pure cores (parse, filter, classify, reply builders) | unit tests, no PDK |
| Host traits (`BodyHandler`, `HeadersHandler`) | small fakes implementing the trait (`set_body` that fails N times) |
| Crypto / verifiers | sign with generated keys in tests; verify RFC test vectors through the real host verifier |
| End to end | PDK harness (Flex + httpmock in Docker): `#[ignore]` + `make test --include-ignored` — `test-env-bound-integration` |

## Release

`cargo build --release --target wasm32-wasip1 --locked` in CI · `[profile.release] lto = true, opt-level = "z", strip = "debuginfo"` · crate version feeds the policy reference name (`…-v1-0`), so bumping it is a deployment decision.

## Related Skills

| When | See |
|---|---|
| Review a gateway policy | rs-review (Security & contract pass) |
| Error paths | rs-error-handling |
| Web semantics behind the gateway | rs-domain-web |
| Containers, health, rollout | rs-domain-cloud-native |
| Logging rules | rs-observability |
| Tests that need Docker/vendor CLIs | rs-testing |
| Official SDK vs a hand-rolled subset under wasm constraints | rs-reuse-first |
| Policy decisions at the filter (PDP/PEP, default deny) | rs-domain-policy |
| Token validation at the edge | rs-domain-auth |
| Check the filter against its `gcl.yaml`/spec (verdicts, reverse direction) | rs-review `guides/spec-compliance.md` |
| Security hunt: panic/DoS on traffic, recursion, exhaustion; fuzz the parsers | rs-security-review, rs-fuzzing |
