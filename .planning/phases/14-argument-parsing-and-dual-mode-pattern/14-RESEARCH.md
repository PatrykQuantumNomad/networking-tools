# Phase 14: Argument Parsing and Dual-Mode Pattern - Research

**Researched:** 2026-02-11
**Domain:** Bash argument parsing, dual-mode CLI execution pattern
**Confidence:** HIGH

## Summary

Phase 14 delivers two new library modules (`lib/args.sh` and enhancements to `lib/output.sh`) that provide `parse_common_args()` and `run_or_show()`. These are purely additive -- no existing script behavior changes until a script explicitly opts in by calling `parse_common_args "$@"`. The arg parser uses a manual `while/case/shift` loop (mandated by ARGS-02) that extracts known flags (`-h`, `-v`, `-q`, `-x`) and passes everything else through to `REMAINING_ARGS`. The dual-mode pattern wraps each command in `run_or_show()` which either prints the command (default) or executes it (`-x` mode).

This phase builds the library functions and proves them with a single pilot migration (nmap/examples.sh). The mass migration of all 17 examples.sh scripts is Phase 15; the 46 use-case scripts are Phase 16. Phase 14 scope is: create the library, prove it works on one script, validate all 5 success criteria.

**Primary recommendation:** Create `scripts/lib/args.sh` with `parse_common_args()`. Add `run_or_show()` and `confirm_execute()` to `scripts/lib/output.sh`. Source `args.sh` from `common.sh`. Pilot on `scripts/nmap/examples.sh` only. Leave all other scripts untouched.

## Standard Stack

### Core

| Library Module | New/Modified | Purpose | Why |
|---------------|-------------|---------|-----|
| `scripts/lib/args.sh` | NEW | `parse_common_args()` function | Central place for common flag handling (ARGS-01) |
| `scripts/lib/output.sh` | MODIFIED | Add `run_or_show()` and `confirm_execute()` | Dual-mode execution mechanism (DUAL-01) |
| `scripts/common.sh` | MODIFIED | Source `args.sh` in module load chain | All scripts get access without changing their source line |
| `scripts/lib/logging.sh` | MODIFIED | Add QUIET behavior (`-q` sets `LOG_LEVEL=warn`) | LOG-05: quiet mode suppresses info but keeps warnings visible |

### No External Dependencies

This phase uses only Bash builtins and existing library modules. No external tools, packages, or downloads.

## Architecture Patterns

### New File: scripts/lib/args.sh

```
scripts/lib/args.sh
  - Source guard (_ARGS_LOADED)
  - Global variable declarations (EXECUTE_MODE, REMAINING_ARGS)
  - parse_common_args() function
```

### Modified File: scripts/lib/output.sh

```
scripts/lib/output.sh (existing)
  + run_or_show() function
  + confirm_execute() function
```

### Modified File: scripts/common.sh

```
scripts/common.sh (existing)
  source lib/strict.sh
  source lib/colors.sh
  source lib/logging.sh
  source lib/validation.sh
  source lib/cleanup.sh
  source lib/output.sh
+ source lib/args.sh       # NEW: after output.sh (uses info/warn/error)
  source lib/diagnostic.sh
  source lib/nc_detect.sh
```

### Pattern 1: parse_common_args() (ARGS-01, ARGS-02, ARGS-03, ARGS-04)

**What:** A shared function that processes command-line arguments, extracting known flags and passing everything else through to `REMAINING_ARGS`.

**Key design decisions (locked by requirements):**
- Manual `while/case/shift` pattern -- NOT getopts/getopt (ARGS-02)
- Unknown flags (`-*`) pass through to REMAINING_ARGS -- NOT rejected (ARGS-03)
- Positional args preserved in REMAINING_ARGS for backward compat (ARGS-04)

