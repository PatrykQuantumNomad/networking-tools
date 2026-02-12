# Domain Pitfalls: Adding BATS Tests and Script Metadata Headers

**Domain:** Adding BATS test framework and structured script headers to an existing bash pentesting toolkit with 81 scripts using strict mode, traps, source guards, and interactive prompts
**Researched:** 2026-02-11
**Overall confidence:** HIGH -- pitfalls verified against BATS official documentation, bats-core GitHub issues, and actual codebase patterns in this repository

## Critical Pitfalls

Mistakes that cause test suites to silently pass when they should fail, break all 81 existing scripts, or require rearchitecting the test approach.

---

### Pitfall 1: `set -u` in sourced scripts blows up BATS internal variables

**What goes wrong:** Every script in this project sources `common.sh`, which loads `strict.sh`, which enables `set -eEuo pipefail`. When a BATS test sources `common.sh` (either directly or via the script under test), `set -u` (nounset) takes effect in the BATS process. BATS uses internal variables like `BATS_CURRENT_STACK_TRACE[@]`, `BATS_TEST_SKIPPED`, and others that may be unset at certain points in the test lifecycle. With `set -u` active, referencing these unset BATS internals causes unbound variable errors that either crash the test runner or produce silent failures with no diagnostic output.

**Why it happens:** BATS files are not executed straight through like normal scripts. BATS uses a specialized evaluation process that preprocesses `@test` blocks into functions, manages its own traps, and maintains internal state variables. When strict mode is inherited from sourced library code, it contaminates BATS's own execution environment. The `-u` flag is the worst offender because BATS's internal arrays (like stack traces) are legitimately empty/unset at various points.

**Consequences:** Tests crash with cryptic unbound variable errors pointing to BATS internals, not your code. Or worse: tests silently pass when they should fail because the error handling machinery itself fails. On macOS with Bash 3.2 (which ships as default), `set -u` combined with `set -e` can set exit status to zero instead of one for unbound variable access, causing the ERR trap to never fire and test failures to go completely undetected.

**Prevention:**
1. Never source `common.sh` at the BATS file level. Source it inside `setup()` or inside specific `@test` blocks.
2. Use `set +u` in `teardown()` to ensure BATS internals are not affected after test code runs.
3. Better: create a `test_helper.bash` that sources `common.sh` within a controlled scope, resetting nounset after loading:
   ```bash
   # test/test_helper.bash
   load_common() {
       source "${BATS_TEST_DIRNAME}/../scripts/common.sh"
   }

   teardown() {
       set +u  # Protect BATS internals from nounset
   }
   ```
4. When testing library functions directly (unit tests), source only the specific `lib/*.sh` module needed, not the full `common.sh` chain.

**Detection:** Run the test suite and look for errors mentioning `BATS_` variables as unbound, or tests that produce no output at all (no pass/fail indication).

**Affected components:** All 81 scripts source `common.sh` which loads `strict.sh` with `set -eEuo pipefail`. All 9 `lib/*.sh` modules have source guards that use `return 0`, which is safe. The danger is the `set -u` propagation.

**Phase mapping:** Address in the very first test infrastructure phase, before writing any actual tests. The test helper pattern must be established first.

