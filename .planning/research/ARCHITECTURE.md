# Architecture Patterns: BATS Testing Framework and Script Metadata Headers

**Domain:** Test infrastructure and structured metadata for a 66-script bash pentesting toolkit
**Researched:** 2026-02-11
**Confidence:** HIGH (official BATS documentation, codebase analysis, established bash patterns)

## Existing Architecture (Baseline)

Before introducing BATS, here is what exists:

```
tests/
  test-arg-parsing.sh        # 268 checks -- bash pass/fail counters, no framework
  test-library-loads.sh       # 39 checks -- bash pass/fail counters, no framework

scripts/
  common.sh                   # Entry point: sources lib/*.sh in dependency order
  lib/
    strict.sh                 # set -eEuo pipefail, ERR trap
    colors.sh                 # ANSI color variables
    logging.sh                # info/success/warn/error/debug with LOG_LEVEL
    validation.sh             # require_root, check_cmd, require_cmd, require_target
    cleanup.sh                # EXIT trap, make_temp, register_cleanup, retry_with_backoff
    output.sh                 # safety_banner, is_interactive, run_or_show, confirm_execute, PROJECT_ROOT
    args.sh                   # parse_common_args, REMAINING_ARGS, EXECUTE_MODE
    diagnostic.sh             # report_pass/fail/warn/skip, report_section, run_check
    nc_detect.sh              # detect_nc_variant
  <tool>/
    examples.sh               # 17 scripts -- Pattern A: 10 examples + interactive demo
    <use-case>.sh              # 46 scripts -- Pattern A variant: task-specific examples

.github/workflows/
  shellcheck.yml              # CI: ShellCheck on push/PR to main

Makefile                       # lint target runs ShellCheck, tool runners
.shellcheckrc                  # source-path=SCRIPTDIR, external-sources=true
```

### Current Script Header Pattern (All 66 Scripts)

Every script follows this exact 3-line header:

```bash
#!/usr/bin/env bash
# <path>/<name>.sh -- <one-line description>
source "$(dirname "$0")/../common.sh"
```

Followed by:

```bash
show_help() { ... }           # Defines help text
parse_common_args "$@"         # Handles -h, -v, -q, -x, --
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"
require_cmd <tool> "<hint>"    # Tool validation
...                            # Script body
```

### Current Test Patterns (Custom Harness)

Both test files use the same homegrown framework:

```bash
set +eEu                      # Disable strict mode for test harness
PASS_COUNT=0; FAIL_COUNT=0
check_pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "  PASS: $1"; }
check_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "  FAIL: $1"; }
```

Tests run scripts as subprocesses (`bash "$script" --help`) and check exit codes + output with `grep -q`. The test-library-loads.sh sources `common.sh` directly and validates functions with `declare -F`.

**What works:** Tests cover the right things (help exits 0, -x rejects non-interactive, parse_common_args behavior, function loading).

**What is limited:** No TAP output, no assertion library, no parallel execution, verbose custom boilerplate, hard to add new test cases, no CI integration for tests (only ShellCheck runs in CI).

## Recommended Architecture (With BATS)

### Decision: BATS-core with bats-support and bats-assert

**Why BATS:** It is the standard testing framework for bash. It provides TAP-compliant output, isolated test execution (each test runs in its own subshell), setup/teardown lifecycle hooks, and the `run` command for capturing output and exit codes. The existing tests already do exactly what BATS tests do -- just with manual boilerplate.

**Why bats-assert:** Provides `assert_success`, `assert_failure`, `assert_output --partial`, `assert_line` -- replacing manual `grep -q` + `check_pass`/`check_fail` patterns.

**Why bats-support:** Required dependency of bats-assert. Provides error formatting.

**Why NOT bats-file or bats-detik:** Not needed. This project tests CLI behavior (exit codes, output), not file operations or Kubernetes.

### Installation Strategy: GitHub Actions Official Action + Local brew

