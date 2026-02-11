# Phase 13: Library Infrastructure - Research

**Researched:** 2026-02-11
**Domain:** Bash library modularization, strict mode, trap handlers, log-level filtering, temp file management, retry logic
**Confidence:** HIGH

## Summary

Phase 13 transforms the 148-line `scripts/common.sh` into a modular library split across `scripts/lib/` while preserving the existing `source "$(dirname "$0")/../common.sh"` line in all 66 consumer scripts unchanged. The phase delivers eight requirements across three domains: strict mode hardening (STRICT-01 through STRICT-05), logging infrastructure (LOG-01 through LOG-05), and infrastructure utilities (INFRA-01 through INFRA-04).

The core challenge is backward compatibility. Every enhancement must produce identical visible output to the current behavior when run without new environment variables or flags. The existing `info()`, `success()`, `warn()`, `error()` functions currently output to stdout (except `error()` which goes to stderr). The `safety_banner()` and all `report_*()` functions also go to stdout. This output routing must be preserved exactly, even as the functions gain internal capabilities like level filtering and color suppression.

The library split decision (8-file, not 2-file) is locked from STATE.md. The implementation creates `scripts/lib/` with focused modules sourced by `common.sh` in dependency order. Source guards (`_MODULE_LOADED` pattern) prevent double-sourcing. The only source-time side effects are: `set -eEuo pipefail` (upgraded from current `set -euo pipefail`), ERR trap registration, EXIT trap registration, color variable initialization (conditional on terminal detection), and variable declarations with safe defaults.

**Primary recommendation:** Build the library bottom-up in dependency order (strict.sh -> colors.sh -> logging.sh -> validation.sh -> cleanup.sh -> output.sh -> diagnostic.sh -> nc_detect.sh), verify backward compatibility after each module by running representative scripts, and validate the full suite only after all modules are in place.

## Prior Decisions (from STATE.md)

These decisions are locked. Research supports THESE, not alternatives.

- **8-file library split** (not 2-file) for maintainability
- **Manual while/case arg parsing** (not getopts/getopt) -- Phase 14, not this phase
- **ERR trap prints stack trace to stderr** (not silent log file)
- **Unknown flags pass through to REMAINING_ARGS** (permissive) -- Phase 14, not this phase
- **Enhance existing info/warn/error in-place** (not parallel log_* functions)
- **Standard comment** "# Interactive demo (skip if non-interactive)" for all guards -- done in Phase 12
- **Version guard** before set -euo pipefail using only Bash 2.x+ syntax -- done in Phase 12
- **Three source-path entries** in .shellcheckrc (SCRIPTDIR, SCRIPTDIR/.., SCRIPTDIR/../lib) -- done in Phase 12

## Standard Stack

### Core

| Technology | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| Bash | 4.0+ minimum | Script runtime; `declare -A` already requires it | Version guard already in common.sh (Phase 12) |
| `set -eEuo pipefail` | Bash 3.0+ for -E | Strict error propagation including into functions/subshells | `-E` ensures ERR trap inherits into functions |
| `shopt -s inherit_errexit` | Bash 4.4+ (gated) | Makes `set -e` apply inside `$()` command substitutions | Without it, failing commands inside `$()` are silently ignored |
| `trap ... ERR` | Bash 3.0+ | Stack trace on unhandled error | `BASH_LINENO`, `FUNCNAME`, `BASH_SOURCE` arrays provide full context |
| `trap ... EXIT` | POSIX | Cleanup on any exit path (normal, error, Ctrl+C) | EXIT trap fires on INT/TERM signals too; no need to trap both |
| `mktemp` | POSIX | Temp file/directory creation | Available on macOS and Linux; `$TMPDIR` respected |
| NO_COLOR | Convention | Disable ANSI when not a terminal | no-color.org standard; also check `[[ -t 1 ]]` for stdout |

### Supporting

| Technology | Purpose | When to Use |
|------------|---------|-------------|
| `BASH_VERSINFO` array | Version-gated features (inherit_errexit) | Check `BASH_VERSINFO[0]` and `BASH_VERSINFO[1]` |
| `date +"%H:%M:%S"` | Timestamps in VERBOSE mode | Portable across macOS and Linux |
| `sleep` | Retry backoff delays | POSIX, no version concerns |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| 8-file split | 2-file split (strict.sh + args.sh) | 2-file underestimates how much code logging, cleanup, and output add; 8-file is locked decision |
| Enhance info/warn/error in-place | Parallel log_info/log_warn/log_error | Parallel functions double the API surface; in-place enhancement is locked decision |
| ERR trap to stderr | ERR trap to LOG_FILE only | Silent log file defeats purpose of developer diagnostics; stderr is locked decision |
| `[[ -t 1 ]]` for stdout color | `[[ -t 2 ]]` for stderr color | Current info/warn/success go to stdout, so check stdout. error() goes to stderr, so check stderr for that. See Architecture Patterns for details. |

## Architecture Patterns

### Recommended Library Structure

