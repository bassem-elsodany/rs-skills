#!/bin/bash
# Rust Skills Validation Script
# Run this to validate skills are properly configured

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "======================================"
echo "Rust Skills Validation"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED=1
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

FAILED=0

# =====================================
# Directory Structure Check
# =====================================
echo "Checking directory structure..."

dirs=(
    "skills/rs-ownership"
    "skills/rs-error-handling"
    "skills/rs-concurrency"
    "skills/rs-performance"
    "skills/rs-mental-model"
    "skills/rs-anti-pattern"
    "skills/rs-unsafe"
    "skills/rs-style"
    "skills/rs-router"
    "skills/rs-learner"
    "agents"
    "commands"
    "cache"
    "tests"
)

for dir in "${dirs[@]}"; do
    if [ -d "$ROOT_DIR/$dir" ]; then
        pass "$dir exists"
    else
        fail "$dir missing"
    fi
done

echo ""

# =====================================
# SKILL.md Files Check
# =====================================
echo "Checking SKILL.md files..."

skill_files=(
    "skills/rs-ownership/SKILL.md"
    "skills/rs-error-handling/SKILL.md"
    "skills/rs-concurrency/SKILL.md"
    "skills/rs-unsafe/SKILL.md"
    "skills/rs-style/SKILL.md"
    "skills/rs-router/SKILL.md"
    "skills/rs-learner/SKILL.md"
)

for file in "${skill_files[@]}"; do
    if [ -f "$ROOT_DIR/$file" ]; then
        # Check for required frontmatter
        if grep -q "^name:" "$ROOT_DIR/$file" && grep -q "^description:" "$ROOT_DIR/$file"; then
            pass "$file valid"
        else
            fail "$file missing frontmatter"
        fi
    else
        fail "$file missing"
    fi
done

echo ""

# =====================================
# Agent Files Check
# =====================================
echo "Checking agent files..."

agent_files=(
    "agents/crate-researcher.md"
    "agents/rs-changelog.md"
    "agents/docs-researcher.md"
    "agents/clippy-researcher.md"
)

for file in "${agent_files[@]}"; do
    if [ -f "$ROOT_DIR/$file" ]; then
        if grep -q "^tools:" "$ROOT_DIR/$file"; then
            pass "$file valid"
        else
            warn "$file has no tools section (inherits defaults)"
        fi
    else
        fail "$file missing"
    fi
done

echo ""

# =====================================
# Command Files Check
# =====================================
echo "Checking command files..."

command_files=(
    "commands/guideline.md"
    "commands/unsafe-check.md"
    "commands/unsafe-review.md"
)

for file in "${command_files[@]}"; do
    if [ -f "$ROOT_DIR/$file" ]; then
        pass "$file exists"
    else
        fail "$file missing"
    fi
done

echo ""

# =====================================
# Unsafe-Checker Rules Check
# =====================================
echo "Checking rs-unsafe rules..."

rule_count=$(find "$ROOT_DIR/skills/rs-unsafe/rules" -name "*.md" ! -name "_*" 2>/dev/null | wc -l)
if [ "$rule_count" -ge 40 ]; then
    pass "rs-unsafe has $rule_count rules (expected 40+)"
else
    warn "rs-unsafe has $rule_count rules (expected 40+)"
fi

# Check checklists
if [ -d "$ROOT_DIR/skills/rs-unsafe/checklists" ]; then
    checklist_count=$(find "$ROOT_DIR/skills/rs-unsafe/checklists" -name "*.md" | wc -l)
    if [ "$checklist_count" -ge 2 ]; then
        pass "rs-unsafe has $checklist_count checklists"
    else
        warn "rs-unsafe has few checklists"
    fi
else
    fail "rs-unsafe checklists missing"
fi

echo ""

# =====================================
# Deep Dive Content Check
# =====================================
echo "Checking deep dive content..."

deep_content=(
    "skills/rs-ownership/patterns/common-errors.md"
    "skills/rs-ownership/patterns/lifetime-patterns.md"
    "skills/rs-ownership/comparison.md"
    "skills/rs-concurrency/patterns/common-errors.md"
    "skills/rs-concurrency/patterns/async-patterns.md"
    "skills/rs-performance/patterns/optimization-guide.md"
    "skills/rs-mental-model/patterns/thinking-in-rust.md"
    "skills/rs-anti-pattern/patterns/common-mistakes.md"
)

for file in "${deep_content[@]}"; do
    if [ -f "$ROOT_DIR/$file" ]; then
        pass "$file exists"
    else
        warn "$file missing (deep dive content)"
    fi
done

echo ""

# =====================================
# Cache Structure Check
# =====================================
echo "Checking cache structure..."

if [ -f "$ROOT_DIR/cache/config.yaml" ]; then
    pass "cache/config.yaml exists"
else
    warn "cache/config.yaml missing"
fi

cache_dirs=("crates" "rust-versions" "clippy-lints" "docs")
for dir in "${cache_dirs[@]}"; do
    if [ -d "$ROOT_DIR/cache/$dir" ]; then
        pass "cache/$dir exists"
    else
        warn "cache/$dir missing"
    fi
done

echo ""

# =====================================
# Summary
# =====================================
echo "======================================"
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
else
    echo -e "${RED}Some checks failed.${NC}"
fi
echo "======================================"

exit $FAILED
