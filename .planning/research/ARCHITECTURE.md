# Architecture: JSON Output Mode Integration

**Domain:** Bash CLI tool library -- structured JSON output for pentesting scripts
**Researched:** 2026-02-13
**Confidence:** HIGH (based on direct codebase analysis + verified tool capabilities)

## Recommended Architecture

### Design Principle: Centralized Envelope, Raw Capture, fd Redirection

The JSON output mode adds a single new library module (`lib/json.sh`) that owns all JSON construction and formatting. Individual scripts never construct raw JSON strings -- they call library functions that use `jq` for correct escaping and structure. The key insight from the existing codebase is that `run_or_show()` is the single bottleneck where command execution happens, so JSON capture hooks into that function. All non-JSON output is redirected to stderr via file descriptor manipulation, keeping stdout clean for the JSON envelope.

### Module Load Order (Modified `common.sh`)

Current `common.sh` sources 9 modules. JSON adds 1 new module at position 6:

```
source "${_LIB_DIR}/strict.sh"       # 1. Strict mode + ERR trap
source "${_LIB_DIR}/colors.sh"       # 2. Color variables
source "${_LIB_DIR}/logging.sh"      # 3. Logging functions
source "${_LIB_DIR}/validation.sh"   # 4. require_cmd, require_target
source "${_LIB_DIR}/cleanup.sh"      # 5. EXIT trap, temp files, retry
source "${_LIB_DIR}/json.sh"         # 6. NEW -- JSON formatting (needs cleanup for make_temp)
source "${_LIB_DIR}/output.sh"       # 7. MODIFIED -- run_or_show gets JSON capture hooks
source "${_LIB_DIR}/args.sh"         # 8. MODIFIED -- parse_common_args gets -j flag + fd redirect
source "${_LIB_DIR}/diagnostic.sh"   # 9. Diagnostic report functions
source "${_LIB_DIR}/nc_detect.sh"    # 10. Netcat variant detection
```

**Rationale for position 6:** `json.sh` depends on `cleanup.sh` (for `make_temp` to create temp files for output capture). It must load before `output.sh` because `run_or_show()` calls JSON functions. It must load before `args.sh` because `parse_common_args()` references `JSON_MODE` and calls `_json_require_jq`. `json.sh` does NOT depend on `logging.sh` -- it uses plain `echo >&2` for its own error messages to avoid a circular dependency (since `logging.sh` will need `json_is_active` for stderr redirection).

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `lib/json.sh` (NEW) | JSON state, envelope construction, result accumulation, jq dependency check, final output | `cleanup.sh` (make_temp for output capture) |
| `lib/args.sh` (MODIFIED) | Parse `-j`/`--json` flag, enforce `-j requires -x`, trigger fd3 redirect, call `_json_require_jq` | `json.sh` (JSON_MODE, _json_require_jq) |
| `lib/output.sh` (MODIFIED) | Capture command stdout/stderr in JSON+execute mode, suppress safety_banner, skip confirm_execute | `json.sh` (json_is_active, json_add_result), `cleanup.sh` (make_temp) |
| `lib/logging.sh` (MODIFIED) | Redirect info/warn/success/debug to stderr when JSON active | `json.sh` (json_is_active) |
| Use-case scripts (46) | Call `json_set_meta`, call `json_finalize` at end | `json.sh` (json_set_meta, json_is_active, json_finalize) |

---

## Data Flow

### Current Data Flow (No JSON)

```
Script starts
  -> parse_common_args "$@"              # Sets EXECUTE_MODE
  -> require_cmd <tool> "<hint>"
  -> TARGET="${1:-default}"
  -> confirm_execute "$TARGET"
  -> safety_banner
  -> run_or_show "N) Description" cmd    # x10 examples
       show mode:  info() to stdout + echo "   cmd" to stdout
       exec mode:  info() to stdout + execute cmd (stdout to terminal)
  -> [interactive demo section]
       show mode + tty:   read -rp prompts, optional execution
       show mode + no tty: exit 0
```

### New Data Flow (JSON Mode: `-j -x`)