```bash
# Source: Greg's Wiki BashFAQ/035 + project requirements
# scripts/lib/args.sh

[[ -n "${_ARGS_LOADED:-}" ]] && return 0
_ARGS_LOADED=1

# Execution mode: "show" (default) or "execute" (-x)
EXECUTE_MODE="${EXECUTE_MODE:-show}"

# Remaining args after common flag extraction
REMAINING_ARGS=()

# Parse common flags from argument list
# Usage: parse_common_args "$@"
# After: positional args are in REMAINING_ARGS array
#
# Expects the calling script to define show_help() before calling.
parse_common_args() {
    REMAINING_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=$((VERBOSE + 1))
                LOG_LEVEL="debug"
                ;;
            -q|--quiet)
                LOG_LEVEL="warn"
                ;;
            -x|--execute)
                EXECUTE_MODE="execute"
                ;;
            --)
                shift
                REMAINING_ARGS+=("$@")
                break
                ;;
            *)
                # Everything else: positional args AND unknown flags
                # This preserves backward compat (ARGS-04) and
                # passes through unknown flags (ARGS-03)
                REMAINING_ARGS+=("$1")
                ;;
        esac
        shift
    done
}
```

**Critical details:**

1. **`-q` sets `LOG_LEVEL=warn` not `LOG_LEVEL=error`**: Setting to `error` would suppress warnings too (safety warnings about unauthorized scanning). Setting to `warn` suppresses info/debug but keeps `warn()` and `error()` visible. The safety_banner should always print regardless of quiet mode since it is a legal notice.

2. **`-v` sets both `VERBOSE` and `LOG_LEVEL`**: This mirrors the existing Phase 13 convention where `VERBOSE >= 1` implies `LOG_LEVEL=debug`. Incrementing VERBOSE also enables timestamps per the existing logging.sh logic.

3. **Unknown flags pass through**: The `*)` catch-all handles BOTH positional arguments (like `scanme.nmap.org`) AND unknown flags (like `--custom-thing`). This means `scripts/nmap/examples.sh -x scanme.nmap.org` puts `-x` in EXECUTE_MODE and `scanme.nmap.org` in REMAINING_ARGS[0].

4. **`--` separator**: Stops flag parsing. Everything after `--` goes to REMAINING_ARGS verbatim. This is the standard POSIX convention.

5. **`show_help` must be defined before calling**: The function calls `show_help` directly. Every script already defines `show_help()` before any argument handling, so this is safe.

### Pattern 2: Script Migration Pattern (Pilot)

**Current pattern (nmap/examples.sh):**
```bash
source "$(dirname "$0")/../common.sh"

show_help() { ... }

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nmap "brew install nmap"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "1) Ping scan -- is the host up?"
echo "   nmap -sn ${TARGET}"
echo ""
```

**Migrated pattern:**
```bash
source "$(dirname "$0")/../common.sh"

show_help() { ... }  # UNCHANGED

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nmap "brew install nmap"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

run_or_show "1) Ping scan -- is the host up?" \
    nmap -sn "$TARGET"
```

**What changes:**
1. `[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0` -- REMOVED (parse_common_args handles -h)
2. `parse_common_args "$@"` + `set -- ...` -- ADDED (replaces inline help check)
3. `confirm_execute "${1:-}"` -- ADDED (before safety_banner, prompts if -x mode)
4. Each `info "N)..." + echo "   cmd" + echo ""` triple -- REPLACED with single `run_or_show` call
5. Interactive demo section at bottom -- may be removed or kept (in -x mode, commands already run)

### Pattern 3: run_or_show() (DUAL-01)

**What:** Shows a command with explanation (default) or executes it (`-x` mode).
**When:** Replaces the 3-line `info + echo + echo` pattern in every educational example.

```bash
# In scripts/lib/output.sh

# Show or execute a command based on EXECUTE_MODE
# Usage: run_or_show "description" command [args...]
run_or_show() {
    local description="$1"
    shift

    if [[ "${EXECUTE_MODE:-show}" == "execute" ]]; then
        info "$description"
        debug "Executing: $*"
        "$@"
    else
        info "$description"
        echo "   $*"
        echo ""
    fi
}
```

**Design notes:**
- In show mode: prints the info line, then the indented command, then blank line -- identical to current output.
- In execute mode: prints the info line, then runs the command. Output appears naturally.
- Uses `"$@"` (not `$*`) to preserve argument quoting when executing.
- The `description` parameter is the existing `info` text like `"1) Ping scan -- is the host up?"`.

### Pattern 4: confirm_execute()

