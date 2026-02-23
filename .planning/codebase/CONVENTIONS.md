# Coding Conventions

**Analysis Date:** 2026-02-23

## Script Header Pattern

Every `.sh` file under `scripts/` MUST have these three metadata fields within the first 10 lines (enforced by `tests/intg-script-headers.bats`):

```bash
#!/usr/bin/env bash
# ============================================================================
# @description  One-line summary of what the script does
# @usage        script-name.sh [target] [-h|--help] [-x|--execute] [-j|--json]
# @dependencies tool-name, common.sh
# ============================================================================
```

## Naming Patterns

**Files:**
- Use lowercase kebab-case: `identify-ports.sh`, `capture-http-credentials.sh`, `crack-wpa-handshake.sh`
- Tool directory names match the tool binary: `nmap/`, `tshark/`, `aircrack-ng/`
- Library modules are lowercase single-word: `args.sh`, `logging.sh`, `cleanup.sh`

**Functions:**
- Public functions: lowercase with underscores: `require_cmd`, `parse_common_args`, `safety_banner`, `run_or_show`
- Private/internal functions: prefixed with underscore: `_log_level_num`, `_should_log`, `_strict_error_handler`, `_cleanup_handler`
- Predicate functions follow `is_` or `check_` pattern: `is_interactive`, `check_cmd`, `json_is_active`

**Variables:**
- Global state: SCREAMING_SNAKE_CASE: `EXECUTE_MODE`, `LOG_LEVEL`, `VERBOSE`, `JSON_MODE`
- Private library state: prefixed with underscore + module: `_JSON_TOOL`, `_CLEANUP_BASE_DIR`, `_STRICT_LOADED`
- Source guards: `_COMMON_LOADED`, `_LOGGING_LOADED`, `_ARGS_LOADED` etc.
- Local variables: lowercase with underscores: `local exit_code`, `local install_hint`, `local tmpfile`

**Constants/Colors:**
- Color escape codes: uppercase one-word: `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `NC`

## Script Structure (Educational Pattern A — examples and use-cases)

Every use-case script follows this exact structure:

1. Shebang + header metadata block
2. `source "$(dirname "$0")/../common.sh"`
3. `show_help()` function with Usage/Description/Flags/Examples sections
4. `parse_common_args "$@"` then `set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"`
5. `require_cmd <tool> "<install-hint>"` (use-case scripts only; examples.sh may require_target too)
6. `require_target "${1:-}"` (only scripts that require a target)
7. `TARGET="${1:-<default>}"` assignment
8. `json_set_meta "<tool>" "$TARGET"` (use-case scripts)
9. `confirm_execute "${1:-}"` (use-case scripts)
10. `safety_banner` (examples.sh scripts)
11. Educational display: `info "=== Title ==="`, numbered examples with `run_or_show` or direct `info`/`echo` pairs
12. `json_finalize` (use-case scripts)
13. Interactive demo block gated by `[[ "${EXECUTE_MODE:-show}" == "show" ]] && [[ -t 0 ]]`

Example from `scripts/nmap/identify-ports.sh`:
```bash
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [target] [-h|--help] [-j|--json]"
    # ...
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

TARGET="${1:-localhost}"
json_set_meta "nmap" "$TARGET" "network-scanner"
confirm_execute "${1:-}"

info "=== Port Identification ==="
# ...
run_or_show "6) Nmap service probing" nmap -sV "$TARGET"
# ...
json_finalize
```

## Code Style

**Strict Mode:**
- All scripts inherit `set -eEuo pipefail` via `scripts/lib/strict.sh`
- Bash 4.0+ required — enforced at source time in `scripts/common.sh`
- `shopt -s inherit_errexit` enabled for Bash 4.4+
- ERR trap provides stack traces via `_strict_error_handler()`

**Variable Quoting:**
- Always quote variable expansions: `"$TARGET"`, `"${1:-}"`, `"${variable:-default}"`
- Use `${VAR:-default}` pattern for optional parameters
- Array expansion: `"${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"` (safe empty-array expansion)

**Conditionals:**
- Use `[[ ... ]]` not `[ ... ]` for all conditionals
- Arithmetic: `(( expr ))` not `[ expr -eq 0 ]`
- Command existence: `command -v cmd &>/dev/null` (via `check_cmd`)

**Local Variables:**
- Always declare local variables with `local` inside functions
- Declare separately from assignment when using command substitution:
  ```bash
  local exit_code
  exit_code=$?
  # NOT: local exit_code=$? (masks exit code)
  ```