```
Script starts
  -> parse_common_args "$@"
       Sets EXECUTE_MODE="execute", JSON_MODE=1
       Validates: -j without -x -> error + exit
       Calls: _json_require_jq -> exits if jq not installed
       Redirects: exec 3>&1 1>&2  (fd3 = original stdout, stdout -> stderr)
  -> require_cmd <tool> "<hint>"         # Error goes to stderr (fd1, which IS stderr now)
  -> TARGET="${1:-default}"
  -> json_set_meta "tool" "$TARGET"      # NEW -- sets envelope metadata
  -> confirm_execute "$TARGET"
       json_is_active -> return 0        # MODIFIED -- skips interactive confirm
  -> safety_banner
       json_is_active -> return 0        # MODIFIED -- suppresses banner
  -> run_or_show "N) Description" cmd    # x10 examples
       JSON+exec: capture stdout+stderr to temp files, store in _JSON_RESULTS
       All info/echo output -> stderr (via fd redirect)
  -> [interactive demo section]
       EXECUTE_MODE="execute" -> skips "show" block entirely
  -> json_is_active && json_finalize     # NEW -- emits JSON envelope to fd3 (original stdout)
```

### fd3 Redirection Strategy (Approach C)

This is the critical architectural decision. When JSON mode activates:

```bash
# In parse_common_args, after validating -j -x:
exec 3>&1    # Save original stdout as fd3
exec 1>&2    # Redirect stdout to stderr
```

**Effect:** Every `echo`, `info`, `warn`, `safety_banner`, bare `echo "   command"` in every script now goes to stderr. Only `json_finalize` writes to fd3 (original stdout). This means:

- **Zero changes needed** to the 46 scripts' educational `echo` lines, `info` calls, or any existing output
- **Zero changes needed** to `logging.sh` -- its output already goes to fd1, which now IS stderr
- `json_finalize` explicitly writes to `>&3` to reach the real stdout
- Downstream consumers see clean JSON on stdout, human-readable noise on stderr

**Why not Approach A (leave bare echo on stdout):** Mixed JSON + text on stdout is not valid JSON. Breaks `| jq`.

**Why not Approach B (add show_example wrapper to 46 scripts):** Requires ~200 lines of changes across 46 files to replace bare `echo` calls. High touch, low value.

**Why Approach C wins:** Zero per-script changes for echo/info suppression. Standard Unix convention (structured data on stdout, messages on stderr). Used by `curl -w`, `git`, `docker` for machine-readable output modes.

---

## Proposed Function Signatures for `lib/json.sh`

### Global State

```bash
# Source guard
[[ -n "${_JSON_LOADED:-}" ]] && return 0
_JSON_LOADED=1

# Set by parse_common_args when -j/--json flag is present
JSON_MODE="${JSON_MODE:-0}"

# Internal accumulator -- array of JSON result objects (strings)
_JSON_RESULTS=()

# Metadata set by each script
_JSON_TOOL=""
_JSON_TARGET=""
_JSON_STARTED=""

# jq availability (checked at load, enforced at activation)
_JSON_AVAILABLE=0
```

### Public Functions

```bash
# json_is_active -- predicate for checking JSON mode
# Usage: if json_is_active; then ... fi
# Usage: json_is_active && json_finalize
json_is_active() {
    [[ "${JSON_MODE:-0}" == "1" ]]
}

# json_set_meta -- called by each script after parse_common_args
# Sets tool name and target for the JSON envelope. Records start timestamp.
# Usage: json_set_meta "nmap" "$TARGET"
json_set_meta() {
    local tool="$1"
    local target="${2:-}"
    _JSON_TOOL="$tool"
    _JSON_TARGET="$target"
    _JSON_STARTED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

# json_add_result -- called by run_or_show for each command execution
# Accumulates one result entry. Uses jq for proper escaping.
# Usage: json_add_result "description" exit_code "stdout_content" "stderr_content"
json_add_result() {
    local description="$1"
    local exit_code="$2"
    local stdout="$3"
    local stderr="${4:-}"

    local result
    result=$(jq -n \
        --arg desc "$description" \
        --argjson code "$exit_code" \
        --arg out "$stdout" \
        --arg err "$stderr" \
        '{description: $desc, exit_code: $code, stdout: $out, stderr: $err}')

    _JSON_RESULTS+=("$result")
}

# json_finalize -- called at end of script to emit the complete JSON envelope
# Writes to fd3 (original stdout, saved before redirect).
# This should be the ONLY content on the real stdout in JSON mode.
# Usage: json_is_active && json_finalize
json_finalize() {
    local finished
    finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local count=${#_JSON_RESULTS[@]}

    # Build results array from accumulated entries
    local results_json="[]"
    if ((count > 0)); then
        results_json=$(printf '%s\n' "${_JSON_RESULTS[@]}" | jq -s '.')
    fi

    jq -n \
        --arg tool "$_JSON_TOOL" \
        --arg target "$_JSON_TARGET" \
        --arg started "$_JSON_STARTED" \
        --arg finished "$finished" \
        --argjson count "$count" \
        --argjson results "$results_json" \
        '{
            meta: {
                tool: $tool,
                target: $target,
                started: $started,
                finished: $finished
            },
            results: $results,
            summary: {
                total: $count,
                succeeded: ($results | map(select(.exit_code == 0)) | length),
                failed: ($results | map(select(.exit_code != 0)) | length)
            }
        }' >&3
}
```

