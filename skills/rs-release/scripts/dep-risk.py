#!/usr/bin/env python3
"""dep-risk — supply-chain risk report for a Cargo project's dependencies.

  dep-risk.py [dir] [--offline] [--all] [--json out.json] [--out report.md]

Measures (never guesses) what can be measured, and says plainly what could not be:
  local, always     build scripts and proc-macros (code that runs at BUILD time), git/path/patched sources,
                    wildcard or unpinned requirements, duplicate versions of a crate
  crates.io         latest version vs locked, yanked, last release age, owner count, recent downloads, licence
  OSV (RustSec)     advisories matching each locked version  (api.osv.dev)
Default scope = direct dependencies of the workspace members (+ the build-time-code census over the whole tree);
--all queries every locked crate (slow: 1 request/second to crates.io).

Rules this script follows (rs-release `rel-supply-chain-evidence`):
  * unavailable data is never evidence of risk — it is reported as "unassessable: <reason>"
  * an absent measurement is never a clean verdict — a run that measured nothing exits non-zero
Network use: only public crate names and versions are sent (crates.io, api.osv.dev). --offline sends nothing.
"""
import datetime
import json
import os
import subprocess
import sys
import time
import urllib.request

UA = "rs-skills dep-risk (generic client)"


def http(url, data=None, timeout=20):
    req = urllib.request.Request(url, data=data, headers={"User-Agent": UA, **({"Content-Type": "application/json"} if data else {})})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def cargo_metadata(root):
    r = subprocess.run(["cargo", "metadata", "--format-version", "1", "--locked"], cwd=root, capture_output=True, text=True)
    if r.returncode != 0:
        r = subprocess.run(["cargo", "metadata", "--format-version", "1"], cwd=root, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("cargo metadata failed: " + r.stderr.strip()[:400])
    return json.loads(r.stdout)


def main(argv):
    root, offline, scope_all, jpath, opath = ".", False, False, None, None
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--offline": offline = True; i += 1
        elif a == "--all": scope_all = True; i += 1
        elif a == "--json": jpath = argv[i + 1]; i += 2
        elif a == "--out": opath = argv[i + 1]; i += 2
        elif a in ("-h", "--help"): print(__doc__); return 0
        else: root = a; i += 1
    meta = cargo_metadata(root)
    pk = {p["id"]: p for p in meta["packages"]}
    members = set(meta["workspace_members"])
    member_names = {pk[m]["name"] for m in members}
    direct = {}
    for m in members:
        for d in pk[m]["dependencies"]:
            direct.setdefault(d["name"], {"req": set(), "kinds": set()})
            direct[d["name"]]["req"].add(d["req"])
            direct[d["name"]]["kinds"].add(d.get("kind") or "normal")
    locked = {}
    for p in meta["packages"]:
        if p["id"] in members:
            continue
        locked.setdefault(p["name"], []).append(p)
    rows = []
    build_time = []
    for name, pkgs in sorted(locked.items()):
        for p in pkgs:
            kinds = {k for t in p["targets"] for k in t["kind"]}
            bt = [k for k in ("custom-build", "proc-macro") if k in kinds]
            src = p.get("source") or "path"
            kind = "registry" if src.startswith("registry+") else "git" if src.startswith("git+") else "path"
            if bt:
                build_time.append((name, p["version"], ",".join(bt), kind))
            if name in direct or scope_all:
                rows.append({"name": name, "version": p["version"], "source": kind, "build_time_code": bt,
                             "direct": name in direct, "req": sorted(direct.get(name, {}).get("req", [])), "license": p.get("license")})
    versions = {n: sorted({p["version"] for p in ps}) for n, ps in locked.items()}
    dups = {n: v for n, v in versions.items() if len(v) > 1}

    measured = 0
    unassessable = {}
    today = datetime.date.today()
    if not offline:
        # advisories, one batch call
        try:
            q = {"queries": [{"package": {"name": r["name"], "ecosystem": "crates.io"}, "version": r["version"]} for r in rows if r["source"] == "registry"]}
            res = http("https://api.osv.dev/v1/querybatch", json.dumps(q).encode())
            regs = [r for r in rows if r["source"] == "registry"]
            for r, item in zip(regs, res.get("results", [])):
                r["advisories"] = sorted({v["id"] for v in item.get("vulns", [])})
                measured += 1
        except Exception as e:
            unassessable["advisories"] = f"OSV unreachable: {type(e).__name__}"
        # crates.io facts
        for r in rows:
            if r["source"] != "registry":
                r["registry"] = "unassessable: not a crates.io source"
                continue
            try:
                c = http(f"https://crates.io/api/v1/crates/{r['name']}")
                time.sleep(1.0)       # crawler policy: <= 1 request/second
                crate = c["crate"]
                vers = {v["num"]: v for v in c.get("versions", [])}
                cur = vers.get(r["version"], {})
                r["latest"] = crate.get("max_stable_version") or crate.get("max_version")
                r["yanked"] = bool(cur.get("yanked"))
                upd = crate.get("updated_at", "")[:10]
                r["last_release"] = upd
                r["age_days"] = (today - datetime.date.fromisoformat(upd)).days if upd else None
                r["recent_downloads"] = crate.get("recent_downloads")
                try:
                    o = http(f"https://crates.io/api/v1/crates/{r['name']}/owners")
                    time.sleep(1.0)
                    r["owners"] = len(o.get("users", []))
                except Exception:
                    r["owners"] = None
                measured += 1
            except Exception as e:
                r["registry"] = f"unassessable: {type(e).__name__}"
        if not any("latest" in r for r in rows):
            unassessable["crates.io"] = "no crates.io data retrieved"
    if not rows:
        print("dep-risk: no dependencies found", file=sys.stderr)
        return 2
    if not offline and measured == 0:
        print("dep-risk: nothing could be measured (network?). Refusing to print an empty 'clean' report; use --offline for the local census.", file=sys.stderr)
        return 3

    # flags
    for r in rows:
        f = []
        if r.get("yanked"): f.append("YANKED")
        if r.get("advisories"): f.append("ADVISORY " + ",".join(r["advisories"][:4]))
        if r["source"] != "registry": f.append(r["source"].upper() + " SOURCE")
        if any(rq in ("*", "") for rq in r["req"]): f.append("WILDCARD REQ")
        if r["build_time_code"]: f.append("BUILD-TIME CODE (" + ",".join(r["build_time_code"]) + ")")
        if r.get("age_days") is not None and r["age_days"] > 730: f.append(f"STALE {r['age_days']//365}y")
        if r.get("owners") == 1 and r.get("recent_downloads", 0) and r["recent_downloads"] > 1_000_000: f.append("single owner (info)")
        if r.get("latest") and r["latest"].split(".")[0] != r["version"].split(".")[0]: f.append(f"MAJOR BEHIND ({r['version']}→{r['latest']})")
        r["flags"] = f

    out = ["# Dependency risk report", "",
           f"_Scope: {'every locked crate' if scope_all else 'direct dependencies'} of {', '.join(sorted(member_names))} — {len(rows)} crate(s). "
           f"Mode: {'offline (local census only)' if offline else 'online (crates.io + OSV)'}. Generated {today}._", "",
           "## Coverage (read this first)", "",
           f"- measured online: {measured} lookup(s); " + ("; ".join(f"{k}: {v}" for k, v in unassessable.items()) or "no lookup failures"),
           "- **unassessable is not risk** and **no flags is not endorsement**: a crate with no flags was measured against these criteria only.",
           "- not covered: licence compliance (use `cargo deny`), vulnerabilities not yet in RustSec/OSV, malicious code review of the crates themselves (see `cargo vet`).", "",
           "## Code that runs at build time (whole tree)", "",
           f"{len(build_time)} crate(s) with a build script or proc-macro run arbitrary code during `cargo build/check/test` and in rust-analyzer — with your privileges and environment.", "",
           "| Crate | Version | Kind | Source |", "|---|---|---|---|"]
    out += [f"| `{n}` | {v} | {k} | {s} |" for n, v, k, s in sorted(build_time)[:80]]
    if len(build_time) > 80:
        out.append(f"| … {len(build_time) - 80} more | | | |")
    out += ["", "## Flagged dependencies", "", "| Crate | Locked | Direct | Flags |", "|---|---|---|---|"]
    flagged = [r for r in rows if r["flags"]]
    out += [f"| `{r['name']}` | {r['version']} | {'yes' if r['direct'] else 'no'} | {'; '.join(r['flags'])} |" for r in sorted(flagged, key=lambda r: (-len(r['flags']), r['name']))] or ["| — | | | none |"]
    out += ["", "## Duplicate versions in the tree", ""]
    out += [f"- `{n}`: {', '.join(v)}" for n, v in sorted(dups.items())[:30]] or ["- none"]
    out += ["", "## All measured crates", "", "| Crate | Locked | Latest | Last release | Owners | Yanked | Advisories |", "|---|---|---|---|---|---|---|"]
    for r in sorted(rows, key=lambda r: r["name"]):
        out.append(f"| `{r['name']}` | {r['version']} | {r.get('latest','—')} | {r.get('last_release','—')} | {r.get('owners','—') if r.get('owners') is not None else '—'} | "
                   f"{'yes' if r.get('yanked') else ('—' if 'yanked' not in r else 'no')} | {', '.join(r.get('advisories', [])) or ('—' if 'advisories' not in r else 'none')} |")
    out += ["", "## What to do", "",
            "1. **ADVISORY / YANKED**: upgrade (`cargo update -p <crate>` or bump the requirement); if no fixed version exists, replace or vendor and note it in a decision record.",
            "2. **BUILD-TIME CODE** on new or rarely used crates: review the build script/proc-macro, or build in a sandbox without secrets (rs-cleanup `guides/devcontainer.md`); consider `cargo vet`.",
            "3. **GIT/PATH SOURCE, WILDCARD REQ**: pin to a registry version or a commit; `cargo deny` `[sources]` rejects unknown registries/git.",
            "4. **STALE / SINGLE OWNER**: judgement — check upstream activity; prefer official or well-maintained alternatives (rs-reuse-first).", ""]
    text = "\n".join(out)
    if opath:
        open(opath, "w").write(text + "\n"); print("wrote", opath)
    else:
        print(text)
    if jpath:
        json.dump({"rows": rows, "build_time": build_time, "duplicates": dups}, open(jpath, "w"), indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
