# Feature Landscape: BATS Testing Framework & Script Metadata Headers

**Domain:** Bash test infrastructure and script documentation standards
**Researched:** 2026-02-11
**Overall confidence:** HIGH (BATS), HIGH (Headers)

## Context: Why This Milestone Now

The previous milestone explicitly listed "Comprehensive unit testing (bats/shunit2)" as an anti-feature. That made sense when the codebase was 17 thin wrapper scripts. The codebase has since grown to 81 scripts with 9 library modules, a shared argument parser, dual-mode execution, and 307 ad-hoc test assertions split across two custom test harnesses (`test-arg-parsing.sh` with 268 checks, `test-library-loads.sh` with 39 checks). The ad-hoc harnesses are brittle (hand-rolled pass/fail counting, manual strict-mode toggling, hardcoded script lists) and unmaintainable. The library surface area (`lib/*.sh`) now warrants real unit tests, not just smoke tests.

Similarly, "Script metadata headers" was deferred. With 81 scripts, the lack of structured headers makes automated tooling (documentation generation, dependency auditing, test discovery) impractical. This milestone addresses both.

---

## Table Stakes

Features users/developers expect when a bash project claims "tested" or "documented." Missing any of these makes the testing/header system feel incomplete or amateurish.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| BATS as test runner | De facto standard for bash testing. Only maintained TAP-compliant bash test framework. No serious alternative exists. | Low | `brew install bats-core` or `npm install --save-dev bats`. v1.13.0 is current. |
| `bats-assert` for assertions | `run` + `[ "$status" -eq 0 ]` is verbose and error-prone. `assert_success`, `assert_output --partial` are readable and produce clear failure messages. | Low | Official companion library. v2.1.0. |
| `bats-support` helper library | Required dependency of `bats-assert`. Provides output formatting for assertion failures. | Low | v0.3.0. Must be loaded before `bats-assert`. |
| Unit tests for all 9 `lib/*.sh` modules | Library functions are the foundation -- every script sources them. Bugs here propagate everywhere. The ad-hoc `test-library-loads.sh` only checks "function exists", not behavior. | Medium | 9 modules: strict, colors, logging, validation, cleanup, output, args, diagnostic, nc_detect. |
| `--help` output tests for all scripts | Currently tested ad-hoc in `test-arg-parsing.sh` with a hardcoded list of 46 use-case scripts. New scripts get missed. BATS can discover `.sh` files dynamically. | Low | Replace the manual `USE_CASE_SCRIPTS` array with glob-based discovery. |
| `-x` rejection tests for non-interactive stdin | Currently tested ad-hoc. Same hardcoded-list problem. | Low | Migrate existing assertions to BATS `run` + `assert_failure`. |
| `make test` target | Standard entry point. Every developer expects `make test` to run the test suite. | Low | One Makefile line: `bats tests/` |
| CI integration (GitHub Actions) | Tests that only run locally are tests that drift. Project already has a ShellCheck CI workflow. | Low | Official `bats-core/bats-action@4.0.0` handles installation of BATS + all helper libraries. |
| Structured script header on every `.sh` file | Every script should be self-documenting: what it does, what it requires, how to use it. Currently headers are ad-hoc single-line comments. | Medium | 81 files to update, but mechanical/template-driven. |

## Differentiators

