#!/usr/bin/env bash
# UserPromptSubmit hook: the "before you build" gates. Fires in Rust projects when the prompt is about
# implementing a standard/protocol/vendor integration, touching a changeable dependency, building or running
# containers, or version control — the four situations where agents have been wasteful or risky.
# The prompt regex lives in hooks/hooks.json (UserPromptSubmit[1].matcher); Claude Code ignores `matcher` on this
# event, so it is applied here. Silent outside Rust projects. Disable: RS_GATES=off.
set -uo pipefail
[[ "${RS_GATES:-on}" == off ]] && exit 0
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
input=$(cat)
read -r hit cwd < <(printf '%s' "$input" | python3 -I -c '
import json, re, sys
hooks = json.load(open(sys.argv[1]))
rx = hooks["hooks"]["UserPromptSubmit"][1]["matcher"]
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
prompt, cwd = d.get("prompt", ""), d.get("cwd", "") or "."
print("1" if re.search(rx, prompt) else "0", cwd.replace(" ", "\\ "))
' "$root/hooks/hooks.json" 2>/dev/null)
[[ "${hit:-0}" == 1 ]] || exit 0
d="${cwd//\\ / }"; [[ -d "$d" ]] || d="$PWD"; found=0
while [[ "$d" != "/" && -n "$d" ]]; do [[ -f "$d/Cargo.toml" ]] && { found=1; break; }; d="$(dirname "$d")"; done
(( found )) || { [[ -n "$(find "${cwd//\\ / }" -maxdepth 3 -name Cargo.toml -not -path '*/target/*' -print -quit 2>/dev/null)" ]] && found=1; }
(( found )) || exit 0
cat <<'MSG' | sed "s#skills/rs-#${root}/skills/rs-#g"

=== rs-skills: BEFORE YOU BUILD — five gates ===
1. STANDARD / PROTOCOL / VENDOR API (MCP, JSON-RPC, OAuth/JWT, gRPC, Kafka, Redis, ClickHouse, S3, Kubernetes …)?
   Skill(rs-reuse-first) FIRST. Search the market (skills/rs-reuse-first/scripts/sdk-scout.sh "<standard>" --github) and use the
   official / de-facto SDK (e.g. MCP -> `rmcp`). Never draft a protocol from memory. Report what you found and chose.
2. ANYTHING THAT CAN CHANGE (database, cache, queue, search, SDK, downstream service, LLM provider)?
   Skill(rs-ports-adapters): a port you own + adapters per product + contract tests; no vendor types in the domain.
3. BUILDING, TESTING, DOCKER? Skill(rs-cleanup): check disk first (disk-guard.sh), label what you create, and finish with
   cleanup + a "Cleanup report". Never prune volumes or `-a` without the user.
4. PARSES / FILTERS / AUTHORISES UNTRUSTED INPUT, or asked to REVIEW, AUDIT or FIX A BUG? Skill(rs-security-review) (threat model first, then the sec-* classes and
   the triage), Skill(rs-fuzzing) for parsers, Skill(rs-bugfix) (failing test first, fix the invariant, hunt variants). Review a change set with diff-review.py.
5. COMMITS, BRANCHES, TAGS? Skill(rs-git): atomic conventional commits, stage by name, no secrets/artefacts, no force-push on shared
   branches, NO AI co-author trailers unless the owner asks.
(Navigation: Skill(rs-guide).)
===
MSG
