#!/usr/bin/env python3
"""TDD tests for the rs-skills hook matcher.  Run: python3 tests/hook-matcher-test.py"""
import json, re, sys
from pathlib import Path

hooks_path = Path(__file__).parent.parent / "hooks" / "hooks.json"
MATCHER = json.load(open(hooks_path))["hooks"]["UserPromptSubmit"][0]["matcher"]
print(f"=== rs-skills hook matcher tests ===\nmatcher: {hooks_path}\n")

# (prompt, should_match)
cases = [
    # Rust signals — must fire
    ("how do I fix E0382", True),
    ("value moved here, cannot borrow", True),
    ("Arc vs Rc for shared state", True),
    ("cargo build fails on linux", True),
    ("is this unsafe block sound?", True),
    ("design a builder for Config", True),
    ("which design pattern fits a plugin system in Rust", True),
    ("tokio spawn requires Send", True),
    ("my axum handler panics on unwrap", True),
    ("add tracing spans to the service", True),
    ("ship this to production", True),
    ("what is the MSRV policy", True),
    ("thiserror or anyhow for a library?", True),
    ("write a newtype for UserId", True),
    ("is Deref for inheritance an anti-pattern", True),
    ("refactor main.rs", True),
    # noise — must not fire
    ("what's for dinner", False),
    ("book a flight to Rome", False),
    ("meeting at 3pm tomorrow", False),
    ("summarise this email", False),
    ("review my function", False),  # no Rust context; CLAUDE.md router-first still applies inside Rust projects
]
passed = failed = 0
for text, should in cases:
    m = re.search(MATCHER, text)
    ok = (m is not None) == should
    passed += ok; failed += (not ok)
    tag = "PASS" if ok else "FAIL"
    got = f"matched '{m.group()}'" if m else "no match"
    print(f"{'✅' if ok else '❌'} {tag}: '{text}' -> {got}")
print(f"\nPassed: {passed}/{len(cases)}  Failed: {failed}/{len(cases)}")
sys.exit(1 if failed else 0)