### Internal Functions

```bash
# _json_check_jq -- called during module load (non-fatal)
# Sets _JSON_AVAILABLE flag for later enforcement
_json_check_jq() {
    if command -v jq &>/dev/null; then
        _JSON_AVAILABLE=1
    else
        _JSON_AVAILABLE=0
    fi
}

# _json_require_jq -- called when -j flag is parsed (fatal with install hint)
# Uses plain echo >&2 (NOT library error function) to avoid circular dependency
_json_require_jq() {
    if [[ "${_JSON_AVAILABLE:-0}" != "1" ]]; then
        echo "[ERROR] JSON output requires 'jq'. Install: brew install jq (macOS) | apt install jq (Debian/Ubuntu)" >&2
        exit 1
    fi
}

# Called at module load time
_json_check_jq
```

---

## Modifications to Existing Modules

### `scripts/common.sh` -- Add Source Line

```diff
 source "${_LIB_DIR}/cleanup.sh"
+source "${_LIB_DIR}/json.sh"
 source "${_LIB_DIR}/output.sh"
```

Also update the `@dependencies` comment in the file header.

### `lib/args.sh` -- Add `-j`/`--json` Flag

Changes to `parse_common_args()`:

```bash
# New case in the while loop (add between -x and -- cases):
-j|--json)
    JSON_MODE=1
    ;;

# New validation block AFTER the while loop, before function returns:
# Enforce: -j requires -x
if [[ "${JSON_MODE:-0}" == "1" && "${EXECUTE_MODE:-show}" != "execute" ]]; then
    echo "[ERROR] JSON output (-j) requires execute mode (-x). Use: $0 -j -x [args]" >&2
    exit 1
fi

# When JSON mode is active, enforce jq dependency and set up fd redirect
if [[ "${JSON_MODE:-0}" == "1" ]]; then
    _json_require_jq
    exec 3>&1    # Save original stdout as fd3
    exec 1>&2    # Redirect all stdout to stderr
fi
```

The fd redirect lives in `args.sh` (not `json.sh`) because it must happen AFTER argument parsing is complete and validation has passed. Placing it in `json.sh` at module load time would redirect stdout before we even know if `-j` was requested.

### `lib/output.sh` -- Modify `run_or_show()`

```bash
run_or_show() {
    local description="$1"
    shift

    if [[ "${EXECUTE_MODE:-show}" == "execute" ]]; then
        if json_is_active; then
            # JSON mode: capture output silently, accumulate results
            local stdout_file stderr_file cmd_exit_code
            stdout_file=$(make_temp)
            stderr_file=$(make_temp)
            # Capture exit code without triggering set -e
            "$@" > "$stdout_file" 2> "$stderr_file" && cmd_exit_code=0 || cmd_exit_code=$?
            json_add_result "$description" "$cmd_exit_code" "$(<"$stdout_file")" "$(<"$stderr_file")"
        else
            # Normal execute mode (unchanged)
            info "$description"
            debug "Executing: $*"
            "$@"
            echo ""
        fi
    else
        # Show mode (unchanged)
        info "$description"
        echo "   $*"
        echo ""
    fi
}
```

