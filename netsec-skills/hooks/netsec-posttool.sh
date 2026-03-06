#!/usr/bin/env bash
# PostToolUse safety hook for networking-tools
# Implements: SAFE-03 (JSON bridge / additionalContext injection), SAFE-04 (audit logging)
#
# Reads hook JSON from stdin. Only processes Bash tool invocations that ran
# wrapper scripts (commands containing scripts/). Everything else fast-exits.

set -euo pipefail

# ---------- 1. Read stdin ----------
INPUT=$(cat)

# ---------- 2. Fast exit if not Bash tool ----------
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# ---------- 3. Fast exit if not a wrapper script invocation ----------
if [[ "$COMMAND" != *"scripts/"* ]]; then
  exit 0
fi

# ---------- Project directory ----------
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
AUDIT_DIR="$PROJECT_DIR/.pentest"
mkdir -p "$AUDIT_DIR"

# ---------- 4. Extract metadata from command ----------
# Tool name from script path: scripts/<tool>/... -> <tool>
SCRIPT_TOOL=$(echo "$COMMAND" | grep -oE 'scripts/[^/]+' | head -1 | sed 's|scripts/||')
SCRIPT_TOOL="${SCRIPT_TOOL:-unknown}"

# Script name from path: .../script-name.sh -> script-name
SCRIPT_NAME=$(echo "$COMMAND" | grep -oE '[^/]+\.sh' | head -1 | sed 's|\.sh||')
SCRIPT_NAME="${SCRIPT_NAME:-unknown}"

# Target: first positional argument after .sh
TARGET=$(echo "$COMMAND" | grep -oE 'scripts/[^[:space:]]+\.sh[[:space:]]+([^[:space:]]+)' | head -1 | sed 's|scripts/[^[:space:]]*\.sh[[:space:]]*||')
TARGET="${TARGET:-}"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# ---------- 5. Extract tool_response fields (graceful degradation) ----------
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // "unknown"')
STDOUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // empty')

# ---------- 6. SAFE-03: Detect and parse JSON envelope ----------
ADDITIONAL_CONTEXT=""
RESULTS_TOTAL=""
RESULTS_OK=""
RESULTS_FAIL=""

if [[ "$COMMAND" == *" -j"* || "$COMMAND" == *" -j "* ]] && [[ -n "$STDOUT" ]]; then
  # Check if stdout is valid JSON with the netsec envelope structure
  if echo "$STDOUT" | jq -e '.meta.tool and .results and .summary' >/dev/null 2>&1; then
    # Parse envelope fields
    ENV_TOOL=$(echo "$STDOUT" | jq -r '.meta.tool // empty')
    ENV_SCRIPT=$(echo "$STDOUT" | jq -r '.meta.script // empty')
    ENV_TARGET=$(echo "$STDOUT" | jq -r '.meta.target // empty')
    ENV_MODE=$(echo "$STDOUT" | jq -r '.meta.mode // "unknown"')
    RESULTS_TOTAL=$(echo "$STDOUT" | jq -r '.summary.total // 0')
    RESULTS_OK=$(echo "$STDOUT" | jq -r '.summary.succeeded // 0')
    RESULTS_FAIL=$(echo "$STDOUT" | jq -r '.summary.failed // 0')

    ADDITIONAL_CONTEXT="Netsec result: ${ENV_TOOL} (${ENV_SCRIPT}) against ${ENV_TARGET} in ${ENV_MODE} mode. ${RESULTS_TOTAL} items: ${RESULTS_OK} succeeded, ${RESULTS_FAIL} failed."
  fi
fi

# ---------- 7. SAFE-04: Build and append audit log entry ----------
AUDIT_FILE="$AUDIT_DIR/audit-$(date +%Y-%m-%d).jsonl"

if [[ -n "$RESULTS_TOTAL" ]]; then
  jq -n -c \
    --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg event "executed" \
    --arg tool "$SCRIPT_TOOL" \
    --arg command "$COMMAND" \
    --arg target "$TARGET" \
    --arg script "$SCRIPT_NAME" \
    --arg exit_code "$EXIT_CODE" \
    --arg session "$SESSION_ID" \
    --arg results_total "$RESULTS_TOTAL" \
    --arg results_ok "$RESULTS_OK" \
    --arg results_fail "$RESULTS_FAIL" \
    '{timestamp:$ts, event:$event, tool:$tool, command:$command, target:$target, script:$script, exit_code:$exit_code, session:$session, results_total:$results_total, results_ok:$results_ok, results_fail:$results_fail}' \
    >> "$AUDIT_FILE"
else
  jq -n -c \
    --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg event "executed" \
    --arg tool "$SCRIPT_TOOL" \
    --arg command "$COMMAND" \
    --arg target "$TARGET" \
    --arg script "$SCRIPT_NAME" \
    --arg exit_code "$EXIT_CODE" \
    --arg session "$SESSION_ID" \
    '{timestamp:$ts, event:$event, tool:$tool, command:$command, target:$target, script:$script, exit_code:$exit_code, session:$session}' \
    >> "$AUDIT_FILE"
fi

# ---------- 8. Output additionalContext JSON if envelope was parsed ----------
if [[ -n "$ADDITIONAL_CONTEXT" ]]; then
  jq -n -c \
    --arg ctx "$ADDITIONAL_CONTEXT" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
fi

exit 0
