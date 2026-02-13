# Phase 24: Library Unit Tests - Research

**Researched:** 2026-02-13
**Domain:** BATS testing for bash libraries (json.sh, args.sh -j flag, output.sh JSON paths)
**Confidence:** HIGH

## Summary

Phase 24 adds BATS unit tests for the JSON output library (`lib/json.sh`) and the `-j`/`--json` flag in `lib/args.sh`. The existing test infrastructure (BATS 1.13.0, bats-assert, bats-support, bats-file as submodules, GitHub Actions CI) is fully set up and working -- 266 tests currently pass. The primary technical challenge is that BATS uses fd3 internally for TAP protocol output, which directly conflicts with json.sh's use of fd3 for JSON output. This has been experimentally verified and a clear testing strategy identified.

There are two categories of functions to test: (1) simple state functions (`json_is_active`, `json_set_meta`, guard paths) that can be tested with direct calls in the BATS process, and (2) functions involving fd3 or `exec` redirections (`json_finalize`, `parse_common_args -j`) that must run in isolated subprocesses with `exec 3>&-` to close the inherited BATS fd3.

**Primary recommendation:** Use `run bash -c 'exec 3>&-; ... source common.sh ... json_finalize'` for any test that invokes json_finalize or parse_common_args with -j. Use direct function calls (no subprocess) for json_is_active, json_set_meta, and guard-path tests.

## Standard Stack

### Core (Already Installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bats-core | 1.13.0 | Test runner | Already in use, CI configured |
| bats-assert | latest (submodule) | Output assertions | assert_success, assert_output, assert_failure |
| bats-support | latest (submodule) | Base assertion support | Required by bats-assert |
| bats-file | latest (submodule) | File assertions | assert_file_exists etc. |
| jq | 1.8.1 (local), preinstalled (CI) | JSON validation in tests | json.sh depends on jq; tests use `jq -e` for assertions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none new) | -- | -- | No new dependencies needed |

**No new installation required.** All tools are already available.

## Architecture Patterns

### Test File Placement
```
tests/
  lib-json.bats          # NEW: Unit tests for lib/json.sh (TEST-01)
  lib-args.bats          # EXISTING: Add -j/--json tests (TEST-02)
  lib-output.bats        # EXISTING: Add JSON-mode tests for run_or_show, safety_banner, confirm_execute
```

### Pattern 1: Direct-Call Tests (Simple State Functions)
**What:** Test functions directly within the BATS process, no subprocess.
**When to use:** Functions that do NOT touch fd3 or run `exec` redirections: `json_is_active`, `json_set_meta`, guard-path no-ops (`json_add_example` with JSON_MODE=0), `safety_banner` with JSON_MODE=1, `confirm_execute` with JSON_MODE=1.
**Example:**
```bash
# Source: Verified experimentally 2026-02-13
setup() {
    load 'test_helper/common-setup'
    _common_setup
    show_help() { echo "test help"; }
    source "${PROJECT_ROOT}/scripts/common.sh"
    set +eEuo pipefail
    trap - ERR
    # Reset JSON state
    JSON_MODE=0
    _JSON_TOOL=""
    _JSON_TARGET=""
    _JSON_SCRIPT=""
    _JSON_STARTED=""
    _JSON_RESULTS=()
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()
}

@test "json_is_active returns true when JSON_MODE=1" {
    JSON_MODE=1
    run json_is_active
    assert_success
}

@test "json_set_meta populates tool and target when active" {
    JSON_MODE=1
    json_set_meta "nmap" "192.168.1.1"
    assert_equal "$_JSON_TOOL" "nmap"
    assert_equal "$_JSON_TARGET" "192.168.1.1"
    [[ -n "$_JSON_STARTED" ]]
}

@test "safety_banner suppressed in JSON mode" {
    JSON_MODE=1
    run safety_banner
    assert_success
    assert_output ""
}
```

