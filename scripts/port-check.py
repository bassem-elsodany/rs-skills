#!/usr/bin/env python3
"""port-check — find vendor/product code that leaked out of the adapter layer (rs-ports-adapters).

  python3 -I scripts/port-check.py [dir] [--adapters a,b] [--allow x.rs,y.rs] [--vendors crate,crate]
                                   [--strict] [--json]

What it reports (heuristic: a review aid, not a proof):
  LEAK      a vendor crate path (`sqlx::`, `redis::`, `clickhouse::`, `rmcp::` …) used outside the adapter layer
  SQL       a SQL / query-language string in business code
  CFG       `cfg(feature = "<vendor>")` scattered through business code
  DEP       a core/domain/app crate whose Cargo.toml depends on a vendor crate
  NOPORT    vendor dependencies exist but no port-shaped trait does

Adapter layer = any path component named adapters/adapter/infra/infrastructure/backends/drivers/connectors/api/inbound/outbound/transport/delivery,
a crate dir named `adapter-*`, `*-adapter(s)`, `*-infra`, or whatever you pass in --adapters.
Allowed to name vendors too: main.rs, bin/, wiring/composition/bootstrap/app.rs, build.rs, tests/, benches/, examples/.
"""
import json
import os
import re
import sys

# Crates whose replacement a user, a licence, a cost or a vendor decision can force.
VENDORS = """
sqlx diesel sea_orm tokio_postgres rusqlite redis fred deadpool_redis bb8_redis clickhouse mongodb
rdkafka lapin async_nats rumqttc paho_mqtt aws_sdk_s3 aws_sdk_dynamodb aws_sdk_sqs aws_sdk_sns aws_config object_store
elasticsearch opensearch meilisearch_sdk tantivy qdrant_client kube k8s_openapi bollard lettre rmcp
reqwest opentelemetry opentelemetry_otlp stripe async_stripe twilio async_openai genai rig
azure_core azure_storage_blobs google_cloud_storage google_cloud_pubsub scylla cdrs_tokio neo4rs surrealdb
""".split()

ADAPTER_DIRS = {"adapters", "adapter", "infra", "infrastructure", "backends", "drivers", "connectors", "api", "inbound", "outbound", "transport", "delivery"}
ROOT_FILES = {"main.rs", "wiring.rs", "composition.rs", "bootstrap.rs", "app.rs", "build.rs"}
SKIP_DIRS = {"target", ".git", "node_modules", "tests", "benches", "examples", "fixtures", "bin"}
CORE_CRATE = re.compile(r"(^|[-_])(core|domain|app|application|model|models|service|services)([-_]|$)")
ADAPTER_CRATE = re.compile(r"(^adapters?[-_]|[-_]adapters?$|[-_]infra$|^infra[-_])")
PORT_TRAIT = re.compile(
    r"^\s*pub(\([a-z]+\))?\s+trait\s+\w*(Store|Repository|Repo|Gateway|Client|Cache|Queue|Port|Publisher|Subscriber|Sender|Provider|Source|Sink|Clock)\b"
)
SQL = re.compile(r'"[^"\n]*\b(SELECT\s+.+\s+FROM|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|CREATE\s+TABLE)\b', re.I)