Features that go beyond "tested bash project" and make this toolkit's test/documentation infrastructure notably professional.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `bats-file` for filesystem assertions | `cleanup.sh` creates temp files/dirs. Testing temp file creation, cleanup-on-exit, and directory structure is clunky with raw assertions. `assert_file_exists`, `assert_dir_exists` read clearly. | Low | Official companion library. v0.4.0. |
| Test tags for categorization | Tag tests as `unit`, `integration`, `slow`, `requires:nmap`, etc. Run subsets: `bats --filter-tags unit tests/`. CI runs `unit` tests; full suite runs locally. | Low | Built into BATS v1.7.0+. Syntax: `# bats test_tags=unit,lib:args` |
| `setup_file` for expensive initialization | Source `common.sh` once per file (not per test). Reduces test suite runtime by avoiding 9-module source chain on every `@test`. | Low | Built into BATS. Export variables from `setup_file` for use in tests. |
| Shared test helper (`test_helper/common-setup.bash`) | Centralize library loading, PATH setup, and fixture paths. Prevents duplication across test files. | Low | Standard BATS pattern from official tutorial. |
| `parse_common_args` parameterized tests | Test every flag combination (`-v`, `-q`, `-x`, `--`, unknown flags, flag ordering, empty args). Currently 15 hand-rolled test blocks. BATS makes each a clean `@test` with proper isolation. | Medium | Each `@test` runs in its own subshell -- no state leakage between flag tests. Key improvement over current harness where `set +eEuo pipefail` must be manually re-applied. |
| Machine-parseable metadata headers | Headers that follow a consistent format enable: automated `--help` generation, dependency graphing, test coverage reporting, documentation site generation. | Medium | Not just comments -- structured key-value pairs that tooling can extract with `grep`/`awk`. |
| `# @description` / `# @dep` shdoc-compatible annotations | Use the shdoc convention for library function documentation. Enables auto-generating API docs from source code. | Low | shdoc is a lightweight awk-based doc generator. Tags: `@description`, `@arg`, `@exitcode`, `@stdout`, `@see`. |
| JUnit report output for CI | `bats --report-formatter junit --output reports/` produces XML that GitHub Actions natively renders as test annotations. | Low | Built into BATS. Zero additional dependencies. |
| `skip` for missing tool dependencies | Many scripts `require_cmd nmap`. Tests should `skip "nmap not installed"` rather than fail on CI runners without pentesting tools. | Low | Built into BATS. Pattern: `command -v nmap || skip "nmap not installed"` |
| Parallel test execution | 81 scripts means potentially hundreds of tests. `bats --jobs 4` runs test files in parallel. | Low | Built into BATS. Requires GNU parallel or shenwei356/rush. |

## Anti-Features

Features to explicitly NOT build. Each is tempting but wrong for this project.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Mocking framework (e.g., bats-mock) | Scripts are thin wrappers around real tools. Mocking `nmap` to return fake output tests the mock, not the script. The value is in testing the framework (args, logging, cleanup), not tool output. | Test library functions directly. Test script CLI behavior (exit codes, `--help` output). Skip tests requiring unavailable tools. |
| 100% code coverage target | Use-case scripts are educational templates -- testing that `info "1) Ping scan"` prints the right string is low-value busywork. Focus coverage on `lib/*.sh` functions where bugs actually matter. | Cover all library functions. Cover all CLI contract behaviors (--help, -x, -v, -q). Skip example output verification. |
| End-to-end tests against Docker lab targets | Requires Docker running, images pulled, services healthy. Slow, flaky, environment-dependent. Makes CI fragile. | Integration tests that verify script startup behavior (sources correctly, parses args, reaches tool invocation point). Docker lab testing stays manual. |
| Custom test reporter | BATS has TAP, pretty, TAP13, and JUnit built in. Writing a custom reporter is maintenance overhead for no benefit. | Use `--formatter pretty` locally, `--report-formatter junit` in CI. |
| Generating `--help` output from headers | Tempting to DRY the header metadata and `show_help()`. But `show_help()` already exists in all 81 scripts with carefully formatted output including examples. Replacing it with auto-generation changes existing behavior and breaks backward compatibility. | Keep `show_help()` as-is. Headers provide machine-readable metadata. `show_help()` provides human-readable help. They serve different audiences. |
| Versioning individual scripts | Adding `# Version: 1.0.0` to each script creates 81 version numbers to manage. The project uses git -- version is the commit hash. | Use `# Since: phase-XX` to track when a script was introduced/last-modified. Git blame handles the rest. |
| Complex header parsing in bash | Building an in-script metadata parser that reads its own headers at runtime adds complexity. Headers should be for external tooling, not self-inspection. | Headers are structured comments. External tools (grep, awk, shdoc) parse them. Scripts never read their own headers. |
| shunit2 as alternative test framework | shunit2 is older, less maintained, and uses xUnit-style setUp/tearDown naming. BATS has the larger community, better CI integration, and official GitHub Action. shunit2 would be a contrarian choice with no benefits. | Use BATS exclusively. |

## Feature Dependencies