**What:** Confirmation gate before running commands in `-x` mode. Security-critical for pentesting tools.
**When:** Called once at the start of the script, after `parse_common_args`, before the examples section.

```bash
# In scripts/lib/output.sh

# Prompt for confirmation in execute mode
# Usage: confirm_execute [target]
confirm_execute() {
    local target="${1:-}"
    [[ "${EXECUTE_MODE:-show}" != "execute" ]] && return 0

    # Skip confirmation if non-interactive (piped input)
    if [[ ! -t 0 ]]; then
        warn "Execute mode requires interactive terminal for confirmation"
        exit 1
    fi

    warn "Execute mode: commands will be run against ${target:-the target}"
    read -rp "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
}
```

**Design notes:**
- Returns immediately in show mode (default) -- zero impact on existing behavior.
- Requires interactive terminal in execute mode (no silent execution via pipes).
- Uses `warn` not `error` -- this is informational, not an error condition.
- Placed after `parse_common_args` but before `safety_banner` in the script flow.

### Pattern 5: set -- with Empty Array Safety

**The problem:** Under `set -u` (which is active via strict.sh), `"${REMAINING_ARGS[@]}"` throws "unbound variable" on Bash 4.0-4.3 when the array is empty.

**The solution:** Use the `${array[@]+...}` expansion pattern:
```bash
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"
```

This expands to nothing when `REMAINING_ARGS` is empty (Bash 4.0-4.3 safe) and to the array contents otherwise. On Bash 4.4+, this is unnecessary but harmless.

**Why not just use `${REMAINING_ARGS[@]:-}`:** The `:-` default substitution on arrays does not behave correctly -- it treats the entire array expansion as a single string. The `+` pattern (if-set-then-expand) is the correct idiom.

### Anti-Patterns to Avoid

- **Splitting `parse_common_args` into multiple passes:** Do NOT parse flags separately from positional args. One pass through `$@` handles everything. Multiple passes break ordering assumptions.
- **Rejecting unknown flags:** Do NOT `error "Unknown option: $1"` + `exit 1`. This breaks per-script extensibility (ARGS-03 requires pass-through).
- **Changing LOG_LEVEL to "error" for quiet mode:** Use "warn" instead. `LOG_LEVEL=error` would suppress safety warnings and `warn()` messages, which are important for pentesting tools.
- **Adding `parse_common_args` calls to all scripts in this phase:** This phase only adds the library functions and migrates ONE pilot script (nmap/examples.sh). Mass migration is Phase 15/16.
- **Modifying the existing `show_help()` functions:** The help text format is a per-script concern. `parse_common_args` just calls it and exits.
- **Making run_or_show handle the `info + echo + echo` triple differently than current:** The default (show) mode output MUST be byte-identical to the current output. This means `run_or_show "1) Ping scan" nmap -sn "$TARGET"` must produce exactly the same text as the current 3-line pattern.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Long option parsing | getopts wrapper with long option hacks | Manual while/case/shift | getopts has no long options; getopt is not portable on macOS (ARGS-02) |
| Argument validation | Custom type-checking framework | Per-script validation after parse_common_args | Each script knows what its arguments mean; generic validation adds complexity |
| Flag ordering | Pre-sort or multi-pass algorithm | Single while loop that handles everything | Single pass is simple, correct, and handles any ordering naturally |
| Help text formatting | Template system or auto-generated help | Script-specific `show_help()` functions | All 67 scripts already have well-crafted show_help(); preserve them |

**Key insight:** The argument parser should do as little as possible. It extracts 4 known flags and passes everything else through. The simplicity is the feature.

## Common Pitfalls

### Pitfall 1: set -u with Empty REMAINING_ARGS Array

**What goes wrong:** `set -- "${REMAINING_ARGS[@]}"` fails with "unbound variable" on Bash 4.0-4.3 when no arguments are passed.
**Why it happens:** Bash < 4.4 treats empty array expansion as accessing an unset variable under `set -u`.
**How to avoid:** Always use `${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}` pattern when expanding the array. The project requires Bash 4.0+ (not 4.4+), so this is a real concern.
**Warning signs:** Scripts that take no arguments (like `hashcat/benchmark-gpu.sh`) will fail if called with zero args.

### Pitfall 2: shift Past End of Arguments

