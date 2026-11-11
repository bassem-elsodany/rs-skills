#!/usr/bin/env python3
"""Generate the `## Rules` section of every SKILL.md that has a rules/ directory.

  scripts/gen-rule-index.py            # write
  scripts/gen-rule-index.py --check    # exit 1 if any index is stale

The section lives between <!-- rules-index:start --> and <!-- rules-index:end -->;
if the markers are absent it is inserted before `## Related Skills` (or appended).
"""
import os, re, sys, glob
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
check = "--check" in sys.argv
START, END = "<!-- rules-index:start -->", "<!-- rules-index:end -->"
stale = 0
for skill_dir in sorted(glob.glob(f"{ROOT}/skills/*/")):
    rules = sorted(glob.glob(f"{skill_dir}rules/*.md"))
    rules = [r for r in rules if not os.path.basename(r).startswith("_")]
    if not rules: continue
    sk = os.path.basename(skill_dir.rstrip("/"))
    items = []
    for r in rules:
        rid = os.path.basename(r)[:-3]
        s = open(r).read()
        m = re.search(r"^> (?!\*\*rs-)(.+)$", s, re.M)
        if not m: m = re.search(r"^# (.+)$", s, re.M)          # actionbook-style rules: use the title
        summary = m.group(1).strip() if m else ""
        items.append(f"- [`{rid}`](rules/{rid}.md) — {summary}")
    # group by prefix
    groups = {}
    for it in items:
        pre = re.match(r"- \[`([a-z]+)-", it).group(1); groups.setdefault(pre, []).append(it)
    body = [START, f"## Rules ({len(items)})", "", f"Depth rules under `rules/` — open the one the question needs, not all of them."]
    for pre, its in groups.items():
        body += ["", f"**{pre}-**", ""] + its
    body += ["", END]
    section = "\n".join(body)
    p = f"{skill_dir}SKILL.md"; s = open(p).read()
    if START in s and END in s:
        new = re.sub(re.escape(START) + r".*?" + re.escape(END), lambda m: section, s, flags=re.S)
    elif "## Related Skills" in s:
        new = s.replace("## Related Skills", section + "\n\n---\n\n## Related Skills", 1)
    else:
        new = s.rstrip("\n") + "\n\n---\n\n" + section + "\n"
    if new != s:
        stale += 1
        if check: print(f"STALE {sk}/SKILL.md rules index")
        else: open(p, "w").write(new); print(f"indexed {sk}: {len(items)} rules")
if check:
    print("rule indexes up to date" if not stale else f"{stale} stale"); sys.exit(1 if stale else 0)