```
BATS Framework Setup
  |-> Install bats-core (brew or npm)
  |-> Install bats-support, bats-assert, bats-file
  |-> Create test_helper/common-setup.bash
  |-> Create tests/ directory structure
  |-> Add make test target
  Depends on: Nothing (fresh infrastructure)

Library Unit Tests (lib/*.sh)
  |-> tests/lib/strict.bats
  |-> tests/lib/colors.bats
  |-> tests/lib/logging.bats
  |-> tests/lib/validation.bats
  |-> tests/lib/cleanup.bats
  |-> tests/lib/output.bats
  |-> tests/lib/args.bats
  |-> tests/lib/diagnostic.bats
  |-> tests/lib/nc_detect.bats
  Depends on: BATS Framework Setup

Script Integration Tests
  |-> tests/scripts/help-flag.bats (all 81 scripts --help)
  |-> tests/scripts/execute-mode.bats (all scripts -x rejection)
  |-> tests/scripts/common-args.bats (flag behavior)
  Depends on: BATS Framework Setup

CI Integration
  |-> .github/workflows/test.yml
  |-> Uses bats-core/bats-action@4.0.0
  |-> JUnit report output
  Depends on: BATS Framework Setup, at least some tests written

Metadata Headers
  |-> Define header format/schema
  |-> Update all 9 lib/*.sh modules
  |-> Update all 17 examples.sh scripts
  |-> Update all 46 use-case scripts
  |-> Update remaining scripts (check-tools.sh, diagnostics, etc.)
  Depends on: Nothing (can be done in parallel with BATS)

Ad-hoc Test Migration
  |-> Migrate test-arg-parsing.sh assertions -> BATS tests
  |-> Migrate test-library-loads.sh assertions -> BATS tests
  |-> Retire old test harnesses (or keep as legacy reference)
  Depends on: Library Unit Tests, Script Integration Tests
```

## Test Categories: What to Test and How

### Category 1: Library Function Unit Tests (HIGH priority)

Pure function testing. Source the library, call the function, check the result.

**Target:** All 9 `lib/*.sh` modules, ~30-40 exported functions.

| Module | Functions to Test | Key Test Cases | Complexity |
|--------|-------------------|----------------|------------|
| `args.sh` | `parse_common_args` | `-h` calls show_help and exits 0; `-v` sets VERBOSE/LOG_LEVEL; `-q` sets LOG_LEVEL=warn; `-x` sets EXECUTE_MODE=execute; `--` stops parsing; unknown flags pass through; empty args; flag after positional; multiple flags combined | Medium |
| `logging.sh` | `info`, `success`, `warn`, `error`, `debug`, `_should_log`, `_log_level_num` | Each function outputs correct prefix; LOG_LEVEL filtering works; VERBOSE enables timestamps; error() always visible; debug() hidden by default; NO_COLOR disables ANSI codes | Medium |
| `validation.sh` | `require_root`, `check_cmd`, `require_cmd`, `require_target` | `check_cmd bash` returns 0; `check_cmd nonexistent_cmd` returns 1; `require_cmd bash` succeeds; `require_cmd nonexistent_cmd` exits 1 with error message; `require_target ""` exits 1; `require_target host` succeeds | Low |
| `cleanup.sh` | `make_temp`, `register_cleanup`, `retry_with_backoff` | `make_temp` creates file in `$_CLEANUP_BASE_DIR`; `make_temp dir` creates directory; files cleaned on exit; `register_cleanup` runs commands on exit; `retry_with_backoff` retries N times; backoff respects delay | Medium |
| `colors.sh` | Color variable definitions | All 6 color vars defined; NO_COLOR empties all vars; non-terminal empties all vars | Low |
| `output.sh` | `safety_banner`, `is_interactive`, `run_or_show`, `confirm_execute`, `PROJECT_ROOT` | `safety_banner` outputs AUTHORIZED USE; `is_interactive` detects terminal; `run_or_show` in show mode prints command; `run_or_show` in execute mode runs command; `confirm_execute` skips in show mode; `PROJECT_ROOT` resolves correctly | Medium |
| `strict.sh` | Strict mode activation, ERR trap | `set -e` is active after sourcing; `set -u` is active; `set -o pipefail` is active; ERR trap produces stack trace on failure | Low |
| `diagnostic.sh` | `report_pass/fail/warn/skip`, `report_section`, `run_check` | Each report function outputs correct prefix; `run_check` reports pass on success; `run_check` reports fail on failure; timeout handling works | Low |
| `nc_detect.sh` | `detect_nc_variant` | Returns one of: ncat, gnu, traditional, openbsd; handles missing nc gracefully | Low |

**BATS pattern for library testing:**

