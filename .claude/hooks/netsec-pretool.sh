#!/usr/bin/env bash
# PreToolUse safety hook for networking-tools
# Implements: SAFE-01 (target allowlist), SAFE-02 (raw tool interception), SAFE-04 (audit logging)
#
# Reads hook JSON from stdin. Only processes Bash tool invocations containing
# security tool commands. Non-security commands (git, ls, npm, etc.) fast-exit
# with zero processing.

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

# ---------- 3. Fast exit if no security tool in command ----------
SECURITY_TOOLS_RE='nmap|tshark|nikto|sqlmap|msfconsole|msfvenom|msfdb|hashcat|john|hping3|skipfish|aircrack-ng|airodump-ng|aireplay-ng|airmon-ng|gobuster|ffuf|foremost|dig|curl|nc|netcat|ncat|traceroute|mtr'

if [[ "$COMMAND" != *"scripts/"* ]] && ! echo "$COMMAND" | grep -qEw "$SECURITY_TOOLS_RE"; then
  exit 0
fi

# ---------- Project directory ----------
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
AUDIT_DIR="$PROJECT_DIR/.pentest"
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# ---------- Helper: write audit log ----------
write_audit() {
  local event="$1" tool="$2" command="$3" target="${4:-}" reason="${5:-}" script="${6:-}"
  mkdir -p "$AUDIT_DIR"
  local audit_file
  audit_file="$AUDIT_DIR/audit-$(date +%Y-%m-%d).jsonl"
  jq -n -c \
    --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg event "$event" \
    --arg tool "$tool" \
    --arg command "$command" \
    --arg target "$target" \
    --arg reason "$reason" \
    --arg script "$script" \
    --arg session "$SESSION_ID" \
    '{timestamp:$ts, event:$event, tool:$tool, command:$command, target:$target, reason:$reason, script:$script, session:$session}' \
    >> "$audit_file"
}

# ---------- Helper: emit deny JSON ----------
deny() {
  local reason="$1" context="$2"
  jq -n -c \
    --arg reason "$reason" \
    --arg context "$context" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason,additionalContext:$context}}'
}

# ---------- 4. SAFE-02: Raw tool interception (before target validation) ----------
# Associative array: tool binary -> wrapper script directory
declare -A TOOL_SCRIPT_DIR=(
  [nmap]="scripts/nmap/"
  [tshark]="scripts/tshark/"
  [msfconsole]="scripts/metasploit/"
  [msfvenom]="scripts/metasploit/"
  [msfdb]="scripts/metasploit/"
  [sqlmap]="scripts/sqlmap/"
  [nikto]="scripts/nikto/"
  [hashcat]="scripts/hashcat/"
  [john]="scripts/john/"
  [hping3]="scripts/hping3/"
  [skipfish]="scripts/skipfish/"
  [aircrack-ng]="scripts/aircrack-ng/"
  [airodump-ng]="scripts/aircrack-ng/"
  [aireplay-ng]="scripts/aircrack-ng/"
  [airmon-ng]="scripts/aircrack-ng/"
  [gobuster]="scripts/gobuster/"
  [ffuf]="scripts/ffuf/"
  [foremost]="scripts/foremost/"
  [dig]="scripts/dig/"
  [curl]="scripts/curl/"
  [nc]="scripts/netcat/"
  [netcat]="scripts/netcat/"
  [ncat]="scripts/netcat/"
  [traceroute]="scripts/traceroute/"
  [mtr]="scripts/traceroute/"
)

# Only check for raw tool usage if the command does NOT go through a wrapper script
if [[ "$COMMAND" != *"scripts/"* ]]; then
  for tool_bin in "${!TOOL_SCRIPT_DIR[@]}"; do
    # Match: command starts with optional sudo then the tool name as a word boundary
    # The tool must be the primary command, not an argument to grep/which/cat/etc.
    if echo "$COMMAND" | grep -qE "^(sudo[[:space:]]+)?${tool_bin}(\\b|\$)"; then

      # Exception for curl and dig: skip interception if the command contains URLs
      if [[ "$tool_bin" == "curl" || "$tool_bin" == "dig" ]]; then
        if echo "$COMMAND" | grep -qE 'https?://'; then
          continue
        fi
      fi

      local_dir="${TOOL_SCRIPT_DIR[$tool_bin]}"
      reason="Blocked: direct '${tool_bin}' call. Use wrapper scripts in ${local_dir} instead (e.g., bash ${local_dir}examples.sh TARGET)"
      context="BLOCKED: raw tool '${tool_bin}' used directly. Command: ${COMMAND}. Redirect to wrapper scripts in ${local_dir}."
      write_audit "blocked" "$tool_bin" "$COMMAND" "" "raw tool bypass" ""
      deny "$reason" "$context"
      exit 0
    fi
  done
  # If we get here and command doesn't contain scripts/, it's a non-security use of a
  # tool name (e.g., grep nmap, which nmap) -- allow it
  exit 0
fi

# ---------- 5. SAFE-01: Target allowlist validation ----------
# Only wrapper script invocations reach this point (command contains scripts/)

SCOPE_FILE="$PROJECT_DIR/.pentest/scope.json"

