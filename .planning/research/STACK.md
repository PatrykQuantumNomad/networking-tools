# Technology Stack: Bash Script Hardening & Dual-Mode CLI

**Project:** networking-tools -- production-grade script infrastructure
**Researched:** 2026-02-11
**Scope:** Strict mode framework, structured logging, argument parsing, dual-mode execution, shellcheck compliance, retry logic
**Constraint:** Pure bash (no external frameworks). Bash 4.0+ minimum. macOS primary, Linux compatible.

## Existing Stack (Validated, DO NOT Re-research)

| Technology | Version | Status |
|------------|---------|--------|
| Bash | 4.0+ target (5.3.9 on dev macOS via Homebrew) | `#!/usr/bin/env bash` picks up Homebrew bash |
| common.sh | Custom shared library | info/warn/error, require_cmd, safety_banner, check_cmd, run_check |
| GNU Make | System | Makefile orchestration for 65+ scripts |
| Docker Compose | v2 | Lab target orchestration |

**macOS bash reality:** System `/bin/bash` is 3.2.57 (GPLv2 -- Apple refuses to ship GPLv3). Homebrew bash is 5.3.9. The `#!/usr/bin/env bash` shebang resolves to whichever is first in `$PATH`. The codebase already uses `declare -A` (associative arrays, Bash 4.0+), confirming a Bash 4.0+ minimum requirement is already in effect.

## Recommended Stack Additions

### Zero External Dependencies

Everything below is implemented as pure bash functions added to `common.sh` or new library files sourced from it. No external tools required beyond `shellcheck` for linting.

| Capability | Implementation | Why Pure Bash |
|------------|----------------|---------------|
| Strict mode framework | `scripts/lib/strict.sh` | Must be sourced before any logic runs; external tools add latency |
| Structured logging | Upgrade existing `info/warn/error` in `common.sh` | Already exists; upgrade in-place preserves backward compatibility |
| Argument parsing | `scripts/lib/args.sh` | Manual `while/case` loop; no dependency on GNU `getopt` |
| Retry with backoff | `retry_with_backoff()` in `common.sh` | Network tools need this; 15-line function, no external tool justified |
| Dual-mode execution | `run_or_show()` wrapper in `common.sh` | Core architectural pattern; must be tightly integrated |
| Temp file cleanup | `trap` + `mktemp` pattern in `strict.sh` | Standard POSIX, no tools needed |

### Development Tool: ShellCheck

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| ShellCheck | 0.11.0 (latest, 2026-01-05) | Static analysis for all scripts | `brew install shellcheck` |

**Why ShellCheck and not alternatives:** ShellCheck is the only widely-adopted bash-specific linter. It catches real bugs (SC2155: masked return values, SC2086: word splitting). Alternatives like `bashate` only check style, not correctness. ShellCheck 0.11.0 supports Bash 5.3 features and `.shellcheckrc` project-level config.

**Confidence: HIGH** -- verified ShellCheck 0.11.0 release date and features via official GitHub releases page.

---

## 1. Strict Mode Framework

### Recommended: Enhanced `set -eEuo pipefail` with ERR Trap

Use `set -eEuo pipefail` (not just `set -euo pipefail`) because the `-E` flag ensures ERR traps are inherited by shell functions, command substitutions, and subshells. Without `-E`, a function that triggers `set -e` will exit silently with no error context.

```bash
# scripts/lib/strict.sh -- Source at the top of every script
set -eEuo pipefail

# Trap ERR for stack trace on failure
_strict_error_handler() {
    local exit_code=$?
    local line_no="${BASH_LINENO[0]}"
    local command="${BASH_COMMAND}"
    error "Command failed (exit $exit_code) at line $line_no: $command"
    # Print call stack (skip the trap handler itself)
    local i
    for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
        error "  at ${FUNCNAME[$i]}() in ${BASH_SOURCE[$i]}:${BASH_LINENO[$((i-1))]}"
    done
}
trap '_strict_error_handler' ERR

# Trap EXIT for cleanup
_strict_cleanup() {
    local exit_code=$?
    # Clean up temp files if the temp dir was created
    if [[ -n "${_TMPDIR:-}" && -d "${_TMPDIR:-}" ]]; then
        rm -rf "$_TMPDIR"
    fi
    exit "$exit_code"
}
trap '_strict_cleanup' EXIT
```