Use `bats-core/bats-action@4.0.0` in CI (installs bats + all libs, provides `BATS_LIB_PATH`). For local development, install via Homebrew. Do NOT use git submodules -- they add clone complexity for a learning-focused project.

**Local (macOS):**
```bash
brew install bats-core
brew install bats-assert     # Pulls bats-support as dependency
```

**CI (GitHub Actions):**
```yaml
- uses: bats-core/bats-action@4.0.0
  id: setup-bats
```

**Library loading in tests:** Use `bats_load_library` with `BATS_LIB_PATH` -- works on both Homebrew and CI without hardcoded paths.

### Target Directory Structure

```
tests/
  test-arg-parsing.sh          # KEEP: existing 268 tests (migrate later)
  test-library-loads.sh         # KEEP: existing 39 tests (migrate later)
  helpers/
    common-setup.bash           # Shared setup: load libs, set PROJECT_ROOT
    mock-commands.bash           # Command stubs for testing without tools installed
  lib/
    args.bats                   # Unit tests for parse_common_args
    logging.bats                # Unit tests for logging functions
    validation.bats             # Unit tests for require_cmd, require_target, etc.
    cleanup.bats                # Unit tests for make_temp, register_cleanup
    output.bats                 # Unit tests for run_or_show, confirm_execute
  scripts/
    help-flags.bats             # Integration: all scripts --help exits 0
    execute-mode.bats           # Integration: all scripts -x rejects non-interactive
    header-metadata.bats        # Integration: all scripts have valid header comments
  setup_suite.bash              # Suite-level setup (optional, for future use)
```

**Rationale for this structure:**

