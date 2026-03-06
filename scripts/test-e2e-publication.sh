#!/usr/bin/env bash
# scripts/test-e2e-publication.sh -- End-to-end plugin publication validation
# Validates the netsec-skills plugin directory is ready for publication
# via both skills.sh and plugin marketplace channels.
#
# Usage: bash scripts/test-e2e-publication.sh [plugin-dir]
# Default plugin-dir: netsec-skills

set -euo pipefail

PLUGIN_DIR="${1:-netsec-skills}"
PASS=0
FAIL=0
TOTAL=0
ERRORS=""

# Colors (respect NO_COLOR)
if [[ -z "${NO_COLOR:-}" ]]; then
    GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
else
    GREEN=""; RED=""; YELLOW=""; RESET=""
fi

_check() {
    local desc="$1"; shift
    TOTAL=$((TOTAL + 1))
    if "$@" > /dev/null 2>&1; then
        printf "  ${GREEN}PASS${RESET}: %s\n" "$desc"
        PASS=$((PASS + 1))
    else
        printf "  ${RED}FAIL${RESET}: %s\n" "$desc"
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  - ${desc}"
    fi
}

# ============================================================
# Section 1: Plugin Structure
# ============================================================
echo ""
echo "=== Section 1: Plugin Structure ==="

_check "plugin.json exists" test -f "$PLUGIN_DIR/.claude-plugin/plugin.json"
_check "plugin.json is valid JSON" jq . "$PLUGIN_DIR/.claude-plugin/plugin.json"
_check "marketplace.json exists" test -f "$PLUGIN_DIR/marketplace.json"
_check "marketplace.json is valid JSON" jq . "$PLUGIN_DIR/marketplace.json"
_check "hooks.json exists" test -f "$PLUGIN_DIR/hooks/hooks.json"
_check "hooks.json is valid JSON" jq . "$PLUGIN_DIR/hooks/hooks.json"
_check "Repo-root marketplace exists" test -f ".claude-plugin/marketplace.json"
_check "Repo-root marketplace is valid JSON" jq . ".claude-plugin/marketplace.json"
_check "Repo-root marketplace source points to plugin dir" \
    jq -e '.plugins[0].source == "./netsec-skills"' ".claude-plugin/marketplace.json"

# ============================================================
# Section 2: Skills
# ============================================================
echo ""
echo "=== Section 2: Skills ==="

SKILL_COUNT=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')
_check "SKILL.md count is 31 (found: $SKILL_COUNT)" test "$SKILL_COUNT" -eq 31

# Check every SKILL.md has name: in frontmatter
_all_have_name() {
    local missing=0
    while IFS= read -r skillfile; do
        if ! awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$skillfile" | grep -q '^name:'; then
            missing=$((missing + 1))
        fi
    done < <(find "$PLUGIN_DIR/skills" -name "SKILL.md")
    return "$missing"
}
_check "Every SKILL.md has name: in frontmatter" _all_have_name

# Check every SKILL.md has description: in frontmatter
_all_have_description() {
    local missing=0
    while IFS= read -r skillfile; do
        if ! awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$skillfile" | grep -q '^description:'; then
            missing=$((missing + 1))
        fi
    done < <(find "$PLUGIN_DIR/skills" -name "SKILL.md")
    return "$missing"
}
_check "Every SKILL.md has description: in frontmatter" _all_have_description

MARKETPLACE_SKILL_COUNT=$(jq '.skills | length' "$PLUGIN_DIR/marketplace.json")
_check "marketplace.json skill count is 27 (found: $MARKETPLACE_SKILL_COUNT)" \
    test "$MARKETPLACE_SKILL_COUNT" -eq 27

# ============================================================
# Section 3: Hooks
# ============================================================
echo ""
echo "=== Section 3: Hooks ==="

_check "netsec-pretool.sh exists and is executable" test -x "$PLUGIN_DIR/hooks/netsec-pretool.sh"
_check "netsec-posttool.sh exists and is executable" test -x "$PLUGIN_DIR/hooks/netsec-posttool.sh"
_check "netsec-health.sh exists" test -f "$PLUGIN_DIR/hooks/netsec-health.sh"

# ============================================================
# Section 4: Agents
# ============================================================
echo ""
echo "=== Section 4: Agents ==="

AGENT_COUNT=$(find "$PLUGIN_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
_check "3 agent .md files in agents/ (found: $AGENT_COUNT)" test "$AGENT_COUNT" -eq 3
_check "pentester.md exists" test -f "$PLUGIN_DIR/agents/pentester.md"
_check "defender.md exists" test -f "$PLUGIN_DIR/agents/defender.md"
_check "analyst.md exists" test -f "$PLUGIN_DIR/agents/analyst.md"

# ============================================================
# Section 5: GSD Boundary
# ============================================================
echo ""
echo "=== Section 5: GSD Boundary ==="

GSD_COUNT=$(find "$PLUGIN_DIR" -name 'gsd-*' | wc -l | tr -d ' ')
_check "No gsd-prefixed files in plugin dir (found: $GSD_COUNT)" test "$GSD_COUNT" -eq 0
_check "No .planning directory in plugin dir" test ! -d "$PLUGIN_DIR/.planning"

if [[ -f "scripts/validate-plugin-boundary.sh" ]]; then
    _check "validate-plugin-boundary.sh passes" bash scripts/validate-plugin-boundary.sh "$PLUGIN_DIR"
else
    echo "  ${YELLOW}SKIP${RESET}: validate-plugin-boundary.sh not found"
fi

# ============================================================
# Section 6: Portability
# ============================================================
echo ""
echo "=== Section 6: Portability ==="

SYMLINK_COUNT=$(find "$PLUGIN_DIR" -type l | wc -l | tr -d ' ')
_check "Zero symlinks in plugin dir (found: $SYMLINK_COUNT)" test "$SYMLINK_COUNT" -eq 0

# Check for absolute paths in hook scripts (excluding shebangs)
_no_absolute_paths_in_hooks() {
    local found=0
    while IFS= read -r hookfile; do
        # grep for lines starting with / but exclude shebang lines (#!/)
        if grep -v '^#!' "$hookfile" | grep -q '^/'; then
            found=$((found + 1))
        fi
    done < <(find "$PLUGIN_DIR/hooks" -name "*.sh")
    return "$found"
}
_check "No absolute paths in hook scripts" _no_absolute_paths_in_hooks

# ============================================================
# Summary
# ============================================================
echo ""
echo "=== Results: ${PASS}/${TOTAL} passed, ${FAIL} failed ==="
if [[ "$FAIL" -gt 0 ]]; then
    printf "\nFailed checks:${ERRORS}\n"
    exit 1
fi
exit 0
