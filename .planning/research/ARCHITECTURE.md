# Architecture Patterns: Bash Script Hardening and Dual-Mode CLI Infrastructure

**Domain:** Production-grade bash script infrastructure for 66 educational security scripts
**Researched:** 2026-02-11
**Confidence:** HIGH (patterns derived from codebase analysis + established bash best practices)

## Current Architecture (Baseline)

```
scripts/
  common.sh                     # 138 lines -- shared utility layer (ALL scripts source this)
  check-tools.sh                # Tool installation checker
  check-docs-completeness.sh    # Documentation checker
  diagnostics/
    dns.sh                      # Pattern B: auto-report with pass/fail/warn counters
    connectivity.sh             # Pattern B: auto-report
    performance.sh              # Pattern B: auto-report
  <tool>/
    examples.sh                 # Pattern A: 10 numbered examples + interactive demo
    <use-case>.sh               # Pattern A variant: task-specific examples + demo
```

**66 consumer scripts** source `common.sh`. Three distinct patterns exist today:

### Pattern A: Educational Examples (46 scripts)

```
examples.sh / use-case scripts:
  source common.sh
  show_help()
  parse -h/--help
  require_cmd
  [require_target | default target]
  safety_banner
  10 numbered examples (info + echo)
  interactive demo ([[ -t 0 ]] guard)
```

### Pattern B: Diagnostic Auto-Reports (3 scripts)

```
diagnostics/*.sh:
  source common.sh
  show_help()
  parse -h/--help
  require_cmd
  default target
  NO safety_banner (non-interactive, informational)
  report_section / count_pass / count_fail / count_warn
  structured output with summary counters
```

### Pattern C: Tool Checkers (2 scripts)

```
check-tools.sh / check-docs-completeness.sh:
  source common.sh
  show_help()
  parse -h/--help
  iterate over tool list
  report installed/missing status
```

### Current common.sh Inventory (138 lines)

| Function/Variable | Lines | Used By | Purpose |
|-------------------|-------|---------|---------|
| Color vars (RED, GREEN, etc.) | 6 | All | ANSI color codes |
| info(), success(), warn(), error() | 4 | All | Colored log output |
| require_root() | 5 | Pattern A (subset) | Root check |
| check_cmd() | 3 | All | Boolean command existence |
| require_cmd() | 8 | All | Exit if command missing |
| require_target() | 6 | Pattern A | Validate target arg |
| safety_banner() | 8 | Pattern A | Legal authorization warning |
| is_interactive() | 3 | Pattern A | TTY detection |
| PROJECT_ROOT | 1 | Some | Repository root path |
| detect_nc_variant() | 13 | netcat scripts | Netcat variant detection |
| report_pass/fail/warn/skip() | 4 | Pattern B | Diagnostic report labels |
| report_section() | 1 | Pattern B | Section headers |
| _run_with_timeout() | 17 | Pattern B | Portable timeout wrapper |
| run_check() | 16 | Pattern B | Execute with timeout + report |

**Key observation:** common.sh is already showing signs of growing beyond a single concern. The diagnostic functions (report_*, run_check, _run_with_timeout) occupy 38 lines and are only used by 3 scripts. The core functions used by all 66 scripts occupy about 44 lines. The netcat variant detection is used by 4 scripts.

## Recommended Architecture (After Hardening)

### Decision: Split common.sh Into a Modular Library

**Recommendation:** Split common.sh into focused library files, but keep a single `common.sh` entry point that sources them for backward compatibility.

**Why split:** Adding dual-mode output, structured logging, argument parsing, and trap/cleanup will at least triple the line count. A 400+ line monolithic common.sh becomes hard to maintain, test, and reason about. Splitting by concern keeps each module focused.

**Why keep the entry point:** All 66 scripts use `source "$(dirname "$0")/../common.sh"`. Changing every script's source line is unnecessary churn. The entry point simply sources sub-modules.

