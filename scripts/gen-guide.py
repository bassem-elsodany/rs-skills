#!/usr/bin/env python3
"""Keep the navigation catalogue and the bundle statistics in step with the skills on disk.

  scripts/gen-guide.py            # rewrite skills/rs-guide/SKILL.md catalogue + metadata.json stats
  scripts/gen-guide.py --check    # exit 1 when either is stale or a skill has no layer (CI / quality gate)

The catalogue (between <!-- catalog:start --> and <!-- catalog:end -->) lists every skill by layer with its
Core Question and what it ships (rules, guides, scripts, templates), so an agent can navigate without
opening 60 files.  A skill missing from LAYERS is reported: classify it here when you add a skill.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECK = "--check" in sys.argv

LAYERS = [
    ("Entry", "Start here", ["rs-router", "rs-guide"]),
    ("L1", "Mechanics — how do I implement it?", [
        "rs-ownership", "rs-resource", "rs-mutability", "rs-traits", "rs-type-driven",
        "rs-error-handling", "rs-concurrency", "rs-async-patterns", "rs-macros-const", "rs-unsafe"]),
    ("L2", "Design — what pattern fits, and what should I not build?", [
        "rs-reuse-first", "rs-ports-adapters", "rs-structure", "rs-patterns", "rs-api-design", "rs-domain-model",
        "rs-domain-error", "rs-ecosystem", "rs-lifecycle", "rs-performance", "rs-anti-pattern", "rs-mental-model"]),
    ("L3", "Domain — why is it designed this way?", [
        "rs-domain-web", "rs-domain-auth", "rs-domain-policy", "rs-domain-data", "rs-domain-distributed",
        "rs-domain-gateway", "rs-domain-cloud-native", "rs-domain-fintech", "rs-domain-cli", "rs-domain-embedded",
        "rs-domain-iot", "rs-domain-ml", "rs-domain-systems"]),
    ("L4", "Delivery — is it shippable, reviewable, cleaned up?", [
        "rs-design-contract", "rs-style", "rs-testing", "rs-fuzzing", "rs-observability", "rs-git", "rs-review",
        "rs-security-review", "rs-bugfix", "rs-release", "rs-cleanup"]),
    ("Tools", "Navigation, research and maintenance", [
        "rs-learner", "rs-daily", "rs-code-navigator", "rs-call-graph", "rs-symbol-analyzer", "rs-trait-explorer",
        "rs-refactor-helper", "rs-deps-visualizer", "rs-meta-parallel", "rs-skill-creator", "rs-util-actionbook",
        "rs-util-agent-browser", "rs-util-dynamic-skills", "rs-util-fix-skill-docs"]),
]
SHORT = {  # one-liners for skills whose SKILL.md has no usable "Core Question"
    "rs-guide": "Which skill do I open, in which order, and what must I never skip?",
    "rs-router": "Which layer does this question enter at, and which skill answers it first?",
    "rs-unsafe": "Is this unsafe block sound, and is the safety argument written down?",
    "rs-domain-web": "How do requests flow through a stateless service — routing, extractors, state, middleware — within latency limits?",
    "rs-domain-cloud-native": "Will this run, scale, stop and be observed correctly as a container in a cluster (12-factor, health, shutdown)?",
    "rs-domain-fintech": "Can every amount, rounding and state change be exact, auditable and reproducible?",
    "rs-domain-cli": "Is the command-line contract (args, config precedence, output, exit codes) clear and scriptable?",
    "rs-domain-embedded": "What must hold with no heap, no OS and real-time deadlines (no_std, interrupts, HALs)?",
    "rs-domain-iot": "How does this behave offline, on a flaky link, on constrained power (MQTT, telemetry, edge)?",
    "rs-domain-ml": "Where do memory, device placement and numerics dominate (tensors, inference, GPU)?",
    "rs-domain-gateway": "If this filter cannot do its job on this request, what reaches the upstream or the client? (nothing unchecked)",
    "rs-style": "Does the code follow Rust naming, formatting and lint conventions?",
    "rs-learner": "What is the latest Rust version / crate version / language feature, from live sources?",
    "rs-daily": "What happened in the Rust ecosystem today / this week / this month?",
    "rs-code-navigator": "Where is this symbol defined and used (LSP)?",
    "rs-call-graph": "Who calls this function, and what does it call (LSP call hierarchy)?",
    "rs-symbol-analyzer": "What structs, traits and functions make up this project (LSP symbols)?",
    "rs-trait-explorer": "Who implements this trait, and which traits does this type implement?",
    "rs-refactor-helper": "What breaks if I rename/move/extract this, and in which order is it safe (LSP)?",
    "rs-deps-visualizer": "How do the project's dependencies relate (ASCII graph)?",
    "rs-meta-parallel": "(experimental) What does an L1/L2/L3 parallel analysis of this question say?",
    "rs-skill-creator": "How do I turn crate or std documentation into a skill in the house format?",
    "rs-util-actionbook": "(internal) actionbook MCP selectors used by documentation research.",
    "rs-util-agent-browser": "(internal) agent-browser CLI workflows used by the research agents.",
    "rs-util-dynamic-skills": "(internal) generate/sync/clean skills for the project's dependencies.",
    "rs-util-fix-skill-docs": "(internal) check and repair generated skill documentation references.",
    "rs-daily-note": "",
}


def read(path):
    with open(path, errors="replace") as f:
        return f.read()


def core_question(skill, text):
    if skill in SHORT and SHORT[skill]:
        return SHORT[skill]
    m = re.search(r"^## Core Question\s*\n+(.+?)(?:\n\n|\n---|\n##)", text, re.S | re.M)
    if m:
        q = re.sub(r"\s+", " ", m.group(1)).strip().strip("*").strip()
        return q[:200]
    if skill in SHORT:
        return SHORT[skill]
    d = re.search(r'^description:\s*"?(.+?)"?\s*$', text, re.M)
    return (d.group(1)[:160] if d else "").strip()


def ships(skill):
    d = os.path.join(ROOT, "skills", skill)
    bits = []
    if skill == "rs-patterns":
        pages = len([f for f in glob.glob(f"{d}/**/*.md", recursive=True) if "/SKILL" not in f and "SOURCES" not in f])
        return f"{pages} pattern pages"
    n = len([f for f in glob.glob(f"{d}/rules/*.md") if not os.path.basename(f).startswith("_")])
    if n:
        bits.append(f"{n} rules")
    for sub in ("guides", "patterns", "examples", "templates", "scripts", "registry", "checklists"):
        if os.path.isdir(os.path.join(d, sub)) and os.listdir(os.path.join(d, sub)):
            bits.append(sub)
    return ", ".join(bits)


def build():
    on_disk = sorted(os.path.basename(os.path.dirname(p)) for p in glob.glob(f"{ROOT}/skills/*/SKILL.md"))
    known = [s for _, _, group in LAYERS for s in group]
    unclassified = [s for s in on_disk if s not in known]
    missing = [s for s in known if s not in on_disk]
    lines = []
    for tag, title, group in LAYERS:
        lines += [f"### {tag} — {title}", "", "| Skill | Core question | Ships |", "|---|---|---|"]
        for s in group:
            if s not in on_disk:
                continue
            q = core_question(s, read(f"{ROOT}/skills/{s}/SKILL.md")).replace("|", "\\|")
            lines.append(f"| `{s}` | {q} | {ships(s)} |")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n", on_disk, unclassified, missing


def stats(on_disk):
    group = {t: [s for s in g if s in on_disk] for t, _, g in LAYERS}
    rules = len([f for f in glob.glob(f"{ROOT}/skills/*/rules/*.md") if not os.path.basename(f).startswith("_")])
    return {
        "total_skills": len(on_disk),
        "entry": len(group["Entry"]), "layer1_mechanics": len(group["L1"]), "layer2_design": len(group["L2"]),
        "layer3_domain": len(group["L3"]), "layer4_delivery": len(group["L4"]), "tools": len(group["Tools"]),
        "agents": len([f for f in glob.glob(f"{ROOT}/agents/*.md")]),
        "commands": len(glob.glob(f"{ROOT}/commands/*.md")),
        "rules": rules,
        "pattern_pages": len(glob.glob(f"{ROOT}/skills/rs-patterns/**/*.md", recursive=True)) - 3,
    }, {
        "entry": group["Entry"], "layer1_mechanics": group["L1"], "layer2_design": group["L2"],
        "layer3_domain": group["L3"], "layer4_delivery": group["L4"], "tools": group["Tools"],
    }


catalog, on_disk, unclassified, missing = build()
problems = []
if unclassified:
    problems.append("skills without a layer in scripts/gen-guide.py: " + ", ".join(unclassified))
if missing:
    problems.append("LAYERS lists skills that do not exist: " + ", ".join(missing))

guide = f"{ROOT}/skills/rs-guide/SKILL.md"
START, END = "<!-- catalog:start -->", "<!-- catalog:end -->"
if os.path.exists(guide):
    s = read(guide)
    new = re.sub(re.escape(START) + r".*?" + re.escape(END), lambda m: f"{START}\n{catalog}{END}", s, flags=re.S)
    if new != s:
        if CHECK:
            problems.append("skills/rs-guide/SKILL.md catalogue is stale (run scripts/gen-guide.py)")
        else:
            open(guide, "w").write(new)
            print("catalogue updated")
else:
    problems.append("skills/rs-guide/SKILL.md missing")

meta_path = f"{ROOT}/metadata.json"
meta = json.load(open(meta_path))
st, sk = stats(on_disk)
if meta.get("stats") != {**meta.get("stats", {}), **st} or meta.get("skills") != sk or meta.get("version") != read(f"{ROOT}/VERSION").strip():
    if CHECK:
        problems.append("metadata.json stats/skills are stale (run scripts/gen-guide.py)")
    else:
        meta["stats"].update(st)
        meta["skills"] = sk
        meta["version"] = read(f"{ROOT}/VERSION").strip()
        open(meta_path, "w").write(json.dumps(meta, indent=2) + "\n")
        print("metadata.json updated:", st["total_skills"], "skills,", st["rules"], "rules")

if CHECK:
    for p in problems:
        print("FAIL", p)
    print("guide catalogue and metadata up to date" if not problems else f"{len(problems)} problem(s)")
    sys.exit(1 if problems else 0)
for p in problems:
    print("WARN", p)