**What goes wrong:** Under `set -e`, `shift` when `$# == 0` causes a non-zero exit and script termination.
**Why it happens:** The `while [[ $# -gt 0 ]]` guard prevents this in the main loop, but the `--` handler does an extra `shift` before `break`.
**How to avoid:** The `--` case must `shift; break` which is safe because `--` itself is in `$@`, so `$#` is at least 1 when we reach it.
**Warning signs:** Tests passing `--` as the only argument.

### Pitfall 3: Backward Compatibility with `$1` Target Pattern

**What goes wrong:** After `parse_common_args "$@"` + `set -- "${REMAINING_ARGS[@]+...}"`, the script's `$1` now comes from REMAINING_ARGS, not the original `$@`. If the parser ate a positional arg by mistake, `$1` is wrong.
**Why it happens:** The `*)` catch-all in the parser MUST capture all non-flag arguments including the target.
**How to avoid:** The parser treats everything that does not match a known flag as a positional argument. `scripts/nmap/examples.sh scanme.nmap.org` puts `scanme.nmap.org` in REMAINING_ARGS[0], which becomes `$1` after `set --`.
**Warning signs:** `make nmap TARGET=scanme.nmap.org` stops working. Test this explicitly as success criterion 4.

### Pitfall 4: Flag Order Independence

**What goes wrong:** User passes `scripts/nmap/examples.sh scanme.nmap.org -x` (target before flag). If the parser stops at first positional arg, `-x` is never seen.
**Why it happens:** Some parsers use `*) break` which stops at the first non-flag argument.
**How to avoid:** The `*)` catch-all APPENDS to REMAINING_ARGS and CONTINUES the loop (does not break). This means flags can appear anywhere in the argument list: before, after, or between positional args.
**Warning signs:** `-x` only works when placed before the target, not after.

### Pitfall 5: run_or_show Output Fidelity in Show Mode

**What goes wrong:** The show-mode output of `run_or_show` does not exactly match the current 3-line pattern, breaking visual compatibility.
**Why it happens:** Subtle differences in indentation, quoting, or variable expansion. For example, `echo "   nmap -sn ${TARGET}"` (current) shows the expanded variable, while `echo "   $*"` in run_or_show also shows expanded args -- but quoting may differ.
**How to avoid:** Ensure `run_or_show` prints `"   $*"` which produces space-separated args with variables already expanded (since the function receives expanded args). Verify output is byte-identical using diff.
**Warning signs:** Diff between old and new output shows whitespace or quoting differences.

### Pitfall 6: Commands with Pipes, Redirections, or Subshells in run_or_show

**What goes wrong:** `run_or_show "desc" nmap -sV "$TARGET" | grep open` does not work because `|` is shell syntax, not an argument.
**Why it happens:** `"$@"` executes a simple command, not a shell pipeline.
**How to avoid:** For the pilot (nmap/examples.sh), most examples are simple commands. For commands with pipes, there are two options: (a) wrap in a function, (b) use `bash -c "..."`. However, for the educational show mode, the current scripts already just echo the full command string. The run_or_show pattern works perfectly for simple commands. Complex commands that need pipes/redirections should remain as show-only or use a wrapper function in execute mode.
**Warning signs:** Examples 9 and 10 in some scripts have complex multi-tool pipelines.

### Pitfall 7: safety_banner Must Not Be Suppressed by Quiet Mode

**What goes wrong:** `-q` mode suppresses `safety_banner` output, removing the legal authorization warning.
**Why it happens:** If quiet mode gates `safety_banner` via `info()` calls.
**How to avoid:** `safety_banner()` uses direct `echo -e` calls (not `info()`), so it is NOT affected by LOG_LEVEL filtering. It will always print. This is correct behavior -- the authorization warning is a legal notice, not an info message.
**Warning signs:** Running `scripts/nmap/examples.sh -q scanme.nmap.org` and not seeing the red "AUTHORIZED USE ONLY" banner.

### Pitfall 8: VERBOSE Interaction with parse_common_args Timing