### Why NOT `IFS=$'\n\t'`

The "unofficial strict mode" recommends `IFS=$'\n\t'`. **Do not use this.** Reason: The existing codebase passes space-separated arguments throughout (e.g., `nmap -sV --top-ports 100 "$TARGET"`). Changing IFS globally would break all command construction that relies on default word splitting. The default IFS (space/tab/newline) is correct for this codebase.

### Known `set -e` Pitfalls and Workarounds

`set -e` has well-documented failure modes. Each one applies to this codebase and has a specific workaround:

| Pitfall | Example in This Codebase | Workaround |
|---------|-------------------------|------------|
| `local var=$(cmd)` masks exit status | `local version=$(get_version "$tool")` | Split: `local version; version=$(get_version "$tool")` |
| Arithmetic with zero returns false | `((installed++))` when installed=0 | Already handled: `((installed++)) \|\| true` (exists in check-tools.sh) |
| Functions in conditionals disable errexit | `if some_function; then` | Acceptable -- the conditional is intentional |
| Pipes ignore non-final failures | `cmd \| grep pattern` | `set -o pipefail` handles this (already set) |
| Command substitution ignores errexit | `result=$(failing_cmd)` inside `$()` | Use `shopt -s inherit_errexit` (Bash 4.4+) |

### `shopt -s inherit_errexit`

Available since Bash 4.4. Makes `set -e` apply inside command substitutions (`$()`). Without it, a failing command inside `$()` does not trigger the ERR trap. Since the minimum Bash version is 4.0+, gate this:

```bash
# Enable if available (Bash 4.4+)
if [[ "${BASH_VERSINFO[0]}" -ge 5 ]] || \
   [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 4 ]]; then
    shopt -s inherit_errexit
fi
```

**Confidence: HIGH** -- `set -e` pitfalls verified against Greg's Wiki BashFAQ/105, the canonical reference for bash error handling.

---

## 2. Structured Logging

### Recommended: Upgrade Existing `info/warn/error` In-Place

Do NOT add a JSON logging library. The scripts are CLI tools for human operators, not services feeding log aggregators. Structured logging here means: consistent format, severity levels, timestamps when verbose, color control, stderr routing.

### Upgrade Path for `common.sh`