```bash
# tests/lib/validation.bats
setup() {
    load '../test_helper/common-setup'
}

@test "check_cmd returns 0 for installed command" {
    run check_cmd bash
    assert_success
}

@test "check_cmd returns 1 for missing command" {
    run check_cmd definitely_not_a_real_command_xyz
    assert_failure
}

@test "require_target exits 1 on empty string" {
    run require_target ""
    assert_failure
    assert_output --partial "Usage:"
}
```

### Category 2: Script CLI Contract Tests (HIGH priority)

Test that every script honors the CLI contract: `--help` exits 0, `-x` rejects non-interactive stdin, `parse_common_args` is present.

**Target:** All 81 scripts.

| Test | What It Verifies | Current Coverage | Migration Path |
|------|-----------------|------------------|----------------|
| `--help` exits 0 | CLI contract | 63 scripts tested (17 examples + 46 use-case) in `test-arg-parsing.sh` | Glob-discover all `*.sh` in scripts/, run `--help`, `assert_success` |
| `--help` contains "Usage:" | Help format contract | Same 63 scripts | `assert_output --partial "Usage:"` |
| `-h` exits 0 | Short flag parity | Only nmap tested | Include in glob discovery |
| `-x` rejects piped stdin | Safety contract | 63 scripts tested | `run bash "$script" -x 2>&1`, `assert_failure` |
| `parse_common_args` present | Code pattern | 46 use-case scripts via grep | `grep -q parse_common_args "$script"` in `@test` |
| Sources common.sh | Dependency contract | Not tested | `grep -q 'source.*common.sh' "$script"` |

**Key improvement:** Dynamic discovery replaces hardcoded arrays. No more forgetting to add new scripts to the test list.

**BATS pattern for script contract tests:**

```bash
# tests/scripts/help-flag.bats
setup_file() {
    export PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

# Dynamically discover scripts -- run once to populate array
setup() {
    load '../test_helper/common-setup'
}

@test "nmap/examples.sh --help exits 0" {
    run bash "$PROJECT_ROOT/scripts/nmap/examples.sh" --help
    assert_success
    assert_output --partial "Usage:"
}
```

### Category 3: Edge Case and Regression Tests (MEDIUM priority)

Test specific behaviors that have caused bugs or confusion.

| Test | What It Catches | Notes |
|------|----------------|-------|
| Empty REMAINING_ARGS under `set -u` | Unbound variable error from `${REMAINING_ARGS[@]}` on empty array | Was a real bug. `${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}` pattern exists as fix. |
| `--` stops flag parsing | Arguments after `--` must not be parsed as flags | `parse_common_args -- -x target` should leave EXECUTE_MODE=show |
| Flag after positional arg | `script.sh target -x` must still detect `-x` | Current parser handles this; test prevents regression |
| Double-sourcing prevention | Sourcing common.sh twice must not error or duplicate traps | Source guards (`_COMMON_LOADED`) protect this |
| NO_COLOR disables ANSI | `NO_COLOR=1 script.sh` must produce clean output | Color variables set to empty strings |
| Cleanup on EXIT | Temp files must be removed even after errors | `make_temp` + forced exit should leave no files |
| ERR trap stack trace | Failing command should produce readable stack trace | Test that error output contains "at ... in file:line" |
| Bash 4.0+ gate | Running under old bash should produce clear error | Hard to test in BATS (BATS itself needs bash) -- skip |

### Category 4: Smoke/Sanity Tests (LOW priority -- already covered)

These exist in `test-library-loads.sh` and are worth migrating but are not high priority since they test "does it load" not "does it work."

| Test | Current Coverage | Migration Priority |
|------|-----------------|-------------------|
| All functions defined after sourcing | 39 checks in test-library-loads.sh | LOW -- unit tests implicitly cover this |
| Source guards set | 9 guards checked | LOW -- covered by double-source test |
| PROJECT_ROOT resolves | 3 checks | LOW -- covered by output.sh tests |
| Color variables declared | 6 checks | LOW -- covered by colors.sh tests |

---

## Header Format: Recommended Schema

### For Library Modules (`lib/*.sh`)

Use shdoc-compatible annotations for function documentation, plus structured file-level metadata.