```
scripts/
  common.sh                      # PRESERVED: entry point, sources lib/*.sh
  lib/
    core.sh                      # Colors, PROJECT_ROOT, is_interactive()
    logging.sh                   # info/success/warn/error + structured log_*() functions
    validation.sh                # require_root, check_cmd, require_cmd, require_target
    args.sh                      # Argument parsing framework (parse_args, show_usage)
    output.sh                    # Dual-mode output (human vs quiet), safety_banner
    cleanup.sh                   # Trap/signal handling, temp file management
    diagnostic.sh                # report_pass/fail/warn/skip, run_check, counters
    nc_detect.sh                 # detect_nc_variant (tool-specific utility)
  diagnostics/
    dns.sh                       # Pattern B (unchanged source line)
    connectivity.sh              # Pattern B (unchanged source line)
    performance.sh               # Pattern B (unchanged source line)
  <tool>/
    examples.sh                  # Pattern A (unchanged source line)
    <use-case>.sh                # Pattern A (unchanged source line)
```

### New common.sh (Entry Point Pattern)

```bash
#!/usr/bin/env bash
# common.sh -- Shared utility functions for all tool scripts
# Source this file: source "$(dirname "$0")/../common.sh"

# Resolve library directory
_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source guard: prevent double-sourcing
if [[ -n "${_COMMON_LOADED:-}" ]]; then return 0 2>/dev/null || true; fi
_COMMON_LOADED=1

# Source all library modules
source "${_COMMON_DIR}/lib/core.sh"
source "${_COMMON_DIR}/lib/logging.sh"
source "${_COMMON_DIR}/lib/validation.sh"
source "${_COMMON_DIR}/lib/args.sh"
source "${_COMMON_DIR}/lib/output.sh"
source "${_COMMON_DIR}/lib/cleanup.sh"
source "${_COMMON_DIR}/lib/diagnostic.sh"
source "${_COMMON_DIR}/lib/nc_detect.sh"
```

**Backward compatibility:** Every existing script still does `source "$(dirname "$0")/../common.sh"` and gets all functions. Zero migration needed for existing scripts.

## Component Boundaries

| Component | Responsibility | Communicates With | Consumers |
|-----------|---------------|-------------------|-----------|
| `lib/core.sh` | Colors, PROJECT_ROOT, base shell setup | None (foundational) | All other lib modules, all scripts |
| `lib/logging.sh` | Human-readable output + structured file logging | `lib/core.sh` (colors) | All scripts |
| `lib/validation.sh` | Prerequisite checks (cmd, root, target) | `lib/logging.sh` (error messages) | All scripts |
| `lib/args.sh` | Argument parsing framework | `lib/logging.sh` (error on invalid args) | Scripts opting in to new arg parsing |
| `lib/output.sh` | Dual-mode output (human/quiet), safety_banner | `lib/core.sh` (colors, is_interactive) | All scripts |
| `lib/cleanup.sh` | Trap handlers, temp file management | `lib/logging.sh` (log cleanup events) | Scripts with temp files or long-running operations |
| `lib/diagnostic.sh` | report_pass/fail/warn, counters, run_check | `lib/core.sh` (colors), `lib/logging.sh` | Pattern B scripts only |
| `lib/nc_detect.sh` | Netcat variant detection | `lib/core.sh` (check_cmd) | netcat/ scripts only |

### Dependency Graph (Source Order Matters)

```
core.sh          (no dependencies)
  |
  +-- logging.sh      (depends on core.sh for colors)
  |     |
  |     +-- validation.sh  (depends on logging.sh for error())
  |     |
  |     +-- args.sh        (depends on logging.sh for error())
  |     |
  |     +-- cleanup.sh     (depends on logging.sh for log events)
  |
  +-- output.sh       (depends on core.sh for colors, is_interactive)
  |
  +-- diagnostic.sh   (depends on core.sh for colors, logging.sh)
  |
  +-- nc_detect.sh    (depends on core.sh for check_cmd)
```

