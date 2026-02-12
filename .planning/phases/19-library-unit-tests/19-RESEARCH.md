# Phase 19: Library Unit Tests - Research

**Researched:** 2026-02-12
**Domain:** BATS unit testing of bash library modules (scripts/lib/*.sh)
**Confidence:** HIGH

## Summary

Phase 19 writes BATS unit tests for 6 library modules in `scripts/lib/`. The infrastructure from Phase 18 is operational: BATS v1.13.0 with bats-assert v2.2.0, bats-file v0.4.0, shared test helper, and 5 passing smoke tests. The established pattern (source common.sh then disable strict mode) is proven and documented.

The core challenge is testing bash functions that have side effects: `exit` calls (validation.sh), EXIT traps with temp file cleanup (cleanup.sh), `sleep` calls with exponential backoff (cleanup.sh retry), stderr output (logging.sh error()), ANSI color codes (colors.sh via logging.sh), and interactive terminal detection (output.sh). Each requires a specific BATS testing technique. Functions that call `exit` must be tested via `run` in subshells to isolate the exit from the BATS process. The `retry_with_backoff` function uses `sleep` and `bc` for exponential delay, which would make real tests slow -- this requires either mocking sleep or using very short delays (0.01s). The EXIT trap from `cleanup.sh` fires when the test subshell exits, which is generally harmless but needs careful handling when testing `make_temp` cleanup behavior.

All 6 requirements (UNIT-01 through UNIT-06) map directly to individual test files, one per functional domain. Since the Makefile uses non-recursive discovery (`./tests/bats/bin/bats tests/`), all `.bats` files must live directly in the `tests/` directory.

**Primary recommendation:** Create one `.bats` file per requirement (6 files) directly in `tests/`, following the established setup pattern from smoke.bats. Use `run` with subshells for functions that exit, `run --separate-stderr` for error() stderr testing, `$BATS_TEST_TMPDIR` for test-owned temp files, and override `sleep` with a no-op function for retry_with_backoff speed.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bats-core | v1.13.0 | Test runner | Already installed (Phase 18). Per-test subshell isolation. |
| bats-assert | v2.2.0 | Assertions: assert_success, assert_failure, assert_output, assert_equal, assert_line, refute_output | Already installed. Provides assert_output --partial, --regexp modes. Supports assert_stderr with `run --separate-stderr`. |
| bats-file | v0.4.0 | Filesystem assertions: assert_file_exists, assert_dir_exists, assert_file_not_exists, assert_dir_not_exists | Already installed. Essential for cleanup.sh make_temp tests. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bats-support | v0.3.0 | Base support for bats-assert (fail, output formatting) | Loaded automatically by common-setup.bash |

### Alternatives Considered

No new libraries needed. Phase 18 established the complete stack. Do not add bats-mock or any other libraries.

**Installation:**

No installation needed -- everything is already in place from Phase 18.

## Architecture Patterns

### Test File Organization

```
tests/
  smoke.bats              # Phase 18 smoke test (5 tests) -- DO NOT MODIFY
  lib-args.bats           # UNIT-01: parse_common_args tests
  lib-validation.bats     # UNIT-02: require_cmd, require_target, check_cmd tests
  lib-logging.bats        # UNIT-03: info, warn, error, debug, LOG_LEVEL tests
  lib-cleanup.bats        # UNIT-04: make_temp file/dir creation and EXIT trap cleanup
  lib-output.bats         # UNIT-05: run_or_show, safety_banner, is_interactive tests
  lib-retry.bats          # UNIT-06: retry_with_backoff tests
  test_helper/
    common-setup.bash     # Phase 18 shared helper -- DO NOT MODIFY
    bats-support/         # submodule
    bats-assert/          # submodule
    bats-file/            # submodule
```

**Why flat in `tests/`:** The Makefile `test` target runs `./tests/bats/bin/bats tests/` without `--recursive` (Phase 18 decision to avoid picking up BATS submodule fixtures). All `.bats` files must be directly in `tests/`.

**Naming convention:** `lib-{module}.bats` to clearly indicate these are library unit tests and to sort together in directory listings. The `lib-` prefix distinguishes from future integration tests.

### Pattern 1: Standard Library Test Setup

**What:** Every test file sources common.sh in setup(), then disables strict mode and traps. This is the established pattern from Phase 18 smoke.bats.

**When to use:** Every library unit test file.

**Example:**

```bash
#!/usr/bin/env bats
# tests/lib-args.bats -- Unit tests for scripts/lib/args.sh

setup() {
    load 'test_helper/common-setup'
    _common_setup

    # Required by parse_common_args -h handler
    show_help() { echo "test help"; }

    # Source all libraries via common.sh
    source "${PROJECT_ROOT}/scripts/common.sh"

    # CRITICAL: Disable strict mode for BATS compatibility
    set +eEuo pipefail
    trap - ERR

    # Reset mutable state to known defaults before each test
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()
}
```

**Why reset state:** `parse_common_args` mutates globals (VERBOSE, LOG_LEVEL, EXECUTE_MODE, REMAINING_ARGS). Each `@test` runs in its own subshell so state does not leak between tests, BUT the `source common.sh` in setup() sets initial values. Resetting in setup() makes the starting state explicit and predictable.

### Pattern 2: Testing Functions That Call `exit`

**What:** Functions like `require_cmd`, `require_target`, and `parse_common_args -h` call `exit`. Use `run` to execute them in a subshell so the exit does not kill the BATS test process.

**When to use:** Any test of require_cmd (missing command), require_target (no argument), or parse_common_args -h.

**Example:**

```bash
@test "require_cmd exits 1 for missing command" {
    run require_cmd "definitely_not_installed_xyz"
    assert_failure
}

@test "require_cmd shows install hint when provided" {
    run require_cmd "definitely_not_installed_xyz" "apt install xyz"
    assert_failure
    assert_output --partial "Install: apt install xyz"
}
```

**Why `run` is sufficient:** `run` creates a subshell. When `require_cmd` calls `exit 1`, it exits the subshell. BATS captures the exit code in `$status` and the output in `$output`. The BATS process is not affected.

**Caveat:** When using `run`, the function executes in a subshell where NO_COLOR may or may not be set depending on `[[ -t 1 ]]` (stdout is not a terminal inside `run`). Since we export `NO_COLOR=1` in `_common_setup`, this is handled.

### Pattern 3: Testing stderr Output

**What:** The `error()` function writes to stderr (`>&2`). Use `run --separate-stderr` to capture stdout and stderr independently.

**When to use:** Tests for `error()` function and any function that writes to stderr.

**Example:**

```bash
@test "error writes to stderr" {
    run --separate-stderr error "something broke"
    assert_success
    # error() writes to stderr, stdout should be empty
    refute_output
    assert [ -n "$stderr" ]
}
```

**Alternative approach:** If `assert_stderr` (bats-assert v2.2.0) works reliably:

```bash
@test "error writes to stderr" {
    run --separate-stderr error "something broke"
    assert_stderr --partial "[ERROR]"
}
```

**Note:** `assert_stderr` was added in bats-assert v2.2.0 (our pinned version). If it does not work, fall back to `assert [ -n "$stderr" ]` or `[[ "$stderr" == *"[ERROR]"* ]]`.

### Pattern 4: Testing EXIT Trap Cleanup

**What:** `cleanup.sh` creates a temp base directory at source time and registers an EXIT trap. Testing that `make_temp` creates files/dirs AND that EXIT trap cleans them up requires running a subprocess that exits.

**When to use:** UNIT-04 tests for make_temp and cleanup.

**Example:**

```bash
@test "make_temp creates a regular file" {
    local tmpfile
    tmpfile=$(make_temp file)
    assert_file_exists "$tmpfile"
}

@test "make_temp creates a directory when type is dir" {
    local tmpdir
    tmpdir=$(make_temp dir)
    assert_dir_exists "$tmpdir"
}

@test "EXIT trap cleans up temp files on process exit" {
    # Run a subprocess that creates a temp file and exits
    local tmpfile
    tmpfile=$(bash -c "
        source '${PROJECT_ROOT}/scripts/common.sh'
        set +eEuo pipefail
        trap - ERR
        make_temp file
    ")
    # After subprocess exits, EXIT trap should have cleaned up
    assert_file_not_exists "$tmpfile"
}
```

**Key insight:** The `make_temp` test for creation must run in the BATS test subshell (where common.sh is already sourced). The cleanup test must run in a separate subprocess (`bash -c`) so we can observe the state after the subprocess's EXIT trap fires. When testing inside the BATS subshell, the EXIT trap has NOT yet fired (it fires when the @test subshell exits), so the file still exists.

**Caveat:** `make_temp` is called inside `$()` command substitution, which is a subshell. The temp file is created inside `$_CLEANUP_BASE_DIR`, which was created at source time in the parent shell. The file path is echoed back. Because `_CLEANUP_BASE_DIR` exists in both the parent and the command substitution subshell, the file is visible in both. The EXIT trap in the outer test subshell will clean it up eventually, but during the test it still exists.

### Pattern 5: Testing retry_with_backoff Without Real Delays

**What:** `retry_with_backoff` calls `sleep` with exponential backoff. Real sleeps make tests slow. Override `sleep` with a no-op or tracking function.

**When to use:** UNIT-06 retry tests.

**Example:**

```bash
# Override sleep to be instant and track calls
sleep() {
    SLEEP_CALLS+=("$1")
    return 0
}

@test "retry_with_backoff retries correct number of times on failure" {
    SLEEP_CALLS=()

    run retry_with_backoff 3 1 false
    assert_failure
    # false fails, so it tries 3 times total (first attempt + 2 retries)
}

@test "retry_with_backoff succeeds immediately on first success" {
    SLEEP_CALLS=()

    run retry_with_backoff 3 1 true
    assert_success
}
```

**Important:** `sleep` must be overridden BEFORE `run` calls the function. When using `run`, the override must be exported as a function: `export -f sleep`. Otherwise the `run` subshell will use the real `sleep`.

**Better approach -- define and export in setup():**

```bash
setup() {
    # ... standard setup ...

    # Override sleep to track calls without real delays
    sleep() { :; }
    export -f sleep
}
```

### Pattern 6: Testing NO_COLOR Behavior

**What:** colors.sh sets color variables to empty strings when `NO_COLOR` is set or stdout is not a terminal. logging.sh uses these variables. Tests must verify that NO_COLOR suppresses ANSI codes.

**When to use:** UNIT-03 NO_COLOR tests.

**Example:**

```bash
@test "info output contains no ANSI codes when NO_COLOR is set" {
    export NO_COLOR=1
    run info "test message"
    assert_success
    # Check that output does NOT contain escape sequences
    refute_output --regexp $'\033'
}
```

**Note:** `_common_setup` already exports `NO_COLOR=1`, so color variables from colors.sh are empty strings. To test WITH colors, a test would need to unset NO_COLOR and re-source colors.sh -- but this is tricky because colors.sh has a source guard. For Phase 19, testing that NO_COLOR suppresses codes is sufficient. Testing that colors appear when NO_COLOR is unset is lower priority and harder to verify (would need to bypass the source guard).

### Anti-Patterns to Avoid

- **Testing in subdirectories of `tests/`:** BATS discovery is non-recursive. Files in `tests/lib/` will NOT be found by `make test`.
- **Sourcing individual lib modules directly:** Always source `common.sh` which loads all modules in dependency order. Individual modules depend on each other (logging.sh uses color variables from colors.sh, validation.sh uses error/info from logging.sh).
- **Forgetting state reset between tests:** While each `@test` runs in its own subshell (so state isolation is automatic), the shared setup() runs fresh each time. But if setup() sources common.sh which sets LOG_LEVEL=info, and you want to test with LOG_LEVEL=warn, reset it IN the test body.
- **Using `! function` instead of `run ! function`:** The `!` negation with bash `set -e` does not propagate failure correctly. Use `run ! function` or `run function` then `assert_failure`.
- **Real `sleep` in retry tests:** A 3-retry test with 1s initial delay would sleep 1+2 = 3 seconds. With many tests, this adds up. Always override sleep.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Temp files in tests | Manual mktemp + rm | `$BATS_TEST_TMPDIR` | Auto-cleaned per test, no leak risk |
| Sleep mocking | Complex mock framework | `sleep() { :; }; export -f sleep` | Bash function overrides builtins; simple, no dependencies |
| Exit code capture | Manual `set +e; func; code=$?; set -e` | `run func` then `assert_failure` / `assert_equal "$status" 1` | BATS `run` handles this correctly, captures output too |
| stderr capture | Manual `2>tmpfile` redirection | `run --separate-stderr func` | Built into BATS v1.5.0+, fills `$stderr` and `${stderr_lines[@]}` |
| Color stripping for assertions | `sed` or `tr` to strip ANSI | Export `NO_COLOR=1` before sourcing | Colors.sh respects NO_COLOR natively; no post-processing needed |

**Key insight:** BATS provides built-in mechanisms for every testing challenge in this phase. The only "trick" is the sleep override for retry tests.

## Common Pitfalls

### Pitfall 1: EXIT Trap Fires Inside BATS Test Subshell

**What goes wrong:** When common.sh is sourced in setup(), cleanup.sh creates a `$_CLEANUP_BASE_DIR` temp directory and registers an EXIT trap. This trap fires when the `@test` subshell exits (after the test completes). This is generally harmless -- it cleans up the temp dir.

**Why it happens:** Each `@test` runs in its own subshell. EXIT traps fire when the subshell exits.

**How to avoid:** Do NOT add `trap - EXIT` in setup() -- the EXIT trap is needed for `make_temp` cleanup tests (UNIT-04). Let it fire naturally. The only impact is that `$_CLEANUP_BASE_DIR` is cleaned up after each test, which is correct behavior.

**Warning signs:** If a test creates a temp file with `make_temp` and then tries to verify it exists after a subprocess exit, the file may already be gone.

### Pitfall 2: Source Guard Prevents Re-sourcing Individual Modules

**What goes wrong:** Each lib module has a source guard (`[[ -n "${_ARGS_LOADED:-}" ]] && return 0`). Once common.sh is sourced in setup(), sourcing the same module again in a test body does nothing. This means you cannot re-source colors.sh with different `NO_COLOR` settings.

**Why it happens:** Source guards prevent double-sourcing, which is correct in production but limits test flexibility.

**How to avoid:** For tests that need to vary module initialization (e.g., testing colors with and without NO_COLOR), set the environment variable BEFORE sourcing common.sh. Since setup() sources common.sh, use `setup_file()` for file-level configuration or move the source call into the test body itself (define `_COMMON_LOADED=""` etc. to reset source guards -- but this is fragile). Better: accept that NO_COLOR=1 is always set in tests (from `_common_setup`) and test the NO_COLOR=1 path. Testing the with-colors path is lower priority.

**Recommended approach:** Test that color variables are empty when NO_COLOR=1 (inspect $RED, $GREEN, etc. directly). Do not attempt to test the colorful output path in BATS.

### Pitfall 3: `run` Creates a Subshell Where Function Overrides May Not Apply

**What goes wrong:** Defining a function (like `sleep() { :; }`) in the test and then using `run retry_with_backoff ...` -- the override may not be visible inside the `run` subshell unless exported.

**Why it happens:** `run` executes in a subshell. Only exported functions (`export -f`) and environment variables are visible in subshells.

**How to avoid:** Export function overrides: `export -f sleep`. Or avoid `run` for functions where you need the override -- call the function directly and check return code manually.

**Warning signs:** Tests that should be instant take seconds (real sleep is being called).

### Pitfall 4: `parse_common_args -h` Calls show_help + exit

**What goes wrong:** `-h` flag processing calls `show_help` then `exit 0`. If `show_help` is not defined, it crashes. If testing -h directly (not via `run`), the exit kills the BATS process.

**Why it happens:** `parse_common_args` is designed to be called from scripts that define `show_help`.

**How to avoid:** Always define `show_help()` in setup(). Always test `-h` via `run parse_common_args -h` to isolate the exit.

**Warning signs:** Test output just stops (BATS process was killed by exit 0).

### Pitfall 5: `is_interactive` Returns False in BATS (Always)

**What goes wrong:** `is_interactive()` checks `[[ -t 0 ]]` (stdin is a terminal). BATS runs tests in subshells with stdin redirected, so `-t 0` is always false.

**Why it happens:** BATS's test execution model does not connect stdin to a terminal.

**How to avoid:** Test `is_interactive` by accepting that it returns false in BATS (test the "not interactive" path). To test the "interactive" path, redirect stdin from /dev/tty in a `run bash -c` subprocess, but this may not work in CI environments. Better: test via the function's documented behavior -- `is_interactive` is just `[[ -t 0 ]]`, so test that it returns 1 (failure) when not interactive.

**Warning signs:** Tests expecting `is_interactive` to succeed will always fail in BATS.

### Pitfall 6: `bc` Dependency in retry_with_backoff

**What goes wrong:** `retry_with_backoff` uses `bc` for exponential backoff calculation (`delay=$(echo "$delay * 2" | bc)`). If `bc` is not installed, the delay calculation fails.

**Why it happens:** `bc` is not always available on minimal systems.

**How to avoid:** Not a test concern since we override `sleep` anyway, but be aware that if testing the actual delay values, `bc` must be available. On macOS (this project's development platform), `bc` is available at `/usr/bin/bc`.

**Warning signs:** "bc: command not found" errors in retry tests.

## Code Examples

Verified patterns from the existing codebase and BATS documentation.

### Complete Test File Template (lib-args.bats)

```bash
#!/usr/bin/env bats
# tests/lib-args.bats -- Unit tests for scripts/lib/args.sh (UNIT-01)

setup() {
    load 'test_helper/common-setup'
    _common_setup

    show_help() { echo "test help output"; }

    source "${PROJECT_ROOT}/scripts/common.sh"
    set +eEuo pipefail
    trap - ERR

    # Reset mutable state
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()
}

@test "parse_common_args: -v sets VERBOSE >= 1" {
    parse_common_args -v target
    (( VERBOSE >= 1 ))
}

@test "parse_common_args: -v sets LOG_LEVEL to debug" {
    parse_common_args -v target
    assert_equal "$LOG_LEVEL" "debug"
}

@test "parse_common_args: -q sets LOG_LEVEL to warn" {
    parse_common_args -q target
    assert_equal "$LOG_LEVEL" "warn"
}

@test "parse_common_args: -x sets EXECUTE_MODE to execute" {
    parse_common_args -x target
    assert_equal "$EXECUTE_MODE" "execute"
}

@test "parse_common_args: unknown flags pass to REMAINING_ARGS" {
    parse_common_args --custom target
    assert_equal "${REMAINING_ARGS[*]}" "--custom target"
}

@test "parse_common_args: -- stops flag parsing" {
    parse_common_args -- -v -x target
    assert_equal "$EXECUTE_MODE" "show"
    assert_equal "$VERBOSE" "0"
    assert_equal "${REMAINING_ARGS[*]}" "-v -x target"
}

@test "parse_common_args: -h calls show_help and exits 0" {
    run parse_common_args -h
    assert_success
    assert_output "test help output"
}

@test "parse_common_args: flags after positional args still work" {
    parse_common_args target -x
    assert_equal "$EXECUTE_MODE" "execute"
    assert_equal "${REMAINING_ARGS[*]}" "target"
}

@test "parse_common_args: no args produces empty REMAINING_ARGS" {
    parse_common_args
    assert_equal "${#REMAINING_ARGS[@]}" "0"
}

@test "parse_common_args: combined -v -x sets both" {
    parse_common_args -v -x target
    (( VERBOSE >= 1 ))
    assert_equal "$EXECUTE_MODE" "execute"
    assert_equal "${REMAINING_ARGS[*]}" "target"
}
```

### Testing require_cmd with Missing Commands

```bash
@test "require_cmd succeeds for existing command" {
    # 'bash' is always available
    run require_cmd bash
    assert_success
}

@test "require_cmd exits 1 for missing command" {
    run require_cmd "nonexistent_command_xyz_123"
    assert_failure
}

@test "require_cmd shows install hint" {
    run require_cmd "nonexistent_command_xyz_123" "brew install xyz"
    assert_failure
    assert_output --partial "Install: brew install xyz"
}
```

### Testing error() Writes to stderr

```bash
@test "error writes to stderr not stdout" {
    run --separate-stderr error "test error message"
    # error() is not gated by _should_log, so it always runs
    assert_success
    # stdout should be empty, stderr should have the message
    refute_output
    assert [ -n "$stderr" ]
}
```

### Testing make_temp Cleanup

```bash
@test "EXIT trap cleans up temp files when process exits" {
    # Create a subprocess that makes a temp file and exits
    local tmpfile
    tmpfile=$(bash -c "
        source '${PROJECT_ROOT}/scripts/common.sh'
        set +eEuo pipefail
        trap - ERR
        make_temp file
    ")
    # The subprocess has exited, its EXIT trap should have fired
    assert_file_not_exists "$tmpfile"
}
```

### Testing retry_with_backoff with Mocked Sleep

```bash
setup() {
    load 'test_helper/common-setup'
    _common_setup
    show_help() { echo "test help"; }
    source "${PROJECT_ROOT}/scripts/common.sh"
    set +eEuo pipefail
    trap - ERR

    # Mock sleep to be instant
    sleep() { :; }
    export -f sleep
}

@test "retry_with_backoff returns 0 on immediate success" {
    run retry_with_backoff 3 1 true
    assert_success
}

@test "retry_with_backoff returns 1 after max attempts exhausted" {
    run retry_with_backoff 3 1 false
    assert_failure
}

@test "retry_with_backoff succeeds on second attempt" {
    # Create a command that fails once then succeeds
    local counter_file="${BATS_TEST_TMPDIR}/counter"
    echo "0" > "$counter_file"

    attempt_cmd() {
        local count
        count=$(<"$counter_file")
        count=$((count + 1))
        echo "$count" > "$counter_file"
        (( count >= 2 ))  # succeed on 2nd attempt
    }
    export -f attempt_cmd

    run retry_with_backoff 3 1 attempt_cmd
    assert_success
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom test harness (test-arg-parsing.sh) | BATS @test blocks | Phase 18 (2026-02-12) | Per-test isolation, TAP output, assertion library |
| `if/else` assertion boilerplate | `assert_success`, `assert_equal`, `assert_output` | Phase 18 | Clear failure messages with expected vs actual |
| Combined stdout/stderr capture | `run --separate-stderr` | bats-core v1.5.0+ | Can assert on error() stderr independently |
| Manual `set +e; cmd; ec=$?; set -e` | `run cmd` then `assert_failure` | bats-core built-in | Cleaner, captures output simultaneously |

**Deprecated/outdated:**
- The existing `tests/test-arg-parsing.sh` (268 assertions) and `tests/test-library-loads.sh` (39 assertions) are legacy. Phase 19 replaces the arg-parsing unit test portion with proper BATS tests. The legacy scripts should be kept until all their coverage is migrated.

## Function Inventory (What to Test)

Complete inventory of public functions per requirement:

### UNIT-01: args.sh
| Function | Parameters | Side Effects | Test Technique |
|----------|-----------|--------------|----------------|
| `parse_common_args` | `"$@"` | Sets VERBOSE, LOG_LEVEL, EXECUTE_MODE, REMAINING_ARGS | Direct call (no exit for most flags), `run` for -h |

### UNIT-02: validation.sh
| Function | Parameters | Side Effects | Test Technique |
|----------|-----------|--------------|----------------|
| `check_cmd` | `cmd_name` | None (boolean return) | Direct call, check `$?` |
| `require_cmd` | `cmd [install_hint]` | Calls `exit 1` on failure | `run` for missing commands |
| `require_target` | `target_arg` | Calls `exit 1` on empty | `run` for empty target |

### UNIT-03: logging.sh
| Function | Parameters | Side Effects | Test Technique |
|----------|-----------|--------------|----------------|
| `info` | `message...` | Writes to stdout | `run`, assert_output |
| `success` | `message...` | Writes to stdout | `run`, assert_output |
| `warn` | `message...` | Writes to stdout | `run`, assert_output |
| `error` | `message...` | Writes to stderr | `run --separate-stderr` |
| `debug` | `message...` | Writes to stdout (when LOG_LEVEL=debug) | `run` with LOG_LEVEL set |

### UNIT-04: cleanup.sh
| Function | Parameters | Side Effects | Test Technique |
|----------|-----------|--------------|----------------|
| `make_temp` | `[file\|dir] [prefix]` | Creates temp file/dir in `$_CLEANUP_BASE_DIR` | Direct call, assert_file_exists |
| `register_cleanup` | `command_string` | Adds to `_CLEANUP_COMMANDS` array | Direct call + subprocess exit test |
| `_cleanup_handler` | (none, internal) | Removes base dir, runs registered commands | Subprocess exit test |

### UNIT-05: output.sh
| Function | Parameters | Side Effects | Test Technique |
|----------|-----------|--------------|----------------|
| `run_or_show` | `description command...` | Prints or executes based on EXECUTE_MODE | `run` with EXECUTE_MODE set |
| `safety_banner` | (none) | Prints warning banner | `run`, assert_output |
| `is_interactive` | (none) | Checks `[[ -t 0 ]]` | Direct call (always false in BATS) |

### UNIT-06: cleanup.sh (retry section)
| Function | Parameters | Side Effects | Test Technique |
|----------|-----------|--------------|----------------|
| `retry_with_backoff` | `max_attempts delay command...` | Calls sleep, retries command | `run` with mocked sleep |

## Open Questions

1. **assert_stderr availability in bats-assert v2.2.0**
   - What we know: bats-assert v2.2.0 release notes mention `assert_stderr` and `assert_stderr_line`. The Phase 18 research flagged this as LOW confidence (not verified in documentation).
   - What's unclear: Whether `assert_stderr` actually works with our pinned v2.2.0.
   - Recommendation: Try it in the first test that needs stderr assertions. If it fails, fall back to manual `assert [ -n "$stderr" ]` or `[[ "$stderr" == *"[ERROR]"* ]]`. This is a minor implementation detail, not a research blocker.

2. **Should we test colors.sh directly?**
   - What we know: `_common_setup` sets NO_COLOR=1, which makes all color variables empty strings. The requirements mention "NO_COLOR suppresses ANSI codes" for UNIT-03 (logging).
   - What's unclear: Whether we need a standalone test for colors.sh or if testing logging with NO_COLOR is sufficient.
   - Recommendation: Test NO_COLOR behavior through logging.sh tests (UNIT-03). Verify color variables are empty strings when NO_COLOR=1. Do not create a separate colors.bats test file -- it's not in the requirements.

3. **Should we test diagnostic.sh and nc_detect.sh?**
   - What we know: The 6 requirements (UNIT-01 through UNIT-06) cover args.sh, validation.sh, logging.sh, cleanup.sh, and output.sh. diagnostic.sh and nc_detect.sh are not mentioned.
   - What's unclear: Whether these should be added.
   - Recommendation: Do NOT test them in Phase 19. They are out of scope per the requirements. diagnostic.sh and nc_detect.sh could be tested in a future phase if needed.

4. **How many tests total should we aim for?**
   - What we know: Each requirement has 3-8 test cases based on the success criteria. The existing test-arg-parsing.sh has 268 assertions for a broader scope.
   - What's unclear: Exact count.
   - Recommendation: Aim for 40-60 total tests across 6 files. Quality over quantity -- each test should verify one specific behavior.

## Sources

### Primary (HIGH confidence)
- Codebase: `scripts/lib/args.sh` -- parse_common_args implementation (55 lines)
- Codebase: `scripts/lib/validation.sh` -- require_cmd, check_cmd, require_target (41 lines)
- Codebase: `scripts/lib/logging.sh` -- info, warn, error, debug, LOG_LEVEL (79 lines)
- Codebase: `scripts/lib/cleanup.sh` -- make_temp, register_cleanup, retry_with_backoff (83 lines)
- Codebase: `scripts/lib/output.sh` -- run_or_show, safety_banner, is_interactive (68 lines)
- Codebase: `scripts/lib/colors.sh` -- color variable definitions, NO_COLOR support (32 lines)
- Codebase: `scripts/lib/strict.sh` -- set -eEuo pipefail, ERR trap (36 lines)
- Codebase: `tests/smoke.bats` -- established BATS test pattern (5 tests, proven working)
- Codebase: `tests/test_helper/common-setup.bash` -- shared helper (_common_setup, NO_COLOR=1)
- Codebase: `tests/test-arg-parsing.sh` -- existing unit test patterns (268 assertions), state reset approach
- Phase 18 research: `.planning/phases/18-bats-infrastructure/18-RESEARCH.md` -- BATS architecture, pitfalls, strict mode handling
- Phase 18 summary: `.planning/phases/18-bats-infrastructure/18-01-SUMMARY.md` -- key decisions (non-recursive, submodule-first loading)

### Secondary (MEDIUM confidence)
- [bats-core writing tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- run, setup/teardown, BATS_TEST_TMPDIR, run --separate-stderr
- [bats-assert README](https://github.com/bats-core/bats-assert) -- assert_success, assert_failure, assert_output, assert_equal, assert_line
- [bats-file README](https://github.com/bats-core/bats-file) -- assert_file_exists, assert_dir_exists, assert_file_not_exists

### Tertiary (LOW confidence)
- `assert_stderr` / `assert_stderr_line` availability in bats-assert v2.2.0 -- mentioned in release notes but not verified in practice

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Everything is already installed from Phase 18, no new dependencies
- Architecture: HIGH -- Test file organization follows established Phase 18 patterns (flat in tests/, same setup pattern), non-recursive discovery confirmed by examining Makefile
- Pitfalls: HIGH -- All pitfalls verified against actual source code of lib modules and confirmed BATS behavior (EXIT traps, strict mode, source guards, -t 0)
- Code examples: HIGH -- Patterns verified against working smoke.bats and existing test-arg-parsing.sh

**Research date:** 2026-02-12
**Valid until:** 2026-03-12 (stable domain -- no external dependencies changing)