```bash
# --- Logging Configuration ---
LOG_LEVEL="${LOG_LEVEL:-info}"  # debug, info, warn, error
NO_COLOR="${NO_COLOR:-}"        # Respect https://no-color.org standard
VERBOSE="${VERBOSE:-0}"

# Detect if output should be colored
_use_color() {
    [[ -z "${NO_COLOR:-}" ]] && [[ -t 2 ]]  # Color only if NO_COLOR unset AND stderr is a terminal
}

# Severity ordering for level filtering
_log_level_num() {
    case "$1" in
        debug) echo 0 ;; info) echo 1 ;; warn) echo 2 ;; error) echo 3 ;;
        *) echo 1 ;;
    esac
}

# Core log function
_log() {
    local level="$1"; shift
    local current; current=$(_log_level_num "$LOG_LEVEL")
    local this; this=$(_log_level_num "$level")
    [[ "$this" -lt "$current" ]] && return 0

    local prefix timestamp=""
    [[ "$VERBOSE" -ge 1 ]] && timestamp="$(date '+%H:%M:%S') "

    if _use_color; then
        case "$level" in
            debug) prefix="${CYAN}[DEBUG]${NC}" ;;
            info)  prefix="${BLUE}[INFO]${NC}" ;;
            warn)  prefix="${YELLOW}[WARN]${NC}" ;;
            error) prefix="${RED}[ERROR]${NC}" ;;
        esac
    else
        prefix="[${level^^}]"
    fi

    echo -e "${timestamp}${prefix} $*" >&2
}

# Public API (backward compatible -- same function names)
debug()   { _log debug "$@"; }
info()    { _log info "$@"; }
warn()    { _log warn "$@"; }
error()   { _log error "$@"; }
success() {
    if _use_color; then
        echo -e "${GREEN}[OK]${NC} $*" >&2
    else
        echo -e "[OK] $*" >&2
    fi
}
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Log to stderr, not stdout | Scripts produce structured output (examples, reports) on stdout. Logging must not pollute it. Current `error()` already uses `>&2`; extend to all levels. |
| NO_COLOR standard | Widely adopted convention (no-color.org). Detect terminal via `[[ -t 2 ]]` for stderr. |
| Level filtering via `LOG_LEVEL` env var | `LOG_LEVEL=debug ./script.sh` enables debug output without modifying scripts. |
| Timestamps only in verbose mode | Educational scripts should stay clean. `VERBOSE=1` adds timestamps for troubleshooting. |
| No JSON output for logs | These are interactive CLI tools. JSON logging adds complexity for zero benefit here. |

### Backward Compatibility

The existing `info()`, `warn()`, `error()`, `success()` function signatures are preserved exactly. All 65+ scripts continue working without modification. The upgrade is purely additive: new `debug()` function, level filtering, color control.

**Confidence: HIGH** -- NO_COLOR standard verified at no-color.org. Pattern is standard POSIX with no bash version dependencies.

---

## 3. Argument Parsing

### Recommended: Manual `while/case` Loop (NOT getopts, NOT getopt)

**Why not `getopts` (bash builtin):** No long option support. `--verbose`, `--mode`, `--output` require long options for a good CLI UX. `getopts` only handles `-v`, `-m`, `-o`.

**Why not `getopt` (external command):** macOS ships BSD `getopt`, which is broken (cannot handle spaces in arguments, no long options). GNU `getopt` requires `brew install gnu-getopt` and PATH manipulation. Adding a required Homebrew dependency for argument parsing is unacceptable for a project that targets fresh macOS installs.

**Why manual `while/case`:** Portable across all bash versions. Supports both short and long options. No dependencies. Recommended by Greg's Wiki (the canonical bash resource, BashFAQ/035). Pattern is well-understood and shellcheck-clean.

### Standard Pattern for This Codebase

```bash
# scripts/lib/args.sh -- Argument parsing helpers

# Parse standard flags that every script supports
# Call as: parse_common_args "$@"; set -- "${REMAINING_ARGS[@]}"
parse_common_args() {
    REMAINING_ARGS=()
    MODE="${MODE:-examples}"    # Default mode: show examples
    VERBOSE="${VERBOSE:-0}"
    OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -x|--execute)
                MODE="execute"
                ;;
            -v|--verbose)
                VERBOSE=$((VERBOSE + 1))
                ;;
            -q|--quiet)
                LOG_LEVEL="error"
                ;;
            --output)
                if [[ -n "${2:-}" ]]; then
                    OUTPUT_FORMAT="$2"
                    shift
                else
                    error "'--output' requires a value (text, json)"
                    exit 1
                fi
                ;;
            --output=*)
                OUTPUT_FORMAT="${1#*=}"
                ;;
            --)
                shift
                REMAINING_ARGS+=("$@")
                break
                ;;
            -*)
                error "Unknown option: $1"
                error "Run with --help for usage information."
                exit 1
                ;;
            *)
                REMAINING_ARGS+=("$1")
                ;;
        esac
        shift
    done
}
```

### Why This Pattern Works for This Codebase

1. **Incremental adoption:** Scripts opt-in by sourcing `args.sh` and calling `parse_common_args`. Existing scripts that only use `-h|--help` continue working with their current inline check.
2. **Consistent flags across all tools:** `-x` for execute, `-v` for verbose, `-q` for quiet. Users learn once.
3. **Positional args preserved:** `REMAINING_ARGS` holds the target IP/URL/file after flags are consumed. Backward compatible with `$1` target pattern.

**Confidence: HIGH** -- Pattern verified against Greg's Wiki BashFAQ/035, the authoritative reference. Tested on both macOS BSD `getopt` limitation confirmed via multiple sources.

---

## 4. Dual-Mode Execution

### Recommended: `run_or_show()` Wrapper Function

The core design pattern for transforming educational scripts into dual-mode CLI tools. In "examples" mode (default), commands are printed with explanations. In "execute" mode (`-x`), commands actually run.

```bash
# In common.sh

