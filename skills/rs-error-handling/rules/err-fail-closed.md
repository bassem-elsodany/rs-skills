# err-fail-closed

> In a security filter, every error path must deny — never forward what it could not check
> **rs-error-handling · rule** — source: rs-skills, learned on the MCP Flex gateway policies (2026-11)

## Why It Matters

A gateway or authorisation filter has two kinds of failure: the check said "no", and the
check **could not run** (parse error, I/O error, regex engine error, host rejected a write).
Code written for the happy path treats the second kind as "skip the check" — and skipping a
security check means forwarding unchecked data. In one review, five High findings were the
same bug in different clothes:

| Fail-open shape | What leaked |
|---|---|
| `Err(_) => return Flow::Continue(())` after a parse failure | the unfiltered `tools/list` |
| `let _ = body_handler.set_body(&scrubbed)` | the original body with the injection |
| `regex.is_match(s).unwrap_or(false)` | anything that hit the backtrack limit |
| `serde_json::from_slice(body).unwrap_or(Value::Null)` then scan the `Null` | non-JSON bodies, never scanned |
| a method on a pass-through list (`resources/read`) | every resource, despite grants |

## Bad

```rust
let doc: Value = match serde_json::from_slice(body) {
    Ok(v) => v,
    Err(_) => return Flow::Continue(()),           // could not filter → forward unfiltered
};
let _ = handler.set_body(&filtered);               // write failed → upstream body goes out
if pattern.regex.is_match(text).unwrap_or(false) { // engine error → "no match"
    block();
}
```

## Good

```rust
let doc: Value = match serde_json::from_slice(body) {
    Ok(v) => v,
    Err(e) => return deny(Reason::Unfilterable(e)), // could not check → deny, log why
};
match handler.set_body(&filtered) {
    Ok(()) => {}
    Err(e) => write_fallback_block_body(handler, e), // and log at error
}
if pattern.regex.is_match(text).unwrap_or(true) {    // engine error counts as a match
    block();
}
```

## How to apply

1. List every early `return` / `?` / `unwrap_or` / `let _ =` in the filter.
2. For each: if this branch runs, **is the data forwarded unchecked?** If yes, it must deny
   (or degrade to a constant, content-free reply), and log at `warn`/`error` with a reason.
3. Model the decision as a type (`Result<Filtered, Unfilterable>`, `BodyWrite::{Replaced, FallbackBlocked, Failed}`)
   so the caller cannot ignore the failure case.
4. Prove each fail-closed branch with a unit test (fake handler that rejects writes, malformed body, failing regex).

## See Also

- [err-result-over-panic](err-result-over-panic.md) — return errors instead of panicking
- rs-review — the *Security & contract pass* checks this on every review
- rs-domain-gateway — the proxy-wasm / Flex PDK specifics