**Confidence:** HIGH -- verified against bats-core issues [#81](https://github.com/bats-core/bats-core/issues/81), [#213](https://github.com/bats-core/bats-core/issues/213), [#423](https://github.com/bats-core/bats-core/issues/423), and the actual `strict.sh` in this codebase.

---

### Pitfall 2: BATS's own ERR trap conflicts with the project's `_strict_error_handler` trap

**What goes wrong:** This project registers `trap '_strict_error_handler' ERR` in `strict.sh` (line 36). BATS also registers its own ERR trap (`bats_error_trap`) to detect test failures and capture stack traces. Only one ERR trap can be active at a time in bash. When a test sources `common.sh`, the project's ERR trap overwrites BATS's ERR trap. This means BATS can no longer detect test failures through its normal mechanism -- it loses the ability to report which line failed and why.

**Why it happens:** In bash, `trap 'handler' ERR` replaces any previous ERR trap. The `-E` flag (errtrace, which this project enables via `set -E`) causes ERR traps to be inherited by shell functions, command substitutions, and subshell environments, which makes the conflict worse -- the project's trap propagates everywhere. BATS expects to be in control of the ERR trap to detect assertion failures.

**Consequences:**
- Test failures produce the project's stack trace format (`[ERROR] Command failed at line X`) instead of BATS's diagnostic format, making failures hard to interpret.
- BATS may not detect failures at all if the project's error handler prints but does not exit with the correct status.
- The `bats_error_trap` never fires, so `$BATS_ERROR_STATUS` is never set, and test result reporting breaks.

**Prevention:**
1. When testing library functions (unit tests), source the specific `lib/*.sh` module without sourcing `strict.sh`. The source guards make this safe.
2. When integration-testing whole scripts, use `run` which executes in a subshell. The trap conflict only matters when sourcing into the same shell.
3. Create a `test_helper.bash` that saves and restores BATS's traps:
   ```bash
   # In setup(), after sourcing common.sh:
   # Re-establish BATS's ERR trap
   trap - ERR  # Clear project's trap in test context
   ```
4. For scripts that must be tested with strict.sh active, run them as subprocesses via `run bash scripts/nmap/examples.sh`, never via `source`.

**Detection:** Run a test that should fail (e.g., `false` as a test line). If BATS reports the test as passing, or if the failure output shows `[ERROR] Command failed` instead of BATS's normal format, the trap conflict is active.

**Affected components:** `scripts/lib/strict.sh` line 36: `trap '_strict_error_handler' ERR`. Also `set -E` on line 10 which causes ERR trap inheritance.

**Phase mapping:** Address alongside Pitfall 1 in test infrastructure setup. The test helper must manage trap lifecycle.

**Confidence:** HIGH -- verified by reading BATS's [tracing.bash](https://github.com/bats-core/bats-core/blob/master/lib/bats-core/tracing.bash) source and this project's `strict.sh`.

---

### Pitfall 3: EXIT trap from `cleanup.sh` fires during BATS teardown, deleting test fixtures

**What goes wrong:** The project's `cleanup.sh` registers `trap '_cleanup_handler' EXIT` (line 35), which deletes `$_CLEANUP_BASE_DIR` and runs all registered cleanup commands. When `common.sh` is sourced in a BATS test, this EXIT trap fires when the test process exits -- including during BATS's own teardown. If any test creates temporary files that reference the cleanup system, those files vanish before assertions can check them. More critically, `_cleanup_handler` calls `exit "$exit_code"` (line 31), which can interfere with BATS's exit trap chain.

**Why it happens:** BATS teardown runs in the same process as the test. When `common.sh` is sourced (not run via `run`), the EXIT trap is registered in the test process. BATS has its own EXIT trap (`bats_exit_trap`) for result reporting. Bash only allows one EXIT trap per process -- the last one registered wins. If the project's EXIT trap is registered after BATS's trap, BATS never reports results. If BATS's trap is registered after, the project's cleanup never runs (which may be fine for tests, but means cleanup-dependent behavior isn't tested).

**Consequences:**
- Temp files created via `make_temp()` are deleted before teardown assertions run.
- BATS result reporting may silently break (no TAP output).
- `_CLEANUP_BASE_DIR` is created via `mktemp` at source time (line 12 of cleanup.sh), meaning every test that sources `common.sh` creates a temp directory in `/tmp` that may or may not get cleaned up depending on trap ordering.

**Prevention:**
1. For unit tests of library functions, source only the specific module being tested, not the full `common.sh` chain. Skip `cleanup.sh` unless explicitly testing cleanup behavior.
2. For integration tests, always use `run` to execute scripts in a subshell. The EXIT trap fires in the subshell, not in the BATS process.
3. If you must source `common.sh` in a test, save and restore BATS's EXIT trap:
   ```bash
   setup() {
       # Let common.sh set up its traps in this scope
       source "${BATS_TEST_DIRNAME}/../scripts/common.sh"
       # BATS will re-establish its own EXIT trap after setup()
   }
   ```
4. Use `$BATS_TEST_TMPDIR` for test-specific temp files instead of the project's `make_temp()`. BATS manages its own temp directory lifecycle.

**Detection:** Check if `$BATS_RUN_TMPDIR` still exists after a test run. Check if TAP output is complete (every test shows ok/not ok).

**Affected components:** `scripts/lib/cleanup.sh` lines 12, 19-32, 35.

**Phase mapping:** Address in test infrastructure phase. Document in test helper which modules are safe to source directly.

**Confidence:** HIGH -- verified by reading `cleanup.sh` trap registration and BATS's EXIT trap chain documentation.

---

### Pitfall 4: Testing scripts that `exit 1` on missing tools kills the BATS process

**What goes wrong:** 66 scripts call `require_cmd` which runs `exit 1` when the required tool is not installed. In a CI environment or dev machine that lacks pentesting tools (nmap, sqlmap, aircrack-ng, etc.), sourcing these scripts causes `exit 1` to terminate the BATS process, not just fail the test. If a script is sourced (not `run`) and calls `require_cmd` during its execution flow, the entire test suite aborts.

**Why it happens:** `exit` in a sourced script exits the calling process. When you `source scripts/nmap/examples.sh` in a BATS test, the script's `require_cmd nmap` calls `exit 1` if nmap is not installed. This exits the BATS test process entirely. The `run` helper avoids this by executing in a subshell, but many test patterns involve sourcing for function access.

**Consequences:** One missing tool kills the entire test suite -- not just the one test, but all remaining tests in the file. No error message from BATS, just an abrupt exit.

**Prevention:**
1. Always use `run` when executing whole scripts: `run bash scripts/nmap/examples.sh target`. Never source a script that has top-level `require_cmd` calls.
2. For testing the library functions themselves, source only `lib/validation.sh` and test `require_cmd` in isolation:
   ```bash
   @test "require_cmd fails for missing command" {
       source "${BATS_TEST_DIRNAME}/../scripts/lib/validation.sh"
       run require_cmd nonexistent_tool_xyz
       [ "$status" -eq 1 ]
   }
   ```
3. Create stub commands in `$BATS_TEST_TMPDIR/bin` and prepend to PATH for integration tests:
   ```bash
   setup() {
       mkdir -p "${BATS_TEST_TMPDIR}/bin"
       # Create a stub that just exits 0
       echo '#!/bin/bash' > "${BATS_TEST_TMPDIR}/bin/nmap"
       echo 'echo "stub nmap"' >> "${BATS_TEST_TMPDIR}/bin/nmap"
       chmod +x "${BATS_TEST_TMPDIR}/bin/nmap"
       export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
   }
   ```
4. Categorize tests into "unit" (test library functions, no tools needed) and "integration" (test full scripts, stubs or real tools needed). Run unit tests in CI always; run integration tests only when tools are available.

**Detection:** Run the test suite on a machine without pentesting tools installed. If the suite produces fewer results than expected (or crashes entirely), this pitfall is active.

**Affected scripts:** 66 scripts call `require_cmd`. Tools required: nmap, tshark, msfconsole, hashcat, john, sqlmap, nikto, hping3, skipfish, aircrack-ng, gobuster, ffuf, dig, curl, nc, traceroute/mtr, foremost.

**Phase mapping:** Address in test architecture phase. The test categorization (unit vs integration) must be decided before writing tests.

**Confidence:** HIGH -- verified by reading `validation.sh` `require_cmd` function and counting 66 scripts that call it.

---

### Pitfall 5: `confirm_execute()` and interactive `read -rp` cause BATS tests to hang or fail

**What goes wrong:** 64 scripts call `confirm_execute()` which, in execute mode, runs `read -rp "Continue? [y/N]"`. Another 64 scripts have interactive demo sections with `[[ ! -t 0 ]] && exit 0` guards followed by `read -rp`. BATS does not provide a terminal on stdin -- `[[ -t 0 ]]` is false in BATS. For scripts with the guard, they exit early (which is fine). But `confirm_execute()` in execute mode checks `[[ ! -t 0 ]]` and calls `exit 1`, which (if sourced, not `run`) kills the BATS process.

**Why it happens:** BATS runs tests in a non-interactive shell. stdin is not a terminal. The `read` builtin returns exit code 1 on EOF. The `confirm_execute()` function explicitly rejects non-interactive execution with `exit 1`. These are all correct behaviors for production use, but they make direct testing impossible without either mocking stdin or ensuring scripts run in show mode (not execute mode).

**Consequences:**
- Tests hang if `read` is reached without the `-t 0` guard.
- Tests abort with exit 1 if `confirm_execute()` is reached in execute mode.
- Tests exit 0 silently if the `[[ ! -t 0 ]] && exit 0` guard triggers (which means the interactive demo section is never tested).

**Prevention:**
1. Default all tests to show mode (`EXECUTE_MODE=show`) unless specifically testing execute mode behavior.
2. For testing execute mode, pipe input to `run`: `echo "y" | run bash scripts/nmap/examples.sh -x target`. But note: this still fails the `-t 0` check. The script needs refactoring to accept a `--yes` or `--no-confirm` flag for testability, or use an environment variable like `NTOOL_NONINTERACTIVE=1`.
3. For testing the interactive demo section, accept that it cannot be tested in BATS directly. Test the individual commands it would run instead.
4. Use `run` (subshell) for all script-level tests. The `exit 0` from the non-interactive guard exits the subshell, not the BATS process, and `$status` will be 0 (which is a valid test assertion: "script exits cleanly in non-interactive mode").

**Detection:** Tests that time out (30+ seconds) are likely stuck on `read`. Tests that unexpectedly succeed with empty `$output` may be hitting the early exit guard.

**Affected components:** `scripts/lib/output.sh` `confirm_execute()` (lines 55-68), `is_interactive()` (lines 20-22). All 64 scripts with `[[ ! -t 0 ]]` guards.

**Phase mapping:** Address in test design phase. Decide whether interactive behavior needs testing (probably not for this project -- the value is in testing the command generation, not the interactive prompts).

**Confidence:** HIGH -- verified by reading `output.sh` and the interactive patterns in all scripts.

---

## Moderate Pitfalls

---

### Pitfall 6: Source guards prevent re-sourcing between tests, causing stale state

**What goes wrong:** Every `lib/*.sh` module uses a source guard pattern: `[[ -n "${_STRICT_LOADED:-}" ]] && return 0`. Once a module is sourced in `setup()` or `setup_file()`, the guard variable persists for the entire test file. If a test modifies a variable or function defined by a library module, subsequent tests in the same file see the modified version. You cannot "re-source" the library to get a fresh copy because the guard prevents it.

**Why it happens:** Source guards are designed for production use where double-sourcing wastes time and can cause side effects. In testing, you often want a clean state between tests. But the guard variables (`_COMMON_LOADED`, `_STRICT_LOADED`, `_COLORS_LOADED`, `_LOGGING_LOADED`, `_VALIDATION_LOADED`, `_CLEANUP_LOADED`, `_OUTPUT_LOADED`, `_ARGS_LOADED`, `_DIAGNOSTIC_LOADED`, `_NC_DETECT_LOADED`) persist across tests within a file because BATS runs tests in the same process (or forks from a common parent).

**Prevention:**
1. If you need clean state, unset the guard variable before re-sourcing:
   ```bash
   setup() {
       unset _VALIDATION_LOADED
       source "${BATS_TEST_DIRNAME}/../scripts/lib/validation.sh"
   }
   ```
2. Better: source libraries in `setup_file()` and design tests to not depend on mutable state from libraries. The library functions in this project are mostly stateless (they read arguments, not global state), so this is usually fine.
3. For modules with mutable state (like `cleanup.sh` with `_CLEANUP_COMMANDS` and `_CLEANUP_BASE_DIR`), reset the state variables in `setup()` rather than re-sourcing:
   ```bash
   setup() {
       _CLEANUP_COMMANDS=()
       _CLEANUP_BASE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/test-session.XXXXXX")
   }
   ```

**Detection:** Tests that pass individually but fail when run together (or vice versa) indicate stale state from source guards.

**Affected components:** All 9 source guard variables across `lib/*.sh` modules. `cleanup.sh` and `args.sh` are the most stateful.

**Phase mapping:** Address in test helper design. Document which modules are safe to source once vs. need per-test reset.

**Confidence:** HIGH -- verified by reading all source guards and identifying stateful variables.

---

### Pitfall 7: BATS `run` subshell isolation hides strict mode failures

**What goes wrong:** The `run` function executes commands in a subshell. This means `set -e` behavior inside `run` is different from the test body. Specifically, BATS disables `execfail` inside `run`, and the subshell may not inherit all shell options. A function that would fail under strict mode in production may succeed inside `run` because the strict mode flags are not fully propagated.

**Why it happens:** `run` is designed to capture exit codes without crashing the test. It intentionally catches failures. But this means you cannot use `run` to verify that strict mode causes a specific failure -- the failure is caught by `run`, not by the test's `set -e`. Furthermore, this project uses `shopt -s inherit_errexit` (in `strict.sh` line 14), but this only works in Bash 4.4+, and `run`'s subshell may not inherit this shopt.

**Consequences:** Tests that use `run` to verify strict mode behavior may pass even when the underlying function has a bug that would cause a failure in production. False confidence in test coverage.

**Prevention:**
1. For testing that strict mode catches errors correctly, call functions directly (without `run`) and use `set -e` in the test body:
   ```bash
   @test "require_cmd exits on missing command" {
       source "${BATS_TEST_DIRNAME}/../scripts/lib/validation.sh"
       # Don't use run -- call directly to test exit behavior
       ! require_cmd nonexistent_tool_xyz 2>/dev/null
   }
   ```
   But note: `!` negation disables `set -e` inside the negated command (this is bash behavior, not a BATS bug). Use `run !` for BATS 1.5.0+.
2. For integration tests, use `run` and explicitly check `$status`:
   ```bash
   @test "script fails when nmap not installed" {
       run bash -c 'PATH=/empty:$PATH bash scripts/nmap/examples.sh target'
       [ "$status" -eq 1 ]
       [[ "$output" == *"not installed"* ]]
   }
   ```
3. Accept that `run` tests exit codes, not strict mode behavior. Unit-test strict mode separately from script behavior.

**Detection:** Write a test that should fail under strict mode but passes. If it passes with `run` but fails without `run`, this pitfall is the cause.

**Phase mapping:** Address in test writing guidelines. Document when to use `run` vs. direct invocation.

**Confidence:** HIGH -- verified against BATS [gotchas documentation](https://bats-core.readthedocs.io/en/stable/gotchas.html) and [issue #36](https://github.com/bats-core/bats-core/issues/36).

---

### Pitfall 8: `load` expects `.bash` extension, but all project libraries use `.sh`

**What goes wrong:** BATS's `load` command automatically appends `.bash` to the filename. Calling `load "../scripts/lib/validation"` looks for `validation.bash`, not `validation.sh`. All 9 library modules in this project use the `.sh` extension. Using `load` to include them will fail with a "file not found" error.

**Why it happens:** BATS convention is to use `.bash` for test helper files. The `load` function enforces this by appending the extension. This project follows standard shell script convention with `.sh` files.

**Prevention:**
1. Use `source` instead of `load` for project library files:
   ```bash
   source "${BATS_TEST_DIRNAME}/../scripts/lib/validation.sh"
   ```
2. Use `load` only for test-specific helpers (which should use `.bash` extension):
   ```bash
   # test/test_helper.bash  <-- .bash extension for BATS
   load test_helper
   ```
3. Do not rename project files from `.sh` to `.bash` -- this breaks ShellCheck, the Makefile `find` command, and the existing `source` chains.

**Detection:** `load` calls that fail with "does not exist" or "No such file" errors.

**Phase mapping:** Address in test infrastructure documentation. Establish the convention early.

**Confidence:** HIGH -- verified against BATS [writing tests documentation](https://bats-core.readthedocs.io/en/stable/writing-tests.html).

---

### Pitfall 9: Script metadata header changes can break ShellCheck SC1128 (shebang must be first line)

**What goes wrong:** If metadata headers are added ABOVE the shebang line (`#!/usr/bin/env bash`), ShellCheck raises SC1128: "The shebang must be on the first line." More importantly, the script loses interpreter control -- it may work when called from bash but fail from zsh, sudo, or cron.

**Why it happens:** The kernel reads the first two bytes of a file to detect `#!`. If those bytes are anything else (a comment, a blank line, a metadata block), the shebang becomes an ordinary comment and the file is executed by whatever shell invokes it. Adding metadata before the shebang is the most common mistake when implementing structured headers.

**Consequences:**
- ShellCheck CI (`make lint`) fails for every modified script.
- Scripts may silently execute under the wrong shell (sh instead of bash) in some environments, causing syntax errors from bash-specific features like `[[ ]]`, `(( ))`, associative arrays.
- The existing `make lint` target runs `shellcheck --severity=warning` which catches SC1128.

**Prevention:**
1. Metadata headers MUST go AFTER the shebang line. The correct pattern:
   ```bash
   #!/usr/bin/env bash
   # ---
   # name: identify-ports
   # tool: nmap
   # category: use-case
   # requires: nmap
   # ---
   source "$(dirname "$0")/../common.sh"
   ```
2. Never add blank lines before the shebang.
3. Run `make lint` after adding headers to catch this immediately.
4. If using `# shellcheck` directives, place them after the shebang but before the metadata block to avoid [SC directive parsing issues](https://github.com/koalaman/shellcheck/issues/3191).

**Detection:** `make lint` fails with SC1128. Also: `head -c 2 scripts/*/examples.sh | xxd` should show `2321` (`#!`) for every script.

**Affected scripts:** All 81 `.sh` files that have shebangs.

**Phase mapping:** Address in the header implementation phase. Create a template and validation script before touching any files.

**Confidence:** HIGH -- verified against [ShellCheck SC1128 documentation](https://www.shellcheck.net/wiki/SC1128) and the existing `make lint` target.

---

### Pitfall 10: Metadata headers between shebang and `source common.sh` interact with ShellCheck directives

**What goes wrong:** Some scripts have `# shellcheck disable=SC2034` or similar directives placed strategically. Adding a metadata block between the shebang and the first code line can change whether a ShellCheck directive is interpreted as file-wide or line-specific. A directive immediately after the shebang (before any code) is treated as file-wide. A directive after a metadata comment block may be treated as applying only to the next line.

**Why it happens:** ShellCheck treats directives differently based on their position:
- After shebang, before any command: file-wide scope
- Directly before a command: applies to that command only
- After a comment block: ambiguous behavior depending on ShellCheck version

The current codebase has file-wide directives in `colors.sh` (`# shellcheck disable=SC2034` before variable assignments) and `output.sh` (`# shellcheck disable=SC2034` before `PROJECT_ROOT`).

**Prevention:**
1. Place file-wide ShellCheck directives immediately after the shebang, before the metadata block:
   ```bash
   #!/usr/bin/env bash
   # shellcheck disable=SC2034
   # ---
   # name: colors
   # purpose: Color variable definitions
   # ---
   ```
2. Place line-specific directives immediately before the line they apply to (not inside the metadata block).
3. Run `make lint` after every header modification.
4. If metadata blocks are structured (YAML-style), ensure ShellCheck does not misinterpret `key: value` patterns. Bash comments are safe, but `# shellcheck key=value` patterns inside metadata could trigger [parsing issues](https://github.com/koalaman/shellcheck/issues/3191).

**Detection:** `make lint` produces new warnings that did not exist before header changes.

**Affected components:** `scripts/lib/colors.sh` (6 SC2034 directives), `scripts/lib/output.sh` (1 SC2034 directive), `scripts/lib/args.sh` (1 SC2034 directive).

**Phase mapping:** Address in header implementation phase. Audit existing directives before adding headers.

**Confidence:** MEDIUM -- ShellCheck directive scoping rules are version-dependent and the behavior at comment block boundaries is not fully documented. Verified against [ShellCheck issue #1877](https://github.com/koalaman/shellcheck/issues/1877).

---

### Pitfall 11: `mktemp` in `cleanup.sh` runs at source time, creating orphan temp dirs in tests

**What goes wrong:** `cleanup.sh` line 12 runs `_CLEANUP_BASE_DIR=$(mktemp -d ...)` at source time (outside any function). Every time `common.sh` is sourced in a BATS test, a new temp directory is created in `/tmp`. If tests source `common.sh` in `setup()` (running before every test), each test creates an orphan temp directory. With 50+ tests, this fills `/tmp` with hundreds of abandoned directories.

**Why it happens:** The `mktemp` call is at module scope (not inside a function). Source guards prevent double-sourcing within a single test, but if tests use `unset _CLEANUP_LOADED` for fresh state (per Pitfall 6), each re-source creates a new temp dir. The EXIT trap that would clean up these dirs may not fire correctly in the BATS context (per Pitfall 3).

**Prevention:**
1. For unit tests, do not source `cleanup.sh` unless explicitly testing cleanup behavior.
2. For integration tests using `run`, the temp dir is created and cleaned up inside the subshell -- no leak.
3. Add a safety check in CI: `find /tmp -name 'ntool-session.*' -mmin +60 -exec rm -rf {} +` in test teardown.
4. Use `$BATS_TEST_TMPDIR` for test temp files instead of `make_temp()`.

**Detection:** After running the test suite, check: `ls /tmp/ntool-session.* 2>/dev/null | wc -l`. If non-zero, temp dirs are leaking.

**Phase mapping:** Address in test infrastructure phase alongside Pitfalls 1-3.

**Confidence:** HIGH -- verified by reading `cleanup.sh` line 12 and the source guard behavior.

---

### Pitfall 12: ANSI color codes in test output break assertions

**What goes wrong:** The project's `info()`, `warn()`, `error()`, and `success()` functions output ANSI escape sequences (`\033[0;34m`, etc.) in their messages. When testing script output with `run`, `$output` contains these escape sequences. String comparisons like `[[ "$output" == *"[INFO] Target:"* ]]` fail because the actual string is `\033[0;34m[INFO]\033[0m Target:`.

**Why it happens:** `colors.sh` disables colors when `[[ ! -t 1 ]]` (stdout is not a terminal). Under `run`, stdout IS captured (not a terminal), so colors should be disabled. But this depends on whether `colors.sh` is sourced before or after the `run` context is established. If `common.sh` is sourced in `setup()` and the color detection runs there (where stdout may or may not be a terminal depending on BATS's internal plumbing), the color state may be incorrect for the `run` context.

**Prevention:**
1. Set `NO_COLOR=1` in test setup to force colors off:
   ```bash
   setup() {
       export NO_COLOR=1
   }
   ```
   This uses the [NO_COLOR standard](https://no-color.org/) that `colors.sh` already respects (line 19).
2. When asserting output, use pattern matching that accounts for possible escape sequences: `[[ "$output" == *"INFO"*"Target:"* ]]`.
3. For integration tests with `run bash script.sh`, the script runs in a subprocess where stdout is not a terminal, so `colors.sh` should disable colors automatically. Verify this works.

**Detection:** Test assertions on output text that fail with no visible difference between expected and actual. Use `echo "$output" | cat -v` to reveal hidden escape sequences.

**Phase mapping:** Address in test helper setup. A single `export NO_COLOR=1` in the shared `test_helper.bash` solves this globally.

**Confidence:** HIGH -- verified by reading `colors.sh` lines 17-32 and the NO_COLOR support.

---

## Minor Pitfalls

---

### Pitfall 13: BATS `!` negation does not cause test failure

**What goes wrong:** Writing `! some_command` in a BATS test to assert that a command fails does NOT fail the test when the command succeeds. Bash deliberately excludes negated return values from triggering `set -e` (this is a POSIX requirement, not a BATS limitation).

**Prevention:** Use `run ! command` (BATS 1.5.0+) or `! command || false` for older versions. ShellCheck detects this with [SC2314/SC2315](https://www.shellcheck.net/wiki/SC2315).

**Phase mapping:** Address in test writing guidelines.

**Confidence:** HIGH -- documented in [BATS gotchas](https://bats-core.readthedocs.io/en/stable/gotchas.html).

---

### Pitfall 14: Piped commands inside `run` are parsed by bash before `run` sees them

**What goes wrong:** `run echo "hello" | grep "hello"` does not work as expected. Bash parses the pipe first, so `run` only receives `echo "hello"`, and the `grep` runs outside `run`. The test fails because `$output` does not contain what you expect.

**Prevention:** Use `run bash -c 'echo "hello" | grep "hello"'` or `bats_pipe echo "hello" \| grep "hello"`.

**Phase mapping:** Address in test writing guidelines.

**Confidence:** HIGH -- documented in [BATS gotchas](https://bats-core.readthedocs.io/en/stable/gotchas.html).

---

### Pitfall 15: Background processes in scripts under test cause BATS to hang

**What goes wrong:** If a script launches a background process that inherits BATS's file descriptor 3 (which BATS uses for internal communication), BATS waits forever for that FD to close. The `_run_with_timeout()` function in `diagnostic.sh` (line 28) runs commands with `"$@" &` -- a background process. If this function is invoked during testing, BATS may hang.

**Prevention:**
1. Close FD 3 in background processes: `"$@" 3>&- &`
2. For scripts that use `_run_with_timeout`, test them with `run` and set a BATS timeout: `bats --timing` to detect slow tests.
3. Avoid testing diagnostic scripts that launch background processes in the initial test phase.

**Affected components:** `scripts/lib/diagnostic.sh` line 28 (`"$@" &`), line 29 (`( sleep ... && kill ... ) &`).

**Phase mapping:** Address when writing tests for diagnostic scripts (likely a later phase).

**Confidence:** HIGH -- documented in [BATS writing tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) and verified against `diagnostic.sh`.

---

### Pitfall 16: Header changes that alter the `source` line position break relative path resolution

**What goes wrong:** Every script has `source "$(dirname "$0")/../common.sh"` as the first code line after the shebang and comments. If a metadata header introduces executable code (like variable assignments) before this line, and that code references functions from `common.sh`, it fails. More subtly: if the `source` line moves far down the file (after many lines of metadata), some editors and tools that scan for the source pattern may not find it.

**Prevention:**
1. Keep metadata as pure comments (no executable code in the header block).
2. The `source common.sh` line must remain the first executable statement after comments.
3. If metadata needs to be machine-readable, parse it from comments -- do not add executable statements before sourcing.

**Phase mapping:** Address in header template design.

**Confidence:** HIGH -- verified by reading the script pattern across all 68 scripts that source `common.sh`.

---

### Pitfall 17: `parse_common_args` and `REMAINING_ARGS` require specific call order that headers must not disrupt

**What goes wrong:** Scripts follow a strict call order: `source common.sh` -> `show_help()` definition -> `parse_common_args "$@"` -> `set -- "${REMAINING_ARGS[@]...}"` -> `require_cmd` -> `require_target`/default target -> `confirm_execute` -> `safety_banner`. If a metadata header introduces code that must run before `parse_common_args` or after `source common.sh`, inserting it at the wrong point breaks argument handling or skips the safety banner.

**Prevention:**
1. Metadata headers must be pure comments, placed between the shebang and `source common.sh`.
2. No executable metadata parsing should occur at script top level.
3. If scripts need to read their own headers at runtime (for `--version` or `--metadata` flags), do this inside `show_help()` or a dedicated function, not at the top level.

**Phase mapping:** Address in header template design.

**Confidence:** HIGH -- verified by reading the argument parsing flow in `args.sh` and multiple scripts.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Severity | Mitigation |
|-------------|---------------|----------|------------|
| Test infrastructure setup | Pitfalls 1-3: strict mode, ERR trap, EXIT trap conflicts with BATS | Critical | Create `test_helper.bash` that manages sourcing and trap lifecycle |
| Test infrastructure setup | Pitfall 8: `load` vs `source` extension mismatch | Moderate | Document convention: `load` for `.bash` helpers, `source` for `.sh` libraries |
| Unit test writing | Pitfall 4: `exit 1` from `require_cmd` kills BATS | Critical | Use `run` for all script execution, `source` only for isolated lib modules |
| Unit test writing | Pitfall 7: `run` hides strict mode failures | Moderate | Document when to use `run` vs direct invocation |
| Unit test writing | Pitfall 13: `!` negation silently passes | Minor | Use `run !` pattern, enable SC2314/SC2315 in ShellCheck |
| Integration test writing | Pitfall 5: interactive prompts block/exit tests | Critical | Default to `EXECUTE_MODE=show`, use `run` for subshell isolation |
| Integration test writing | Pitfall 15: background processes hang BATS | Minor | Close FD 3 in background jobs, defer diagnostic script tests |
| Integration test writing | Pitfall 12: ANSI colors break assertions | Moderate | Set `NO_COLOR=1` in test helper |
| CI pipeline | Pitfall 4: missing tools crash suite | Critical | Split unit/integration tests, stub commands for CI |
| CI pipeline | Pitfall 11: temp dir leaks in `/tmp` | Moderate | CI cleanup step, use `$BATS_TEST_TMPDIR` |
| Header implementation | Pitfall 9: metadata above shebang | Critical | Template enforcement, `make lint` validation |
| Header implementation | Pitfall 10: ShellCheck directive scope changes | Moderate | Audit existing directives, test `make lint` after changes |
| Header implementation | Pitfall 16-17: disrupting source/call order | Moderate | Pure-comment headers, no executable code before `source` |

## Sources

- [BATS Gotchas (official documentation)](https://bats-core.readthedocs.io/en/stable/gotchas.html)
- [BATS Writing Tests (official documentation)](https://bats-core.readthedocs.io/en/stable/writing-tests.html)
- [BATS Issue #36: Strict mode support](https://github.com/bats-core/bats-core/issues/36)
- [BATS Issue #81: Silent failure with set -u](https://github.com/bats-core/bats-core/issues/81)
- [BATS Issue #213: set -u support](https://github.com/bats-core/bats-core/issues/213)
- [BATS Issue #423: Unbound variable in setup_file](https://github.com/bats-core/bats-core/issues/423)
- [BATS tracing.bash source (ERR trap implementation)](https://github.com/bats-core/bats-core/blob/master/lib/bats-core/tracing.bash)
- [ShellCheck SC1128: Shebang must be on first line](https://www.shellcheck.net/wiki/SC1128)
- [ShellCheck SC2314/SC2315: BATS negation warnings](https://www.shellcheck.net/wiki/SC2315)
- [ShellCheck Issue #3191: Comment parsing with shellcheck directives](https://github.com/koalaman/shellcheck/issues/3191)
- [ShellCheck Issue #1877: File-wide directive scoping](https://github.com/koalaman/shellcheck/issues/1877)
- [bats-mock: Mocking/stubbing library for BATS](https://github.com/jasonkarns/bats-mock)
- [BashFAQ/105: set -e pitfalls](https://mywiki.wooledge.org/BashFAQ/105)
- Codebase analysis: `scripts/lib/strict.sh`, `scripts/lib/cleanup.sh`, `scripts/lib/validation.sh`, `scripts/lib/output.sh`, `scripts/lib/colors.sh`, `scripts/lib/args.sh`, `scripts/common.sh`
