#!/usr/bin/env python3
"""validate-plugin — offline checks that a plugin repository follows the published plugin/skill conventions.

  validate-plugin.py [dir]          # validate (exit 1 on any ERROR; WARN never fails)
  validate-plugin.py --self-test    # prove each check still detects what it exists to detect

Complements `claude plugin validate --strict` (the authoritative check — run it when the Claude CLI is installed;
CI runners usually have none). Rules come from Anthropic's plugin and skill documentation and from practices of
well-maintained skill repositories:

  skills    SKILL.md starts with frontmatter; name == directory, kebab-case, <= 64 chars, no reserved words;
            description present, <= 1024 chars (portable to Kiro etc.; Claude Code allows 1536), no angle brackets; only recognised keys; body <= 500 lines;
            no bare script paths (they resolve only from the bundle root — use ${CLAUDE_PLUGIN_ROOT}/${CLAUDE_SKILL_DIR})
  agents    frontmatter with name + description; tools as a YAML list under `tools:` (not `allowed-tools`, which is
            ignored for agents); no helper documents inside agents/ (every .md there is loaded as an agent)
  commands  frontmatter with description; `allowed-tools` (not `tools`)
  hooks     valid JSON with the top-level "hooks" wrapper; ${CLAUDE_PLUGIN_ROOT} quoted; script exists and is executable
  manifests plugin.json / marketplace.json parse; name kebab-case and not Anthropic-reserved; version == VERSION;
            no hand-listed component arrays that can drift from the directories
  repo      no CLAUDE.md at the plugin root, no OS/Python cache files tracked, no hard-coded home-directory paths
"""
import json
import os
import re
import subprocess
import sys
import tempfile

SKILL_KEYS = {"name", "description", "when_to_use", "argument-hint", "arguments", "disable-model-invocation",
              "user-invocable", "allowed-tools", "disallowed-tools", "model", "effort", "context", "agent",
              "background", "hooks", "paths", "shell", "metadata", "license", "compatibility"}
RESERVED = re.compile(r"(^|-)(claude|anthropic|anthropics)(-|$)")


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None, text
    fm = {}
    cur = None
    for line in m.group(1).split("\n"):
        k = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if k:
            cur = k.group(1)
            fm[cur] = k.group(2)
        elif cur and (line.startswith(" ") or line.startswith("-")):
            fm[cur] += "\n" + line
    return fm, text[m.end():]


def tracked(root):
    r = subprocess.run(["git", "-C", root, "ls-files"], capture_output=True, text=True)
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.split("\n")
    out = []
    for dp, dn, fn in os.walk(root):
        dn[:] = [d for d in dn if d not in (".git", "target", "node_modules")]
        out += [os.path.relpath(os.path.join(dp, f), root) for f in fn]
    return out