# Run a command or show it, depending on MODE
# Usage: run_or_show "description" command arg1 arg2 ...
run_or_show() {
    local description="$1"
    shift

    info "$description"
    if [[ "${MODE:-examples}" == "execute" ]]; then
        debug "Executing: $*"
        "$@"
    else
        # Show mode: print the command that would run
        echo "   $*"
        echo ""
    fi
}
```

### Integration with Existing Script Patterns

Current Pattern A script (examples.sh):
```bash
info "1) Ping scan -- is the host up?"
echo "   nmap -sn ${TARGET}"
echo ""
```

Upgraded to dual-mode:
```bash
run_or_show "1) Ping scan -- is the host up?" nmap -sn "$TARGET"
```

**Key benefit:** The upgrade is a 1-line change per example. The existing educational output is preserved in the default mode. Execute mode is opt-in via `-x`.

### Pattern Variations

| Script Type | Default Mode | Execute Mode Behavior |
|------------|-------------|----------------------|
| Pattern A (examples.sh) | Show numbered examples with explanations | Run each command sequentially (with confirmation gate) |
| Pattern B (use-case scripts) | Show commands that would run | Execute the specific use-case workflow |
| Pattern C (diagnostics) | Already executes and reports | No change needed -- diagnostics always execute |

### Confirmation Gate for Execute Mode

For Pattern A scripts (which show 10 examples), executing all 10 commands blindly is dangerous. Add a confirmation gate:

```bash
# Only in examples.sh scripts, not in use-case scripts
if [[ "${MODE:-examples}" == "execute" ]]; then
    warn "Execute mode will run commands against ${TARGET}"
    safety_banner
    read -rp "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi
```

**Confidence: HIGH** -- Pattern is a standard bash idiom. No version dependencies.

---

## 5. Retry with Backoff

### Recommended: Simple Exponential Backoff Function

Network tools frequently hit transient failures (DNS timeouts, rate limiting, connection resets). A retry wrapper prevents scripts from failing on first transient error.

```bash
# In common.sh

# Retry a command with exponential backoff
# Usage: retry_with_backoff <max_attempts> <initial_delay_sec> command [args...]
# Example: retry_with_backoff 3 1 curl -s "http://example.com"
retry_with_backoff() {
    local max_attempts="$1"
    local delay="$2"
    shift 2

    local attempt=1
    while true; do
        if "$@"; then
            return 0
        fi

        if [[ "$attempt" -ge "$max_attempts" ]]; then
            error "Command failed after $max_attempts attempts: $*"
            return 1
        fi

        warn "Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..."
        sleep "$delay"
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
}
```

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| Exponential backoff (delay * 2) | Standard pattern. Prevents hammering a failing target. |
| No jitter | Overkill for single-user CLI tools. Jitter matters for distributed systems hitting shared APIs. |
| Max 3 attempts default | Network tools should fail fast. 3 retries with 1/2/4 second delays = 7 seconds total. |
| Function wraps any command | `retry_with_backoff 3 1 dig +short example.com A` works. |

**Confidence: HIGH** -- Exponential backoff is a universally standard pattern. Implementation verified against multiple sources.

---

## 6. ShellCheck Compliance

### Recommended: `.shellcheckrc` Project Config + Targeted Inline Disables

```bash
# .shellcheckrc (project root)
# ShellCheck project-level configuration
# Resolved via directory walk: script dir -> parent -> ... -> project root