```
scripts/
  common.sh                      # PRESERVED entry point (sources lib/*.sh)
  lib/
    strict.sh                    # set -eEuo pipefail, shopt inherit_errexit, ERR trap
    colors.sh                    # Color variable definitions, NO_COLOR/terminal detection
    logging.sh                   # info/success/warn/error/debug + LOG_LEVEL filtering
    validation.sh                # require_root, check_cmd, require_cmd, require_target
    cleanup.sh                   # EXIT trap, make_temp(), register_cleanup()
    output.sh                    # safety_banner, is_interactive, PROJECT_ROOT
    diagnostic.sh                # report_pass/fail/warn/skip/section, run_check, _run_with_timeout
    nc_detect.sh                 # detect_nc_variant()
```

**Note on naming:** The prior research (ARCHITECTURE.md) proposed `core.sh` containing colors + PROJECT_ROOT + is_interactive + set -euo pipefail. This phase splits that further into `strict.sh` (strict mode and traps) and `colors.sh` (color definitions and terminal detection) because strict mode is conceptually separate from color output, and the ERR/EXIT traps belong with strict mode, not with color definitions. This gives cleaner module boundaries while staying within the 8-file split decision.

### Dependency Graph and Source Order

```
strict.sh          (no dependencies -- MUST be first)
  |
  +-- colors.sh        (no dependencies, but logically after strict)
  |     |
  |     +-- logging.sh     (depends on colors.sh for color vars)
  |           |
  |           +-- validation.sh  (depends on logging.sh for error())
  |           |
  |           +-- cleanup.sh     (depends on logging.sh for debug())
  |
  +-- output.sh       (depends on colors.sh for color vars)
  |
  +-- diagnostic.sh   (depends on colors.sh for color vars)
  |
  +-- nc_detect.sh    (depends on validation.sh for check_cmd)
```

Source order in common.sh MUST follow this graph:
1. `strict.sh`
2. `colors.sh`
3. `logging.sh`
4. `validation.sh`
5. `cleanup.sh`
6. `output.sh`
7. `diagnostic.sh`
8. `nc_detect.sh`

### Pattern 1: Source Guard (STRICT-05)

Every `lib/*.sh` file MUST start with a source guard to prevent double-sourcing.

```bash
# lib/logging.sh
[[ -n "${_LOGGING_LOADED:-}" ]] && return 0
_LOGGING_LOADED=1
```

**Why `return 0` not `exit 0`:** These files are sourced, not executed. `exit` would kill the sourcing shell. `return` exits the sourced file only. The `return 0` is safe because in a sourced context `return` works; if somehow executed directly (not sourced), `return` outside a function prints an error but does not crash -- it just falls through. Some guides add `2>/dev/null || true` after `return 0` for this edge case, but since our scripts always source (never execute) lib files, plain `return 0` is sufficient.

**Variable naming convention:** `_MODULENAME_LOADED` (e.g., `_STRICT_LOADED`, `_COLORS_LOADED`, `_LOGGING_LOADED`). The underscore prefix signals "internal/private."

### Pattern 2: ERR Trap Stack Trace (STRICT-02)

```bash
_strict_error_handler() {
    local exit_code=$?
    local line_no="${BASH_LINENO[0]}"
    local command="${BASH_COMMAND}"
    echo "[ERROR] Command failed (exit $exit_code) at line $line_no: $command" >&2
    # Print call stack (skip the trap handler itself)
    local i
    for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
        echo "  at ${FUNCNAME[$i]}() in ${BASH_SOURCE[$i]}:${BASH_LINENO[$((i-1))]}" >&2
    done
}
trap '_strict_error_handler' ERR
```

**Key considerations:**
- Output goes to stderr (locked decision from STATE.md)
- Uses plain `echo` without color codes -- the ERR trap fires in error conditions where color state may be unreliable
- Skips index 0 of `FUNCNAME` (which is `_strict_error_handler` itself)
- `BASH_LINENO[$((i-1))]` gives the line WHERE the function at `FUNCNAME[$i]` was called
- Must NOT use any library functions (info/error) inside the handler -- those functions might be what triggered the error

**Interaction with `|| true` guards:** The ERR trap does NOT fire for commands followed by `|| true` or inside `if` conditionals. This is correct behavior -- those commands are explicitly expected to potentially fail. The 40+ existing `|| true` guards in the codebase will not trigger false stack traces.

### Pattern 3: EXIT Trap with Cleanup (STRICT-04, INFRA-03)

```bash
_CLEANUP_FILES=()
_CLEANUP_DIRS=()

_cleanup_handler() {
    local exit_code=$?
    # Remove registered temp files
    local f
    for f in "${_CLEANUP_FILES[@]}"; do
        [[ -e "$f" ]] && rm -f "$f" 2>/dev/null || true
    done
    # Remove registered temp directories
    local d
    for d in "${_CLEANUP_DIRS[@]}"; do
        [[ -d "$d" ]] && rm -rf "$d" 2>/dev/null || true
    done
    exit "$exit_code"
}
trap '_cleanup_handler' EXIT
```

