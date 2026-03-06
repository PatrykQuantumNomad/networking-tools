#!/usr/bin/env bash
# @description Verify netsec-skills plugin directory contains only allowed files
# @usage bash scripts/validate-plugin-boundary.sh [plugin-dir]
# @dependencies find jq
# validate-plugin-boundary.sh
#
# Verify that the netsec-skills/ plugin directory contains only allowed files.
# Uses an allowlist approach -- any file not matching a known pattern is a violation.
#
# Usage:
#   bash scripts/validate-plugin-boundary.sh [plugin-dir]
#
# Arguments:
#   plugin-dir  Path to the plugin directory (default: netsec-skills)
#
# Examples:
#   bash scripts/validate-plugin-boundary.sh
#   bash scripts/validate-plugin-boundary.sh ./netsec-skills
#   bash scripts/validate-plugin-boundary.sh /path/to/custom-plugin
#
# Exit codes:
#   0  All files match the allowlist (PASS)
#   1  One or more violations found (FAIL)

set -euo pipefail

PLUGIN_DIR="${1:-netsec-skills}"
VIOLATIONS=0
BROKEN_SYMLINKS=0
JSON_ERRORS=0
FILE_COUNT=0

# Verify plugin directory exists
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "ERROR: Plugin directory not found: $PLUGIN_DIR"
  exit 1
fi

# --- Helper: check if a relative path matches the allowlist ---
matches_allowlist() {
  local rel="$1"
  case "$rel" in
    # Skill symlinks (directory symlinks organized by category)
    skills/tools/*)          return 0 ;;
    skills/workflows/*)      return 0 ;;
    skills/agents/*)         return 0 ;;
    skills/utility/*)        return 0 ;;
    # Hook shell scripts and configuration
    hooks/*.sh)              return 0 ;;
    hooks/*.json)            return 0 ;;
    # Agent definition symlinks
    agents/*.md)             return 0 ;;
    # Utility scripts
    scripts/*.sh)            return 0 ;;
    # Plugin manifest
    .claude-plugin/plugin.json) return 0 ;;
    # Content catalog
    marketplace.json)        return 0 ;;
    # Documentation
    README.md)               return 0 ;;
    # Everything else is a violation
    *)                       return 1 ;;
  esac
}

echo "=== Plugin Boundary Validation ==="
echo "Directory: $PLUGIN_DIR"
echo ""

# --- Check 1: Allowlist enforcement ---
echo "--- Allowlist Check ---"
while IFS= read -r file; do
  # Skip directories (find with -type l catches directory symlinks too)
  [[ -d "$file" && ! -L "$file" ]] && continue

  FILE_COUNT=$((FILE_COUNT + 1))

  # Resolve relative path within plugin
  rel="${file#$PLUGIN_DIR/}"

  if ! matches_allowlist "$rel"; then
    echo "  VIOLATION: $rel"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done < <(find "$PLUGIN_DIR" \( -type f -o -type l \))

echo "  Files checked: $FILE_COUNT"
echo ""

# --- Check 2: GSD boundary (defense in depth) ---
echo "--- GSD Boundary Check ---"
GSD_COUNT=$(find "$PLUGIN_DIR" -name "gsd-*" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$GSD_COUNT" -gt 0 ]]; then
  echo "  GSD LEAK: Found $GSD_COUNT gsd-prefixed files:"
  find "$PLUGIN_DIR" -name "gsd-*" -exec echo "    {}" \;
  VIOLATIONS=$((VIOLATIONS + GSD_COUNT))
else
  echo "  No gsd-prefixed files found"
fi
echo ""

# --- Check 3: Broken symlinks ---
echo "--- Symlink Integrity Check ---"
while IFS= read -r link; do
  if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
    echo "  BROKEN: $link -> $(readlink "$link")"
    BROKEN_SYMLINKS=$((BROKEN_SYMLINKS + 1))
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done < <(find "$PLUGIN_DIR" -type l)

TOTAL_SYMLINKS=$(find "$PLUGIN_DIR" -type l 2>/dev/null | wc -l | tr -d ' ')
echo "  Total symlinks: $TOTAL_SYMLINKS"
echo "  Broken symlinks: $BROKEN_SYMLINKS"
echo ""

# --- Check 4: JSON syntax validation ---
echo "--- JSON Syntax Validation ---"
while IFS= read -r jsonfile; do
  if ! jq . "$jsonfile" > /dev/null 2>&1; then
    echo "  INVALID JSON: $jsonfile"
    JSON_ERRORS=$((JSON_ERRORS + 1))
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    echo "  OK: ${jsonfile#$PLUGIN_DIR/}"
  fi
done < <(find "$PLUGIN_DIR" -name "*.json" -type f)
echo ""

# --- Summary ---
echo "=== Summary ==="
echo "  Files checked:     $FILE_COUNT"
echo "  Symlinks:          $TOTAL_SYMLINKS (broken: $BROKEN_SYMLINKS)"
echo "  JSON files:        $(find "$PLUGIN_DIR" -name "*.json" -type f | wc -l | tr -d ' ') (errors: $JSON_ERRORS)"
echo "  Violations:        $VIOLATIONS"
echo ""

if [[ "$VIOLATIONS" -eq 0 ]]; then
  echo "PASS: Plugin boundary clean ($PLUGIN_DIR)"
  exit 0
else
  echo "FAIL: $VIOLATIONS boundary violation(s) found"
  exit 1
fi