1. **tests/lib/*.bats** -- Unit tests for library modules. One .bats file per lib/*.sh file. These test functions in isolation by sourcing common.sh and calling functions directly.

2. **tests/scripts/*.bats** -- Integration tests that run scripts as subprocesses. These replace the current test-arg-parsing.sh pattern but use BATS assertions instead of manual counters.

3. **tests/helpers/common-setup.bash** -- Loaded by every .bats file. Sets PROJECT_ROOT, loads bats-support and bats-assert.

4. **Existing tests kept alongside** -- No immediate migration required. They still pass, they still run. Migrate them to .bats format incrementally.

### Component: tests/helpers/common-setup.bash

This is the central helper that every test file loads.

```bash
#!/usr/bin/env bash
# tests/helpers/common-setup.bash -- Shared BATS test setup

_common_setup() {
    # Load assertion libraries (works with both brew and CI BATS_LIB_PATH)
    bats_load_library bats-support
    bats_load_library bats-assert

    # Resolve project root from test file location
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export PROJECT_ROOT

    # Make scripts accessible
    SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
    export SCRIPTS_DIR
}
```

**Usage in test files:**

```bash
setup() {
    load 'helpers/common-setup'
    _common_setup
}
```

**Why `_common_setup` as a function, not bare code:** BATS documentation explicitly warns against running `load` and `source` outside of functions -- diagnostics are worse when errors occur in "free code". Wrapping in a function called from `setup()` follows the recommended pattern.

**Why `bats_load_library` over `load 'test_helper/bats-support/load'`:** The `bats_load_library` approach works with any installation method (brew, npm, CI action) via the `BATS_LIB_PATH` environment variable. Hardcoded paths break across environments.

### Component: tests/helpers/mock-commands.bash

For testing scripts that require tools not installed in CI:

```bash
#!/usr/bin/env bash
# tests/helpers/mock-commands.bash -- Command stubs for CI testing

# Create a mock command that always succeeds
create_mock_cmd() {
    local cmd_name="$1"
    local mock_dir="${BATS_TEST_TMPDIR}/mocks"
    mkdir -p "$mock_dir"

    cat > "${mock_dir}/${cmd_name}" <<'MOCK'
#!/usr/bin/env bash
# Mock: exits 0, outputs nothing
exit 0
MOCK
    chmod +x "${mock_dir}/${cmd_name}"

    # Prepend mock directory to PATH
    export PATH="${mock_dir}:${PATH}"
}
```

**Why mocks matter:** The scripts call `require_cmd nmap`, `require_cmd sqlmap`, etc. In CI, these tools are not installed. Without mocks, every integration test would fail at the require_cmd step. Mocks let tests validate script behavior (help output, argument parsing, output format) without requiring tool installation.

### Component: Unit Test Pattern (tests/lib/*.bats)

Example: `tests/lib/args.bats`

```bash
#!/usr/bin/env bats

setup() {
    load 'helpers/common-setup'
    _common_setup

    # Source the library under test
    # Disable strict mode for test harness (matches existing test pattern)
    show_help() { echo "help"; }
    source "${SCRIPTS_DIR}/common.sh"
    set +eEuo pipefail
    trap - ERR
}

@test "parse_common_args: -v sets VERBOSE >= 1" {
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()

    parse_common_args -v scanme.nmap.org

    (( VERBOSE >= 1 ))
}

@test "parse_common_args: -q sets LOG_LEVEL to warn" {
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()

    parse_common_args -q scanme.nmap.org

    assert_equal "$LOG_LEVEL" "warn"
}

@test "parse_common_args: -x sets EXECUTE_MODE to execute" {
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()

    parse_common_args -x scanme.nmap.org

    assert_equal "$EXECUTE_MODE" "execute"
    assert_equal "${REMAINING_ARGS[*]}" "scanme.nmap.org"
}

@test "parse_common_args: -- stops flag parsing" {
    VERBOSE=0
    LOG_LEVEL="info"
    EXECUTE_MODE="show"
    REMAINING_ARGS=()

    parse_common_args -- -x scanme.nmap.org

    assert_equal "$EXECUTE_MODE" "show"
    assert_equal "${REMAINING_ARGS[*]}" "-x scanme.nmap.org"
}
```

**Key pattern:** Source `common.sh` in `setup()`, then immediately disable strict mode with `set +eEuo pipefail` and clear the ERR trap. This matches what the existing test-arg-parsing.sh does (line 9: `set +eEu`, line 188: `set +eEuo pipefail`, line 189: `trap - ERR`). The reason is that BATS needs to control test execution flow itself -- strict mode's `set -e` would cause test failures to abort instead of being caught by BATS.

**Defining `show_help()` before sourcing:** `parse_common_args` calls `show_help` on `-h`/`--help`. It must exist before sourcing common.sh or tests that invoke parse_common_args with those flags would fail. The existing test-arg-parsing.sh does exactly this (line 182).

### Component: Integration Test Pattern (tests/scripts/*.bats)

Example: `tests/scripts/help-flags.bats`

```bash
#!/usr/bin/env bats

setup() {
    load 'helpers/common-setup'
    _common_setup
}

# Dynamically generate tests for all example scripts
@test "nmap/examples.sh: --help exits 0" {
    run bash "${SCRIPTS_DIR}/nmap/examples.sh" --help
    assert_success
}

@test "nmap/examples.sh: --help contains Usage:" {
    run bash "${SCRIPTS_DIR}/nmap/examples.sh" --help
    assert_output --partial "Usage:"
}

@test "nmap/examples.sh: -x rejects non-interactive stdin" {
    run bash -c "echo '' | bash '${SCRIPTS_DIR}/nmap/examples.sh' -x scanme.nmap.org"
    assert_failure
}
```

**Note on dynamic test generation:** BATS supports generating tests dynamically using `bats_test_function` but this is an advanced pattern. For the initial BATS setup, enumerate test cases explicitly. A helper script can generate the .bats file from the script list if needed later.

### Component: CI Workflow (`.github/workflows/tests.yml`)

```yaml
name: Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  bats:
    name: BATS tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Setup BATS
        id: setup-bats
        uses: bats-core/bats-action@4.0.0

      - name: Run BATS tests
        env:
          BATS_LIB_PATH: ${{ steps.setup-bats.outputs.lib-path }}
          TERM: xterm
        run: bats --recursive tests/ --filter-tags '!slow'

  legacy-tests:
    name: Legacy test scripts
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Run legacy tests
        run: |
          bash tests/test-library-loads.sh
          bash tests/test-arg-parsing.sh
```

**Key decisions:**

1. **Separate workflow file** (`tests.yml`) rather than adding to `shellcheck.yml`. ShellCheck and BATS have different concerns and should be independently reportable. They can run in parallel.

2. **Two jobs initially:** The `bats` job runs new .bats tests. The `legacy-tests` job runs the existing bash test scripts unchanged. This allows incremental migration -- as tests move to BATS, the legacy job shrinks.

3. **`bats --recursive tests/`:** Picks up all .bats files in tests/ and subdirectories automatically. New test files are automatically included.

4. **`--filter-tags '!slow'`:** Allows marking integration tests that take long (e.g., ones that actually invoke tools) as `# bats test_tags=slow` and excluding them from CI. Fast unit tests always run.

5. **`TERM: xterm`:** Required by bats-core for proper terminal output in CI.

### Component: Makefile Integration

```makefile
test: ## Run BATS tests
	@bats --recursive tests/

test-legacy: ## Run legacy test scripts
	@bash tests/test-arg-parsing.sh
	@bash tests/test-library-loads.sh

test-all: test test-legacy ## Run all tests
```

**Local BATS_LIB_PATH for macOS/Homebrew:**

```bash
# In shell profile or before running tests:
export BATS_LIB_PATH="$(brew --prefix)/lib"
```

Or in Makefile:

```makefile
test: ## Run BATS tests
	@BATS_LIB_PATH="$$(brew --prefix 2>/dev/null)/lib:${BATS_LIB_PATH:-}" bats --recursive tests/
```

## Script Metadata Headers

### Decision: Structured Comment Block, NOT shdoc Annotations

**Recommendation:** Add a structured comment header block to every script, parseable with simple grep/awk but readable as plain comments.

**Why NOT shdoc (@description, @param, @example):** shdoc annotations are designed for documenting functions within library files, not for top-level script metadata. The project's scripts are not libraries with exported functions -- they are standalone CLI scripts. shdoc also requires installing an external tool (gawk dependency). The overhead is not justified.

**Why NOT YAML frontmatter in comments:** Requires a YAML parser. Bash does not have one built in. Over-engineering for the use case.

**Why structured comments:** They are human-readable without any tool, parseable with standard bash (grep, awk, cut), and extend the existing single-line comment header naturally.

### Recommended Header Format

```bash
#!/usr/bin/env bash
# ============================================================================
# nmap/examples.sh -- Network Mapper: host discovery and port scanning
#
# Tool:        nmap
# Category:    examples
# Requires:    nmap
# Target:      required
# Since:       v1.0
# ============================================================================
source "$(dirname "$0")/../common.sh"
```

For use-case scripts:

```bash
#!/usr/bin/env bash
# ============================================================================
# nmap/discover-live-hosts.sh -- Find all active hosts on a subnet
#
# Tool:        nmap
# Category:    use-case
# Requires:    nmap
# Target:      optional (default: localhost)
# Since:       v1.2
# ============================================================================
source "$(dirname "$0")/../common.sh"
```

For library modules:

```bash
#!/usr/bin/env bash
# ============================================================================
# lib/logging.sh -- Logging functions with LOG_LEVEL filtering
#
# Category:    library
# Provides:    info, success, warn, error, debug
# Depends:     lib/colors.sh
# Since:       v1.2
# ============================================================================
```

### Header Fields

| Field | Required | Values | Purpose |
|-------|----------|--------|---------|
| `Tool` | Scripts only | Tool name (nmap, sqlmap, etc.) | Which tool this script demonstrates |
| `Category` | Always | `examples`, `use-case`, `diagnostic`, `checker`, `library` | Script classification |
| `Requires` | Scripts only | Comma-separated command names | External dependencies |
| `Target` | Scripts only | `required`, `optional (default: X)`, `none` | Whether target argument is needed |
| `Since` | Always | Version tag | When introduced |
| `Provides` | Library only | Comma-separated function names | Exported functions |
| `Depends` | Library only | Comma-separated lib paths | Module dependencies |

### Parsing Headers Programmatically

Headers are designed to be extracted with simple bash:

```bash
# Extract a single field from a script header
get_header_field() {
    local script="$1"
    local field="$2"
    grep "^# ${field}:" "$script" | sed "s/^# ${field}:[[:space:]]*//"
}