def main(argv):
    root, adapters, allow, vendors, strict, as_json = ".", [], set(), set(VENDORS), False, False
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--adapters":
            adapters = [p.strip("/") for p in argv[i + 1].split(",")]; i += 2
        elif a == "--allow":
            allow = set(argv[i + 1].split(",")); i += 2
        elif a == "--vendors":
            vendors |= {v.replace("-", "_") for v in argv[i + 1].split(",")}; i += 2
        elif a == "--strict":
            strict = True; i += 1
        elif a == "--json":
            as_json = True; i += 1
        elif a in ("-h", "--help"):
            print(__doc__); return 0
        else:
            root = a; i += 1
    vend_re = re.compile(r"\b(" + "|".join(sorted(vendors, key=len, reverse=True)) + r")::")
    cfg_re = re.compile(r'cfg\([^)]*feature\s*=\s*"(' + "|".join(v.replace("_", "[-_]") for v in sorted(vendors)) + r')"')
    findings = []
    port_traits = 0
    vendor_files = set()

    def is_adapter(rel):
        parts = rel.split(os.sep)
        if any(p in ADAPTER_DIRS for p in parts[:-1]):
            return True
        if any(ADAPTER_CRATE.search(p) for p in parts[:-1]):
            return True
        return any(rel.startswith(a + os.sep) or rel == a for a in adapters)

    def is_allowed_root(rel):
        parts = rel.split(os.sep)
        base = parts[-1]
        if base in ROOT_FILES or base in allow or rel in allow:
            return True
        return "bin" in parts[:-1] or any(p in ("tests", "benches", "examples", "fixtures") for p in parts[:-1])

    for dp, dn, fn in os.walk(root):
        dn[:] = sorted(d for d in dn if d not in {"target", ".git", "node_modules"})
        for f in sorted(fn):
            path = os.path.join(dp, f)
            rel = os.path.relpath(path, root)
            if f == "Cargo.toml":
                crate_dir = os.path.basename(os.path.dirname(os.path.abspath(path)))
                text = open(path, errors="ignore").read()
                name = (re.search(r'^name\s*=\s*"([^"]+)"', text, re.M) or [None, crate_dir])[1]
                src_dir = os.path.join(os.path.dirname(os.path.abspath(path)), "src")
                has_adapter_dir = os.path.isdir(src_dir) and any(d in ADAPTER_DIRS for d in os.listdir(src_dir))
                # a crate that keeps its own adapters/ directory is a composition crate, not a pure core crate
                if CORE_CRATE.search(name) and not ADAPTER_CRATE.search(name) and not is_adapter(rel) and not has_adapter_dir:
                    deps = sorted({m.group(1).replace("-", "_") for m in re.finditer(r"^([A-Za-z0-9_-]+)\s*(?:=|\.workspace)", text, re.M)} & vendors)
                    if deps:
                        findings.append(("DEP", rel, 0, f"crate `{name}` depends on {', '.join(deps)} — move the code that needs them to an adapter crate"))
                continue
            if not f.endswith(".rs") or is_adapter(rel) or is_allowed_root(rel):
                continue
            in_block = False
            for n, line in enumerate(open(path, errors="ignore"), 1):
                s = line.strip()
                if in_block:
                    in_block = "*/" not in s
                    continue
                if s.startswith("/*"):
                    in_block = "*/" not in s
                    continue
                if s.startswith("//"):
                    continue
                if PORT_TRAIT.match(line):
                    port_traits += 1
                m = vend_re.search(line)
                if m:
                    vendor_files.add(rel)
                    hint = "derive on a domain type — give the adapter its own row type" if "derive(" in line else "vendor type outside the adapter layer"
                    findings.append(("LEAK", rel, n, f"`{m.group(1)}::` — {hint}"))
                if SQL.search(line):
                    findings.append(("SQL", rel, n, "query language in business code — the port expresses intent (`daily_counts`), the adapter owns the query"))
                if cfg_re.search(line):
                    findings.append(("CFG", rel, n, "backend chosen with cfg in business code — select it in the composition root"))
    manifests_with_vendors = False
    for dp, dn, fn in os.walk(root):
        dn[:] = [d for d in dn if d not in {"target", ".git", "node_modules"}]
        if "Cargo.toml" in fn:
            t = open(os.path.join(dp, "Cargo.toml"), errors="ignore").read()
            if {m.group(1).replace("-", "_") for m in re.finditer(r"^([A-Za-z0-9_-]+)\s*(?:=|\.workspace)", t, re.M)} & vendors:
                manifests_with_vendors = True
    if manifests_with_vendors and port_traits == 0:
        findings.append(("NOPORT", ".", 0, "vendor crates are dependencies but no port-shaped trait (…Store/Repository/Gateway/Cache/Queue…) exists — see rs-ports-adapters"))

    if as_json:
        print(json.dumps([{"kind": k, "file": f, "line": ln, "message": m} for k, f, ln, m in findings], indent=2))
    else:
        for k, f, ln, m in findings:
            loc = f"{f}:{ln}" if ln else f
            print(f"{k:<7} {loc}  {m}")
        leaks = len(findings)
        print(f"ports: {leaks} finding(s); {port_traits} port-shaped trait(s); vendor names used in {len(vendor_files)} non-adapter file(s)")
        if leaks:
            print("fix: define the port in the feature module, move the vendor code to adapters/<product>/, map types and errors at that boundary (skills/rs-ports-adapters/SKILL.md)")
    return 1 if strict and findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