```bash
#!/usr/bin/env bash
# @file validation.sh
# @brief Command and target validation functions
# @description
#   Provides require_root, check_cmd, require_cmd, require_target.
#   Sourced via common.sh -- never executed directly.

# Source guard -- prevent double-sourcing
[[ -n "${_VALIDATION_LOADED:-}" ]] && return 0
_VALIDATION_LOADED=1

# @description Check if a command exists on PATH
# @arg $1 string Command name to check
# @exitcode 0 Command found
# @exitcode 1 Command not found
check_cmd() {
    command -v "$1" &>/dev/null
}
```

**File-level fields:**
| Field | Required | Purpose |
|-------|----------|---------|
| `@file` | Yes | Filename (matches actual filename) |
| `@brief` | Yes | One-line summary (what `grep` extracts) |
| `@description` | No | Multi-line explanation (for doc generation) |

**Function-level fields:**
| Field | Required | Purpose |
|-------|----------|---------|
| `@description` | Yes (for public functions) | What the function does |
| `@arg` | Yes (if args taken) | `$1 type Description` format |
| `@exitcode` | Yes (if non-trivial) | Document exit codes |
| `@stdout` | No | What the function prints |
| `@stderr` | No | What goes to stderr |
| `@see` | No | Cross-references to related functions |
| `@internal` | No | Mark private/helper functions |

### For Executable Scripts (`examples.sh`, use-case scripts)

Use a simpler comment-based header. These are not library code -- they are user-facing tools.

```bash
#!/usr/bin/env bash
# @file nmap/discover-live-hosts.sh
# @brief Find all active hosts on a subnet
# @description
#   Discovers live hosts on a network using various probe techniques.
#   Uses ping sweeps, ARP, TCP, UDP, and ICMP methods.
#
# @dep nmap "brew install nmap"
# @default-target localhost
source "$(dirname "$0")/../common.sh"
```

**Script-level fields:**
| Field | Required | Purpose |
|-------|----------|---------|
| `@file` | Yes | Relative path from scripts/ (matches directory structure) |
| `@brief` | Yes | One-line summary |
| `@description` | No | Multi-line explanation |
| `@dep` | Yes | Tool dependency and install hint. Format: `command "install_hint"`. Matches `require_cmd` calls. |
| `@default-target` | No | Default target value if script has one |

### Why This Format

1. **shdoc compatibility:** The `@description`, `@arg`, `@exitcode` tags are shdoc standard. Can generate Markdown API docs from library modules.
2. **Simple extraction:** `grep '^# @brief' scripts/**/*.sh` produces a one-line index of every script.
3. **Dependency auditing:** `grep '^# @dep' scripts/**/*.sh` lists every external tool dependency.
4. **Minimal disruption:** Existing single-line headers (`# nmap/examples.sh -- Network Mapper...`) are replaced, not supplemented. No duplication.
5. **No runtime impact:** Headers are comments. Zero performance or behavioral change.

### What NOT to Include in Headers

| Field | Why Exclude |
|-------|-------------|
| Author | Single-author project. Git blame covers this. |
| Date | Git log covers this. Dates in headers go stale immediately. |
| Version | Not versioning individual scripts. Git commit is the version. |
| License | One LICENSE file at repo root covers all scripts. |
| Copyright | Same reason as License. |
| Changelog | Git log. |
| TODO | Use issue tracker or `.planning/`. |

---

## MVP Recommendation

Prioritize:
1. **BATS framework setup** -- Install bats-core + helper libraries, create test directory structure, shared test helper, `make test` target. Foundation for everything else. (LOW complexity, HIGH value)
2. **Library unit tests (`lib/*.sh`)** -- Test all 9 modules' exported functions. This is where bugs actually matter. Migrate and expand on `test-library-loads.sh` and the unit test sections of `test-arg-parsing.sh`. (MEDIUM complexity, HIGH value)
3. **Script CLI contract tests** -- `--help` and `-x` tests for all 81 scripts using dynamic discovery. Replaces the brittle hardcoded-list approach. (LOW complexity, HIGH value)
4. **CI integration** -- GitHub Actions workflow using `bats-core/bats-action@4.0.0`. JUnit report output. (LOW complexity, HIGH value)
5. **Metadata headers on library modules** -- Update 9 `lib/*.sh` files with shdoc-compatible annotations. Smallest batch, highest documentation value per file. (LOW complexity, MEDIUM value)
6. **Metadata headers on all scripts** -- Update remaining 72 scripts with structured headers. Mechanical but large. (MEDIUM complexity, MEDIUM value)

