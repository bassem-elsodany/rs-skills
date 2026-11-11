# auth-object-level-checks

> Authorise the resource, not just the route; take the tenant from the verified identity
> **rs-domain-auth · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Broken object-level authorisation (BOLA/IDOR) — "you are logged in, here is order 1234" for someone else's order — is the most common serious API flaw. Route-level role checks do not prevent it.

## Do

- Every handler that touches a resource id asks the decision point: *may this principal perform this action on **this** resource?* (rs-domain-policy).
- Repositories filter by tenant/owner from the `Principal` (`WHERE tenant_id = $1 AND id = $2`), so a forgotten check cannot leak data.
- Return 404 for resources the caller may not know exist.
- Test: user A requests user B's resource id — must be 403/404, for every endpoint (table-driven).

## Bad

```rust
async fn get_order(Path(id): Path<OrderId>, db: Db) -> Json<Order> { Json(db.order(id).await?) }   // any authenticated user, any id
```

## See Also

- [auth-validate-all-claims](auth-validate-all-claims.md)