# Example usage:
tool=$(get_header_field scripts/nmap/examples.sh "Tool")    # "nmap"
category=$(get_header_field scripts/nmap/examples.sh "Category")  # "examples"
```

This enables future BATS tests to validate headers:

```bash
@test "nmap/examples.sh: has valid Tool header" {
    run get_header_field "${SCRIPTS_DIR}/nmap/examples.sh" "Tool"
    assert_success
    assert_output "nmap"
}
```

### Migration Impact on Existing Source Pattern

The header block is inserted between the shebang and the `source` line. It does NOT change the `source` line itself, the `show_help()` function, the `parse_common_args` call, or any script behavior.

**Before:**
```bash
#!/usr/bin/env bash
# nmap/examples.sh -- Network Mapper: host discovery and port scanning
source "$(dirname "$0")/../common.sh"
```

**After:**
```bash
#!/usr/bin/env bash
# ============================================================================
# nmap/examples.sh -- Network Mapper: host discovery and port scanning
#
# Tool:        nmap
# Category:    examples
# Requires:    nmap
# Target:      required
# Since:       v1.0
# ============================================================================
source "$(dirname "$0")/../common.sh"
```

**Impact:** Zero behavioral change. The added lines are comments. ShellCheck ignores them. The `source` line remains on its original relative position. The `show_help()` function remains unchanged. This is purely additive metadata.

### ShellCheck Compatibility

The header block is pure comments. ShellCheck does not analyze comments. No `.shellcheckrc` changes needed. No `shellcheck disable` directives needed. The `source-path=SCRIPTDIR` resolution still works because the `source` line is unchanged.

## Data Flow: Test Execution

### BATS Unit Test Flow (tests/lib/*.bats)

```
bats tests/lib/args.bats
  |
  BATS evaluates file (counts @test blocks)
  |
  For each @test:
    |
    setup()
    |  load 'helpers/common-setup'    # Relative to tests/
    |  _common_setup()
    |    bats_load_library bats-support
    |    bats_load_library bats-assert
    |    PROJECT_ROOT = resolved path
    |
    |  show_help() { echo "help"; }   # Stub for parse_common_args
    |  source "${SCRIPTS_DIR}/common.sh"
    |    -> lib/strict.sh             # set -eEuo pipefail, ERR trap
    |    -> lib/colors.sh
    |    -> lib/logging.sh
    |    -> lib/validation.sh
    |    -> lib/cleanup.sh            # Registers EXIT trap
    |    -> lib/output.sh
    |    -> lib/args.sh               # Defines parse_common_args
    |    -> lib/diagnostic.sh
    |    -> lib/nc_detect.sh
    |
    |  set +eEuo pipefail             # Disable strict mode for test control
    |  trap - ERR                     # Clear ERR trap (BATS handles errors)
    |
    @test body executes
    |  Call function under test
    |  Assert results with bats-assert
    |
    teardown() (if defined)
    |
    BATS reports pass/fail (TAP format)
