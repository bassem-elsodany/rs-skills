#!/bin/bash
# rs-skills meta-cognition hook (UserPromptSubmit)
# Fires on Rust-related prompts and forces the 4-layer routing discipline.
# Claude Code ignores `matcher` for UserPromptSubmit, so the prompt is filtered here,
# using the matcher in hooks.json as the single source of truth.
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
input=$(cat)
if ! printf '%s' "$input" | python3 -c '
import json, re, sys
hooks = json.load(open(sys.argv[1]))
matcher = hooks["hooks"]["UserPromptSubmit"][0]["matcher"]
try:
    prompt = json.load(sys.stdin).get("prompt", "")
except Exception:
    prompt = ""
sys.exit(0 if re.search(matcher, prompt) else 1)
' "$root/hooks/hooks.json" 2>/dev/null; then
  exit 0
fi

cat << 'EOF2'

=== rs-skills: MANDATORY ROUTING ===

A Rust signal was detected. Before answering you MUST route through rs-router
and reason across layers. Loading only one skill is NOT acceptable.

## STEP 1 — Identify the entry layer

| Signal in the prompt | Entry | First skill |
|---|---|---|
| E0xxx, compile/borrow/lifetime/type error | L1 Mechanics | rs-ownership / rs-mutability / rs-traits / rs-error-handling / rs-concurrency (see rs-router error table) |
| "how to design", "which pattern", "best practice", API shape, "where should this go", "split this" | L2 Design | rs-structure, rs-patterns, rs-domain-model, rs-anti-pattern, rs-performance, rs-ecosystem, rs-lifecycle, rs-domain-error, rs-mental-model, **rs-reuse-first** (before implementing any standard/SDK), **rs-ports-adapters** (anything replaceable) |
| web/HTTP/axum · gateway policy/proxy-wasm/Flex PDK · CLI/clap · k8s/grpc · fintech/decimal · embedded/no_std · IoT/MQTT · ML/tensor · DB/cache · JWT/OAuth · policy engine · distributed · eBPF/GPU/io_uring | L3 Domain | rs-domain-web / -gateway / -cli / -cloud-native / -fintech / -embedded / -iot / -ml / -data / -auth / -policy / -distributed / -systems |
| style, naming, review · tests, mocks · logging, tracing · ship, release, CI, lints, MSRV · git/commits/branches/tags · build, docker, disk | L4 Delivery | rs-style · rs-testing · rs-observability · rs-release · rs-git · rs-cleanup |
| unsafe, FFI, raw pointer, transmute | L1 (special) | rs-unsafe |

If a DOMAIN keyword is present you MUST load BOTH the L1 (or L2) skill AND the
rs-domain-* skill.

## STEP 2 — Trace

```
L1 symptom (e.g. Rc is not Send)
    ^ TRACE UP: which design choice (L2) and which domain constraint (L3) caused it?
    v TRACE DOWN: which pattern satisfies the constraint, and how is it implemented (L1)?
    > CHECK L4: is the result testable, observable, and shippable as written?
```

## STEP 3 — Output format (all three sections are required)

### Reasoning Chain
```
+-- L1 Mechanics: [symptom]
|       ^
+-- L3 Domain (rs-domain-xxx): [constraint and why it exists]
|       v
+-- L2 Design: [decision]
|       v
+-- L4 Delivery: [test / observability / release implication, or "none"]
```
### Constraints Analysis — cite the specific rules from the skills you loaded.
### Recommended Solution — code that follows the domain and delivery rules,
not just the compile fix.

## Skills to invoke (use the Skill tool)
- Skill(rs-router) — always first
- Skill(rs-<l1-skill>) — the mechanics skill the router picks
- Skill(rs-domain-xxx) — when domain keywords are present
- Skill(rs-style) — whenever you write or review code
- Skill(rs-structure) — before creating a file or when asked to split/refactor: decide the feature module, never a flat src/
- Skill(rs-design-contract) — whenever you create or edit a .rs file (write/read the Design Contract header)
- Skill(rs-reuse-first) — BEFORE implementing a protocol/standard/vendor API: find the official/de-facto SDK first (never draft it from memory)
- Skill(rs-ports-adapters) — when code talks to anything replaceable (DB, cache, queue, SDK, downstream): port + adapters, no vendor types in the domain
- Skill(rs-cleanup) — when you build, compile, test or run containers: measure disk, clean what you create, report
- Skill(rs-git) — when you commit, branch, tag or release (no AI trailers unless the owner asks)
- Skill(rs-security-review) — untrusted input, services, "review/audit/vulnerability": threat model → capability probe → sec-* classes → triage; Skill(rs-fuzzing) for parsers/decoders; Skill(rs-bugfix) to fix a bug (failing test first, invariant fix, variants)
- Skill(rs-guide) — when unsure which skill applies: the navigation map

When you display that rs-skills is loaded, print exactly:
🦀 rs-skills loaded — routing through rs-router

===================================
EOF2
