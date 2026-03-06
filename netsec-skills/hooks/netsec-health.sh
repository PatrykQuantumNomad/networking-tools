#!/usr/bin/env bash
# netsec-health.sh — Health check for the networking-tools safety architecture
# Verifies that all safety hooks are installed, registered, and functioning.
# Supports optional -j flag for JSON output.
#
# Exit 0 = all checks pass, Exit 1 = one or more failures

set -uo pipefail

# ---------- Options ----------
JSON_OUTPUT=false
if [[ "${1:-}" == "-j" ]]; then
  JSON_OUTPUT=true
fi

# ---------- Counters and state ----------
PASS=0
FAIL=0
CHECKS=()

check() {
    local label="$1" result="$2"
    if [[ "$result" == "true" ]]; then
        if [[ "$JSON_OUTPUT" == "false" ]]; then
            echo "  [pass] $label"
        fi
        ((PASS++))
        CHECKS+=("{\"label\":\"$label\",\"status\":\"pass\"}")
    else
        if [[ "$JSON_OUTPUT" == "false" ]]; then
            echo "  [FAIL] $label"
        fi
        ((FAIL++))
        CHECKS+=("{\"label\":\"$label\",\"status\":\"fail\"}")
    fi
}

# ---------- Determine project root ----------
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# ---------- 1. Hook Files ----------
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Hook Files"
    echo "----------"
fi

PRETOOL="$PROJECT_DIR/.claude/hooks/netsec-pretool.sh"
POSTTOOL="$PROJECT_DIR/.claude/hooks/netsec-posttool.sh"

check "PreToolUse hook file exists (.claude/hooks/netsec-pretool.sh)" \
    "$( [[ -f "$PRETOOL" ]] && echo true || echo false )"

check "PostToolUse hook file exists (.claude/hooks/netsec-posttool.sh)" \
    "$( [[ -f "$POSTTOOL" ]] && echo true || echo false )"

check "PreToolUse hook is executable" \
    "$( [[ -x "$PRETOOL" ]] && echo true || echo false )"

check "PostToolUse hook is executable" \
    "$( [[ -x "$POSTTOOL" ]] && echo true || echo false )"

# ---------- 2. Hook Registration ----------
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Hook Registration"
    echo "-----------------"
fi

SETTINGS="$PROJECT_DIR/.claude/settings.json"

check "PreToolUse hook registered in settings.json" \
    "$( jq -e '.hooks.PreToolUse' "$SETTINGS" &>/dev/null && echo true || echo false )"

check "PostToolUse hook registered in settings.json" \
    "$( jq -e '.hooks.PostToolUse' "$SETTINGS" &>/dev/null && echo true || echo false )"

# ---------- 3. Scope Configuration ----------
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Scope Configuration"
    echo "-------------------"
fi

SCOPE_FILE="$PROJECT_DIR/.pentest/scope.json"

check "Scope file exists (.pentest/scope.json)" \
    "$( [[ -f "$SCOPE_FILE" ]] && echo true || echo false )"

check "Scope file is valid JSON with targets array" \
    "$( jq -e '.targets | type == "array"' "$SCOPE_FILE" &>/dev/null && echo true || echo false )"

if [[ -f "$SCOPE_FILE" ]] && [[ "$JSON_OUTPUT" == "false" ]]; then
    TARGETS=$(jq -r '.targets | join(", ")' "$SCOPE_FILE" 2>/dev/null)
    if [[ -n "$TARGETS" ]]; then
        echo "  Targets: $TARGETS"
    fi
fi

# ---------- 4. Audit Infrastructure ----------
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Audit Infrastructure"
    echo "--------------------"
fi

AUDIT_DIR="$PROJECT_DIR/.pentest"

check "Audit directory exists (.pentest/)" \
    "$( [[ -d "$AUDIT_DIR" ]] && echo true || echo false )"

check "Audit directory is writable" \
    "$( [[ -w "$AUDIT_DIR" ]] && echo true || echo false )"

check ".pentest/ is gitignored" \
    "$( cd "$PROJECT_DIR" && git check-ignore -q .pentest/ 2>/dev/null && echo true || echo false )"

if [[ -d "$AUDIT_DIR" ]] && [[ "$JSON_OUTPUT" == "false" ]]; then
    AUDIT_COUNT=$(ls "$AUDIT_DIR"/audit-*.jsonl 2>/dev/null | wc -l | tr -d ' ')
    echo "  Audit files: $AUDIT_COUNT"
fi

# ---------- 5. Dependencies ----------
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Dependencies"
    echo "------------"
fi

check "jq is installed" \
    "$( command -v jq &>/dev/null && echo true || echo false )"

check "bash version >= 4.0 (associative arrays)" \
    "$( [[ "${BASH_VERSINFO[0]}" -ge 4 ]] && echo true || echo false )"

# ---------- Summary ----------
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "=== $PASS passed, $FAIL failed ==="
fi

# ---------- JSON output ----------
if [[ "$JSON_OUTPUT" == "true" ]]; then
    CHECKS_JSON=$(printf '%s\n' "${CHECKS[@]}" | jq -s '.')
    jq -n \
        --argjson checks "$CHECKS_JSON" \
        --arg pass "$PASS" \
        --arg fail "$FAIL" \
        '{checks:$checks, passed:($pass|tonumber), failed:($fail|tonumber)}'
fi

# ---------- Guided repair (interactive terminal only) ----------
if [[ "$FAIL" -gt 0 ]] && [[ -t 0 ]] && [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Some checks failed. Would you like to attempt guided repair?"
    echo ""

    # Hook files not executable
    if [[ -f "$PRETOOL" && ! -x "$PRETOOL" ]] || [[ -f "$POSTTOOL" && ! -x "$POSTTOOL" ]]; then
        read -rp "Fix: Make hook files executable? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            chmod +x "$PRETOOL" "$POSTTOOL" 2>/dev/null && echo "  Fixed." || echo "  Failed."
        fi
    fi

    # Audit directory missing
    if [[ ! -d "$AUDIT_DIR" ]]; then
        read -rp "Fix: Create .pentest/ audit directory? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            mkdir -p "$AUDIT_DIR" && echo "  Fixed." || echo "  Failed."
        fi
    fi

    # Scope file missing
    if [[ ! -f "$SCOPE_FILE" ]]; then
        read -rp "Fix: Create .pentest/scope.json with default lab targets? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            mkdir -p "$AUDIT_DIR"
            echo '{"targets":["localhost","127.0.0.1"],"ports":[],"notes":"Default scope - add your targets here"}' > "$SCOPE_FILE"
            echo "  Fixed."
        fi
    fi

    # .pentest/ not gitignored
    if ! (cd "$PROJECT_DIR" && git check-ignore -q .pentest/ 2>/dev/null); then
        read -rp "Fix: Add .pentest/ to .gitignore? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo ".pentest/" >> "$PROJECT_DIR/.gitignore" && echo "  Fixed." || echo "  Failed."
        fi
    fi
fi

# ---------- Exit code ----------
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