**What goes wrong:** `VERBOSE` is set in `logging.sh` at source time, and `parse_common_args` sets it later. But `logging.sh` already checked `VERBOSE` to set `LOG_LEVEL`.
**Why it happens:** The `if ((VERBOSE >= 1)); then LOG_LEVEL="debug"; fi` check in logging.sh runs at source time. If `-v` is passed later via parse_common_args, the LOG_LEVEL update needs to happen again.
**How to avoid:** In `parse_common_args`, when handling `-v`, explicitly set BOTH `VERBOSE` and `LOG_LEVEL="debug"`. This is already shown in the pattern above. The source-time check in logging.sh handles the `VERBOSE=1` environment variable case; the parse_common_args handles the `-v` flag case.
**Warning signs:** `scripts/nmap/examples.sh -v scanme.nmap.org` not showing debug output.

## Code Examples

### Complete args.sh Module

```bash
#!/usr/bin/env bash
# args.sh -- Argument parsing helpers
# Provides parse_common_args() for consistent flag handling across all scripts.

# Source guard
[[ -n "${_ARGS_LOADED:-}" ]] && return 0
_ARGS_LOADED=1

# Execution mode: "show" (default) or "execute" (-x/--execute)
EXECUTE_MODE="${EXECUTE_MODE:-show}"

# Remaining arguments after common flags are extracted
REMAINING_ARGS=()

# Parse common flags shared by all scripts
# Usage: parse_common_args "$@"
# After: access remaining args via REMAINING_ARGS array
#
# Handles: -h/--help, -v/--verbose, -q/--quiet, -x/--execute, --
# Everything else (positional args + unknown flags) -> REMAINING_ARGS
#
# Requires: show_help() to be defined by the calling script
parse_common_args() {
    REMAINING_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=$((VERBOSE + 1))
                LOG_LEVEL="debug"
                ;;
            -q|--quiet)
                LOG_LEVEL="warn"
                ;;
            -x|--execute)
                EXECUTE_MODE="execute"
                ;;
            --)
                shift
                REMAINING_ARGS+=("$@")
                break
                ;;
            *)
                REMAINING_ARGS+=("$1")
                ;;
        esac
        shift
    done
}
```

### Complete run_or_show and confirm_execute (additions to output.sh)

```bash
# Run a command or display it, depending on EXECUTE_MODE
# In "show" mode (default): prints description + indented command
# In "execute" mode (-x): prints description + runs the command
#
# Usage: run_or_show "N) Description" command [args...]
run_or_show() {
    local description="$1"
    shift

    if [[ "${EXECUTE_MODE:-show}" == "execute" ]]; then
        info "$description"
        debug "Executing: $*"
        "$@"
        echo ""
    else
        info "$description"
        echo "   $*"
        echo ""
    fi
}

# Prompt for confirmation before executing commands in -x mode
# No-op in show mode (default). Exits if user declines.
# Refuses to execute if stdin is not a terminal (piped/automated).
#
# Usage: confirm_execute [target]
confirm_execute() {
    local target="${1:-}"
    [[ "${EXECUTE_MODE:-show}" != "execute" ]] && return 0

    if [[ ! -t 0 ]]; then
        warn "Execute mode requires an interactive terminal for confirmation"
        exit 1
    fi

    echo ""
    warn "Execute mode: commands will run against ${target:-the target}"
    read -rp "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
}
```

### Pilot Migration: nmap/examples.sh (Before/After)

**Before (current):**
```bash
[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd nmap "brew install nmap"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "1) Ping scan -- is the host up?"
echo "   nmap -sn ${TARGET}"
echo ""

# ... 9 more examples ...

[[ ! -t 0 ]] && exit 0
read -rp "Run a quick ping scan on ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: nmap -sn ${TARGET}"
    nmap -sn "$TARGET"
fi
```

**After (migrated):**
```bash
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nmap "brew install nmap"
require_target "${1:-}"

confirm_execute "${1:-}"
safety_banner

TARGET="$1"

info "=== Nmap Examples ==="
info "Target: ${TARGET}"
echo ""

run_or_show "1) Ping scan -- is the host up?" \
    nmap -sn "$TARGET"

# ... 9 more examples with run_or_show ...

# Interactive demo -- only in show mode (in execute mode, commands already ran)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "Run a quick ping scan on ${TARGET} now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: nmap -sn ${TARGET}"
        nmap -sn "$TARGET"
    fi
fi
```