### `lib/output.sh` -- Modify `safety_banner()`

```bash
safety_banner() {
    # Suppress in JSON mode -- banner is human-readable noise
    json_is_active && return 0

    # Existing implementation unchanged
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  AUTHORIZED USE ONLY${NC}"
    echo -e "${RED}  Only scan targets you own or have${NC}"
    echo -e "${RED}  explicit written permission to test.${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
}
```

### `lib/output.sh` -- Modify `confirm_execute()`

```bash
confirm_execute() {
    local target="${1:-}"
    [[ "${EXECUTE_MODE:-show}" != "execute" ]] && return 0

    # Skip interactive confirmation in JSON mode (non-interactive by design)
    json_is_active && return 0

    # Existing implementation unchanged
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

### `lib/logging.sh` -- No Changes Needed

With the fd3 redirect strategy, `logging.sh` requires **zero modifications**. Here is why:

When `exec 1>&2` is executed in `parse_common_args`, all subsequent writes to fd1 (stdout) go to stderr. The logging functions (`info`, `warn`, `success`, `debug`) all write to fd1 via `echo -e`. After the redirect, their output goes to stderr automatically. The `error` function already writes to `>&2` explicitly, which is correct in both modes.

This is a major advantage of Approach C -- no logging changes at all.

---

## Per-Script Changes (46 Use-Case Scripts)

Each script needs exactly **2 additions** (3-4 lines total):

### Addition 1: Set JSON metadata (after parse_common_args block)

```bash
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd nmap "brew install nmap"
TARGET="${1:-localhost}"

json_set_meta "nmap" "$TARGET"          # <-- ADD THIS LINE
```

Placement: after TARGET is assigned, before `confirm_execute`. This ensures the tool name and target are captured in the JSON envelope.

### Addition 2: Finalize JSON at end of script

```bash
# At the very end of the script, after the interactive demo block:

json_is_active && json_finalize         # <-- ADD THIS LINE
```

### Why the Interactive Demo Section Needs No Changes

The existing guard pattern already handles JSON mode:

```bash
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    read -rp "..." answer
    # ...