```

### BATS Integration Test Flow (tests/scripts/*.bats)

```
bats tests/scripts/help-flags.bats
  |
  For each @test:
    |
    setup()
    |  load 'helpers/common-setup'
    |  _common_setup()
    |
    @test body
    |  run bash "${SCRIPTS_DIR}/nmap/examples.sh" --help
    |    -> Script runs in subprocess (isolated)
    |    -> BATS captures stdout+stderr in $output
    |    -> BATS captures exit code in $status
    |
    |  assert_success                  # $status == 0
    |  assert_output --partial "Usage:" # $output contains "Usage:"
```

**Key difference:** Unit tests source `common.sh` into the test process. Integration tests run scripts as subprocesses via `run bash`. Integration tests are slower but test the full script lifecycle.

## Interaction Between BATS and Strict Mode

This is the most critical integration concern.

### The Problem

The project uses `set -eEuo pipefail` (via `lib/strict.sh`) which causes the shell to exit on any command failure. BATS expects to control test execution flow itself -- a failed assertion should not abort the test process, it should be reported.

### The Solution

**For unit tests (sourcing common.sh):** Disable strict mode immediately after sourcing:

```bash
setup() {
    ...
    source "${SCRIPTS_DIR}/common.sh"
    set +eEuo pipefail
    trap - ERR
}
```

This is safe because:
1. All library functions are already defined (sourcing completed successfully)
2. The test harness controls execution, not strict mode
3. This matches exactly what the existing test-arg-parsing.sh does (line 187-189)

**For integration tests (running scripts as subprocesses):** No issue. The `run` command executes in a subshell. The script's strict mode is contained within that subshell. BATS captures the exit code regardless.

### The cleanup.sh EXIT Trap Interaction

`lib/cleanup.sh` registers an EXIT trap. When sourced in a unit test:

1. The EXIT trap will fire when the BATS test subprocess exits
2. It will try to clean up `$_CLEANUP_BASE_DIR`
3. This is harmless -- it cleans a temp directory

However, if a test creates files via `make_temp`, those files are properly cleaned up by the EXIT trap. This is actually beneficial -- no test-specific cleanup code needed.

**No special handling required.** The EXIT trap and BATS coexist correctly because each @test runs in its own subshell.

## Patterns to Follow

### Pattern 1: One .bats File Per Module

**What:** Each lib/*.sh module gets a corresponding tests/lib/*.bats file.
**When:** Always, for library modules.
**Why:** Clear mapping between source and test. Easy to find tests. Easy to run a single module's tests (`bats tests/lib/args.bats`).

### Pattern 2: setup() Loads, @test Asserts

**What:** All sourcing and environment setup happens in `setup()`. Test bodies only call functions and assert.
**When:** All test files.
**Why:** BATS documentation explicitly warns against loading files outside of functions. Setup failures get better diagnostics when they occur in `setup()`.

```bash
# GOOD:
setup() {
    load 'helpers/common-setup'
    _common_setup
    source "${SCRIPTS_DIR}/common.sh"
    set +eEuo pipefail
    trap - ERR
}

