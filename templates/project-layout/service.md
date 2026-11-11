# Service (hexagonal / ports and adapters)

> Template — see skills/rs-structure for the rules.

```
my_service/
  src/
    main.rs           runtime, tracing init, call app::run
    app.rs            wiring: build adapters, inject into domain services, start server
    api/              transport: http/ (routes, handlers, dto, extractors) grpc/ …
    domain/           pure: model/ service/ ports.rs (traits the domain needs), error.rs — no tokio, no sqlx
    infra/            adapters implementing domain::ports: store/postgres.rs, cache/redis.rs, clients/…
    config/
  tests/              api-level tests with in-memory adapters
```
Dependency direction: `api` → `domain` ← `infra`; `app.rs` is the only file
that knows all three. The Design Contract of `domain/mod.rs` states the
"no I/O" invariant.