# Tell shellcheck where to find sourced files
source-path=SCRIPTDIR
source-path=SCRIPTDIR/..
source-path=SCRIPTDIR/../lib

# Allow sourcing paths determined at runtime
external-sources=true
```

### Common SC Warnings in This Codebase and Fixes

| SC Code | Description | Occurrences in Codebase | Fix |
|---------|-------------|------------------------|-----|
| SC2155 | `local var=$(cmd)` masks return value | Every `local result=$(dig ...)` pattern | Split: `local result; result=$(dig ...)` |
| SC2086 | Unquoted variable | `echo $output` patterns | Quote: `echo "$output"` |
| SC2034 | Variable appears unused | Colors (RED, GREEN, etc.) defined in common.sh, used in sourcing scripts | Add `export` or `# shellcheck disable=SC2034` in common.sh |
| SC1091 | Source file not found | `source "$(dirname "$0")/../common.sh"` | `.shellcheckrc` with `source-path=SCRIPTDIR` and `external-sources=true` |
| SC2015 | `A && B \|\| C` is not if-then-else | `[[ -t 0 ]] && cmd \|\| true` | Rewrite as proper `if/then/else` or add `# shellcheck disable=SC2015` |

### Shellcheck-Safe Patterns for Known Problem Areas

**Arithmetic increment at zero:**
```bash
# BAD: ((count++)) exits with status 1 when count=0 under set -e
# GOOD: Two options
((count++)) || true            # Already used in check-tools.sh
count=$((count + 1))           # Alternative: always succeeds
```

**Read with prompt:**
```bash
# BAD: shellcheck warns about read without -r
# GOOD: Already using -rp throughout (verified)
read -rp "Continue? [y/N] " answer
```

**Piped grep that may find nothing:**
```bash
# BAD: grep returns exit 1 when no match, triggers set -e
result=$(echo "$output" | grep "pattern")  # Exits script if no match!
# GOOD: Use || true guard
result=$(echo "$output" | grep "pattern" || true)
```

**Command that may fail in non-error case:**
```bash
# BAD: nc -h exits non-zero on some variants
nc -h 2>&1 | head -1
# GOOD: Already handled with || true (check-tools.sh line 71)
nc -h 2>&1 | head -1 || true
```

### CI Integration

```yaml
# .github/workflows/shellcheck.yml
- name: ShellCheck
  run: |
    shellcheck --severity=warning scripts/**/*.sh scripts/common.sh
```

Start with `--severity=warning` (skip style/info). Tighten to `--severity=style` later once the backlog is cleared.

**Confidence: HIGH** -- `.shellcheckrc` format verified against ShellCheck wiki. SC codes verified against shellcheck.net/wiki.

---

## 7. Temp File Management

### Recommended: mktemp with EXIT Trap Cleanup

```bash
# In scripts/lib/strict.sh

# Create a temp directory for this script invocation
# Cleaned up automatically via EXIT trap
_TMPDIR=""

create_temp_dir() {
    _TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/networking-tools.XXXXXX")
    debug "Created temp directory: $_TMPDIR"
    echo "$_TMPDIR"
}

create_temp_file() {
    local suffix="${1:-.tmp}"
    if [[ -z "$_TMPDIR" ]]; then
        create_temp_dir > /dev/null
    fi
    local tmpfile
    tmpfile=$(mktemp "${_TMPDIR}/XXXXXX${suffix}")
    debug "Created temp file: $tmpfile"
    echo "$tmpfile"
}
```