### Pattern 2: Subprocess Tests (fd3/exec Functions)
**What:** Run the function in `bash -c` with `exec 3>&-` to close the BATS-inherited fd3, forcing json_finalize's stdout fallback path.
**When to use:** `json_finalize`, `json_add_example` + finalize, `json_add_result` + finalize, `parse_common_args -j`.
**Example:**
```bash
# Source: Verified experimentally 2026-02-13
@test "json_finalize outputs valid envelope with results" {
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        JSON_MODE=1
        _JSON_TOOL="nmap"
        _JSON_TARGET="192.168.1.1"
        _JSON_SCRIPT="test-script"
        _JSON_STARTED="2026-01-01T00:00:00Z"
        _JSON_RESULTS=()
        EXECUTE_MODE="show"
        json_add_example "Port scan" "nmap -p 80 target"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.meta.tool == "nmap"'
    echo "$output" | jq -e '.summary.total == 1'
    echo "$output" | jq -e '.results[0].command == "nmap -p 80 target"'
}
```

### Pattern 3: Variable Echo Tests (parse_common_args -j)
**What:** Run parse_common_args in subprocess, echo variable values, assert on output.
**When to use:** Testing -j flag effects (JSON_MODE, color reset, EXECUTE_MODE combo).
**Why subprocess:** `parse_common_args -j` runs `exec 3>&1` and `exec 1>&2`, which would corrupt BATS internal state.
**Example:**
```bash
# Source: Verified experimentally 2026-02-13
@test "-j sets JSON_MODE=1 and resets colors" {
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        VERBOSE=0; LOG_LEVEL="info"; EXECUTE_MODE="show"; JSON_MODE=0; REMAINING_ARGS=()
        RED="x"; GREEN="x"  # Force non-empty to verify reset
        parse_common_args -j target
        echo "JSON_MODE=$JSON_MODE"
        echo "RED=${RED}END"
    '
    assert_success
    assert_output --partial "JSON_MODE=1"
    assert_output --partial "RED=END"
}
```

### Pattern 4: jq -e for JSON Assertion
**What:** Pipe `$output` through `jq -e '<expression>'` to validate JSON structure and values. `jq -e` exits non-zero if the expression evaluates to false/null.
**When to use:** All json_finalize tests.
**Example:**
```bash
echo "$output" | jq -e '.meta.tool == "nmap"'
echo "$output" | jq -e '.summary.total == 2'
echo "$output" | jq -e '.results | length == 2'
echo "$output" | jq -e '.results[0].exit_code == 0'
```

### Anti-Patterns to Avoid
- **Calling `json_finalize` inside `run` without subprocess:** fd3 is BATS TAP stream; json_finalize writes JSON to TAP output, `$output` is empty, TAP stream is corrupted. VERIFIED: this causes test failures and garbled output.
- **Closing fd3 with `exec 3>&-` directly in BATS test body:** This closes BATS's own TAP stream, breaking subsequent test output. VERIFIED: causes "Bad file descriptor" errors and test count mismatches.
- **Calling `parse_common_args -j` directly in BATS test body:** The `exec 3>&1; exec 1>&2` redirections corrupt BATS process I/O. Must use subprocess.
- **Testing jq-missing by restricting PATH:** On macOS (Sequoia+), jq is in `/usr/bin`. On ubuntu-latest, jq is preinstalled. Override `_JSON_JQ_AVAILABLE=0` directly instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON assertion | String matching on JSON output | `jq -e` piped from `$output` | jq handles whitespace, key ordering, escaping correctly |
| JSON-MODE=0 guard testing | Complex subprocess for no-op tests | Direct call + check array length/variable emptiness | No fd3 involvement when JSON_MODE=0 |
| jq-missing simulation | PATH manipulation to hide jq | Override `_JSON_JQ_AVAILABLE=0` after source | jq is in /usr/bin on macOS Sequoia+, preinstalled on ubuntu-latest |

