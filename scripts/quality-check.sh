#!/bin/bash
# Quality check script for rs-skills
# Run before releases to ensure consistency

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "======================================"
echo "Rust Skills Quality Check"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

error() {
    echo -e "${RED}ERROR:${NC} $1"
    ERRORS=$((ERRORS+1))
}

warn() {
    echo -e "${YELLOW}WARN:${NC} $1"
    WARNINGS=$((WARNINGS+1))
}

pass() {
    echo -e "${GREEN}OK:${NC} $1"
}

# =====================================
# 1. Check SKILL.md Frontmatter
# =====================================
echo "Checking SKILL.md frontmatter..."

for skill_file in $(find "$ROOT_DIR/skills" -name "SKILL.md" -type f); do
    skill_name=$(dirname "$skill_file" | xargs basename)

    # Check for required fields
    if ! grep -q "^name:" "$skill_file"; then
        error "$skill_name/SKILL.md missing 'name:' field"
    fi

    if ! grep -q "^description:" "$skill_file"; then
        error "$skill_name/SKILL.md missing 'description:' field"
    fi

    # Check description has trigger words
    desc_lines=$(sed -n '/^description:/,/^[a-z]*:/p' "$skill_file" | head -20)
    if [ ${#desc_lines} -lt 50 ]; then
        warn "$skill_name/SKILL.md description may be too short for triggering"
    fi
done

echo ""

# =====================================
# 1b. Navigation catalogue and metadata are generated: they must be current
# =====================================
echo "Checking guide catalogue and metadata..."
if python3 -I "$ROOT_DIR/scripts/gen-guide.py" --check >/dev/null 2>&1; then
    pass "rs-guide catalogue and metadata.json are current"
else
    error "rs-guide catalogue / metadata.json stale or a skill has no layer — run: python3 -I scripts/gen-guide.py"
fi
echo ""

# =====================================
# 1c. Plugin conventions (frontmatter, agents, commands, hooks, manifests, hygiene)
# =====================================
echo "Checking plugin conventions..."
if python3 -I "$ROOT_DIR/scripts/validate-plugin.py" "$ROOT_DIR" > /tmp/rs-validate.$$ 2>&1; then
    pass "validate-plugin.py: no errors"
else
    grep -E "^ERROR" /tmp/rs-validate.$$ | head -10; error "validate-plugin.py found convention errors"
fi
rm -f /tmp/rs-validate.$$
echo ""

# =====================================
# 2. Check Agent Tool Declarations
# =====================================
echo "Checking agent tool declarations..."

for agent_file in "$ROOT_DIR"/agents/*.md; do
    agent_name=$(basename "$agent_file" .md)

    if ! grep -q "^tools:" "$agent_file"; then
        warn "$agent_name agent has no 'tools:' declaration (inherits defaults)"
    fi

    if ! grep -q "^model:" "$agent_file"; then
        warn "$agent_name agent missing 'model:' declaration"
    fi
done

echo ""

# =====================================
# 3. Check for Dead Links in Skills
# =====================================
echo "Checking for dead internal links..."

for md_file in $(find "$ROOT_DIR/skills" -name "*.md" -type f); do
    # Extract markdown links
    links=$(grep -oE '\[.*\]\(([^)]+)\)' "$md_file" 2>/dev/null | grep -oE '\(([^)]+)\)' | tr -d '()' || true)

    for link in $links; do
        # Skip external links and anchors
        if [[ "$link" == http* ]] || [[ "$link" == \#* ]]; then
            continue
        fi

        # Resolve relative path
        dir=$(dirname "$md_file")
        full_path="$dir/$link"

        if [ ! -f "$full_path" ]; then
            warn "Dead link in $(basename "$md_file"): $link"
        fi
    done
done

echo ""

# =====================================
# 4. Check Version Consistency
# =====================================
echo "Checking version consistency..."

version_file="$ROOT_DIR/VERSION"
metadata_file="$ROOT_DIR/metadata.json"

if [ -f "$version_file" ] && [ -f "$metadata_file" ]; then
    version=$(cat "$version_file" | tr -d '[:space:]')
    metadata_version=$(grep '"version"' "$metadata_file" | head -1 | cut -d'"' -f4)

    if [ "$version" != "$metadata_version" ]; then
        error "Version mismatch: VERSION=$version, metadata.json=$metadata_version"
    else
        pass "Version consistent: $version"
    fi
else
    warn "Missing VERSION or metadata.json"
fi

echo ""

# =====================================
# 5. Check Required Directories
# =====================================
echo "Checking required directories..."

required_dirs=(
    "skills"
    "agents"
    "commands"
    "cache"
    "tests"
    "templates"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$ROOT_DIR/$dir" ]; then
        count=$(find "$ROOT_DIR/$dir" -type f | wc -l)
        pass "$dir/ exists ($count files)"
    else
        error "$dir/ missing"
    fi
done

echo ""

# =====================================
# 6. Check Skill Count Matches Metadata
# =====================================
echo "Checking skill counts..."

if [ -f "$metadata_file" ]; then
    expected_meta=$(grep '"total_skills"' "$metadata_file" | grep -oE '[0-9]+')
    actual_meta=$(find "$ROOT_DIR/skills" -maxdepth 1 -type d -name "rs-*" | wc -l | tr -d '[:space:]')

    if [ "$expected_meta" = "$actual_meta" ]; then
        pass "Skill count: $actual_meta"
    else
        error "Skill count: metadata.json says $expected_meta, found $actual_meta"
    fi

fi

echo ""

# =====================================
# Summary
# =====================================
echo "======================================"
echo "Quality Check Summary"
echo "======================================"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Quality check FAILED${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Quality check PASSED with warnings${NC}"
    exit 0
else
    echo -e "${GREEN}Quality check PASSED${NC}"
    exit 0
fi