**The source order in common.sh must follow this graph.** core.sh first, logging.sh second, everything else after.

## Feature 1: Dual-Mode Output

### Problem

Currently, all scripts output educational text unconditionally. There is no way to:
- Run a script quietly for automation (suppress examples, show only results)
- Pipe output cleanly to another tool
- Use scripts in CI/CD or cron jobs with minimal noise

### Recommended Pattern

Detect output mode via environment variable and/or flag, then route output through mode-aware functions.

**Three modes:**

| Mode | Trigger | Behavior |
|------|---------|----------|
| `human` (default) | TTY detected, no flags | Full colored output with examples, banners, interactive prompts |
| `quiet` | `-q` / `--quiet` / `QUIET=1` | Suppress educational text, show only actionable output (commands, results) |
| `json` (future) | `--json` / `JSON_OUTPUT=1` | Structured JSON output for machine consumption |

**Implementation in `lib/output.sh`:**

```bash
# Determine output mode
# Priority: explicit flag > environment variable > TTY detection
OUTPUT_MODE="${OUTPUT_MODE:-}"
[[ -z "$OUTPUT_MODE" ]] && OUTPUT_MODE="human"

# Is the output for a human?
is_human_output() {
    [[ "$OUTPUT_MODE" == "human" ]]
}

# Print educational text (suppressed in quiet mode)
teach() {
    is_human_output && echo -e "$@"
}

# Print a numbered example (suppressed in quiet mode)
example() {
    local num="$1"
    shift
    if is_human_output; then
        info "${num}) $1"
        shift
        for line in "$@"; do
            echo "   ${line}"
        done
        echo ""
    fi
}

# Print actionable output (always shown)
result() {
    echo -e "$@"
}
```

**Migration path for existing scripts:**

```bash
# BEFORE (Pattern A):
info "1) Ping scan -- is the host up?"
echo "   nmap -sn ${TARGET}"
echo ""

# AFTER (dual-mode aware):
example 1 "Ping scan -- is the host up?" \
    "nmap -sn ${TARGET}"
```

This is an opt-in migration. Existing scripts work unchanged. New features or refactored scripts adopt the `example()` / `teach()` / `result()` functions.

### Integration with Pattern B (Diagnostics)

Diagnostic scripts already produce structured output. In quiet mode, they should still produce report_pass/fail/warn lines (those are the "results"). The educational headers and section decorations can be suppressed.

```bash
# In lib/diagnostic.sh:
report_section() {
    is_human_output && echo -e "\n${CYAN}=== $* ===${NC}\n"
}
```

## Feature 2: Structured Logging

### Problem

Current logging goes only to stdout/stderr with color codes. There is no way to:
- Write logs to a file for post-mortem analysis
- Filter by log level
- Get timestamps for debugging timing issues
- Produce machine-parseable log output

### Recommended Pattern

Keep the existing `info()`, `warn()`, `error()`, `success()` functions unchanged for human output. Add a parallel structured logging layer that optionally writes to a file.

**Implementation in `lib/logging.sh`:**

```bash
# --- Human-Readable Output (existing, preserved) ---
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# --- Structured File Logging (new, opt-in) ---
LOG_FILE="${LOG_FILE:-}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Numeric log levels for comparison
declare -A _LOG_LEVELS=([ERROR]=1 [WARN]=2 [INFO]=3 [DEBUG]=4)

_log() {
    local level="$1"
    shift
    local level_num="${_LOG_LEVELS[$level]:-3}"
    local threshold="${_LOG_LEVELS[$LOG_LEVEL]:-3}"

    # Only log if level meets threshold
    (( level_num > threshold )) && return 0

    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local msg="[${timestamp}] [${level}] $*"

    # Write to log file if configured
    if [[ -n "$LOG_FILE" ]]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

log_error() { _log ERROR "$@"; error "$@"; }
log_warn()  { _log WARN "$@";  warn "$@"; }
log_info()  { _log INFO "$@";  info "$@"; }
log_debug() { _log DEBUG "$@"; }  # debug only goes to file, not stdout
```