@test "require_target exits on empty arg" {
    run require_target ""
    assert_failure
}

# BAD:
load 'helpers/common-setup'    # Outside function -- poor diagnostics on failure
source "/path/to/common.sh"    # Outside function -- runs n+1 times
```

### Pattern 3: Use `run` for Anything That Might Fail

**What:** Wrap function calls in `run` when testing failure cases.
**When:** Testing exit codes, error messages, functions that call `exit`.
**Why:** Without `run`, a function that calls `exit 1` will exit the entire test process (even with `set +e`, because `exit` is not a command failure -- it is an explicit exit). The `run` command executes in a subshell, containing the `exit`.

```bash
# GOOD:
@test "require_cmd fails when tool missing" {
    run require_cmd nonexistent_tool_xyz
    assert_failure
    assert_output --partial "not installed"
}

# BAD (exits the test process):
@test "require_cmd fails when tool missing" {
    require_cmd nonexistent_tool_xyz    # Calls exit 1 -> kills test
    # Never reaches here
}
```

### Pattern 4: Integration Tests Use Full Script Paths

**What:** Integration tests run scripts via `bash "$full_path"`, not by sourcing.
**When:** Testing script-level behavior (help output, argument parsing, exit codes).
**Why:** Sourcing a script would execute it in the test process, including `exit` calls. Running as a subprocess isolates the script completely.

```bash
@test "nmap/examples.sh: --help exits 0" {
    run bash "${SCRIPTS_DIR}/nmap/examples.sh" --help
    assert_success
    assert_output --partial "Usage:"
}
```

### Pattern 5: Mock Commands for CI

**What:** Create stub executables on PATH to satisfy `require_cmd` checks in CI.
**When:** Integration tests that run scripts requiring tools not available in CI.
**Why:** The scripts exit immediately if `require_cmd` fails. Mocking the command lets the test proceed to validate help output, argument parsing, and other non-tool behavior.

```bash
setup() {
    load 'helpers/common-setup'
    _common_setup
    load 'helpers/mock-commands'
    create_mock_cmd "nmap"
}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Sourcing Scripts Instead of Running Them