**Why a temp directory instead of individual files:** Single `rm -rf` in the EXIT trap cleans everything. No tracking individual file paths. If the script creates 5 temp files, they all live in one directory and get cleaned up atomically.

**Confidence: HIGH** -- `mktemp` and `trap EXIT` are POSIX. Pattern verified against Greg's Wiki BashFAQ/062.

---

## 8. Color Detection and NO_COLOR

### Recommended: Respect NO_COLOR Standard + Terminal Detection

```bash
# Determine if colors should be used (called once at source time)
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 2 ]]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi
```

**Why this matters:** When output is piped (`./script.sh | tee log.txt`), ANSI codes pollute the file. When `NO_COLOR=1` is set, colors are disabled globally. The existing code always emits colors even when piped -- this is a bug that should be fixed.

**Check stderr (`-t 2`), not stdout (`-t 1`):** Logging goes to stderr. If stderr is a terminal, use colors. If stdout is piped but stderr is still a terminal (common: `./script.sh > output.txt`), colors should still show in the terminal for status messages.

**Confidence: HIGH** -- NO_COLOR standard verified at no-color.org. Terminal detection is POSIX.

---

## File Structure: New and Modified

### New Files

| File | Purpose | Lines (est.) |
|------|---------|-------------|
| `scripts/lib/strict.sh` | Strict mode, ERR trap, EXIT cleanup, temp files | ~60 |
| `scripts/lib/args.sh` | Argument parsing helpers, `parse_common_args()` | ~70 |
| `.shellcheckrc` | Project-level ShellCheck configuration | ~8 |

### Modified Files

| File | Changes |
|------|---------|
| `scripts/common.sh` | Add `debug()`, upgrade `_log()` core, add `retry_with_backoff()`, add `run_or_show()`, add NO_COLOR detection, source `lib/strict.sh` |
| `scripts/*/examples.sh` (17 files) | Add `-x`/`--execute` support, fix SC2155 patterns |
| `scripts/*/use-case-scripts` (~28 files) | Fix SC2155 patterns, adopt `parse_common_args()` |

### Source Order in Scripts

```bash
#!/usr/bin/env bash
# tool/examples.sh -- Description
source "$(dirname "$0")/../common.sh"    # Sources lib/strict.sh internally
source "$(dirname "$0")/../lib/args.sh"  # Optional: only if using parse_common_args

show_help() { ... }
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]}"
```

**Alternative:** Have `common.sh` source `lib/strict.sh` and `lib/args.sh` internally, so scripts only need one `source` line. This is cleaner but means every script gets argument parsing even if it doesn't use it. **Recommendation:** Have `common.sh` source `lib/strict.sh` (strict mode should always be on) but keep `lib/args.sh` as an explicit opt-in source.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Strict mode | `set -eEuo pipefail` + ERR trap | Explicit `\|\| { error; exit 1; }` after every command | Unscalable for 65+ scripts with hundreds of commands. Strict mode catches mistakes by default. |
| Strict mode | ERR trap with stack trace | `wick/bash-strict-mode` library (GitHub) | External dependency for ~30 lines of code. Not worth the supply chain risk. |
| IFS | Keep default (space/tab/newline) | `IFS=$'\n\t'` (unofficial strict mode) | Breaks space-separated command construction throughout the codebase. |
| Argument parsing | Manual `while/case` | `getopts` builtin | No long option support. `--verbose` and `--execute` are critical for UX. |
| Argument parsing | Manual `while/case` | GNU `getopt` | Not available on macOS by default. BSD `getopt` is broken. |
| Argument parsing | Manual `while/case` | `argbash` code generator | Adds a build step. Generated code is harder to maintain than a 50-line manual parser. |
| Logging | Upgrade existing functions | `bashlog` library | External dependency. Existing `info/warn/error` API is already embedded in 65+ scripts. |
| Logging | Human-readable colored output | JSON structured logging (`log.sh`, `jq`) | Requires `jq` dependency. Scripts are interactive CLI tools, not services. JSON adds complexity for zero user benefit. |
| Retry | Custom `retry_with_backoff()` | `retry` Go binary (joshdk/retry) | External binary dependency. A 15-line bash function does the same thing. |
| Dual-mode | `run_or_show()` function | `set -x` trace mode | `set -x` prints ALL commands including internal logic, not just the tool commands. Too noisy. |
| Dual-mode | `run_or_show()` function | Separate `--dry-run` scripts | Doubles the script count. One script with mode toggle is cleaner. |
| ShellCheck | `.shellcheckrc` project config | Inline `# shellcheck disable` everywhere | `.shellcheckrc` handles cross-cutting rules (source paths, external sources). Inline disables are for per-line exceptions. |