### Handling Commands That Need sudo

Some nmap examples require `sudo`:
```bash
# Current:
info "4) OS detection (requires sudo)"
echo "   sudo nmap -O ${TARGET}"

# Migrated:
run_or_show "4) OS detection (requires sudo)" \
    sudo nmap -O "$TARGET"
```

In show mode, this prints `sudo nmap -O scanme.nmap.org`. In execute mode, it runs `sudo nmap -O scanme.nmap.org` which will prompt for the sudo password naturally.

### Handling Complex Commands (Show-Only)

Some examples have pipes or complex syntax that cannot be a simple command:
```bash
# Current:
info "9) Scan a subnet"
echo "   nmap -sn 192.168.1.0/24"

# This is a static example (hardcoded subnet, not $TARGET)
# Keep as info + echo in the migrated version:
info "9) Scan a subnet"
echo "   nmap -sn 192.168.1.0/24"
echo ""
```

For the nmap/examples.sh pilot, examples 1-8 and 10 use `$TARGET` and can use `run_or_show`. Example 9 uses a hardcoded subnet and should remain as a static display.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `[[ "${1:-}" =~ ^(-h\|--help)$ ]]` inline per-script | `parse_common_args "$@"` centralized | Phase 14 (this phase) | All flags handled in one place |
| `info + echo + echo` 3-line pattern | `run_or_show` 1-line call | Phase 14 (this phase) | Enables dual-mode execution |
| Interactive demo as only execution path | `-x` flag as explicit execution mode | Phase 14 (this phase) | Scriptable execution without interactive prompts |

**No deprecated approaches:** This is a new capability. The old inline help check is not deprecated -- it just gets replaced by the more capable centralized parser during migration.

## Verification Strategy

### Success Criterion 1: --help and -h print usage

```bash
bash scripts/nmap/examples.sh --help 2>&1 | head -1
# Expected: "Usage: examples.sh <target>" (show_help output)

bash scripts/nmap/examples.sh -h 2>&1 | head -1
# Expected: same as above
```

### Success Criterion 2: Backward compatible default mode

```bash
# Capture before migration
bash scripts/nmap/examples.sh scanme.nmap.org 2>/dev/null > /tmp/before.txt

# Capture after migration (no -x flag)
bash scripts/nmap/examples.sh scanme.nmap.org 2>/dev/null > /tmp/after.txt

diff /tmp/before.txt /tmp/after.txt
# Expected: no differences (or minimal, documented differences)
```

### Success Criterion 3: -x mode prompts then executes

```bash
# Must be interactive terminal
bash scripts/nmap/examples.sh -x scanme.nmap.org
# Expected: "Execute mode: commands will run against scanme.nmap.org"
# Expected: "Continue? [y/N]" prompt
# On 'y': runs nmap commands
# On 'n': exits cleanly
```

### Success Criterion 4: make nmap TARGET=... still works

```bash
make nmap TARGET=scanme.nmap.org
# Expected: identical to pre-migration behavior (Makefile passes TARGET as $1)
```

### Success Criterion 5: Unknown flags pass through

```bash
bash scripts/nmap/examples.sh --custom-thing scanme.nmap.org
# Expected: no error from argument parser
# The script sees "scanme.nmap.org" in $1 (--custom-thing is in REMAINING_ARGS too)
```

Wait -- this needs careful consideration. If `--custom-thing` is in REMAINING_ARGS[0] and `scanme.nmap.org` is in REMAINING_ARGS[1], then `$1` after `set --` would be `--custom-thing`, not the target. This is correct behavior for ARGS-03 (pass through) but means `require_target "${1:-}"` would get `--custom-thing` as the "target". This is acceptable because:
1. The user is passing a flag the script does not know about.
2. The script treats it as a positional arg (which it is, syntactically).
3. The tool (nmap) will error on `--custom-thing` naturally.

The success criterion is about the arg parser not crashing, not about the downstream tool accepting the value.

## Module Load Order

The new `args.sh` module must be sourced AFTER `logging.sh` (because `parse_common_args` references `VERBOSE` and `LOG_LEVEL`) and AFTER `output.sh` (because scripts may call `confirm_execute` which uses `warn`). It should be sourced BEFORE `diagnostic.sh` and `nc_detect.sh` (which are leaf modules).