fi
```

Since JSON mode requires `-x` (execute mode), `EXECUTE_MODE` is `"execute"`, so the entire `if` block is skipped. The interactive demo never runs in JSON mode. No changes needed.

---

## Handling Tool Output Diversity

### Tool Native Structured Output Support

| Tool | Native JSON/Structured Output | Flag |
|------|-------------------------------|------|
| nmap | XML via `-oX -` (stdout) | Well-structured, convertible |
| nikto | JSON via `-Format json -o -` | Native JSON to stdout |
| tshark | JSON via `-T json` | Native JSON output |
| ffuf | JSON via `-of json -o -` | Native JSON output |
| hashcat | Status JSON via `--status-json` | Status only, not crack results |
| sqlmap | JSON via REST API (`sqlmapapi.py`) | Different interface than CLI |
| gobuster | No native JSON | Text only |
| john | No native JSON | Text only |
| curl | Custom format via `-w` | Controlled format strings |
| dig | No native JSON (text, +yaml) | Text/YAML |
| hping3 | No native JSON | Text only |
| metasploit | No native JSON (console) | Not designed for parsing |
| aircrack-ng | No native JSON | Text only |
| skipfish | No native JSON (HTML reports) | Not designed for parsing |
| foremost | No native JSON (text audit) | Text only |
| traceroute | No native JSON | Text only |
| netcat | Raw stream | Not applicable |

### Phase 1 Strategy: Raw Capture (All 46 Scripts)

Store the raw stdout as a string in each result entry. This is correct and useful immediately -- downstream consumers can grep, parse, or display the raw output.

```json
{
  "meta": {"tool": "nmap", "target": "192.168.1.0/24", "started": "...", "finished": "..."},
  "results": [
    {
      "description": "1) Basic ping sweep of a subnet",
      "exit_code": 0,
      "stdout": "Starting Nmap 7.94 ...\nHost 192.168.1.1 is up (0.0045s latency).\n...",
      "stderr": ""
    }
  ],
  "summary": {"total": 10, "succeeded": 9, "failed": 1}
}
```

**Why raw capture first:** Attempting to parse 17 different tool output formats in bash is an anti-pattern (see Anti-Patterns section). Raw capture works for ALL tools, ships in a single milestone, and provides immediate value for `| jq` pipelines.

### Future Phase 2: Native Tool JSON (Deferred -- NOT in v1.4)

For tools that support native structured output, a future milestone could:
1. Add an optional `parsed` field to result entries (default: `null`)
2. Modify specific scripts to request native JSON/XML from the tool
3. Embed the parsed output as a nested JSON object

This is explicitly OUT OF SCOPE for v1.4. The raw capture approach is complete and correct on its own.

---

## JSON Envelope Schema

```json
{
  "meta": {
    "tool": "nmap",
    "target": "192.168.1.0/24",
    "started": "2026-02-13T14:30:00Z",
    "finished": "2026-02-13T14:30:45Z"
  },
  "results": [
    {
      "description": "1) Basic ping sweep of a subnet",
      "exit_code": 0,
      "stdout": "Starting Nmap 7.94 ( https://nmap.org ) ...\n...",
      "stderr": ""
    },
    {
      "description": "2) ARP discovery on local network",
      "exit_code": 0,
      "stdout": "...",
      "stderr": ""
    }
  ],
  "summary": {
    "total": 10,
    "succeeded": 9,
    "failed": 1
  }
}
```

**Field specifications:**

| Field | Type | Description |
|-------|------|-------------|
| `meta.tool` | string | Bare tool name (e.g., "nmap", not "nmap/discover-live-hosts") |
| `meta.target` | string | Target argument as received by the script |
| `meta.started` | string | ISO 8601 UTC timestamp when script began |
| `meta.finished` | string | ISO 8601 UTC timestamp when json_finalize ran |
| `results` | array | Ordered list of command execution results |
| `results[].description` | string | Human-readable description (e.g., "1) Basic ping sweep...") |
| `results[].exit_code` | integer | Command exit code (0 = success) |
| `results[].stdout` | string | Raw captured stdout (may contain newlines, ANSI codes) |
| `results[].stderr` | string | Raw captured stderr |
| `summary.total` | integer | Count of results entries |
| `summary.succeeded` | integer | Count where exit_code == 0 |
| `summary.failed` | integer | Count where exit_code != 0 |

---

## Patterns to Follow

### Pattern 1: fd Redirection for Clean Stdout (Critical)

**What:** Use file descriptor 3 to preserve original stdout for JSON output, redirect normal stdout to stderr.

**When:** JSON mode activated in `parse_common_args`.

**Why:** Standard Unix convention for machine-readable output. Zero changes needed to 46 scripts' echo/info lines.

```bash
# In parse_common_args (args.sh):
if [[ "${JSON_MODE:-0}" == "1" ]]; then
    _json_require_jq
    exec 3>&1 1>&2
fi

# In json_finalize (json.sh):
jq ... >&3
```

### Pattern 2: Source Guard Consistency

**What:** `[[ -n "${_JSON_LOADED:-}" ]] && return 0; _JSON_LOADED=1` at top of json.sh.

**When:** Always. Matches all 9 existing lib modules.

### Pattern 3: Lazy jq Dependency

**What:** Check jq availability at module load (non-fatal `_json_check_jq`), enforce at activation (fatal `_json_require_jq` with install hint).

**When:** json.sh loads in EVERY script invocation. jq is only required when `-j` is used.

**Why:** Don't break the 99% of invocations that never use `-j`. Only fail when user explicitly requests JSON.

### Pattern 4: Non-Zero Exit Capture (Strict Mode Safety)

**What:** Capture command exit codes without triggering `set -e`.

**When:** Every `run_or_show` invocation in JSON+execute mode.

```bash
"$@" > "$stdout_file" 2> "$stderr_file" && cmd_exit_code=0 || cmd_exit_code=$?
```

**Why:** Security tools frequently exit non-zero (nmap finding no hosts = exit 1, sqlmap finding no injection = exit 1). `set -e` would kill the script on the first "failure". The `&& 0 || $?` pattern captures the code without triggering ERR.

### Pattern 5: Consistent Per-Script Additions

**What:** Every use-case script gets the same 2 additions in the same locations.

**When:** All 46 scripts.

```bash
# ALWAYS after TARGET assignment, before confirm_execute:
json_set_meta "<tool>" "$TARGET"

