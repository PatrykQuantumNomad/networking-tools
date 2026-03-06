#!/usr/bin/env bash
# netsec-scope.sh -- Portable scope management for pentesting engagements
# Usage: netsec-scope.sh <init|add|remove|show|clear> [target]
#
# Manages .pentest/scope.json in the user's project directory.
# Works from any directory -- resolves project via CLAUDE_PROJECT_DIR > git root > CWD.

set -euo pipefail

# ---------- Dependencies ----------
command -v jq >/dev/null 2>&1 || {
  echo "Error: jq is required. Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
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
SCOPE_FILE="$PROJECT_DIR/.pentest/scope.json"

# ---------- Helpers ----------
require_scope_file() {
  if [[ ! -f "$SCOPE_FILE" ]]; then
    echo "Error: No scope file found at $SCOPE_FILE"
    echo "Run: netsec-scope.sh init"
    exit 1
  fi
}

# ---------- Operations ----------
OPERATION="${1:-show}"

case "$OPERATION" in
  init)
    mkdir -p "$(dirname "$SCOPE_FILE")"
    echo '{"targets":["localhost","127.0.0.1"]}' > "$SCOPE_FILE"
    echo "Scope initialized at $SCOPE_FILE"
    jq . "$SCOPE_FILE"
    ;;

  add)
    if [[ -z "${2:-}" ]]; then
      echo "Error: Target required. Usage: netsec-scope.sh add <target>"
      exit 1
    fi
    require_scope_file
    jq --arg t "$2" '.targets += [$t] | .targets |= unique' "$SCOPE_FILE" > "${SCOPE_FILE}.tmp" \
      && mv "${SCOPE_FILE}.tmp" "$SCOPE_FILE"
    echo "Added '$2' to scope"
    jq -r '.targets[]' "$SCOPE_FILE"
    ;;

  remove)
    if [[ -z "${2:-}" ]]; then
      echo "Error: Target required. Usage: netsec-scope.sh remove <target>"
      exit 1
    fi
    require_scope_file
    jq --arg t "$2" '.targets -= [$t]' "$SCOPE_FILE" > "${SCOPE_FILE}.tmp" \
      && mv "${SCOPE_FILE}.tmp" "$SCOPE_FILE"
    echo "Removed '$2' from scope"
    jq -r '.targets[]' "$SCOPE_FILE"
    ;;

  show)
    if [[ -f "$SCOPE_FILE" ]]; then
      jq . "$SCOPE_FILE"
    else
      echo "No scope file found. Run: netsec-scope.sh init"
      exit 1
    fi
    ;;

  clear)
    require_scope_file
    echo '{"targets":[]}' > "$SCOPE_FILE"
    echo "Warning: Scope cleared. All pentesting commands will be blocked until targets are added."
    ;;

  *)
    echo "Usage: netsec-scope.sh <init|add|remove|show|clear> [target]"
    echo ""
    echo "Operations:"
    echo "  init              Create scope file with default targets (localhost, 127.0.0.1)"
    echo "  add <target>      Add a target to scope"
    echo "  remove <target>   Remove a target from scope"
    echo "  show              Display current scope (default)"
    echo "  clear             Remove all targets from scope"
    exit 1
    ;;
esac