def validate(root):
    errs, warns = [], []
    E = lambda m: errs.append(m)
    W = lambda m: warns.append(m)
    files = tracked(root)
    exists = lambda p: os.path.exists(os.path.join(root, p))
    ver = open(os.path.join(root, "VERSION")).read().strip() if exists("VERSION") else None

    # ---- skills
    names = set()
    for f in sorted(x for x in files if re.fullmatch(r"skills/[^/]+/SKILL\.md", x)):
        d = f.split("/")[1]
        text = open(os.path.join(root, f)).read()
        fm, body = frontmatter(text)
        if fm is None:
            E(f"{f}: no frontmatter block on the first line"); continue
        name = fm.get("name", "").strip().strip('"')
        if name != d: E(f"{f}: name '{name}' != directory '{d}'")
        if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) or len(name) > 64: E(f"{f}: name must be kebab-case, <= 64 chars")
        if RESERVED.search(name): E(f"{f}: name contains a reserved word")
        names.add(name)
        desc = fm.get("description", "").strip()
        if not desc: E(f"{f}: description missing")
        if len(desc) + len(fm.get("when_to_use", "")) > 1536: E(f"{f}: description + when_to_use exceed 1536 chars (listing truncates)")
        if len(desc) > 1024: E(f"{f}: description is {len(desc)} chars (> 1024): Kiro and other agents cap it there, so skills stay portable")
        if re.search(r"<[A-Za-z/][^>]*>", desc): E(f"{f}: angle brackets in description")
        for k in fm:
            if k not in SKILL_KEYS: W(f"{f}: unrecognised frontmatter key '{k}' (ignored by Claude Code)")
        if text.count("\n") > 500: E(f"{f}: {text.count(chr(10))} lines (> 500) — move detail into guides/ or rules/")
        for i, line in enumerate(body.split("\n"), 1):
            if re.search(r"(?<![\w./}\-])skills/[a-z][\w-]*/scripts/[\w./-]+\.(sh|py)", line):
                E(f"{f}: bare script path (resolves only from the bundle root): {line.strip()[:70]}"); break

    # ---- agents
    for f in sorted(x for x in files if re.fullmatch(r"agents/.+\.md", x)):
        fm, _ = frontmatter(open(os.path.join(root, f)).read())
        if fm is None: E(f"{f}: no frontmatter — every .md under agents/ loads as an agent; move helper documents elsewhere"); continue
        if not fm.get("name") or not fm.get("description"): E(f"{f}: needs name and description")
        if "allowed-tools" in fm: E(f"{f}: agents use `tools:` — `allowed-tools` is silently ignored and the agent inherits everything")
        if "tools" not in fm: W(f"{f}: no `tools:` list — the agent inherits every tool")
        elif "\n" not in fm["tools"] and not fm["tools"].strip(): E(f"{f}: empty tools")
        if "model" not in fm: W(f"{f}: no `model:`")

    # ---- commands
    for f in sorted(x for x in files if re.fullmatch(r"commands/.+\.md", x)):
        fm, _ = frontmatter(open(os.path.join(root, f)).read())
        if fm is None or not fm.get("description"): E(f"{f}: frontmatter with a description is required")
        elif "tools" in fm and "allowed-tools" not in fm: E(f"{f}: commands use `allowed-tools`, not `tools`")

    # ---- hooks
    if exists("hooks/hooks.json"):
        try:
            h = json.load(open(os.path.join(root, "hooks/hooks.json")))
            if "hooks" not in h: E("hooks/hooks.json: missing the top-level \"hooks\" wrapper")
            for ev, groups in h.get("hooks", {}).items():
                for g in groups:
                    for hk in g.get("hooks", []):
                        c = hk.get("command", "")
                        if "${CLAUDE_PLUGIN_ROOT}" in c and '"${CLAUDE_PLUGIN_ROOT}"' not in c: E(f"hooks.{ev}: ${{CLAUDE_PLUGIN_ROOT}} must be quoted: {c}")
                        m = re.search(r'\$\{CLAUDE_PLUGIN_ROOT\}"?(/[^\s"]+)', c)
                        if m:
                            p = m.group(1).lstrip("/")
                            if not exists(p): E(f"hooks.{ev}: script not found: {p}")
                            elif not os.access(os.path.join(root, p), os.X_OK): E(f"hooks.{ev}: script not executable: {p}")
        except json.JSONDecodeError as e:
            E(f"hooks/hooks.json: invalid JSON ({e})")

    # ---- manifests
    for mf in (".claude-plugin/plugin.json", ".claude-plugin/marketplace.json"):
        if not exists(mf): W(f"{mf} missing"); continue
        try:
            d = json.load(open(os.path.join(root, mf)))
        except json.JSONDecodeError as e:
            E(f"{mf}: invalid JSON ({e})"); continue
        nm = d.get("name", "")
        if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", nm): E(f"{mf}: name must be kebab-case")
        if re.match(r"^(claude|anthropic|anthropics|cc-plugin)-", nm) or nm in ("claude", "anthropic", "claude-code"): E(f"{mf}: name is reserved")
        if ver and d.get("version") != ver: E(f"{mf}: version {d.get('version')} != VERSION {ver}")
        if mf.endswith("plugin.json"):
            for k in ("skills", "commands", "agents"):
                if isinstance(d.get(k), list): W(f"{mf}: hand-listed '{k}' can drift from the directory — rely on the default scan")
    if exists("metadata.json") and ver:
        if json.load(open(os.path.join(root, "metadata.json"))).get("version") != ver: E("metadata.json: version != VERSION")

    # ---- repo hygiene
    if "CLAUDE.md" in files: E("CLAUDE.md at the plugin root is not loaded as context (validate warns) — use AGENTS.md and .claude/CLAUDE.md")
    for f in files:
        base = os.path.basename(f)
        if base in (".DS_Store", "Thumbs.db", "desktop.ini") or f.endswith(".pyc") or "__pycache__/" in f: E(f"{f}: OS/Python cache file is tracked")
    for f in files:
        if re.match(r"(skills|commands|agents|hooks|\.claude|scripts)/", f) and f != "scripts/validate-plugin.py" and f != "scripts/export-public.sh":
            try:
                t = open(os.path.join(root, f), errors="ignore").read()
            except (IsADirectoryError, FileNotFoundError):
                continue
            m = re.search(r"/Users/[a-z][\w.-]+/|C:\\Users\\", t)
            if m and "tests/fixtures" not in f: E(f"{f}: hard-coded home directory path ({m.group(0)})")
    return errs, warns