---

## Version Compatibility Matrix

| Feature | Bash 3.2 (macOS system) | Bash 4.0+ | Bash 4.4+ | Bash 5.0+ |
|---------|------------------------|-----------|-----------|-----------|
| `set -euo pipefail` | Yes | Yes | Yes | Yes |
| `set -E` (inherit ERR) | Yes | Yes | Yes | Yes |
| `declare -A` (assoc arrays) | NO | Yes | Yes | Yes |
| `${!array[@]}` (indirect) | NO | Yes | Yes | Yes |
| `shopt -s inherit_errexit` | NO | NO | Yes | Yes |
| `BASH_VERSINFO` | Yes | Yes | Yes | Yes |
| `readarray`/`mapfile` | NO | Yes | Yes | Yes |
| `${var@Q}` (quoting) | NO | NO | NO | Yes |
| `EPOCHSECONDS` | NO | NO | NO | Yes |

**Decision:** Target Bash 4.0+ minimum. This is already the implicit requirement (codebase uses `declare -A`). Guard Bash 4.4+ features (`inherit_errexit`) behind version checks. Do NOT use Bash 5.0+ features (`${var@Q}`, `EPOCHSECONDS`).

---

## Installation

```bash
# Development tool (one-time setup)
brew install shellcheck    # macOS
# apt install shellcheck   # Debian/Ubuntu
# dnf install shellcheck   # Fedora/RHEL

# Verify
shellcheck --version
# Expected: 0.10.0+ (0.11.0 is latest as of 2026-01-05)

# Run on project
shellcheck --severity=warning scripts/**/*.sh
```

No runtime dependencies to install. All new code is pure bash.

---

## Sources

### HIGH Confidence (Canonical references, official documentation)
- Greg's Wiki BashFAQ/035 (argument parsing patterns): https://mywiki.wooledge.org/BashFAQ/035
- Greg's Wiki BashFAQ/105 (set -e pitfalls): https://mywiki.wooledge.org/BashFAQ/105
- Greg's Wiki BashFAQ/062 (temp files): https://mywiki.wooledge.org/BashFAQ/062
- ShellCheck Wiki (SC codes, directives, .shellcheckrc): https://www.shellcheck.net/wiki/
- ShellCheck v0.11.0 Release: https://github.com/koalaman/shellcheck/releases
- NO_COLOR Standard: https://no-color.org/
- Bash Reference Manual (set builtin): https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html

### MEDIUM Confidence (Community references verified against official docs)
- Unofficial Bash Strict Mode (redsymbol.net): http://redsymbol.net/articles/unofficial-bash-strict-mode/
- Exit Traps (redsymbol.net): http://redsymbol.net/articles/bash-exit-traps/
- Bash strict mode with stack trace (bpm-rocks/strict): https://github.com/bpm-rocks/strict
- Exponential backoff in bash (gist): https://gist.github.com/reacocard/28611bfaa2395072119464521d48729a
- Bash logging levels pattern: https://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/

### LOW Confidence (Single source, needs validation during implementation)
- `FORCE_COLOR` standard (less widely adopted than NO_COLOR): https://force-color.org/
