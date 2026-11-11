# Web middleware (tower layers) — what goes in, in which order

> **rs-domain-web · guide** — axum/tower terms; the same stack applies to actix-style middleware. Verified crates: `tower` 0.5, `tower-http` 0.7, `axum` 0.8, `tower_governor`, `axum-prometheus`.

Middleware = cross-cutting behaviour around a handler, composed as layers. Every layer is code that runs on **every request**: keep it small, bounded and fail-safe.

## Recommended order (outermost → innermost)

```
ServiceBuilder::new()
  .layer(1. catch panic → 500, never crash the worker)      tower-http CatchPanicLayer
  .layer(2. request id: accept-or-generate, propagate)       tower-http SetRequestIdLayer / PropagateRequestIdLayer
  .layer(3. tracing span per request (id, method, route)     tower-http TraceLayer  → rs-observability
  .layer(4. metrics (latency, status, in-flight)             axum-prometheus / opentelemetry layer
  .layer(5. timeout (overall request deadline)               tower-http TimeoutLayer / tower::timeout
  .layer(6. load shedding / concurrency limit / rate limit   tower::load_shed, ConcurrencyLimit, tower_governor
  .layer(7. body size limit                                  axum DefaultBodyLimit / tower-http RequestBodyLimitLayer
  .layer(8. CORS (browsers only)                             tower-http CorsLayer — explicit origins, not Any, with credentials
  .layer(9. compression (responses)                          tower-http CompressionLayer
  .layer(10. security headers                                tower-http SetResponseHeaderLayer (HSTS, nosniff, frame-ancestors)
  .layer(11. authentication → Principal in extensions        your layer / extractor  → rs-domain-auth
  .layer(12. authorisation (PEP → PDP)                        your layer or per-handler  → rs-domain-policy
  → router → handler
```
Why this order: panics and ids first so everything after is traced and survivable; deadlines/limits before expensive work; auth before any handler logic; authorisation after identity (and per resource inside the handler for object-level checks).

## Rules

| Rule | Detail |
|---|---|
| **Fail closed** | an auth/authorisation layer that errors returns 401/403/503 — never calls `next` (`err-fail-closed`) |
| **Order is behaviour** | test it: a request without a token must not reach the handler, must still get a request id, and must be traced |
| **Bound everything** | timeouts, body size, concurrency, queue depth; unbounded middleware state is a leak |
| **No blocking in layers** | CPU/blocking work → `spawn_blocking`; hashing, big JSON, compression on huge bodies |
| **Rate limiting** | per key (IP/token/tenant), shared state behind a port if multi-instance (Redis) — in-process limits multiply by instance count; return 429 + `Retry-After` |
| **CORS** | explicit origin list; never `Any` with credentials; it is a browser rule, not authentication |
| **Request ids** | accept an inbound id only from trusted proxies; always return it; put it in every log line and downstream call (rs-observability) |
| **Don't log bodies/headers wholesale** | `Authorization`, cookies, tokens redacted (`obs-no-sensitive-data`) |
| **Extensions are typed** | store `Principal` as a request extension (newtype) and extract it; handlers cannot be built without it (rs-type-driven) |
| **Graceful shutdown** | stop accepting, drain in-flight (rs-async-patterns `async-graceful-shutdown`) |

## Writing a custom layer

Prefer `axum::middleware::from_fn` (async fn taking `Request` and `Next`) for app-specific logic; implement `tower::Layer` + `Service` only for reusable library middleware (poll_ready, `Pin<Box<dyn Future>>` or a named future with `pin-project-lite` — rs-async-patterns `pin-and-futures`). Keep it `Clone` and cheap (`Arc` state).

```rust
// from_fn layer: reject without a verified principal; never call next on error
async fn require_principal(mut req: Request, next: Next) -> Result<Response, StatusCode> {
    let bearer = req.headers().get(AUTHORIZATION).and_then(|v| v.to_str().ok()).ok_or(StatusCode::UNAUTHORIZED)?;
    let principal = authenticate(bearer).await.map_err(|_| StatusCode::UNAUTHORIZED)?;   // errors deny
    req.extensions_mut().insert(principal);
    Ok(next.run(req).await)
}
```
(Check `axum` 0.8 docs for current `from_fn`/`Next` signatures when you write it.)