**What:** Using `source scripts/nmap/examples.sh` in a test.
**Why bad:** The script calls `parse_common_args "$@"`, `require_target`, `safety_banner`, etc. These will execute in the test process. The `exit` in `require_target` will kill the test. The interactive prompt will hang.
**Instead:** Use `run bash "${SCRIPTS_DIR}/nmap/examples.sh" --help` for integration tests. Only source `common.sh` for unit testing library functions.

### Anti-Pattern 2: Testing Tool Behavior, Not Script Behavior

**What:** Writing tests that validate nmap actually scans ports.
**Why bad:** The project is an educational toolkit. Scripts print example commands -- they do not (by default) execute them. Tests should validate the script's output format, help text, argument parsing, and exit codes. Not the behavior of the underlying security tools.
**Instead:** Test that the script outputs expected example text, handles arguments correctly, and exits with correct codes.

### Anti-Pattern 3: One Giant .bats File

**What:** Putting all 300+ test cases in a single file.
**Why bad:** Slow to run (no parallelism within a file), hard to navigate, setup() becomes a kitchen sink.
**Instead:** Split by concern: lib/ unit tests per module, scripts/ integration tests per behavior category.

### Anti-Pattern 4: Migrating All Legacy Tests at Once

**What:** Rewriting test-arg-parsing.sh (268 checks) and test-library-loads.sh (39 checks) into BATS immediately.
**Why bad:** High risk of introducing regressions. The existing tests work and validate important behavior.
**Instead:** Keep legacy tests running in CI. Write new tests in BATS. Migrate legacy tests incrementally, one section at a time, verifying that the BATS version catches the same failures.

## Build Order (Dependency-Driven)

The following order respects dependencies between components:

### Step 1: BATS Infrastructure Setup

Create the test directory structure, common-setup.bash helper, and Makefile targets. Verify BATS can run a trivial test.

**Creates:** `tests/helpers/common-setup.bash`, `tests/setup_suite.bash`, Makefile `test` target
**Depends on:** Nothing (foundational)
**Risk:** LOW

### Step 2: CI Workflow

Add `.github/workflows/tests.yml` with bats-action and legacy test job. Verify both BATS and legacy tests run in CI.

**Creates:** `.github/workflows/tests.yml`
**Depends on:** Step 1 (needs at least one .bats file to run)
**Risk:** LOW

### Step 3: Unit Tests for Library Modules

