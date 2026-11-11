#!/usr/bin/env python3
"""check-diagrams — render every ```mermaid block in the Markdown docs, so a broken diagram is found before GitHub shows it.

  python3 -I scripts/check-diagrams.py [--keep DIR]      # needs Mermaid CLI: npm i -g @mermaid-js/mermaid-cli  (mmdc)

Also checks that docs/diagrams/*.mmd (the editable sources) match the blocks embedded in README.md.
Skips with exit 0 and a note when mmdc is not installed (CI runners usually have none).
"""
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
keep = sys.argv[sys.argv.index("--keep") + 1] if "--keep" in sys.argv else None
blocks = []
for f in ["README.md"] + sorted(glob.glob(os.path.join(root, "docs", "*.md"))):
    p = f if os.path.isabs(f) else os.path.join(root, f)
    for i, m in enumerate(re.finditer(r"```mermaid\n(.*?)\n```", open(p).read(), re.S), 1):
        blocks.append((os.path.relpath(p, root), i, m.group(1)))
bad = 0
readme = open(os.path.join(root, "README.md")).read()
for src in sorted(glob.glob(os.path.join(root, "docs", "diagrams", "*.mmd"))):
    text = open(src).read().strip()
    if text not in readme:
        print(f"DRIFT  {os.path.relpath(src, root)} is not embedded verbatim in README.md"); bad += 1
mmdc = shutil.which("mmdc")
if not mmdc:
    print(f"mmdc not found: {len(blocks)} mermaid block(s) not rendered (npm i -g @mermaid-js/mermaid-cli)")
    sys.exit(1 if bad else 0)
out = keep or tempfile.mkdtemp(prefix="rs-diagrams.")
os.makedirs(out, exist_ok=True)
for f, i, code in blocks:
    n = f"{os.path.basename(f)}-{i}"
    mmd = os.path.join(out, n + ".mmd")
    open(mmd, "w").write(code)
    r = subprocess.run([mmdc, "-i", mmd, "-o", os.path.join(out, n + ".png"), "-b", "white"], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"FAIL   {f} block {i}: {(r.stderr or r.stdout).strip().splitlines()[-1][:160]}"); bad += 1
    else:
        print(f"OK     {f} block {i}")
if not keep: shutil.rmtree(out, ignore_errors=True)
print(f"diagrams: {len(blocks)} block(s), {bad} problem(s)")
sys.exit(1 if bad else 0)