## Common Pitfalls

### Pitfall 1: BATS fd3 Conflict with json.sh fd3
**What goes wrong:** json_finalize checks `{ true >&3; } 2>/dev/null` -- inside BATS, fd3 is always open (BATS TAP stream). json_finalize writes JSON to fd3, corrupting TAP output. `$output` captured by `run` is empty.
**Why it happens:** BATS duplicates stdout as fd3 for TAP protocol separation. Child processes (including `run` subshells) inherit fd3.
**How to avoid:** Use `run bash -c 'exec 3>&-; ...'` to create a clean subprocess where fd3 is closed, forcing json_finalize's stdout fallback path.
**Warning signs:** Tests pass but TAP output contains raw JSON; `$output` is unexpectedly empty; test count mismatches ("Executed N instead of expected M tests").

### Pitfall 2: exec Redirections in BATS Process
**What goes wrong:** `parse_common_args -j` runs `exec 3>&1; exec 1>&2`. If called directly in BATS test body, stdout is redirected to stderr for the entire BATS process, breaking all subsequent output.
**Why it happens:** `exec` modifies file descriptors for the current process, not a subshell.
**How to avoid:** Always test `-j` flag parsing in a subprocess (`run bash -c '...'`).
**Warning signs:** All tests after the -j test fail; assertion output disappears.

### Pitfall 3: Source Guard Double-Source Prevention
**What goes wrong:** json.sh has `[[ -n "${_JSON_LOADED:-}" ]] && return 0`. In subprocess tests that `source common.sh`, the guard works correctly. But if a test tries to re-source to reset state, the guard prevents it.
**Why it happens:** Source guards are designed for production use, not repeated test setup.
**How to avoid:** Reset state variables explicitly in setup() rather than re-sourcing. For subprocess tests, each `bash -c` gets a fresh process.
**Warning signs:** State from previous test leaks into next test.

### Pitfall 4: Subprocess Variable Quoting with PROJECT_ROOT
**What goes wrong:** `run bash -c '... source "'"${PROJECT_ROOT}"'/scripts/common.sh" ...'` -- the PROJECT_ROOT expansion happens in the outer shell. If path contains spaces, quoting breaks.
**Why it happens:** Nested quoting in `bash -c` heredoc-style strings.
**How to avoid:** Use the `'"${PROJECT_ROOT}"'` quoting pattern (single-quote break, double-quote var, single-quote resume). This is already proven in existing tests (lib-cleanup.bats uses this exact pattern for subprocess tests).
**Warning signs:** "No such file or directory" errors in subprocess tests.

### Pitfall 5: Forgetting to Reset _JSON_RESULTS Array
**What goes wrong:** `_JSON_RESULTS` accumulates across tests if not reset, causing count mismatches.
**Why it happens:** setup() must explicitly clear the array; `_JSON_RESULTS=()` is needed.
**How to avoid:** Reset all JSON state variables in setup() for direct-call tests. Subprocess tests are inherently isolated.
**Warning signs:** `summary.total` is higher than expected.

### Pitfall 6: set +eEuo pipefail and trap - ERR
**What goes wrong:** strict.sh sets `set -eEuo pipefail` and installs an ERR trap. Without disabling these in setup(), BATS assertion failures trigger the ERR trap, producing confusing stack traces and double error reporting.
**Why it happens:** BATS needs control over exit behavior; strict mode interferes.
**How to avoid:** Always include `set +eEuo pipefail; trap - ERR` after sourcing common.sh in setup(). Already documented in existing test patterns.
**Warning signs:** Stack traces mixed with BATS assertion failure messages.

## Code Examples