**Key design decisions:**

1. **Opt-in via LOG_FILE:** If LOG_FILE is empty (default), no file logging occurs. Zero overhead for scripts that do not need it.
2. **Preserve existing functions:** `info()`, `warn()`, `error()`, `success()` remain identical. Scripts using them today change nothing.
3. **New log_*() functions for dual output:** Scripts that want both human output AND file logging use `log_info()` instead of `info()`. This is an opt-in upgrade, not a forced migration.
4. **LOG_LEVEL filtering:** Only applies to file output. Human output functions always print (the user explicitly called them).

## Feature 3: Argument Parsing Framework

### Problem

Current argument parsing is minimal and inconsistent:
- Help: `[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0` (all scripts)
- Target: positional `$1` with optional default (most scripts)
- No support for flags like `-q`, `--quiet`, `-v`, `--verbose`, `--json`
- No support for `--target=value` or `-t value` syntax
- Adding a new global flag (like `--quiet`) means touching every script

### Recommended Pattern

Use manual parsing (not getopts) because the project needs long options (`--quiet`, `--json`, `--log-file`) and the simplicity of the current positional pattern should be preserved.

**Implementation in `lib/args.sh`:**

```bash
# Parse common flags from argument list, pass remaining args back
# Usage: parse_common_args "$@"; set -- "${REMAINING_ARGS[@]}"
REMAINING_ARGS=()

parse_common_args() {
    REMAINING_ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help  # Expects script to define show_help()
                exit 0
                ;;
            -q|--quiet)
                OUTPUT_MODE="quiet"
                shift
                ;;
            --json)
                OUTPUT_MODE="json"
                shift
                ;;
            --log-file)
                LOG_FILE="${2:?--log-file requires a path}"
                shift 2
                ;;
            --log-file=*)
                LOG_FILE="${1#*=}"
                shift
                ;;
            --debug)
                LOG_LEVEL="DEBUG"
                shift
                ;;
            --)
                shift
                REMAINING_ARGS+=("$@")
                break
                ;;
            -*)
                # Unknown flag -- let calling script handle it
                REMAINING_ARGS+=("$1")
                shift
                ;;
            *)
                # Positional argument
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}
```

**Migration path for existing scripts:**

```bash
# BEFORE:
[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0
require_target "${1:-}"
TARGET="$1"

# AFTER (opt-in, not forced):
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]}"
require_target "${1:-}"
TARGET="${1:-}"
```

