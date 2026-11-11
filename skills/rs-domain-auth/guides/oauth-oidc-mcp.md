# OAuth 2.0 / OIDC and MCP authorisation

> **rs-domain-auth · guide** — use `oauth2` / `openidconnect` (rs-reuse-first) or the MCP SDK's `auth` feature; do not hand-build token exchanges.

## Flows

| Client type | Flow | Notes |
|---|---|---|
| web app with a backend, mobile, SPA | **Authorisation code + PKCE (S256)** | exact-match redirect URIs; `state` (CSRF) and `nonce` (OIDC replay); no implicit flow, no password grant |
| service/daemon, no user | **Client credentials** | short-lived access tokens; scopes least-privilege; secrets in a secret store; prefer private-key JWT or mTLS client auth over shared secrets |
| device without browser | device authorisation grant | |
| delegation between services | token exchange (RFC 8693) | the downstream audience must be explicit |

- **Access tokens are for the resource server, ID tokens are for the client.** Never use an ID token to call an API.
- **Refresh tokens:** rotate on use, bind to client, revoke on reuse (detects theft); keep out of browser storage.
- **Sender-constrained tokens** (DPoP RFC 9449, mTLS RFC 8705) when a stolen bearer token would be costly.
- **Opaque tokens** → introspection (RFC 7662) with a short cache; **JWT access tokens** → local validation (`guides/jwt-validation.md`).
- **Discovery:** read `/.well-known/openid-configuration` (issuer, endpoints, JWKS URI) at start-up from a configured issuer; pin the issuer.

## MCP servers and gateways as OAuth resource servers

The Model Context Protocol's authorisation model treats an MCP server as an **OAuth resource server** (verify against the spec revision you target — it has moved between revisions):

| Concern | Practice |
|---|---|
| discovery | the server publishes **protected-resource metadata** (RFC 9728) pointing to its authorisation server(s); unauthenticated calls get `401` with a `WWW-Authenticate` header carrying the metadata URL |
| audience | tokens must be issued **for this server** — clients request them with a **resource indicator** (RFC 8707); the server rejects tokens whose `aud` is not itself (no token passthrough to downstream APIs) |
| scopes | map MCP tools/resources to scopes; check per tool call, not only at connection time |
| client registration | pre-registered clients or dynamic registration / client-ID metadata documents, as the spec revision allows |
| transport | HTTP-based transports use OAuth; stdio servers take credentials from the environment |
| user vs agent | a tool call acts *for* a user: carry the delegation (subject + actor) into the policy decision and the audit log (rs-domain-policy) |

Implementation: `rmcp` has an `auth` feature (OAuth client side) and server extension points — check the SDK's `examples/` and docs for the exact types of the version you pin (rs-reuse-first). The validation of inbound tokens still follows `guides/jwt-validation.md`, behind an `Authenticator` port.

## Gateways

At an API gateway / proxy-wasm filter (rs-domain-gateway): validate the token **once** at the edge, write the verified identity to **dedicated properties/headers that clients cannot set** (strip inbound copies first), and have downstream components trust only those. A filter that fails to validate must fail closed.
