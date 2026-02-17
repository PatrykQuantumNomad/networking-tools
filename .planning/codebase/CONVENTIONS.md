# Coding Conventions

**Analysis Date:** 2026-02-17

## Naming Patterns

**Files:**
- Scripts use kebab-case: `discover-live-hosts.sh`, `scan-web-vulnerabilities.sh`
- Library modules use kebab-case: `strict.sh`, `logging.sh`, `validation.sh`
- Test files use kebab-case with `.bats` extension: `smoke.bats`, `lib-json.bats`, `intg-cli-contracts.bats`
- Test files prefixed by type: `lib-` (unit), `intg-` (integration), `smoke.bats`

**Functions:**
- snake_case for public functions: `require_cmd`, `safety_banner`, `parse_common_args`, `run_or_show`
- Leading underscore for private/internal functions: `_log_timestamp`, `_should_log`, `_json_require_jq`, `_common_setup`
- Function names are descriptive verbs: `check_cmd`, `require_target`, `make_temp`, `json_is_active`

**Variables:**
- SCREAMING_SNAKE_CASE for global configuration: `EXECUTE_MODE`, `JSON_MODE`, `VERBOSE`, `LOG_LEVEL`
- SCREAMING_SNAKE_CASE for environment/color variables: `NO_COLOR`, `PROJECT_ROOT`, `RED`, `GREEN`, `NC`
- Leading underscore for internal state: `_COMMON_LOADED`, `_JSON_TOOL`, `_JSON_RESULTS`
- lowercase snake_case for local variables: `local cmd="$1"`, `local install_hint="${2:-}"`

**Script Header Format:**
- Structured header comment block with `@description`, `@usage`, `@dependencies`
- Example: `# @description  Find all active hosts on a subnet`
- Header location: immediately after shebang

## Code Style