**Why only trap EXIT, not INT/TERM:** When bash receives INT (Ctrl+C) or TERM, it runs the EXIT trap before exiting. Trapping both causes double execution of cleanup. Trapping only EXIT is the correct pattern per Greg's Wiki SignalTrap.

**Why preserve exit code:** `$?` is captured before cleanup runs, then `exit "$exit_code"` restores it so the calling process sees the correct exit status.

**ERR trap + EXIT trap interaction:** Both can coexist. When an error occurs: ERR trap fires first (prints stack trace), then the script exits, then EXIT trap fires (cleans up). This is the intended behavior.

### Pattern 4: Color Detection (LOG-03)

```bash
# Detect terminal capability at source time (once, not per-call)
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi
```

**Critical detail -- stdout vs stderr:** The current `info()`, `success()`, `warn()` functions output to stdout. Only `error()` outputs to stderr. The `safety_banner()` and all `report_*()` functions also output to stdout. Therefore, the terminal check for color MUST test fd 1 (stdout), not fd 2 (stderr).

However, the STACK.md research recommended checking stderr (`[[ -t 2 ]]`) because it envisioned moving all logging to stderr. The locked decision says "enhance existing info/warn/error in-place," which means preserving their current stdout/stderr routing. So the color check MUST use `[[ -t 1 ]]` to match the fact that info/warn/success go to stdout.

**For error() specifically:** It already goes to stderr. When stdout is piped but stderr is a terminal (common: `./script.sh > output.txt`), error messages should still have color if stderr is a terminal. This is a refinement: the base color variables control stdout-bound output. The error function could check `[[ -t 2 ]]` independently, but for simplicity and backward compatibility, use the same color variables everywhere. The success criterion says "Piping any script through `cat` (non-terminal stdout) produces output with zero ANSI escape codes" -- this means checking `[[ -t 1 ]]` for the global color decision is correct.

**NO_COLOR convention:** The `NO_COLOR` environment variable (no-color.org) forces colors off regardless of terminal state. Check it first.

### Pattern 5: Log Level Filtering (LOG-01, LOG-02)

```bash
# Log levels: debug=0, info=1, warn=2, error=3
LOG_LEVEL="${LOG_LEVEL:-info}"
VERBOSE="${VERBOSE:-0}"

# When VERBOSE=1, treat as LOG_LEVEL=debug
[[ "$VERBOSE" -ge 1 ]] && LOG_LEVEL="debug"

_log_level_num() {
    case "$1" in
        debug) echo 0 ;; info) echo 1 ;; warn) echo 2 ;; error) echo 3 ;;
        *) echo 1 ;;
    esac
}

_should_log() {
    local msg_level="$1"
    local current
    current=$(_log_level_num "$LOG_LEVEL")
    local this
    this=$(_log_level_num "$msg_level")
    [[ "$this" -ge "$current" ]]
}
```

**Enhancing existing functions in-place (locked decision):**

```bash
info() {
    _should_log info || return 0
    local timestamp=""
    [[ "$VERBOSE" -ge 1 ]] && timestamp="$(date '+%H:%M:%S') "
    echo -e "${timestamp}${BLUE}[INFO]${NC} $*"
}

debug() {
    _should_log debug || return 0
    local timestamp
    timestamp="$(date '+%H:%M:%S') "
    echo -e "${timestamp}${CYAN}[DEBUG]${NC} $*"
}
```

**Why `debug()` always has a timestamp:** Debug output is for troubleshooting. Timestamps are always useful there. Regular `info()` only gets timestamps when `VERBOSE=1`.

**Backward compatibility analysis:**
- Default `LOG_LEVEL=info`: `debug()` messages are suppressed (invisible). `info/warn/error/success` behave identically to today.
- Default `VERBOSE=0`: No timestamps on `info/warn/error/success`. Identical to today.
- `VERBOSE=1` or `LOG_LEVEL=debug`: Enables debug messages and adds timestamps. This is the new behavior triggered by explicit opt-in.
- When `LOG_LEVEL=warn`: `info()` is suppressed, `warn/error` still show. This enables the `-q`/`--quiet` behavior (Phase 14 handles the flag, this phase provides the mechanism).

### Pattern 6: make_temp() (INFRA-03)

```bash
make_temp() {
    local type="${1:-file}"  # "file" or "dir"
    local prefix="${2:-ntool}"
    local result

    if [[ "$type" == "dir" ]]; then
        result=$(mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXX")
        _CLEANUP_DIRS+=("$result")
    else
        result=$(mktemp "${TMPDIR:-/tmp}/${prefix}.XXXXXX")
        _CLEANUP_FILES+=("$result")
    fi
    echo "$result"
}
```

**Usage:** `tmpfile=$(make_temp)` or `tmpdir=$(make_temp dir)`. Auto-cleaned on EXIT.

### Pattern 7: retry_with_backoff() (INFRA-04)

