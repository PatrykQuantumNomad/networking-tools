#!/usr/bin/env bash
# netsec-health.sh -- Health check for the networking-tools safety architecture
# Detects plugin vs in-repo context and adapts checks accordingly.
# Supports optional -j flag for JSON output.
#
# Plugin context: CLAUDE_PLUGIN_ROOT set, hooks at $CLAUDE_PLUGIN_ROOT/hooks/
# In-repo context: hooks at .claude/hooks/, registration in .claude/settings.json
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
        PASS=$((PASS + 1))
        CHECKS+=("{\"label\":\"$label\",\"status\":\"pass\"}")
    else
        if [[ "$JSON_OUTPUT" == "false" ]]; then
            echo "  [FAIL] $label"
        fi
        FAIL=$((FAIL + 1))
        CHECKS+=("{\"label\":\"$label\",\"status\":\"fail\"}")
    fi
}

# ---------- Resolve project directory ----------
resolve_project_dir() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    echo "$CLAUDE_PROJECT_DIR"
  elif git rev-parse --show-toplevel 2>/dev/null; then
    :
  else
    pwd
  fi
}

PROJECT_DIR="$(resolve_project_dir)"

# ---------- Context detection ----------
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  CONTEXT="plugin"
  HOOK_DIR="$CLAUDE_PLUGIN_ROOT/hooks"
  HOOK_CONFIG="$CLAUDE_PLUGIN_ROOT/hooks/hooks.json"
  HOOK_LABEL="plugin: hooks/"
  CONFIG_LABEL="hooks.json"
else
  CONTEXT="in-repo"
  HOOK_DIR="$PROJECT_DIR/.claude/hooks"
  HOOK_CONFIG="$PROJECT_DIR/.claude/settings.json"
  HOOK_LABEL=".claude/hooks/"
  CONFIG_LABEL="settings.json"
fi

if [[ "$JSON_OUTPUT" == "false" ]]; then
  echo "Context: $CONTEXT"
fi

# ---------- 1. Hook Files ----------
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Hook Files"
    echo "----------"
fi

PRETOOL="$HOOK_DIR/netsec-pretool.sh"
POSTTOOL="$HOOK_DIR/netsec-posttool.sh"

check "PreToolUse hook file exists ($HOOK_LABEL)" \
    "$( [[ -f "$PRETOOL" ]] && echo true || echo false )"

check "PostToolUse hook file exists ($HOOK_LABEL)" \
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

check "PreToolUse hook registered in $CONFIG_LABEL" \
    "$( jq -e '.hooks.PreToolUse' "$HOOK_CONFIG" &>/dev/null && echo true || echo false )"

check "PostToolUse hook registered in $CONFIG_LABEL" \
    "$( jq -e '.hooks.PostToolUse' "$HOOK_CONFIG" &>/dev/null && echo true || echo false )"

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

# Informational: report bash version (no longer a hard requirement)
if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo "  bash version: ${BASH_VERSION}"
fi

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
        --arg context "$CONTEXT" \
        '{context:$context, checks:$checks, passed:($pass|tonumber), failed:($fail|tonumber)}'
fi

# ---------- Guided repair (interactive terminal only) ----------
if [[ "$FAIL" -gt 0 ]] && [[ -t 0 ]] && [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo "Some checks failed. Would you like to attempt guided repair?"
    echo ""

    # Hook files not executable (in-repo context only -- plugin hooks are managed by the plugin system)
    if [[ "$CONTEXT" == "in-repo" ]]; then
        if [[ -f "$PRETOOL" && ! -x "$PRETOOL" ]] || [[ -f "$POSTTOOL" && ! -x "$POSTTOOL" ]]; then
            read -rp "Fix: Make hook files executable? [y/N] " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                chmod +x "$PRETOOL" "$POSTTOOL" 2>/dev/null && echo "  Fixed." || echo "  Failed."
            fi
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
            echo '{"targets":["localhost","127.0.0.1"]}' > "$SCOPE_FILE"
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