**Why manual parsing over getopts:**
- getopts does not support long options (`--quiet`, `--json`, `--log-file`)
- getopt (external) has portability issues on macOS vs Linux
- Manual parsing is explicit, readable, and allows unknown flags to pass through to the script
- The existing scripts use a very simple positional pattern; manual parsing extends it naturally
- Confidence: HIGH (based on Greg's Wiki BashFAQ/035, clig.dev guidelines)

## Feature 4: Trap/Cleanup Framework

### Problem

Currently, no scripts register trap handlers. If a script creates temp files, they are cleaned up inline (or not at all). There is no consistent way to:
- Clean up temp files on script exit (normal or error)
- Handle Ctrl+C gracefully
- Log script completion status

### Recommended Pattern

Register a single EXIT trap that calls a cleanup function. Scripts register cleanup tasks by pushing to an array.

**Implementation in `lib/cleanup.sh`:**

```bash
# Cleanup task registry
_CLEANUP_TASKS=()
_CLEANUP_FILES=()

# Register a cleanup command
register_cleanup() {
    _CLEANUP_TASKS+=("$*")
}

# Register a temp file for automatic deletion
register_tempfile() {
    local tmpfile="$1"
    _CLEANUP_FILES+=("$tmpfile")
}

# Create a temp file and register it for cleanup
make_temp() {
    local prefix="${1:-ntool}"
    local tmpfile
    tmpfile=$(mktemp "/tmp/${prefix}.XXXXXX")
    register_tempfile "$tmpfile"
    echo "$tmpfile"
}

# Internal cleanup handler
_run_cleanup() {
    local exit_code=$?
    # Remove registered temp files
    for f in "${_CLEANUP_FILES[@]}"; do
        [[ -f "$f" ]] && rm -f "$f"
    done
    # Run registered cleanup tasks
    for task in "${_CLEANUP_TASKS[@]}"; do
        eval "$task" 2>/dev/null || true
    done
    exit "$exit_code"
}

# Register the EXIT trap (only trap EXIT; INT/TERM trigger EXIT automatically)
trap _run_cleanup EXIT
```

**Key design decisions:**

1. **Trap only EXIT, not INT/TERM/ERR.** When a signal like INT or TERM is received, bash runs the EXIT trap before exiting. Trapping both INT and EXIT causes double execution of cleanup. Trapping only EXIT is the correct pattern.
2. **Preserve exit code.** The cleanup handler captures `$?` before running cleanup, then exits with the original code.
3. **eval for registered tasks.** Scripts can register arbitrary cleanup commands (e.g., `register_cleanup "docker stop mycontainer"`). The eval runs in the cleanup context.
4. **make_temp() helper.** Replaces ad-hoc `mktemp` calls with automatic cleanup registration.
5. **Confidence:** HIGH (established bash pattern, Greg's Wiki SignalTrap)

**Migration path:** The EXIT trap registers automatically when common.sh is sourced. Scripts that create temp files switch from manual `mktemp` + manual `rm` to `make_temp()`. No impact on scripts that do not use temp files.

## Feature 5: Strict Mode Hardening

### Current State

common.sh already has `set -euo pipefail` on line 5. This is good. However:

1. Some scripts use `|| true` guards defensively (found in diagnostic scripts) -- this is correct for pipefail compatibility but should be documented as a pattern, not just scattered.
2. No ERR trap to log which command failed.
3. No debug mode that enables `set -x` for tracing.

### Recommended Additions

**In `lib/core.sh`:**

```bash
set -euo pipefail

# Debug mode: enable trace if DEBUG or BASH_XTRACE is set
if [[ "${DEBUG:-}" == "1" || "${BASH_XTRACE:-}" == "1" ]]; then
    set -x
fi

# ERR trap: log the failing command (informational, does not change behavior)
_on_error() {
    local exit_code=$?
    local line_no="${BASH_LINENO[0]}"
    local command="${BASH_COMMAND}"
    # Only log to file if LOG_FILE is set (avoid noisy stderr for simple scripts)
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] [ERROR] Command failed: '${command}' at line ${line_no} (exit code ${exit_code})" >> "$LOG_FILE"
    fi
}
trap '_on_error' ERR
```

**Pattern for defensive `|| true` usage:**

```bash
# DOCUMENT: Use || true when a command's non-zero exit is expected
# and should not trigger set -e. Common cases:
#   - grep that might match nothing: grep "pattern" file || true
#   - kill that might find no process: kill "$pid" 2>/dev/null || true
#   - commands in pipelines where set -o pipefail would trigger: cmd | head || true
```

## Data Flow: Script Execution With New Infrastructure

### Before (Current)

```
Script starts
  |
  source common.sh
  |  - set -euo pipefail
  |  - define colors, functions
  |
  [[ -h/--help ]] -> show_help -> exit
  |
  require_cmd -> exit on failure
  require_target -> exit on failure
  |
  safety_banner (always)
  |
  10x: info "N) ..." + echo "   cmd" + echo ""
  |
  [[ -t 0 ]] -> interactive demo or exit
```

### After (With New Infrastructure)

```
Script starts
  |
  source common.sh
  |  - source lib/core.sh      (set -euo pipefail, colors, ERR trap)
  |  - source lib/logging.sh   (info/warn/error + log_*() + LOG_FILE)
  |  - source lib/validation.sh (require_cmd, require_target, require_root)
  |  - source lib/args.sh      (parse_common_args)
  |  - source lib/output.sh    (teach, example, result, safety_banner)
  |  - source lib/cleanup.sh   (EXIT trap, make_temp, register_cleanup)
  |  - source lib/diagnostic.sh (report_*, run_check, counters)
  |  - source lib/nc_detect.sh (detect_nc_variant)
  |
  parse_common_args "$@"      # Handles -h, -q, --json, --log-file, --debug
  set -- "${REMAINING_ARGS[@]}" # Remaining positional args
  |
  require_cmd -> exit on failure (logged if LOG_FILE set)
  require_target -> exit on failure
  |
  safety_banner (suppressed in quiet mode)
  |
  10x: example N "Title" "cmd"  (suppressed in quiet mode)
  |
  [[ -t 0 && human mode ]] -> interactive demo or exit
```

## Migration Strategy: Incremental, Not Big-Bang

### Why Incremental

- 66 scripts must continue working at every step
- Each change can be verified independently
- Risk is contained per step
- No "flag day" where everything must change at once

### Build Order (Dependency-Driven)

**Step 1: Create lib/ directory and split common.sh (foundation)**

Split existing functions into lib/*.sh files. Keep common.sh as entry point that sources them. Run all scripts after to verify zero behavioral change.

```
Risk: LOW (pure refactor, no behavior change)
Verification: Every script produces identical output before/after
Backward compat: 100% -- source line unchanged
```

**Step 2: Add source guards to each lib/*.sh (safety)**

Prevent double-sourcing issues if any script sources common.sh multiple times or sources lib files directly.

```
Risk: LOW (additive only)
Verification: Source common.sh twice in a test script, verify no errors
Backward compat: 100%
```

**Step 3: Add cleanup framework (lib/cleanup.sh + EXIT trap)**

This must come before logging-to-file because log files need proper cleanup. The EXIT trap registers automatically -- all scripts get cleanup support without changes.

```
Risk: LOW (EXIT trap is passive; does nothing unless scripts register tasks)
Verification: Scripts that create temp files still work
Backward compat: 100% -- trap does nothing unless register_cleanup/make_temp called
```

**Step 4: Add structured logging (lib/logging.sh enhancement)**

Add log_*() functions and LOG_FILE support alongside existing info/warn/error. Existing functions are unchanged.

```
Risk: LOW (purely additive -- new functions, no changes to existing ones)
Verification: info/warn/error still produce identical output
Backward compat: 100% -- new functions are opt-in
```

**Step 5: Add argument parsing framework (lib/args.sh)**

Add parse_common_args() function. Does not change any existing script behavior until a script explicitly calls it.

```
Risk: LOW (purely additive)
Verification: New function works in isolation tests
Backward compat: 100% -- purely opt-in
```

**Step 6: Add dual-mode output (lib/output.sh)**

Add teach(), example(), result() functions. Add OUTPUT_MODE variable. Modify safety_banner() to respect quiet mode.

```
Risk: MEDIUM (safety_banner behavior changes in quiet mode)
Verification: Without -q flag, all output is identical to before
Backward compat: 99% -- safety_banner now checks OUTPUT_MODE but defaults to "human"
```

**Step 7: Migrate one tool as proof of concept**

Pick one tool directory (recommendation: `nmap/` -- most used, well-understood) and migrate its examples.sh and use-case scripts to use the new parse_common_args + example() + teach() pattern.

```
Risk: LOW (single tool, easy to revert)
Verification: nmap scripts work identically in human mode, support -q flag
```

**Step 8: Migrate remaining tools (batch, tool-by-tool)**

Migrate remaining 17 tool directories one at a time. Each tool's scripts are independent, so this can be parallelized.

```
Risk: LOW per tool (isolated changes)
Verification: Each tool tested after migration
```

### What NOT to Do

| Anti-Pattern | Why | Instead |
|--------------|-----|---------|
| Rename common.sh | Breaks 66 source lines | Keep as entry point |
| Change existing function signatures | Breaks all callers | Add new functions alongside |
| Force all scripts to use parse_common_args | Unnecessary churn | Let scripts opt in |
| Add `set -x` globally | Noise in all output | Gate behind DEBUG=1 env var |
| Make LOG_FILE mandatory | Overhead for simple educational scripts | Opt-in via env var or --log-file flag |

## Patterns to Follow

### Pattern 1: Source Guard

**What:** Prevent double-sourcing of library files.
**When:** Every lib/*.sh file.
**Why:** Complex source chains (common.sh -> lib/logging.sh, script -> common.sh) can lead to double-sourcing. Guards prevent function redefinition and side-effect duplication.

```bash
# lib/logging.sh
if [[ -n "${_LOGGING_LOADED:-}" ]]; then return 0 2>/dev/null || true; fi
_LOGGING_LOADED=1
```

### Pattern 2: Additive Functions, Not Modified Functions

**What:** Add new functions (log_info, teach, example) rather than changing existing ones (info, warn).
**When:** Any time new behavior is needed.
**Why:** 66 scripts depend on exact behavior of info(), warn(), error(). Changing them risks regressions across every script. Adding parallel functions is zero-risk.

```bash
# DO: Add new function
log_info() { _log INFO "$@"; info "$@"; }

# DON'T: Modify existing function
info() { _log INFO "$@"; echo -e "${BLUE}[INFO]${NC} $*"; }  # BREAKS if _log not loaded
```

### Pattern 3: Environment Variable Configuration

**What:** Use environment variables for global behavior switches.
**When:** Features that affect all scripts (logging, output mode, debug).
**Why:** Environment variables work across source boundaries, can be set from Makefile, and do not require argument parsing changes.

```bash
# Set from Makefile:
# make nmap TARGET=192.168.1.1 QUIET=1

# Set from command line:
# LOG_FILE=/tmp/scan.log bash scripts/nmap/examples.sh 192.168.1.1

# Set from within script:
export LOG_FILE="/tmp/scan.log"
```

### Pattern 4: Default-Off, Opt-In

**What:** New features are inactive by default and activated explicitly.
**When:** Every new feature added to common.sh/lib/.
**Why:** The primary audience is learners running scripts interactively. New features should enhance without disrupting the default educational experience.

### Pattern 5: Defensive `|| true` Documentation

**What:** Document why `|| true` guards exist rather than removing them.
**When:** Any command that intentionally produces non-zero exits under normal operation.
**Why:** `set -e` and `set -o pipefail` cause scripts to exit on any failure. Some commands (grep with no match, kill of non-existent PID) return non-zero normally. The `|| true` guard is correct -- it just needs documentation.

```bash
# grep returns 1 when no lines match; this is expected, not an error
timeout_hops=$(echo "$traceroute_output" | grep -nE '^\s*[0-9]+\s+\*' || true)
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Namespace Collision on Split

**What:** Splitting common.sh into lib/ files where two files define the same internal variable name.
**Why bad:** All lib files are sourced into the same shell scope. Variable `result` in lib/validation.sh would collide with `result` in lib/diagnostic.sh.
**Prevention:** Use `local` for all function-internal variables. Prefix module-level variables with module name (e.g., `_LOG_LEVELS`, `_CLEANUP_TASKS`).

### Anti-Pattern 2: Circular Source Dependencies

**What:** lib/logging.sh sources lib/validation.sh, which sources lib/logging.sh.
**Why bad:** Infinite recursion or incomplete initialization.
**Prevention:** Strict one-way dependency graph (see dependency graph above). Source guards catch violations.

### Anti-Pattern 3: Global State Mutation in Library Init

**What:** Library files that change behavior just by being sourced (e.g., overwriting variables, registering traps that conflict).
**Why bad:** Sourcing common.sh should be safe and predictable. Side effects at source time create ordering bugs.
**Prevention:** The only acceptable source-time side effects are: `set -euo pipefail` (already exists), EXIT trap registration (passive until cleanup tasks registered), and variable declarations with defaults.

### Anti-Pattern 4: Testing by Running All 66 Scripts

**What:** Verifying the library split by manually running every script.
**Why bad:** Slow, error-prone, misses edge cases.
**Prevention:** Create a simple smoke test that sources common.sh and verifies all expected functions exist (type -t function_name). This catches missing sources, typos, and load-order bugs in seconds.

```bash
# tests/test-common.sh
source "$(dirname "$0")/../scripts/common.sh"
for fn in info warn error success require_cmd require_target \
          safety_banner check_cmd is_interactive parse_common_args \
          teach example result log_info log_warn log_error make_temp; do
    if ! type -t "$fn" &>/dev/null; then
        echo "FAIL: function '$fn' not defined after sourcing common.sh"
        exit 1
    fi
done
echo "PASS: all expected functions loaded"
```

## Scalability Considerations

| Concern | At 66 scripts (now) | At 100 scripts | At 200+ scripts |
|---------|---------------------|----------------|-----------------|
| common.sh load time | Negligible (<10ms for 8 source calls) | Same | Same (bash source is fast) |
| Library maintenance | 8 focused files, easy to navigate | Same structure | May need sub-directories in lib/ |
| New feature addition | Add to appropriate lib/*.sh | Same | Same |
| Testing | Smoke test + manual spot checks | Add per-module unit tests | Automated test suite |
| Argument parsing | parse_common_args handles global flags | May need per-tool arg definitions | Consider a tool registration pattern |

## Integration Points with Makefile

The Makefile currently passes TARGET via positional arguments:

```makefile
nmap: ## Run nmap examples
    @bash scripts/nmap/examples.sh $(TARGET)
```

For dual-mode support, the Makefile should also pass environment variables:

```makefile
# Quiet mode via make
nmap-quiet:
    @QUIET=1 bash scripts/nmap/examples.sh $(TARGET)

# Or with logging
nmap-log:
    @LOG_FILE=/tmp/nmap-scan.log bash scripts/nmap/examples.sh $(TARGET)
```

Alternatively, scripts that have been migrated to parse_common_args will accept flags:

```makefile
nmap: ## Run nmap examples
    @bash scripts/nmap/examples.sh $(if $(QUIET),-q) $(TARGET)
```

## Sources

### HIGH Confidence (Established best practices, official documentation)
- [Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) -- set -euo pipefail rationale and pitfalls
- [Greg's Wiki BashFAQ/035](http://mywiki.wooledge.org/BashFAQ/035) -- argument parsing approaches (getopts vs manual)
- [Greg's Wiki SignalTrap](https://mywiki.wooledge.org/SignalTrap) -- trap EXIT vs trapping individual signals
- [Command Line Interface Guidelines](https://clig.dev/) -- CLI UX patterns for quiet/verbose modes, output formatting, error handling
- [Designing Modular Bash](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/) -- function namespacing, source guards, library patterns

### MEDIUM Confidence (Community best practices, multiple sources agree)
- [Safer bash scripts with set -euxo pipefail](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/) -- strict mode patterns
- [Structured Logging in Shell Scripting](https://medium.com/picus-security-engineering/structured-logging-in-shell-scripting-dd657970cd5d) -- bash logging patterns
- [Unix Interface Design Patterns](https://homepage.cs.uri.edu/~thenry/resources/unix_art/ch11s06.html) -- cantrip design, separation of interactive/non-interactive

### Codebase Analysis (Direct observation)
- `scripts/common.sh` (138 lines) -- current shared utility layer
- `scripts/diagnostics/dns.sh`, `connectivity.sh`, `performance.sh` -- Pattern B reference
- `scripts/nmap/examples.sh`, `identify-ports.sh` -- Pattern A reference
- `scripts/check-tools.sh` -- Pattern C reference
- 66 total consumer scripts across 18 tool directories