```bash
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    shift 2

    local attempt=1
    while true; do
        if "$@"; then
            return 0
        fi
        if [[ "$attempt" -ge "$max_attempts" ]]; then
            warn "Command failed after $max_attempts attempts: $*"
            return 1
        fi
        debug "Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..."
        sleep "$delay"
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
}
```

**Design:** Exponential backoff (1s, 2s, 4s). No jitter (overkill for single-user CLI). Uses `debug()` for retry messages (invisible by default). Uses `warn()` for final failure.

### Anti-Patterns to Avoid

- **Circular source dependencies:** `lib/logging.sh` MUST NOT source `lib/validation.sh` (which depends on logging.sh). The dependency graph is strictly one-way.
- **Global state mutation in library init:** The only acceptable source-time side effects are: `set -eEuo pipefail`, trap registration, variable declarations with defaults, and color initialization. No function calls, no network I/O, no disk I/O.
- **Modifying existing function signatures:** `info()`, `warn()`, `error()`, `success()` MUST keep the same calling convention (`info "message"` -> colored output). The enhancement adds filtering BEFORE the echo, not a different calling convention.
- **Using library functions inside trap handlers:** The ERR trap handler MUST NOT call `error()` or any library function because the error might have originated from inside that function, causing recursion. Use plain `echo ... >&2`.
- **Namespace collision:** All module-level variables MUST be prefixed with underscore. Use `local` for all function-internal variables. Two modules defining `result` at module scope would collide.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stack trace formatting | Custom FUNCNAME/LINENO walker | The standard `BASH_LINENO[i-1]` / `FUNCNAME[i]` / `BASH_SOURCE[i]` pattern | Bash arrays are indexed specifically for this; the offset between LINENO and FUNCNAME indices is a documented convention |
| Temp file tracking | Custom PID-based file naming | `mktemp` + EXIT trap + array tracking | mktemp guarantees unique names; EXIT trap is reliable on all exit paths |
| Color detection | Custom TERM variable parsing | `[[ -t 1 ]]` + `NO_COLOR` env var | POSIX `-t` test is authoritative; NO_COLOR is the adopted convention |
| Exponential backoff | Sleep-based retry loop from scratch | The standard `delay=$((delay * 2))` pattern | Universally standard; no innovation needed |

**Key insight:** Every component in this phase has a well-established bash pattern. The value is in correct integration and backward compatibility, not in novel implementation.

## Common Pitfalls

### Pitfall 1: ERR Trap Fires on `|| true` Guarded Commands

**What goes wrong:** If the ERR trap is not properly configured, it may fire even for commands that are expected to fail and are guarded with `|| true`.
**Why it happens:** This would only happen if `set -E` is used but the trap does not account for the conditional context.
**How to avoid:** Bash automatically suppresses the ERR trap for commands in conditional contexts (`if`, `||`, `&&`). The 40+ existing `|| true` guards will NOT trigger false stack traces. No action needed -- just do not remove the guards.
**Warning signs:** Stack traces appearing for grep-no-match or nc -h in normal operation.

### Pitfall 2: EXIT Trap Overwriting by Consumer Scripts

**What goes wrong:** If a consumer script sets its own `trap ... EXIT`, it overwrites the cleanup trap registered by `lib/cleanup.sh`, and temp files are never cleaned up.
**Why it happens:** Bash only supports one handler per signal. Setting a new trap replaces the previous one.
**How to avoid:** Currently, zero scripts in the codebase set their own traps. The `register_cleanup()` function allows scripts to add cleanup tasks without overwriting the trap. Document that scripts should use `register_cleanup "command"` instead of `trap "command" EXIT`.
**Warning signs:** Temp files left in `/tmp/ntool.*` after script exit.

### Pitfall 3: `set -E` Causes ERR Trap to Fire Inside Subshells

**What goes wrong:** `set -E` makes the ERR trap inherit into shell functions and subshells. A command substitution like `result=$(grep "pattern" file)` where grep finds nothing would trigger the ERR trap inside the subshell AND potentially exit the script.
**Why it happens:** `-E` flag enables ERR trap inheritance. Without `-E`, only the top-level scope has the ERR trap.
**How to avoid:** This is actually the desired behavior -- errors inside subshells should be caught. But commands that legitimately fail (grep no-match) MUST have `|| true` guards. The existing 40+ guards handle this. New code must follow the same pattern.
**Warning signs:** Scripts dying with stack traces on operations that worked before.

### Pitfall 4: `info()` Enhancement Changes Output When Piped

**What goes wrong:** Adding `_should_log info || return 0` at the top of `info()` changes behavior when `LOG_LEVEL` is accidentally set to something unexpected. Also, changing the output destination (stdout vs stderr) would break scripts that parse their own output.
**Why it happens:** The success criterion states "identical output to before" when run without new variables.
**How to avoid:** Default `LOG_LEVEL=info` means `_should_log info` always returns true. Default `VERBOSE=0` means no timestamps. The echo statement inside `info()` MUST stay as `echo -e "..." ` (stdout, no `>&2`) to match current behavior. Only the conditional wrapper is new.
**Warning signs:** `bash scripts/nmap/examples.sh scanme.nmap.org 2>/dev/null` should show identical output before and after. If info messages disappear when stderr is suppressed, info was accidentally moved to stderr.