Recommended insertion point in common.sh:
```bash
source "${_LIB_DIR}/strict.sh"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logging.sh"
source "${_LIB_DIR}/validation.sh"
source "${_LIB_DIR}/cleanup.sh"
source "${_LIB_DIR}/output.sh"
source "${_LIB_DIR}/args.sh"        # NEW
source "${_LIB_DIR}/diagnostic.sh"
source "${_LIB_DIR}/nc_detect.sh"
```

## Scope Boundary

### In Scope (Phase 14)
- Create `scripts/lib/args.sh` with `parse_common_args()`
- Add `run_or_show()` and `confirm_execute()` to `scripts/lib/output.sh`
- Source `args.sh` from `scripts/common.sh`
- Migrate `scripts/nmap/examples.sh` as pilot (one script only)
- Verify all 5 success criteria against the pilot script

### Out of Scope (Phase 15-16)
- Migrating the other 16 examples.sh scripts (Phase 15)
- Migrating the 46 use-case scripts (Phase 16)
- Migrating the 3 diagnostic scripts (they already execute, no dual-mode needed)
- Adding new flags beyond -h/-v/-q/-x
- JSON output mode (deferred to v2+)
- Execution timer (deferred to v2+)

## Open Questions

1. **Should the interactive demo section be removed for -x migrated scripts?**
   - What we know: In execute mode, all 10 examples run via run_or_show. The interactive demo at the bottom would be redundant.
   - What's unclear: Should the demo section remain for show mode (backward compat) or be removed entirely?
   - Recommendation: Keep the demo section but guard it with `[[ "${EXECUTE_MODE:-show}" == "show" ]]`. In execute mode, skip it since commands already ran. This preserves exact backward compatibility in show mode.

2. **How should run_or_show handle commands that require sudo?**
   - What we know: Some examples prefix with `sudo`. In execute mode, `"$@"` would run `sudo nmap ...` which prompts for password.
   - What's unclear: Should there be a special sudo handling path?
   - Recommendation: No special handling needed. Let sudo prompt naturally. Users running `-x` mode on security tools expect sudo prompts. The confirmation gate already warns them.

3. **Should `parse_common_args` modify `$@` directly or use REMAINING_ARGS?**
   - What we know: Bash functions cannot modify the caller's `$@`. The caller must do `set -- "${REMAINING_ARGS[@]+...}"`.
   - What's unclear: Is the 2-line dance (`parse_common_args "$@"` + `set -- ...`) too verbose?
   - Recommendation: Keep the 2-line pattern. It is explicit, easy to understand, and matches established bash conventions. A wrapper that tries to hide this would be fragile.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: direct reading of all 67 scripts, 8 lib modules, Makefile, and common.sh
- Phase 13 library modules: `scripts/lib/logging.sh`, `scripts/lib/output.sh`, `scripts/lib/strict.sh`
- Prior research: `.planning/research/STACK.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/FEATURES.md`, `.planning/research/SUMMARY.md`
- Phase 13 research: `.planning/phases/13-library-infrastructure/13-RESEARCH.md`
- Greg's Wiki BashFAQ/035 (argument parsing): https://mywiki.wooledge.org/BashFAQ/035
- Greg's Wiki BashFAQ/112 (empty arrays and set -u): https://mywiki.wooledge.org/BashFAQ/112

### Secondary (MEDIUM confidence)
- CLI Guidelines (clig.dev): https://clig.dev/ -- conventions for -q, -v, --help
- NO_COLOR convention: https://no-color.org/

### Tertiary (LOW confidence)
- None. All findings verified against codebase and authoritative sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- purely bash builtins, no external dependencies
- Architecture: HIGH -- pattern verified against Greg's Wiki and proven in prior project research
- Pitfalls: HIGH -- identified through codebase analysis (set -u interaction, empty array, shift behavior)
- Pilot migration: HIGH -- nmap/examples.sh is the simplest example to migrate, well-understood structure

**Research date:** 2026-02-11
**Valid until:** Indefinite (bash argument parsing patterns are stable)