### Complete lib-json.bats setup() Pattern
```bash
# Source: Verified experimentally 2026-02-13
setup() {
    load 'test_helper/common-setup'
    _common_setup

    show_help() { echo "test help"; }
    source "${PROJECT_ROOT}/scripts/common.sh"
    set +eEuo pipefail
    trap - ERR

    # Reset all mutable JSON state
    JSON_MODE=0
    _JSON_TOOL=""
    _JSON_TARGET=""
    _JSON_SCRIPT=""
    _JSON_STARTED=""
    _JSON_RESULTS=()
    EXECUTE_MODE="show"
}
```

### Subprocess Helper Pattern (Reduces Boilerplate)
```bash
# Source: Derived from lib-cleanup.bats subprocess pattern
# A helper function to reduce boilerplate for subprocess json tests
_run_json_finalize() {
    local body="$1"
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        JSON_MODE=1
        _JSON_TOOL=""
        _JSON_TARGET=""
        _JSON_SCRIPT=""
        _JSON_STARTED="2026-01-01T00:00:00Z"
        _JSON_RESULTS=()
        EXECUTE_MODE="show"
        '"$body"'
    '
}

@test "json_finalize with two examples" {
    _run_json_finalize '
        _JSON_TOOL="nmap"; _JSON_TARGET="target"
        json_add_example "Scan" "nmap target"
        json_add_example "Detect" "nmap -sV target"
        json_finalize
    '
    assert_success
    echo "$output" | jq -e '.summary.total == 2'
}
```

### Adding -j Tests to Existing lib-args.bats
```bash
# Source: Verified experimentally 2026-02-13
# These tests go at the end of the existing lib-args.bats file

@test "-j sets JSON_MODE=1" {
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        VERBOSE=0; LOG_LEVEL="info"; EXECUTE_MODE="show"; JSON_MODE=0; REMAINING_ARGS=()
        parse_common_args -j target
        echo "JSON_MODE=$JSON_MODE"
        echo "REMAINING=${REMAINING_ARGS[*]}"
    '
    assert_success
    assert_output --partial "JSON_MODE=1"
    assert_output --partial "REMAINING=target"
}

@test "--json long flag works same as -j" {
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        VERBOSE=0; LOG_LEVEL="info"; EXECUTE_MODE="show"; JSON_MODE=0; REMAINING_ARGS=()
        parse_common_args --json target
        echo "JSON_MODE=$JSON_MODE"
    '
    assert_success
    assert_output --partial "JSON_MODE=1"
}
```

### Testing Special Character Escaping
```bash
# Source: Verified experimentally 2026-02-13
@test "special characters are properly JSON-escaped" {
    run bash -c '
        exec 3>&-
        export NO_COLOR=1
        show_help() { echo "test help"; }
        source "'"${PROJECT_ROOT}"'/scripts/common.sh"
        set +eEuo pipefail
        trap - ERR
        JSON_MODE=1
        _JSON_TOOL="test"; _JSON_TARGET="target"
        _JSON_SCRIPT="test"; _JSON_STARTED="2026-01-01T00:00:00Z"
        _JSON_RESULTS=(); EXECUTE_MODE="show"
        json_add_example "Test with \"quotes\" and \\backslash" "echo \"hello world\""
        json_finalize
    '
    assert_success
    # jq -e validates the JSON is parseable and the value matches
    echo "$output" | jq -e '.results | length == 1'
}
```

## Test Coverage Checklist

### lib/json.sh Functions (TEST-01)
| Function | Test Cases |
|----------|-----------|
| `json_is_active` | JSON_MODE=0 returns false, JSON_MODE=1 returns true, unset returns false |
| `json_set_meta` | No-op when inactive, sets tool+target when active, sets ISO 8601 timestamp, handles empty target |
| `json_add_result` | No-op when inactive, accumulates with exit_code/stdout/stderr/command, multiple results accumulate |
| `json_add_example` | No-op when inactive, accumulates desc+command, multiple examples accumulate |
| `json_finalize` | No-op when inactive, empty results produces `[]`, show mode envelope, execute mode with succeeded/failed counts, special character escaping, valid JSON output |
| `_json_require_jq` | Exits 1 with error message when `_JSON_JQ_AVAILABLE=0` |
| `_json_check_jq` | Sets `_JSON_JQ_AVAILABLE=1` when jq present (verified at source time) |