Defer:
- **Parallel test execution** -- Only matters once the test suite is large enough to be slow. Optimize later.
- **shdoc documentation generation** -- The headers should be written now (for future tooling), but actually running shdoc to generate docs is a separate milestone.
- **Retiring old test harnesses** -- Keep `test-arg-parsing.sh` and `test-library-loads.sh` until BATS tests fully cover their assertions, then remove.

## Key Technical Considerations

### BATS + Strict Mode Interaction

The project uses `set -eEuo pipefail` in `strict.sh`. BATS uses `set -e` internally for test failure detection. Key implications:

1. **`run` absorbs exit codes** -- `run` executes in a subshell and captures `$status`. This neutralizes `set -e` inside `run`. Functions tested via `run` will not cause test abort on failure -- the failure is captured in `$status`.
2. **Direct calls propagate `set -e`** -- Calling a function WITHOUT `run` means `set -e` applies. A failing assertion or unexpected exit will abort the test (which is correct behavior).
3. **`set -u` in sourced libraries** -- When tests `source common.sh`, `set -u` activates. Tests must not reference unset variables. Use `${VAR:-}` pattern in test code.
4. **ERR trap conflicts** -- The project's ERR trap (`_strict_error_handler`) will fire in test context. This is noise, not signal. Tests should `trap - ERR` after sourcing common.sh.

**Recommended test helper pattern:**

```bash
# test_helper/common-setup.bash
_common_setup() {
    load 'bats-support/load'
    load 'bats-assert/load'
    load 'bats-file/load'

    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export PROJECT_ROOT

    # Source common.sh for library function access
    # Then disable strict mode artifacts that interfere with BATS
    source "$PROJECT_ROOT/scripts/common.sh"
    set +eEu  # Let BATS handle error detection
    trap - ERR  # Remove project ERR trap (BATS has its own)
    set -o pipefail  # Keep pipefail -- it's useful in tests too
}
```

### load vs source for `.sh` Files

BATS `load` only loads `.bash` files (appends `.bash` automatically). The project's libraries are `.sh` files. Use `source` directly for project libraries, `load` for BATS helpers.

### Test File Organization

```
tests/
  test_helper/
    bats-support/     (git submodule or npm)
    bats-assert/      (git submodule or npm)
    bats-file/        (git submodule or npm)
    common-setup.bash
  lib/
    args.bats
    cleanup.bats
    colors.bats
    diagnostic.bats
    logging.bats
    nc_detect.bats
    output.bats
    strict.bats
    validation.bats
  scripts/
    help-flag.bats
    execute-mode.bats
  integration/
    common-args.bats
    edge-cases.bats
```

## Sources

- [bats-core official documentation](https://bats-core.readthedocs.io/en/stable/) -- Writing tests, installation, usage, gotchas (HIGH confidence)
- [bats-core GitHub repository](https://github.com/bats-core/bats-core) -- v1.13.0, Nov 2025 (HIGH confidence)
- [bats-core/bats-action GitHub Action](https://github.com/bats-core/bats-action) -- v4.0.0, Feb 2026 (HIGH confidence)
- [BATS writing tests documentation](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- run helper, setup/teardown, tags, special variables (HIGH confidence)
- [BATS gotchas documentation](https://bats-core.readthedocs.io/en/stable/gotchas.html) -- set -e conflicts, negation, subshell scope (HIGH confidence)
- [BATS tutorial](https://bats-core.readthedocs.io/en/stable/tutorial.html) -- Project layout, test_helper pattern, library loading (HIGH confidence)
- [BATS usage documentation](https://bats-core.readthedocs.io/en/stable/usage.html) -- --jobs, --formatter, --filter-tags, --report-formatter (HIGH confidence)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) -- File headers, function documentation (HIGH confidence)
- [shdoc documentation generator](https://github.com/reconquest/shdoc) -- @description, @arg, @exitcode annotations (MEDIUM confidence)
- [bats-core/bats-file](https://github.com/bats-core/bats-file) -- Filesystem assertions (HIGH confidence)
- Codebase analysis: direct reading of all 81 scripts, 9 lib modules, 2 existing test harnesses, Makefile (HIGH confidence)
- [Bash Script Header Conventions](https://bashcommands.com/bash-script-header) -- Header format patterns (MEDIUM confidence)
- [bats-core strict mode issue #36](https://github.com/bats-core/bats-core/issues/36) -- set -eEuo pipefail compatibility discussion (MEDIUM confidence)