# Check scope file existence
if [[ ! -f "$SCOPE_FILE" ]]; then
  # Extract tool name from script path for audit
  SCRIPT_TOOL=$(echo "$COMMAND" | grep -oE 'scripts/[^/]+' | head -1 | sed 's|scripts/||')
  write_audit "blocked" "${SCRIPT_TOOL:-unknown}" "$COMMAND" "" "no scope file" ""
  reason="No scope file found at .pentest/scope.json. Create one with {\"targets\":[\"localhost\"]} or run the health-check."
  context="BLOCKED: no scope file. Expected at ${SCOPE_FILE}. Help the user create one with allowed targets."
  deny "$reason" "$context"
  exit 0
fi

# Extract target from wrapper script command
# Pattern: bash scripts/.../*.sh <TARGET> [options...]
# Strip quotes and shell metacharacters from extracted target
RAW_TARGET=$(echo "$COMMAND" | grep -oE 'scripts/[^[:space:]]+\.sh[[:space:]]+([^[:space:]]+)' | head -1 | sed 's|scripts/[^[:space:]]*\.sh[[:space:]]*||')
TARGET=$(echo "$RAW_TARGET" | sed "s/[\"';\`|&(){}]//g")

# If no target extracted, allow the command (might be --help or no-target script)
if [[ -z "$TARGET" ]]; then
  SCRIPT_TOOL=$(echo "$COMMAND" | grep -oE 'scripts/[^/]+' | head -1 | sed 's|scripts/||')
  SCRIPT_NAME=$(echo "$COMMAND" | grep -oE '[^/]+\.sh' | head -1 | sed 's|\.sh||')
  write_audit "allowed" "${SCRIPT_TOOL:-unknown}" "$COMMAND" "" "" "${SCRIPT_NAME:-unknown}"
  exit 0
fi

# Parse scope targets
SCOPE_TARGETS=$(jq -r '.targets[]' "$SCOPE_FILE" 2>/dev/null)
if [[ -z "$SCOPE_TARGETS" ]]; then
  SCRIPT_TOOL=$(echo "$COMMAND" | grep -oE 'scripts/[^/]+' | head -1 | sed 's|scripts/||')
  write_audit "blocked" "${SCRIPT_TOOL:-unknown}" "$COMMAND" "$TARGET" "empty scope" ""
  reason="Scope file exists but has no targets. Add targets to .pentest/scope.json"
  context="BLOCKED: scope file empty. Target '${TARGET}' cannot be validated."
  deny "$reason" "$context"
  exit 0
fi

# Normalize localhost equivalences
normalize_target() {
  local t="$1"
  case "$t" in
    localhost) echo "localhost 127.0.0.1" ;;
    127.0.0.1) echo "127.0.0.1 localhost" ;;
    *) echo "$t" ;;
  esac
}

# Validate target against scope
TARGET_ALLOWED=false
TARGET_VARIANTS=$(normalize_target "$TARGET")

while IFS= read -r scope_entry; do
  [[ -z "$scope_entry" ]] && continue

  # CIDR /24 match (simple: compare first 3 octets)
  if [[ "$scope_entry" == *"/24" ]]; then
    cidr_prefix=$(echo "$scope_entry" | sed 's|/24||' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
    target_prefix=$(echo "$TARGET" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
    if [[ -n "$cidr_prefix" && -n "$target_prefix" && "$cidr_prefix" == "$target_prefix" ]]; then
      TARGET_ALLOWED=true
      break
    fi
    continue
  fi

  # Exact match (with localhost equivalence)
  scope_variants=$(normalize_target "$scope_entry")
  for tv in $TARGET_VARIANTS; do
    for sv in $scope_variants; do
      if [[ "$tv" == "$sv" ]]; then
        TARGET_ALLOWED=true
        break 3
      fi
    done
  done
done <<< "$SCOPE_TARGETS"

SCRIPT_TOOL=$(echo "$COMMAND" | grep -oE 'scripts/[^/]+' | head -1 | sed 's|scripts/||')
SCRIPT_NAME=$(echo "$COMMAND" | grep -oE '[^/]+\.sh' | head -1 | sed 's|\.sh||')

if [[ "$TARGET_ALLOWED" == "true" ]]; then
  # ---------- 8. Allowed: audit and exit ----------
  write_audit "allowed" "${SCRIPT_TOOL:-unknown}" "$COMMAND" "$TARGET" "" "${SCRIPT_NAME:-unknown}"
  exit 0
else
  # ---------- 8. Blocked: target not in scope ----------
  SCOPE_LIST=$(echo "$SCOPE_TARGETS" | tr '\n' ', ' | sed 's/,$//')
  write_audit "blocked" "${SCRIPT_TOOL:-unknown}" "$COMMAND" "$TARGET" "target not in scope" "${SCRIPT_NAME:-unknown}"
  reason="Target '${TARGET}' not in scope. Allowed: ${SCOPE_LIST}. Add it to .pentest/scope.json"
  context="BLOCKED: target '${TARGET}' not in scope. Current scope: [${SCOPE_LIST}]. Scope file: ${SCOPE_FILE}."
  deny "$reason" "$context"
  exit 0
fi