**Formatting:**
- Indentation: 4 spaces (no tabs)
- Line continuation: backslash (`\`) at end of line for multi-line commands
- Heredocs for multi-line help text using `cat <<EOF` or `cat <<'EOF'` (unquoted)
- Command substitution uses `$(...)` not backticks

**Linting:**
- ShellCheck enforced via `make lint` (severity=warning)
- `.shellcheckrc` configuration file at project root
- ShellCheck directives placed inline: `# shellcheck disable=SC2034  # Comment explaining why`
- Source path resolution configured: `source-path=SCRIPTDIR`, `source-path=SCRIPTDIR/..`

**Shebang:**
- All scripts: `#!/usr/bin/env bash`
- Test files: `#!/usr/bin/env bats`

**Strict Mode:**
- Enabled in `scripts/lib/strict.sh`: `set -eEuo pipefail`
- ERR trap handler with stack traces: `_strict_error_handler`
- Bash 4.4+ gets `inherit_errexit` option
- Tests disable strict mode: `set +eEuo pipefail` and `trap - ERR` for BATS compatibility

## Import Organization

**Order:**
1. Source `common.sh` (which loads all libraries in dependency order)
2. Define `show_help()` function (required before `parse_common_args`)
3. Call `parse_common_args "$@"` and reset positional parameters
4. Validate dependencies with `require_cmd`
5. Set target variable with default fallback
6. Call `confirm_execute` if script supports `-x` mode
7. Call `safety_banner` if script performs scanning

**Pattern:**
```bash
#!/usr/bin/env bash
# Header comment block
source "$(dirname "$0")/../common.sh"

show_help() {
    # Help text
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nmap "brew install nmap"
TARGET="${1:-localhost}"
confirm_execute "${1:-}"
safety_banner
```

**Path Aliases:**
- No path aliases used
- Relative sourcing: `source "$(dirname "$0")/../common.sh"`
- Library sourcing: `source "${_LIB_DIR}/strict.sh"` (from common.sh)

**Source Guards:**
- All library modules use source guards: `[[ -n "${_COLORS_LOADED:-}" ]] && return 0`
- Common.sh has master guard: `[[ -n "${_COMMON_LOADED:-}" ]] && return 0`

## Error Handling

**Patterns:**
- Strict mode catches errors automatically (`set -e`)
- ERR trap prints stack trace to stderr via `_strict_error_handler`
- Functions use `|| return 0` for non-fatal conditions: `_should_log debug || return 0`
- Early exit with error message: `error "message" >&2; exit 1`
- Validation functions exit with code 1: `require_cmd`, `require_target`, `require_root`

**Error Output:**
- Always write to stderr: `>&2`
- Use `error()` function from `scripts/lib/logging.sh` for consistent formatting
- Error function adds timestamp in verbose mode: `[$(date '+%H:%M:%S')] [ERROR]`

**Exit Codes:**
- Success: `exit 0` or implicit (no exit statement)
- Validation failure: `exit 1`
- Help display: `exit 0`
- User cancellation: `exit 0`

## Logging

**Framework:** Custom logging in `scripts/lib/logging.sh`

**Patterns:**
- Use log level functions: `debug`, `info`, `success`, `warn`, `error`
- All log output uses color variables from `scripts/lib/colors.sh`
- Timestamps added when `VERBOSE >= 1`: `[$(date '+%H:%M:%S')]`
- JSON mode suppresses logs (redirected to stderr): `exec 1>&2` in `parse_common_args`

**Log Levels:**
- `debug`: Only visible when `VERBOSE >= 1` or `LOG_LEVEL="debug"`
- `info`: Default visibility (`LOG_LEVEL="info"`)
- `warn`: Always visible unless `LOG_LEVEL="error"`
- `error`: Always visible, writes to stderr

**Filtering:**
- Controlled by `LOG_LEVEL` variable: `debug`, `info`, `warn`, `error`
- Numeric comparison via `_log_level_num()`: debug=0, info=1, warn=2, error=3
- Check before logging: `_should_log info || return 0`

## Comments

**When to Comment:**
- Structured header block at file start (description, usage, dependencies)
- Source guards: `# Source guard — prevent double-sourcing`
- Complex logic or non-obvious behavior
- ShellCheck directives with explanation: `# shellcheck disable=SC2034  # Used by logging.sh`
- Inline explanations for educational scripts: numbered examples with context

**Documentation Format:**
- File headers use `@description`, `@usage`, `@dependencies` tags
- Inline comments use single `#` with space after
- Section separators: `# --- Section Name ---` or `# ============ ... ============`

**JSDoc/TSDoc:**
- Not applicable (bash project)

## Function Design

**Size:**
- Small, focused functions (typically 5-20 lines)
- Longer functions only for complex operations with clear sections (e.g., `parse_common_args`)

**Parameters:**
- Prefer named positional parameters: `local cmd="$1"; local install_hint="${2:-}"`
- Use parameter expansion for defaults: `"${1:-}"`
- Document required vs optional in function comments
- Global state modified via exported variables: `EXECUTE_MODE`, `JSON_MODE`, `VERBOSE`

**Return Values:**
- Exit codes: `return 0` for success, `return 1` for failure (boolean checks)
- Output via stdout (captured with `$()`)
- Error messages always to stderr: `>&2`
- Modified global variables for state changes

## Module Design

**Exports:**
- Functions are implicitly exported (bash sourcing model)
- Explicit export for variables: `export PROJECT_ROOT`
- NO_COLOR exported in JSON mode: `export NO_COLOR=1`

**Barrel Files:**
- `scripts/common.sh` acts as a barrel file, sources all modules in dependency order:
  1. `strict.sh`
  2. `colors.sh`
  3. `logging.sh`
  4. `validation.sh`
  5. `cleanup.sh`
  6. `json.sh`
  7. `output.sh`
  8. `args.sh`
  9. `diagnostic.sh`
  10. `nc_detect.sh`

**Module Pattern:**
- Each library file in `scripts/lib/` is self-contained
- Source guard at top: `[[ -n "${_MODULE_LOADED:-}" ]] && return 0`
- Header comment block with `@description`, `@usage`, `@dependencies`
- No side effects on load (only function/variable definitions)

---

*Convention analysis: 2026-02-17*