# ALWAYS as the last line of the script:
json_is_active && json_finalize
```

**Why:** Consistent placement makes it trivial to verify completeness (grep for `json_set_meta` / `json_finalize`), easy to add to new scripts, and simple to test.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Manual JSON String Construction

**What:** Building JSON with `echo`, `printf`, or string concatenation.

**Why bad:** Tool output containing `"`, `\`, newlines, or control characters produces invalid JSON. A single nmap service banner with a quote character breaks everything.

**Instead:** Always use `jq -n --arg` for string values. jq handles all escaping correctly.

### Anti-Pattern 2: Per-Script JSON Templates

**What:** Each script constructs its own JSON envelope.

**Why bad:** 46 copies of envelope logic. Schema changes require 46 edits. Inconsistent field names.

**Instead:** All JSON construction lives in `lib/json.sh`. Scripts call `json_set_meta` and `json_finalize`.

### Anti-Pattern 3: Parsing Tool Output in Bash

**What:** Writing bash regex/awk/sed parsers to extract structured data from tool stdout.

**Why bad:** Tool output formats are version-dependent, locale-dependent, and fragile. Maintenance cost explodes across 17 tools.

**Instead:** Phase 1 stores raw stdout. If structured parsing is ever needed, use tools' native structured output (nmap `-oX`, nikto `-Format json`, tshark `-T json`).

### Anti-Pattern 4: Pure-Bash JSON Fallback

**What:** "If jq is installed use it, otherwise fall back to printf-based JSON."

**Why bad:** The fallback is the dangerous path (Anti-Pattern 1). Two code paths. Untestable without removing jq.

**Instead:** jq is a hard dependency when `-j` is used. Clear error message with install hint. jq is a single static binary available on every platform via every package manager.

### Anti-Pattern 5: Modifying logging.sh for JSON Mode

**What:** Adding `if json_is_active; then >&2` conditionals to every logging function.

**Why bad:** 4 functions modified, 8+ lines changed, and the fd3 redirect already handles this for free.

**Instead:** The `exec 1>&2` redirect in args.sh means logging functions automatically write to stderr without any changes.

---

## Edge Cases and Design Decisions

### Scripts With No `run_or_show` Calls in Execute Mode

Several scripts (e.g., `hashcat/crack-ntlm-hashes.sh`, `sqlmap/dump-database.sh`) have most examples as bare `info` + `echo` and only a few `run_or_show` calls. In JSON mode, only `run_or_show` calls produce results. These scripts may produce 2-3 results instead of 10:

```json
{"meta": {...}, "results": [{...}, {...}], "summary": {"total": 2, "succeeded": 2, "failed": 0}}
```

This is correct and expected. An empty or sparse results array signals "this script has few executable examples." The educational echo lines still appear on stderr for human visibility.

### Commands Requiring sudo

Many nmap and tshark commands use `sudo` (e.g., `sudo nmap -sn -PR ...`). In JSON mode, `run_or_show` captures stdout/stderr of the full `sudo command`. If sudo prompts for a password, the prompt goes to stderr (the real terminal). The user running `-j -x` should have sudo configured (cached credential or NOPASSWD).

### Long-Running Commands

tshark packet captures and skipfish scans can run indefinitely. Scripts that use these should pass count limiters (tshark `-c 50`, skipfish with timeouts) in their `run_or_show` calls. This is already the case in the existing scripts. No additional JSON-specific handling needed.

### ANSI Color Codes in Captured Output

Some tools emit ANSI escape codes in their output. These end up in the `stdout` field as literal escape sequences. This is acceptable -- `jq` handles the escaping correctly, and downstream consumers can strip ANSI if needed. The existing `NO_COLOR` / `[[ ! -t 1 ]]` detection in `colors.sh` affects the SCRIPT's colors, not the tool's.

### Empty Target Argument

Some scripts have optional targets with defaults (e.g., `TARGET="${1:-localhost}"`). `json_set_meta` receives the resolved default, which is correct -- the JSON should reflect what was actually used.

### ERR Trap Interaction