Write tests/lib/*.bats for each lib module, starting with the most critical: args.bats (parse_common_args), validation.bats (require_cmd, require_target), logging.bats.

**Creates:** `tests/lib/args.bats`, `tests/lib/validation.bats`, `tests/lib/logging.bats`, `tests/lib/cleanup.bats`, `tests/lib/output.bats`
**Depends on:** Step 1 (helpers must exist)
**Risk:** LOW

### Step 4: Integration Tests for Script Behavior

Write tests/scripts/*.bats that test --help, -x rejection, and argument handling across all scripts. Add mock-commands.bash helper.

**Creates:** `tests/scripts/help-flags.bats`, `tests/scripts/execute-mode.bats`, `tests/helpers/mock-commands.bash`
**Depends on:** Step 1, Step 3 (unit tests should pass first)
**Risk:** LOW

### Step 5: Script Metadata Headers

Add structured comment headers to all 66 scripts. Write tests/scripts/header-metadata.bats to validate headers.

**Creates:** Header blocks in all scripts, `tests/scripts/header-metadata.bats`
**Depends on:** Step 1 (BATS infrastructure), Step 4 (integration test patterns established)
**Risk:** LOW (headers are comments, zero behavioral change)

### Step 6: Incremental Legacy Test Migration

Migrate sections of test-arg-parsing.sh to BATS format, one section at a time. Remove from legacy script once BATS equivalent passes.

**Modifies:** `tests/test-arg-parsing.sh` (shrinks), `tests/lib/args.bats` (grows), `tests/scripts/help-flags.bats` (grows)
**Depends on:** Steps 3-4 (BATS patterns proven)
**Risk:** LOW per section

## Files Changed / Created Summary

| File | Status | Purpose |
|------|--------|---------|
| `tests/helpers/common-setup.bash` | NEW | Shared BATS setup helper |
| `tests/helpers/mock-commands.bash` | NEW | Command stubs for CI |
| `tests/lib/args.bats` | NEW | Unit tests for parse_common_args |
| `tests/lib/validation.bats` | NEW | Unit tests for require_cmd, etc. |
| `tests/lib/logging.bats` | NEW | Unit tests for logging functions |
| `tests/lib/cleanup.bats` | NEW | Unit tests for make_temp, etc. |
| `tests/lib/output.bats` | NEW | Unit tests for run_or_show, etc. |
| `tests/scripts/help-flags.bats` | NEW | All scripts --help exits 0 |
| `tests/scripts/execute-mode.bats` | NEW | All scripts -x rejects non-interactive |
| `tests/scripts/header-metadata.bats` | NEW | Validate header metadata fields |
| `tests/setup_suite.bash` | NEW | Optional suite-level setup |
| `.github/workflows/tests.yml` | NEW | CI workflow for BATS + legacy tests |
| `Makefile` | MODIFIED | Add `test`, `test-legacy`, `test-all` targets |
| `scripts/**/*.sh` (66 files) | MODIFIED | Add structured comment header blocks |
| `tests/test-arg-parsing.sh` | KEPT | Legacy tests, migrate incrementally |
| `tests/test-library-loads.sh` | KEPT | Legacy tests, migrate incrementally |

## Sources

### HIGH Confidence
- [BATS-core Writing Tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- Official documentation on setup/teardown, load, run, bats_load_library
- [BATS-core Tutorial](https://bats-core.readthedocs.io/en/stable/tutorial.html) -- Official tutorial on project structure, common-setup pattern
- [bats-core/bats-action](https://github.com/bats-core/bats-action) -- Official GitHub Action (v4.0.0, released 2026-02-08)
- [bats-core/bats-assert](https://github.com/bats-core/bats-assert) -- Assertion library documentation (assert_success, assert_output, assert_line)
- [bats-core/bats-support](https://github.com/bats-core/bats-support) -- Required dependency of bats-assert

### MEDIUM Confidence
- [HackerOne: Testing Bash Scripts with BATS](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide) -- Practical patterns for testing bash scripts with BATS
- [Baeldung: Testing Bash Scripts with Bats](https://www.baeldung.com/linux/testing-bash-scripts-bats) -- Tutorial on BATS test organization

### Codebase Analysis (Direct Observation)
- `tests/test-arg-parsing.sh` -- 268 checks, existing test patterns for arg parsing and script behavior
- `tests/test-library-loads.sh` -- 39 checks, existing patterns for function/variable validation
- `scripts/common.sh` -- Entry point sourcing 9 lib modules
- `scripts/lib/strict.sh` -- Strict mode and ERR trap (critical BATS interaction point)
- `scripts/lib/args.sh` -- parse_common_args (primary unit test target)
- `.github/workflows/shellcheck.yml` -- Existing CI workflow pattern
- `.shellcheckrc` -- Existing ShellCheck configuration