### Pitfall 5: Color Variables Set to Empty Strings Break `echo -e` Output

**What goes wrong:** When `NO_COLOR` is set or stdout is not a terminal, color variables are set to empty strings. The `echo -e "${BLUE}[INFO]${NC} $*"` becomes `echo -e "[INFO] $*"`. This is correct. But `echo -e ""` (empty variable) still outputs a newline. And some edge cases with `-e` flag and empty variables can cause formatting differences.
**How to avoid:** Test the exact output format with colors disabled. The `[INFO]` prefix and message text should appear identically with or without colors -- only the ANSI escape sequences change. The success criterion (#4) specifically requires zero ANSI codes when piped through `cat`.
**Warning signs:** Extra whitespace or missing prefixes in non-color output.

### Pitfall 6: `shopt -s inherit_errexit` Breaks `local var=$(cmd)` Pattern

**What goes wrong:** With `inherit_errexit`, `local var=$(failing_cmd)` will now propagate the error from `failing_cmd` instead of masking it (which is the SC2155 behavior). This is actually the DESIRED behavior but it could break scripts that rely on `local var=$(cmd_that_might_fail)` working silently.
**Why it happens:** `inherit_errexit` makes `set -e` apply inside `$()`. Combined with `local`, the error is no longer masked.
**How to avoid:** The `shopt -s inherit_errexit` is gated behind a Bash 4.4+ check. On Bash 4.0-4.3, this behavior does not apply. For scripts running on 4.4+, the existing `|| true` guards and conditional contexts handle this. But be aware: this is a subtle behavioral change for 4.4+ users. If any `local var=$(cmd)` pattern breaks, split to `local var; var=$(cmd)` or add `|| true`.
**Warning signs:** Scripts that work on Bash 4.0-4.3 fail on Bash 5.x.

## Code Examples

### New common.sh (Entry Point)

```bash
#!/usr/bin/env bash
# common.sh -- Shared utility functions for all tool scripts
# Source this file: source "$(dirname "$0")/../common.sh"

# --- Bash Version Guard ---
# Require Bash 4.0+ (associative arrays, mapfile, etc.)
# Uses only Bash 2.x+ syntax so it prints a clear error on old bash.
if [[ -z "${BASH_VERSINFO:-}" ]] || ((BASH_VERSINFO[0] < 4)); then
    echo "[ERROR] Bash 4.0+ required (found: ${BASH_VERSION:-unknown})" >&2
    echo "[ERROR] macOS ships Bash 3.2 -- install modern bash: brew install bash" >&2
    exit 1
fi

# Source guard: prevent double-sourcing
[[ -n "${_COMMON_LOADED:-}" ]] && return 0
_COMMON_LOADED=1

# Resolve library directory
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"

# Source all library modules (order matters -- see dependency graph)
source "${_LIB_DIR}/strict.sh"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logging.sh"
source "${_LIB_DIR}/validation.sh"
source "${_LIB_DIR}/cleanup.sh"
source "${_LIB_DIR}/output.sh"
source "${_LIB_DIR}/diagnostic.sh"
source "${_LIB_DIR}/nc_detect.sh"
```

### lib/strict.sh (STRICT-01, STRICT-02, STRICT-03)

```bash
# lib/strict.sh -- Strict mode and error handling
[[ -n "${_STRICT_LOADED:-}" ]] && return 0
_STRICT_LOADED=1

set -eEuo pipefail

# Enable inherit_errexit if Bash 4.4+ (makes set -e apply inside $())
if [[ "${BASH_VERSINFO[0]}" -ge 5 ]] || \
   [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 4 ]]; then
    shopt -s inherit_errexit
fi

# ERR trap: print stack trace to stderr on unhandled error
_strict_error_handler() {
    local exit_code=$?
    local line_no="${BASH_LINENO[0]}"
    local command="${BASH_COMMAND}"
    echo "[ERROR] Command failed (exit $exit_code) at line $line_no: $command" >&2
    local i
    for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
        echo "  at ${FUNCNAME[$i]}() in ${BASH_SOURCE[$i]}:${BASH_LINENO[$((i-1))]}" >&2
    done
}
trap '_strict_error_handler' ERR
```

### lib/colors.sh (LOG-03, partial)

```bash
# lib/colors.sh -- Color definitions and terminal detection
[[ -n "${_COLORS_LOADED:-}" ]] && return 0
_COLORS_LOADED=1

# Default color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Disable colors if NO_COLOR is set or stdout is not a terminal
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi
```

### lib/logging.sh (LOG-01, LOG-02, LOG-04, LOG-05)

```bash
# lib/logging.sh -- Logging functions with level filtering
[[ -n "${_LOGGING_LOADED:-}" ]] && return 0
_LOGGING_LOADED=1

# Configuration (set via environment or flags)
LOG_LEVEL="${LOG_LEVEL:-info}"
VERBOSE="${VERBOSE:-0}"

# VERBOSE=1 implies debug log level
[[ "$VERBOSE" -ge 1 ]] && LOG_LEVEL="debug"

_log_level_num() {
    case "$1" in
        debug) echo 0 ;; info) echo 1 ;; warn) echo 2 ;; error) echo 3 ;;
        *) echo 1 ;;
    esac
}

_should_log() {
    local current this
    current=$(_log_level_num "$LOG_LEVEL")
    this=$(_log_level_num "$1")
    [[ "$this" -ge "$current" ]]
}

debug() {
    _should_log debug || return 0
    local timestamp
    timestamp="$(date '+%H:%M:%S') "
    echo -e "${timestamp}${CYAN}[DEBUG]${NC} $*"
}

info() {
    _should_log info || return 0
    local timestamp=""
    [[ "$VERBOSE" -ge 1 ]] && timestamp="$(date '+%H:%M:%S') "
    echo -e "${timestamp}${BLUE}[INFO]${NC} $*"
}

success() {
    _should_log info || return 0
    local timestamp=""
    [[ "$VERBOSE" -ge 1 ]] && timestamp="$(date '+%H:%M:%S') "
    echo -e "${timestamp}${GREEN}[OK]${NC} $*"
}

warn() {
    _should_log warn || return 0
    local timestamp=""
    [[ "$VERBOSE" -ge 1 ]] && timestamp="$(date '+%H:%M:%S') "
    echo -e "${timestamp}${YELLOW}[WARN]${NC} $*"
}

error() {
    # error() always shows (never filtered) and goes to stderr
    local timestamp=""
    [[ "$VERBOSE" -ge 1 ]] && timestamp="$(date '+%H:%M:%S') "
    echo -e "${timestamp}${RED}[ERROR]${NC} $*" >&2
}
```

**Design note on error() filtering:** `error()` is NOT gated by `_should_log` because errors should always be visible regardless of LOG_LEVEL. The LOG_LEVEL mechanism filters informational noise; it should never suppress actual errors.

### Smoke Test Pattern

```bash
#!/usr/bin/env bash
# tests/test-common-loads.sh -- Verify library loads correctly
source "$(dirname "$0")/../scripts/common.sh"

failed=0
for fn in info warn error success debug require_cmd require_target \
          safety_banner check_cmd is_interactive make_temp \
          retry_with_backoff register_cleanup detect_nc_variant \
          report_pass report_fail report_warn report_skip report_section \
          run_check; do
    if ! declare -F "$fn" > /dev/null 2>&1; then
        echo "FAIL: function '$fn' not defined"
        failed=$((failed + 1))
    fi
done

if [[ "$failed" -eq 0 ]]; then
    echo "PASS: all expected functions loaded"
else
    echo "FAIL: $failed functions missing"
    exit 1
fi
```

## Module Content Mapping

This maps every existing function/variable from current `common.sh` to its new home in `lib/*.sh`:

| Current Location | Function/Variable | New Home | Notes |
|-----------------|-------------------|----------|-------|
| Line 8-12 | Bash version guard | `common.sh` (stays) | Before any source statements |
| Line 14 | `set -euo pipefail` | `lib/strict.sh` | Upgraded to `set -eEuo pipefail` |
| Line 17-22 | Color variables (RED, GREEN, etc.) | `lib/colors.sh` | Add NO_COLOR + terminal detection |
| Line 24 | `info()` | `lib/logging.sh` | Add LOG_LEVEL filtering + VERBOSE timestamps |
| Line 25 | `success()` | `lib/logging.sh` | Add LOG_LEVEL filtering + VERBOSE timestamps |
| Line 26 | `warn()` | `lib/logging.sh` | Add LOG_LEVEL filtering + VERBOSE timestamps |
| Line 27 | `error()` | `lib/logging.sh` | Add VERBOSE timestamps; keep >&2 |
| (new) | `debug()` | `lib/logging.sh` | NEW: invisible by default |
| Line 30-35 | `require_root()` | `lib/validation.sh` | Unchanged |
| Line 38-40 | `check_cmd()` | `lib/validation.sh` | Unchanged |
| Line 43-51 | `require_cmd()` | `lib/validation.sh` | Unchanged |
| Line 54-60 | `require_target()` | `lib/validation.sh` | Unchanged |
| Line 63-70 | `safety_banner()` | `lib/output.sh` | Unchanged (Phase 14 may add quiet-mode gating) |
| Line 73-75 | `is_interactive()` | `lib/output.sh` | Unchanged |
| Line 78 | `PROJECT_ROOT` | `lib/output.sh` | Unchanged |
| Line 84-97 | `detect_nc_variant()` | `lib/nc_detect.sh` | Unchanged |
| Line 102-105 | `report_pass/fail/warn/skip()` | `lib/diagnostic.sh` | Unchanged |
| Line 107 | `report_section()` | `lib/diagnostic.sh` | Unchanged |
| Line 110-127 | `_run_with_timeout()` | `lib/diagnostic.sh` | Unchanged |
| Line 131-147 | `run_check()` | `lib/diagnostic.sh` | Unchanged |
| (new) | `make_temp()` | `lib/cleanup.sh` | NEW: temp file with EXIT trap cleanup |
| (new) | `register_cleanup()` | `lib/cleanup.sh` | NEW: register arbitrary cleanup command |
| (new) | `retry_with_backoff()` | `lib/cleanup.sh` or `lib/validation.sh` | NEW: exponential backoff retry |

## Requirement-to-Module Mapping

| Requirement | Module(s) | What it delivers |
|-------------|-----------|-----------------|
| STRICT-01 | `lib/strict.sh` | `set -eEuo pipefail` (upgraded from `set -euo pipefail`) |
| STRICT-02 | `lib/strict.sh` | ERR trap with `BASH_LINENO`/`FUNCNAME`/`BASH_SOURCE` stack trace to stderr |
| STRICT-03 | `lib/strict.sh` | `shopt -s inherit_errexit` gated behind Bash 4.4+ check |
| STRICT-04 | `lib/cleanup.sh` | EXIT trap running cleanup on normal exit, error, and Ctrl+C |
| STRICT-05 | All `lib/*.sh` files | `_MODULE_LOADED` source guard at top of every module |
| LOG-01 | `lib/logging.sh` | `info/warn/error/success` support `LOG_LEVEL` filtering |
| LOG-02 | `lib/logging.sh` | `debug()` function, invisible by default, visible with `VERBOSE=1` or `LOG_LEVEL=debug` |
| LOG-03 | `lib/colors.sh` | ANSI codes disabled when stdout is not a terminal or `NO_COLOR` is set |
| LOG-04 | `lib/logging.sh` | `VERBOSE` mechanism enabling timestamps + debug output (flag handling is Phase 14) |
| LOG-05 | `lib/logging.sh` | `LOG_LEVEL` mechanism where `LOG_LEVEL=error` suppresses non-error output (flag is Phase 14) |
| INFRA-01 | `common.sh` + all `lib/*.sh` | Split into `scripts/lib/` modules behind backward-compatible entry point |
| INFRA-02 | `common.sh` | All 66 scripts keep existing source line unchanged |
| INFRA-03 | `lib/cleanup.sh` | `make_temp()` creates tracked temp files/dirs, auto-cleaned on EXIT |
| INFRA-04 | `lib/cleanup.sh` | `retry_with_backoff()` with configurable max retries and exponential delay |

## Verification Strategy

### Success Criterion 1: Identical Output

```bash
# Before: capture baseline output
bash scripts/nmap/examples.sh scanme.nmap.org 2>/dev/null > /tmp/before.txt
# After: capture new output
bash scripts/nmap/examples.sh scanme.nmap.org 2>/dev/null > /tmp/after.txt
# Compare
diff /tmp/before.txt /tmp/after.txt
# Expected: no differences
```

Run for at least: one examples.sh, one use-case script, one diagnostic, check-tools.sh.

### Success Criterion 2: Stack Trace on Error

```bash
# Create a test script that errors
cat > /tmp/test-stacktrace.sh << 'EOF'
#!/usr/bin/env bash
source "scripts/common.sh"
my_function() {
    false  # This should trigger ERR trap
}
my_function
EOF
bash /tmp/test-stacktrace.sh 2>&1 | grep -q "Command failed"
# Expected: stack trace visible on stderr
```

### Success Criterion 3: VERBOSE Mode

```bash
VERBOSE=1 bash scripts/nmap/examples.sh scanme.nmap.org 2>&1 | head -5
# Expected: timestamps like "12:34:56 [INFO] ..." visible
bash scripts/nmap/examples.sh scanme.nmap.org 2>&1 | grep -c '^\d\d:\d\d:\d\d'
# Expected: 0 (no timestamps without VERBOSE)
```

### Success Criterion 4: No ANSI in Pipes

```bash
bash scripts/nmap/examples.sh scanme.nmap.org | cat | grep -cP '\033\[' || echo "0"
# Expected: 0
```

### Success Criterion 5: Temp File Cleanup

```bash
cat > /tmp/test-cleanup.sh << 'EOF'
#!/usr/bin/env bash
source "scripts/common.sh"
tmpfile=$(make_temp)
echo "test" > "$tmpfile"
echo "Created: $tmpfile"
# Script exits normally; EXIT trap should clean up
EOF
tmpfile=$(bash /tmp/test-cleanup.sh | grep "Created:" | awk '{print $2}')
[[ ! -f "$tmpfile" ]]  # File should be gone
```

## Scope Boundaries

### In Scope (Phase 13)

- Create `scripts/lib/` directory with 8 module files
- Rewrite `common.sh` as entry point sourcing lib modules
- Add `set -eEuo pipefail` (upgrade from `set -euo pipefail`)
- Add ERR trap with stack trace to stderr
- Add `shopt -s inherit_errexit` (Bash 4.4+ gated)
- Add EXIT trap with cleanup handler
- Add source guards to all modules
- Enhance `info/warn/error/success` with LOG_LEVEL filtering
- Add `debug()` function
- Add NO_COLOR + terminal detection for color suppression
- Add VERBOSE mechanism (timestamps + debug visibility)
- Add LOG_LEVEL mechanism (debug/info/warn/error filtering)
- Add `make_temp()` function
- Add `register_cleanup()` function
- Add `retry_with_backoff()` function

### Out of Scope (Later Phases)

- `-v`/`--verbose` flag handling (Phase 14 -- argument parsing)
- `-q`/`--quiet` flag handling (Phase 14 -- argument parsing)
- `parse_common_args()` function (Phase 14)
- `run_or_show()` dual-mode function (Phase 16)
- Modifying any consumer script's logic (Phases 15-16)
- ShellCheck compliance fixes (Phase 17)
- `check-docs-completeness.sh` does not source common.sh; not affected

## Open Questions

1. **Where does `retry_with_backoff()` live?**
   - It logically belongs in `lib/cleanup.sh` (infrastructure utilities) or could be its own `lib/retry.sh`.
   - Within the 8-file constraint, it fits in `lib/cleanup.sh` since that module covers "infrastructure utilities."
   - Recommendation: Put it in `lib/cleanup.sh` alongside `make_temp()` and `register_cleanup()`.

2. **Should `safety_banner()` respect LOG_LEVEL?**
   - Currently it outputs unconditionally to stdout.
   - Phase 14 may gate it behind quiet mode.
   - For Phase 13: leave unchanged. The mechanism (LOG_LEVEL) is available but `safety_banner()` does not use it yet.

3. **Output routing: should info/warn/success move to stderr?**
   - STACK.md research recommended moving all logging to stderr.
   - Current behavior: info/warn/success go to stdout; error goes to stderr.
   - Moving to stderr would break scripts that capture output via pipe/redirect.
   - Decision: Keep current routing. The locked decision says "enhance in-place" which means preserving output destinations.
   - The success criterion says piping through `cat` should strip ANSI codes. Since `cat` receives stdout, the color check correctly uses `[[ -t 1 ]]`.

4. **`report_*()` functions and NO_COLOR**
   - The `report_pass/fail/warn/skip/section()` functions in `lib/diagnostic.sh` also emit ANSI codes.
   - They must also respect the NO_COLOR/terminal detection from `lib/colors.sh`.
   - Since they use the same color variables (RED, GREEN, CYAN, NC), they automatically benefit from the color suppression in `colors.sh`. No additional changes needed.

## Sources

### Primary (HIGH confidence)
- **Codebase analysis** -- Direct reading of all 68 .sh files, common.sh line-by-line inventory
- [Bash Reference Manual - set builtin](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html) -- `-E` flag behavior, ERR trap inheritance
- [Bash Reference Manual - shopt](https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html) -- `inherit_errexit` documentation
- [Greg's Wiki BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105) -- `set -e` pitfalls and ERR trap behavior
- [Greg's Wiki SignalTrap](https://mywiki.wooledge.org/SignalTrap) -- EXIT trap fires on INT/TERM; do not trap both
- [Greg's Wiki BashFAQ/062](https://mywiki.wooledge.org/BashFAQ/062) -- Temp file management with mktemp + trap
- [NO_COLOR Standard](https://no-color.org/) -- NO_COLOR convention specification
- Prior project research: `.planning/research/STACK.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `FEATURES.md`, `SUMMARY.md`

### Secondary (MEDIUM confidence)
- [Unofficial Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) -- `set -euo pipefail` patterns and pitfalls
- [Exit Traps in Bash](http://redsymbol.net/articles/bash-exit-traps/) -- EXIT trap patterns
- [Designing Modular Bash](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/) -- Source guards, module patterns

## Metadata

**Confidence breakdown:**
- Library split architecture: HIGH -- derived from actual common.sh analysis + locked 8-file decision
- Strict mode (set -eEuo pipefail, ERR trap): HIGH -- Bash Reference Manual is authoritative; patterns verified against Greg's Wiki
- Logging upgrade (LOG_LEVEL, VERBOSE, debug()): HIGH -- standard bash patterns, no external dependencies
- NO_COLOR/terminal detection: HIGH -- no-color.org is the standard; `[[ -t 1 ]]` is POSIX
- Temp file cleanup (make_temp, EXIT trap): HIGH -- Greg's Wiki BashFAQ/062 is the canonical reference
- retry_with_backoff: HIGH -- universally standard exponential backoff pattern
- Backward compatibility analysis: HIGH -- tested by reading all 66 consumer scripts and verifying no function signature changes

**Research date:** 2026-02-11
**Valid until:** Indefinite (stable domain -- bash patterns do not change)