The `strict.sh` ERR trap calls `_strict_error_handler` which prints to stderr. In JSON mode, stderr IS the redirected stdout, so error traces appear on the terminal (correct). The ERR trap does NOT interfere with JSON output on fd3.

The `&& cmd_exit_code=0 || cmd_exit_code=$?` pattern in `run_or_show` prevents the ERR trap from firing for expected non-zero exits from security tools.

---

## New vs Modified Files Summary

### New Files

| File | Purpose | Estimated Lines |
|------|---------|----------------|
| `scripts/lib/json.sh` | JSON formatting module -- all public/internal functions | ~100 |
| `tests/lib-json.bats` | Unit tests for json.sh functions | ~120 |

### Modified Files (Library -- 3 files)

| File | What Changes | Est. Lines Changed |
|------|-------------|-------------------|
| `scripts/common.sh` | Add `source "${_LIB_DIR}/json.sh"` at position 6, update header comment | +2 |
| `scripts/lib/args.sh` | Add `-j\|--json` case, post-loop validation, jq enforcement, fd redirect | +15 |
| `scripts/lib/output.sh` | JSON branch in `run_or_show`, early return in `safety_banner` and `confirm_execute` | +15, ~3 lines modified |

### Modified Files (Scripts -- 46 use-case scripts)

Each script gets ~3 new lines:

| Change | Line |
|--------|------|
| `json_set_meta "toolname" "$TARGET"` | After TARGET assignment |
| `json_is_active && json_finalize` | Last line of script |

Total: ~138 new lines across 46 files.

### Modified Files (Tests)

| File | What Changes |
|------|-------------|
| `tests/lib-args.bats` | Add tests for -j parsing, -j without -x rejection |
| `tests/lib-output.bats` | Add tests for run_or_show in JSON mode |
| `tests/intg-cli-contracts.bats` | Add JSON output contract tests (valid JSON, envelope schema) |

### NOT Modified (Important)

| File | Why Not |
|------|---------|
| `scripts/lib/logging.sh` | fd redirect handles stderr routing automatically |
| `scripts/lib/strict.sh` | No interaction with JSON mode |
| `scripts/lib/colors.sh` | No interaction with JSON mode |
| `scripts/lib/cleanup.sh` | Only used (not modified) -- make_temp for output capture |
| `scripts/lib/validation.sh` | No interaction with JSON mode |
| `scripts/lib/diagnostic.sh` | Diagnostic scripts are Pattern B, out of scope for JSON |
| `scripts/lib/nc_detect.sh` | No interaction with JSON mode |
| 17 `examples.sh` scripts | Only 46 use-case scripts get JSON, not examples |
| 3 diagnostic scripts | Different pattern (Pattern B), out of scope |

---

## Build Order (Dependency-Driven)

### Step 1: Create `lib/json.sh` -- Core Module

Create the module with source guard, state variables, all 4 public functions (`json_is_active`, `json_set_meta`, `json_add_result`, `json_finalize`), and 2 internal functions (`_json_check_jq`, `_json_require_jq`).

**Depends on:** Nothing (standalone module, uses plain echo for errors, `make_temp` from cleanup.sh is only called via `run_or_show`).

**Testable independently:** Yes -- can source json.sh and call functions in BATS.

### Step 2: Add Source Line to `common.sh`

Add `source "${_LIB_DIR}/json.sh"` between cleanup.sh and output.sh.

**Depends on:** Step 1 (file must exist).

**Risk:** Zero -- adding a source of a file that only defines functions and checks jq.

### Step 3: Modify `lib/args.sh` -- Add `-j` Flag

Add the `-j|--json` case, the post-loop `-j requires -x` validation, `_json_require_jq` call, and `exec 3>&1 1>&2` fd redirect.

**Depends on:** Steps 1-2 (json.sh functions must be loaded).

### Step 4: Modify `lib/output.sh` -- JSON Hooks

Add JSON branch in `run_or_show()`, early returns in `safety_banner()` and `confirm_execute()`.

**Depends on:** Steps 1-3 (JSON_MODE, json_is_active, json_add_result, make_temp must be available).

### Step 5: Write Unit Tests (`tests/lib-json.bats`)

Test all json.sh functions: envelope structure, result accumulation, jq escaping of special characters, empty results, json_is_active predicate.

