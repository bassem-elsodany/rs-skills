# Policy architecture in Rust

> **rs-domain-policy · guide** — the decision core in `templates/policy-engine/policy.rs` compiles and is tested (deny-overrides, Indeterminate never permits, default deny)

## Request model

```rust
pub struct Request { pub subject: BTreeMap<String,String>, pub resource: BTreeMap<String,String>, pub action: String }
// extend with: environment (time, network), delegation (actor acting for subject), tenant, tool/risk metadata
```
- Build the request in the **PEP** from verified facts only. For agent/tool scenarios include *who the agent acts for* and *which tool with which arguments* (hash or classification, not raw secrets).
- Keep it serialisable: the same request can be evaluated in-process, by a sidecar, or replayed from the audit log.

## The `Authorizer` port

```rust
pub trait Authorizer: Send + Sync {
    fn decide(&self, req: &Request) -> impl Future<Output = Decision> + Send;   // total: errors become Decision::Indeterminate
}
```
Adapters: `RulesAuthorizer` (in-process, like the template), `CedarAuthorizer`, `RegorusAuthorizer`, `RemotePdp` (HTTP/gRPC with timeout), `AllowListAuthorizer` (tests). Contract suite: the same decision table passes for every adapter (rs-ports-adapters `port-contract-tests`). The port returns `Decision`, never `Result<bool, E>`: failure *is* a decision.

## PEP patterns

| Where | Do |
|---|---|
| HTTP middleware (axum/tower) | extract `Principal`, build `Request`, `decide`, `enforce`; on deny return 403 with a generic body and log the trail |
| gateway filter / proxy-wasm | decide in the request-headers or body phase; on `Indeterminate` return an error response, never continue (rs-domain-gateway `err-fail-closed`) |
| MCP tool call | decide per `tools/call` with tool name + argument classification; filter `tools/list` to what the principal may call |
| data layer | row-level/tenant filters in queries as defence in depth (rs-domain-auth `auth-object-level-checks`) |

## Obligations

A decision may carry obligations (`redact: ["ssn"]`, `log: "high-risk"`, `require: "step-up-auth"`). Model them as a typed enum on the decision; the PEP must implement each one or deny. Unknown obligation ⇒ deny.

## Performance

- Compile/parse policies once; evaluate with borrowed data; avoid allocating per request in the hot path (rs-performance).
- Cache **decisions** only keyed by (request fingerprint, policy epoch); invalidate by bumping the epoch on policy or attribute changes.
- Bound evaluation time (timeout → `Indeterminate`); pathological policies must not stall the gateway.
- Single-threaded VMs (proxy-wasm): no threads, no blocking network calls; attributes must be in the request or a local cache.
