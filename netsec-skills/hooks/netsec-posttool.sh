#!/usr/bin/env bash
# PostToolUse safety hook for networking-tools (portable plugin version)
# Implements: SAFE-03 (JSON bridge / additionalContext injection), SAFE-04 (audit logging)
#
# Portable version: works both in-repo and as a Claude Code plugin via ${CLAUDE_PLUGIN_ROOT}.
# Logs audit entries for both wrapper script and direct tool invocations.
# Requires bash 3.2+ (no bash 4.0+ features).
#
# Reads hook JSON from stdin. Processes Bash tool invocations that ran
# wrapper scripts (commands containing scripts/) and direct security tool calls.

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

# ---------- Project directory (portable resolution) ----------
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

AUDIT_DIR="$PROJECT_DIR/.pentest"

# ---------- 3. Extract response fields early (needed for direct tool audit) ----------
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# ---------- 4. Handle non-wrapper-script invocations ----------
SECURITY_TOOLS_RE='nmap|tshark|nikto|sqlmap|msfconsole|msfvenom|msfdb|hashcat|john|hping3|skipfish|aircrack-ng|airodump-ng|aireplay-ng|airmon-ng|gobuster|ffuf|foremost|dig|curl|nc|netcat|ncat|traceroute|mtr'

if [[ "$COMMAND" != *"scripts/"* ]]; then
  # Not a wrapper script invocation -- check if it's a direct security tool call
  if echo "$COMMAND" | grep -qEw "$SECURITY_TOOLS_RE"; then
    # Extract the tool name from the command
    DIRECT_TOOL=$(echo "$COMMAND" | grep -oEw "$SECURITY_TOOLS_RE" | head -1)
    # Still log the direct tool usage for audit trail
    mkdir -p "$AUDIT_DIR"
    AUDIT_FILE="$AUDIT_DIR/audit-$(date +%Y-%m-%d).jsonl"
    jq -n -c \
      --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      --arg event "direct_tool" \
      --arg tool "$DIRECT_TOOL" \
      --arg command "$COMMAND" \
      --arg exit_code "$EXIT_CODE" \
      --arg session "$SESSION_ID" \
      '{timestamp:$ts, event:$event, tool:$tool, command:$command, exit_code:$exit_code, session:$session}' \
      >> "$AUDIT_FILE"
  fi
  exit 0
fi

# ---------- 5. Wrapper script path: extract metadata from command ----------
mkdir -p "$AUDIT_DIR"

# Tool name from script path: scripts/<tool>/... -> <tool>
SCRIPT_TOOL=$(echo "$COMMAND" | grep -oE 'scripts/[^/]+' | head -1 | sed 's|scripts/||')
SCRIPT_TOOL="${SCRIPT_TOOL:-unknown}"

# Script name from path: .../script-name.sh -> script-name
SCRIPT_NAME=$(echo "$COMMAND" | grep -oE '[^/]+\.sh' | head -1 | sed 's|\.sh||')
SCRIPT_NAME="${SCRIPT_NAME:-unknown}"

# Target: first positional argument after .sh
TARGET=$(echo "$COMMAND" | grep -oE 'scripts/[^[:space:]]+\.sh[[:space:]]+([^[:space:]]+)' | head -1 | sed 's|scripts/[^[:space:]]*\.sh[[:space:]]*||')
TARGET="${TARGET:-}"

# ---------- 6. Extract stdout for JSON envelope parsing ----------
STDOUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // empty')

# ---------- 7. SAFE-03: Detect and parse JSON envelope ----------
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

# ---------- 8. SAFE-04: Build and append audit log entry ----------
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

# ---------- 9. Output additionalContext JSON if envelope was parsed ----------
if [[ -n "$ADDITIONAL_CONTEXT" ]]; then
  jq -n -c \
    --arg ctx "$ADDITIONAL_CONTEXT" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
fi

exit 0