**Depends on:** Steps 1-4 (library must be complete).

### Step 6: Migrate Use-Case Scripts (46 Scripts)

Add `json_set_meta` and `json_finalize` to each script. Batch by tool directory:
- Batch 1: nmap (3 scripts) -- validate pattern
- Batch 2: nikto, sqlmap (6 scripts)
- Batch 3: tshark, hashcat, john (8 scripts)
- Batch 4: curl, dig, gobuster, ffuf (7 scripts)
- Batch 5: hping3, metasploit, netcat, traceroute (9 scripts)
- Batch 6: aircrack-ng, skipfish, foremost (8 scripts)

**Depends on:** Steps 1-5 (library tested, pattern proven with nmap batch).

### Step 7: Integration Tests

Add JSON contract tests to `tests/intg-cli-contracts.bats`:
- `-j -x` produces valid JSON (pipe to `jq .`)
- JSON envelope has required fields (meta, results, summary)
- `-j` without `-x` exits with error
- `-j` without `jq` installed exits with error

**Depends on:** Steps 1-6 (at least some scripts migrated).

### Step 8: Documentation Updates

Update show_help() in each script to mention `-j`/`--json`. Update site docs if needed.

**Depends on:** Steps 1-7 (feature complete).

---

## Scalability Considerations

| Concern | 3 commands | 10 commands | 50+ commands |
|---------|-----------|-------------|-------------|
| Memory (bash arrays) | Negligible | ~50KB in _JSON_RESULTS | ~500KB, fine |
| Temp files | 6 files | 20 files | 100 files, auto-cleaned by EXIT trap |
| jq invocations | 3 (add_result) + 1 (finalize) | 10 + 1 | 50 + 1, each is fast |
| JSON output size | ~2KB | ~10KB | ~50KB, pipe to file if needed |

No scalability concerns at the project's scale. The largest script runs 10 commands.

---

## Sources

### Codebase Analysis (Direct Observation -- HIGH Confidence)

- `scripts/common.sh` -- Module load order, source guard pattern (lines 17-34)
- `scripts/lib/args.sh` -- `parse_common_args()` function signature, flag cases, REMAINING_ARGS pattern (lines 26-58)
- `scripts/lib/output.sh` -- `run_or_show()`, `safety_banner()`, `confirm_execute()` signatures and behavior (lines 37-71)
- `scripts/lib/logging.sh` -- `info()`, `warn()`, `error()` output patterns, stderr for error() (lines 49-82)
- `scripts/lib/cleanup.sh` -- `make_temp()` function for temp file creation (lines 49-61)
- `scripts/lib/strict.sh` -- `set -eEuo pipefail` and ERR trap behavior (lines 13-39)
- `scripts/lib/colors.sh` -- `NO_COLOR` and `[[ ! -t 1 ]]` detection pattern (lines 22-35)
- 8 representative use-case scripts analyzed for patterns: nmap/identify-ports.sh, nmap/discover-live-hosts.sh, nikto/scan-specific-vulnerabilities.sh, sqlmap/dump-database.sh, hashcat/crack-ntlm-hashes.sh, tshark/analyze-dns-queries.sh, curl/debug-http-response.sh, gobuster/discover-directories.sh
- `tests/lib-output.bats` -- Existing test patterns for run_or_show and safety_banner

### External Sources (MEDIUM-HIGH Confidence)

- [jq official site](https://jqlang.org/) -- jq 1.8.1 (July 2025), `--arg`/`--argjson`/`-n` flags, `-s` slurp mode
- [Baeldung: Build JSON String with Bash Variables](https://www.baeldung.com/linux/bash-variables-create-json-string) -- Why jq over printf for JSON construction
- [Nmap output formats](https://nmap.org/book/output.html) -- `-oX` XML output capability
- [Nikto export formats](https://github.com/sullo/nikto/wiki/Export-Formats) -- `-Format json` native JSON
- [tshark man page](https://www.wireshark.org/docs/man-pages/tshark.html) -- `-T json` and `-T ek` output
- [ffuf GitHub](https://github.com/ffuf/ffuf) -- `-of json` output format
- [hashcat machine_readable wiki](https://hashcat.net/wiki/doku.php?id=machine_readable) -- `--status-json` flag