def self_test():
    ok = True
    def case(name, setup, expect):
        nonlocal ok
        with tempfile.TemporaryDirectory() as d:
            for p, c in setup.items():
                os.makedirs(os.path.dirname(os.path.join(d, p)) or d, exist_ok=True)
                open(os.path.join(d, p), "w").write(c)
            errs, _ = validate(d)
            hit = any(expect in e for e in errs)
            print(("ok   " if hit else "FAIL ") + name)
            ok &= hit
    good = "---\nname: rs-x\ndescription: Does x. Use when y.\n---\nbody\n"
    case("skill name mismatch", {"skills/rs-y/SKILL.md": good}, "!= directory")
    case("missing frontmatter", {"skills/rs-x/SKILL.md": "# no fm\n"}, "no frontmatter")
    case("angle brackets", {"skills/rs-x/SKILL.md": "---\nname: rs-x\ndescription: uses <b>x</b>\n---\n"}, "angle brackets")
    case("description over 1024", {"skills/rs-x/SKILL.md": "---\nname: rs-x\ndescription: " + "word " * 250 + "\n---\n"}, "> 1024")
    case("too long", {"skills/rs-x/SKILL.md": good + "x\n" * 600}, "> 500")
    case("bare script path", {"skills/rs-x/SKILL.md": good + "run skills/rs-x/scripts/go.sh now\n"}, "bare script path")
    case("agent allowed-tools", {"agents/a.md": "---\nname: a\ndescription: d\nallowed-tools: Read\n---\n"}, "silently ignored")
    case("agent helper doc", {"agents/_shared/h.md": "# helper\n"}, "no frontmatter")
    case("command without description", {"commands/c.md": "# /c\n"}, "description is required")
    case("hook unquoted", {"hooks/hooks.json": json.dumps({"hooks": {"Stop": [{"hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/x.sh"}]}]}})}, "must be quoted")
    case("hook missing wrapper", {"hooks/hooks.json": "{}"}, "wrapper")
    case("claude.md at root", {"CLAUDE.md": "x"}, "CLAUDE.md at the plugin root")
    case("ds_store tracked", {".DS_Store": "x"}, "cache file")
    case("home path", {"skills/rs-x/SKILL.md": good + "see /Users/someone/x\n"}, "home directory")
    case("version drift", {"VERSION": "2.0.0\n", ".claude-plugin/plugin.json": json.dumps({"name": "p", "version": "1.0.0"})}, "!= VERSION")
    print("self-test " + ("passed" if ok else "FAILED"))
    return 0 if ok else 1


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    root = next((a for a in sys.argv[1:] if not a.startswith("-")), ".")
    errs, warns = validate(os.path.abspath(root))
    for w in warns: print("WARN ", w)
    for e in errs: print("ERROR", e)
    print(f"validate-plugin: {len(errs)} error(s), {len(warns)} warning(s)")
    sys.exit(1 if errs else 0)