**Formatting:**
- 4-space indentation throughout
- No trailing whitespace
- Comment blocks use `# --- Section Name ---` separators
- Inline comments explain the "why", not the "what"

**ShellCheck:**
- `shellcheck --severity=warning` enforced on all scripts
- Config: `.shellcheckrc` at project root
- `# shellcheck disable=SC2034` used for intentionally-unused color variables

## Logging Conventions

Use functions from `scripts/lib/logging.sh` — never raw `echo` for user-facing messages:

```bash
info "Normal operational message"       # Blue [INFO] to stdout
success "Operation completed"           # Green [OK] to stdout
warn "Non-fatal concern"                # Yellow [WARN] to stdout
error "Failure message"                 # Red [ERROR] to stderr (always shown)
debug "Verbose diagnostic detail"       # Cyan [DEBUG] to stdout (LOG_LEVEL=debug only)
```

Diagnostic scripts use `scripts/lib/diagnostic.sh` functions:
```bash
report_pass "Check passed"     # Green [PASS]
report_fail "Check failed"     # Red [FAIL]
report_warn "Ambiguous result" # Yellow [WARN]
report_section "Section Name"  # Cyan section header
```

**LOG_LEVEL filtering:** `debug` < `info` < `warn` < `error`. Errors always display regardless of level.

## Error Handling

**Exit Codes:**
- `exit 1` for all error conditions
- `exit 0` for user-cancelled operations (e.g., declined confirmation prompt)
- Functions return 0/1 naturally via `[[ ... ]]` or command exit status

**Validation Guard Pattern:**
```bash
require_cmd nmap "brew install nmap"    # exits 1 if not installed
require_target "${1:-}"                 # exits 1 if no argument
require_root                            # exits 1 if not root (rare)
```

**Source Guards (all lib modules):**
```bash
[[ -n "${_MODULE_LOADED:-}" ]] && return 0
_MODULE_LOADED=1
```

## Function Documentation

Document function purpose with inline comments before the function:
```bash
# Check if a command exists
check_cmd() {
    command -v "$1" &>/dev/null
}

# Require a command or exit with install hint
require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"
    ...
}
```

Multi-line docstrings use `#` comment blocks above complex functions.

## show_help() Convention

Every script's `show_help()` must output `Usage:` (enforced by `tests/intg-cli-contracts.bats` INTG-01). Standard sections:

```bash
show_help() {
    echo "Usage: $(basename "$0") [target] [flags]"
    echo ""
    echo "Description:"
    echo "  One or two sentences."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") 192.168.1.1"
    echo ""
    echo "Flags:"
    echo "  -h, --help     Show this help message"
    echo "  -j, --json     Output as JSON (requires jq)"
    echo "  -x, --execute  Execute commands instead of displaying them"
}
```

Use-case scripts MUST document `--json` flag (enforced by `tests/intg-doc-json-flag.bats` DOC-01 and DOC-02).

## Output Display Pattern

Use `run_or_show` for numbered examples that may optionally execute:
```bash
run_or_show "N) Human-readable description" command [args...]
```

For show-only examples (complex pipelines or ones that can't run safely):
```bash
info "N) Description"
echo "   command | pipe | etc"
echo ""
```

For JSON-tracked show-only examples:
```bash
info "N) Description"
echo "   command | pipe"
echo ""
json_add_example "Description" "command | pipe"
```

## Temp File Management

Use `make_temp` from `scripts/lib/cleanup.sh` — never raw `mktemp`:
```bash
local tmpfile
tmpfile=$(make_temp file "prefix")      # auto-cleaned on EXIT
local tmpdir
tmpdir=$(make_temp dir)
```

## Module Loading Order

`scripts/common.sh` sources lib modules in strict dependency order:
1. `strict.sh` — bash strict mode (no deps)
2. `colors.sh` — color vars (no deps)
3. `logging.sh` — depends on colors.sh
4. `validation.sh` — depends on colors.sh, logging.sh
5. `cleanup.sh` — no deps
6. `json.sh` — depends on cleanup.sh
7. `output.sh` — depends on colors.sh, json.sh, cleanup.sh
8. `args.sh` — no deps (but calls json.sh functions)
9. `diagnostic.sh` — depends on colors.sh, logging.sh
10. `nc_detect.sh` — no deps

---

*Convention analysis: 2026-02-23*