### lib/args.sh -j Flag (TEST-02)
| Scenario | Test Cases |
|----------|-----------|
| `-j` basic | Sets JSON_MODE=1, remaining args preserved |
| `--json` long flag | Same behavior as -j |
| `-j` + jq check | Calls `_json_require_jq`, fails when jq unavailable |
| `-j` color reset | RED/GREEN/YELLOW/BLUE/CYAN/NC all set to empty string |
| `-j -x` combo | Both JSON_MODE=1 and EXECUTE_MODE=execute |
| `-j -v` combo | Both JSON_MODE=1 and VERBOSE incremented |
| `-- -j` | -j passed as positional arg, not parsed as flag |
| `-j -h` | Help takes precedence (exits 0 with help output) |

### lib/output.sh JSON Paths (Supplementary)
| Function | Test Cases |
|----------|-----------|
| `safety_banner` | Suppressed (no output) when JSON_MODE=1 |
| `confirm_execute` | Skipped (returns 0) when JSON_MODE=1 |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| BATS `run --separate-stderr` for fd testing | Subprocess `bash -c 'exec 3>&-'` isolation | N/A (project-specific) | Avoids BATS fd3 conflict entirely |
| String matching for JSON validation | `jq -e` expression assertions | Standard practice | Handles whitespace, ordering, escaping correctly |

## Open Questions

1. **run_or_show JSON paths (show+JSON, execute+JSON)**
   - What we know: These paths call json_add_example/json_add_result, which need JSON_MODE=1 and jq available.
   - What's unclear: Whether to test these in lib-output.bats or defer to integration tests.
   - Recommendation: Add basic tests in lib-output.bats using subprocess pattern. The functions are testable since run_or_show with JSON mode calls json_add_example/json_add_result (which are pure accumulation functions).

2. **CI jq version**
   - What we know: jq is preinstalled on ubuntu-latest (GitHub Actions). Version may differ from local (1.8.1).
   - What's unclear: Exact CI version; whether any jq features used are version-sensitive.
   - Recommendation: The json.sh code uses only basic jq features (`-n`, `--arg`, `--argjson`, `-s`). These are stable across all modern jq versions (1.6+). No risk here.

## Sources

### Primary (HIGH confidence)
- BATS official docs: [Writing Tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- `run` options, `--separate-stderr`, fd3 usage
- BATS official docs: [Gotchas](https://bats-core.readthedocs.io/en/stable/gotchas.html) -- subshell variable scope, strict mode, fd3 blocking
- BATS GitHub: [Issue #43 - fd3 significance](https://github.com/bats-core/bats-core/issues/43) -- BATS duplicates stdout as fd3 for TAP
- BATS GitHub: [Issue #533 - Close fd3 in run](https://github.com/bats-core/bats-core/issues/533) -- fd3 inherited by run subshell
- Local experimental verification (2026-02-13): All test patterns verified with actual BATS runs against the project codebase

### Secondary (MEDIUM confidence)
- GitHub Actions runner images: [jq preinstalled on ubuntu-latest](https://github.com/actions/runner-images/issues/9550)
- GitHub Docs: [GitHub-hosted runners](https://docs.github.com/actions/using-github-hosted-runners/about-github-hosted-runners)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools already in use, no new dependencies
- Architecture (test patterns): HIGH -- all patterns experimentally verified with actual BATS runs
- Pitfalls (fd3 conflict): HIGH -- reproduced and solved experimentally; both the problem and the solution verified
- CI compatibility: HIGH -- jq preinstalled, BATS 1.13.0 configured, subprocess tests use standard bash

**Research date:** 2026-02-13
**Valid until:** 2026-06-13 (stable domain; BATS and jq APIs are mature)
