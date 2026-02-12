# Project Research Summary

**Project:** networking-tools v1.3 — BATS testing framework + structured script headers
**Domain:** Bash testing infrastructure and script documentation standards
**Researched:** 2026-02-11
**Confidence:** HIGH

## Executive Summary

This milestone addresses the testing and documentation debt from 81 bash scripts across 10 pentesting tools. The project has evolved from 17 thin wrapper scripts to a sophisticated codebase with 9 library modules (`lib/*.sh`), shared argument parsing, dual-mode execution (show/execute), and 307 ad-hoc test assertions in two custom test harnesses. The current test approach (manual pass/fail counting) is unmaintainable. The lack of structured headers prevents automated tooling. This research establishes BATS-core as the test framework and defines a machine-parseable header format.

The recommended approach uses BATS v1.13.0 with helper libraries (bats-support v0.3.0, bats-assert v2.2.0, bats-file v0.4.0) installed via git submodules locally and bats-action v4.0.0 in CI. Tests are split into unit tests for library modules and integration tests for script behavior. Installation via git submodules (not npm, not Homebrew) ensures pinned versions and offline reproducibility. Structured headers use a shdoc-inspired comment format with `@tag` syntax for metadata extraction without requiring a build tool.

The critical risk is strict mode conflict. Every script sources `common.sh` which enables `set -eEuo pipefail` and registers ERR/EXIT traps. BATS has its own trap chain and expects to control error detection. Sourcing `common.sh` in tests overwrites BATS's traps, causing silent failures or crashes. Prevention: disable strict mode immediately after sourcing (`set +eEuo pipefail; trap - ERR`) in test setup, or use `run bash script.sh` for integration tests to isolate the script in a subshell. This pattern must be established in the test infrastructure phase before any tests are written.

## Key Findings

### Recommended Stack

BATS-core is the only mature, actively maintained TAP-compliant bash test framework. It provides isolated test execution (each `@test` runs in a subshell), assertion libraries via bats-assert, parallel execution via `--jobs`, and official GitHub Action integration. The existing ad-hoc tests already do what BATS tests do — they just use manual boilerplate instead of a framework. Migration is a natural evolution, not a paradigm shift.

**Core technologies:**
- **bats-core v1.13.0:** TAP-compliant test runner with parallel execution, test filtering, and setup/teardown lifecycle hooks. The standard for bash testing.
- **bats-support v0.3.0:** Required dependency for bats-assert. Provides failure formatting and error reporting primitives.
- **bats-assert v2.2.0:** Assertion library with `assert_success`, `assert_failure`, `assert_output`, `assert_line`. Replaces manual `if/else` assertion boilerplate with clear failure diffs.
- **bats-file v0.4.0:** Filesystem assertions (`assert_file_exists`, `assert_dir_exists`) for testing temp file creation and cleanup behavior in `cleanup.sh`.
- **bats-action v4.0.0:** Official GitHub Action (released 2025-02-08) that installs BATS + all helper libraries with binary caching and BATS_LIB_PATH configuration.
- **Git submodules:** Installation method for local development. Pinned versions, works offline, no runtime dependency manager. npm is NOT viable (helper libraries not published to npm per bats-core issue #493).
- **Structured comment headers:** shdoc-inspired `@tag` format parseable with grep/awk. No external tool required (shdoc itself is rejected — overkill for CLI scripts that already have `show_help()` functions).

### Expected Features

The project already has 307 test assertions split across two custom harnesses (`test-arg-parsing.sh` with 268 checks, `test-library-loads.sh` with 39 checks). This is not greenfield testing — it is test migration and expansion.

**Must have (table stakes):**
- BATS as test runner — de facto standard, no serious alternative exists.
- `bats-assert` for assertions — `assert_success` is readable and produces clear failure messages vs. manual `[ "$status" -eq 0 ]`.
- Unit tests for all 9 `lib/*.sh` modules — library functions are the foundation. Bugs here propagate everywhere. The ad-hoc `test-library-loads.sh` only checks "function exists", not behavior.
- `--help` output tests for all 81 scripts — currently tested ad-hoc with hardcoded list. BATS can discover scripts dynamically.
- `make test` target — standard entry point every developer expects.
- CI integration (GitHub Actions) — tests that only run locally drift. Project already has ShellCheck CI workflow.
- Structured script header on every `.sh` file — 81 files have ad-hoc single-line comments. Need machine-parseable metadata for future tooling.

**Should have (competitive):**
- `bats-file` for filesystem assertions — testing `cleanup.sh` temp file creation is clunky with raw assertions.
- Test tags for categorization (`unit`, `integration`, `slow`) — run subsets with `bats --filter-tags unit`.
- `setup_file` for expensive initialization — source `common.sh` once per file instead of per test.
- Shared test helper (`test_helper/common-setup.bash`) — centralize library loading, PATH setup, fixture paths.
- Machine-parseable metadata headers — enable future automated `--help` generation, dependency graphing, documentation site generation.
- JUnit report output for CI — `bats --report-formatter junit` produces XML that GitHub Actions renders as test annotations.
- `skip` for missing tool dependencies — tests should `skip "nmap not installed"` rather than fail on CI runners without pentesting tools.
- Parallel test execution — `bats --jobs 4` runs test files in parallel (built into BATS).

**Defer (v2+):**
- Mocking framework (bats-mock) — scripts are thin wrappers around real tools. Mocking `nmap` tests the mock, not the script. Value is in testing the framework (args, logging, cleanup), not tool output.
- 100% code coverage target — use-case scripts are educational templates. Testing that `info "1) Ping scan"` prints the right string is low-value busywork. Focus coverage on `lib/*.sh` functions where bugs actually matter.
- End-to-end tests against Docker lab targets — requires Docker running, images pulled, services healthy. Slow, flaky, environment-dependent. Makes CI fragile.
- Custom test reporter — BATS has TAP, pretty, TAP13, and JUnit built in.
- Generating `--help` output from headers — `show_help()` already exists in all 81 scripts with carefully formatted output. Replacing it with auto-generation changes existing behavior.
- Code coverage tools (bashcov/kcov) — premature. Get BATS running first. Coverage is a separate milestone.

### Architecture Approach

Test infrastructure coexists with existing code. No changes to production scripts except adding comment headers. Tests are organized by concern: `tests/lib/*.bats` for unit tests (one file per module), `tests/scripts/*.bats` for integration tests (script behavior). A shared test helper (`tests/test_helper/common-setup.bash`) loads bats-support/bats-assert and sets `PROJECT_ROOT`. The dual-path library loading (via `BATS_LIB_PATH` in CI, via submodule paths locally) is abstracted into the helper.

**Major components:**
1. **tests/test_helper/common-setup.bash** — Shared setup loaded by every test file. Handles library loading (BATS_LIB_PATH vs submodules), PROJECT_ROOT resolution, PATH modification for script access. Critical: disables strict mode after sourcing common.sh (`set +eEuo pipefail; trap - ERR`) to prevent trap conflicts.
2. **tests/lib/*.bats** — Unit tests for library modules. Nine files, one per `lib/*.sh` module. Source only the specific module under test (not full `common.sh` chain) for isolation. Test library functions directly via function calls, not via `run`.
3. **tests/scripts/*.bats** — Integration tests for script behavior. Test via `run bash scripts/tool/script.sh` (subshell isolation). Validate `--help` exits 0, `-x` rejects non-interactive stdin, parse_common_args behavior. Use mocks for missing tools.
4. **Structured headers** — Comment blocks between shebang and `source common.sh`. Fields: `@name` (path), `@description` (one-liner), `@tool` (nmap/tshark/etc), `@category` (examples/use-case/library), `@target` (required/optional/none), `@requires` (tools). Parseable via grep: `grep '^# @tool' scripts/**/*.sh | sed 's/# @tool *//'`.
5. **CI workflow (.github/workflows/bats.yml)** — Uses bats-action@4.0.0 to install BATS + helpers. Runs `bats tests/ --recursive --jobs 4 --timing`. Separate workflow from shellcheck.yml (tests and linting are independent concerns). Initially runs alongside legacy tests until migration complete.

### Critical Pitfalls

These are blockers that cause test suites to silently pass when they should fail or break all 81 existing scripts.

1. **`set -u` in sourced scripts blows up BATS internal variables** — Every script sources `common.sh` which loads `strict.sh` with `set -eEuo pipefail`. BATS uses internal variables like `BATS_CURRENT_STACK_TRACE[@]` that may be unset. With `set -u` active, referencing these unset BATS internals causes unbound variable errors or silent failures. **Prevention:** Never source `common.sh` at BATS file level. Source inside `setup()` and immediately run `set +u` in `teardown()` to protect BATS internals. Better: create test_helper that sources within controlled scope and resets nounset after loading.

2. **BATS's ERR trap conflicts with project's `_strict_error_handler` trap** — `strict.sh` registers `trap '_strict_error_handler' ERR`. BATS registers `trap 'bats_error_trap' ERR`. Only one ERR trap can be active. When test sources `common.sh`, project's trap overwrites BATS's trap, breaking failure detection. **Prevention:** After sourcing common.sh in setup(), run `trap - ERR` to clear project's trap in test context. For integration tests, use `run bash script.sh` (subshell isolation) never `source`.

3. **EXIT trap from `cleanup.sh` fires during BATS teardown, deleting test fixtures** — `cleanup.sh` registers `trap '_cleanup_handler' EXIT` which deletes temp dirs and calls `exit`. When `common.sh` sourced in test, this EXIT trap fires during test process exit, interfering with BATS's own EXIT trap for result reporting. **Prevention:** For unit tests, source only specific module, not full `common.sh` chain. For integration tests, always use `run` (subshell). Use `$BATS_TEST_TMPDIR` for test temp files instead of project's `make_temp()`.

4. **Testing scripts that `exit 1` on missing tools kills the BATS process** — 66 scripts call `require_cmd` which runs `exit 1` when tool not installed. In CI or dev machines lacking pentesting tools, sourcing these scripts causes `exit 1` to terminate the BATS process. **Prevention:** Always use `run bash script.sh` when executing whole scripts. Never source a script that has top-level `require_cmd` calls. Create stub commands in `$BATS_TEST_TMPDIR/bin` and prepend to PATH. Categorize tests as "unit" (no tools needed) vs "integration" (stubs or real tools needed).

5. **`confirm_execute()` and interactive `read -rp` cause BATS tests to hang or fail** — 64 scripts call `confirm_execute()` which, in execute mode, runs `read -rp "Continue? [y/N]"`. BATS does not provide a terminal on stdin. `confirm_execute()` explicitly rejects non-interactive execution with `exit 1`. **Prevention:** Default all tests to show mode (`EXECUTE_MODE=show`). Use `run` (subshell) for script-level tests — the `exit 0` from non-interactive guard exits the subshell, not BATS process.

## Implications for Roadmap

Based on research, this milestone naturally splits into 5 sequential phases. Dependencies flow from infrastructure setup → unit tests → integration tests → headers → migration. The strict mode trap conflicts (pitfalls 1-3) must be addressed in the first phase before any tests are written.

### Phase 1: BATS Infrastructure Setup
**Rationale:** Foundation for all subsequent phases. Cannot write tests without test framework. Git submodules must be pinned to specific versions before any tests depend on them. The test helper pattern (managing strict mode, trap lifecycle, library loading) must be proven before tests are written.

**Delivers:**
- Git submodules for bats-core v1.13.0, bats-support v0.3.0, bats-assert v2.2.0, bats-file v0.4.0
- `tests/test_helper/common-setup.bash` with dual-path library loading (BATS_LIB_PATH vs submodules)
- Makefile targets: `test`, `test-verbose`, `test-filter`
- One smoke test proving the infrastructure works and strict mode conflicts are handled

**Addresses:** Must-have features (BATS as test runner, bats-assert library, shared test helper, make test target)

**Avoids:** Pitfalls 1-3 (strict mode, ERR trap, EXIT trap conflicts), Pitfall 8 (`load` vs `source` extension mismatch)

**Research flags:** None — well-documented in official BATS tutorial. Direct implementation.

---

### Phase 2: Library Unit Tests
**Rationale:** Library functions (`lib/*.sh`) are the foundation. Every script sources them. Bugs here propagate everywhere. Unit tests have highest ROI — they catch bugs in reusable code. These tests inform the integration test patterns for Phase 3.

**Delivers:**
- `tests/lib/args.bats` — test `parse_common_args` with all flag combinations (-v, -q, -x, --, unknown flags, flag ordering, empty args)
- `tests/lib/validation.bats` — test `require_cmd`, `require_target`, `check_cmd` with installed/missing commands
- `tests/lib/logging.bats` — test info/warn/error/debug output, LOG_LEVEL filtering, VERBOSE behavior, NO_COLOR support
- `tests/lib/cleanup.bats` — test `make_temp` creates files, EXIT trap cleans up, `register_cleanup` runs commands on exit
- `tests/lib/output.bats` — test `safety_banner`, `is_interactive`, `run_or_show`, `PROJECT_ROOT` resolution

**Addresses:** Must-have features (unit tests for all 9 lib modules)

**Uses:** BATS infrastructure from Phase 1, bats-assert for assertions, bats-file for filesystem checks

**Avoids:** Pitfall 6 (source guard stale state) via per-test reset of mutable state variables

**Research flags:** None — library functions have clear contracts. Existing ad-hoc tests show what to validate.

---

### Phase 3: Script Integration Tests
**Rationale:** Integration tests validate the CLI contract (--help, -x rejection) across all 81 scripts. These replace the brittle hardcoded-list approach in `test-arg-parsing.sh`. Must come after unit tests (library behavior proven) and before header migration (tests can validate headers once added).

**Delivers:**
- `tests/scripts/help-flags.bats` — all 81 scripts `--help` exits 0, contains "Usage:"
- `tests/scripts/execute-mode.bats` — all 81 scripts `-x` rejects piped stdin
- `tests/helpers/mock-commands.bash` — create stub executables for CI (nmap, sqlmap, etc.)
- Dynamic script discovery (glob `scripts/**/*.sh`) replacing hardcoded arrays

**Addresses:** Must-have features (--help output tests, -x rejection tests, CI integration)

**Uses:** mock-commands helper to satisfy `require_cmd` checks in CI

**Avoids:** Pitfall 4 (exit 1 kills BATS) via `run bash script.sh` pattern and command stubs, Pitfall 5 (interactive prompts) via `run` subshell isolation

**Research flags:** None — integration test pattern proven by existing ad-hoc tests.

---

### Phase 4: CI Integration
**Rationale:** Tests that only run locally drift. CI must run BATS tests on every PR. Separate workflow from shellcheck.yml (independent concerns). Must run alongside legacy tests initially (both systems validate behavior until migration complete in Phase 5).

**Delivers:**
- `.github/workflows/bats.yml` using bats-action@4.0.0
- Workflow runs `bats tests/ --recursive --jobs 4 --timing`
- JUnit report output via `--report-formatter junit` for GitHub test annotations
- Both BATS tests and legacy tests run in parallel jobs

**Addresses:** Must-have features (CI integration via GitHub Actions), Should-have features (JUnit report output, parallel execution)

**Uses:** bats-action v4.0.0, BATS_LIB_PATH output from action

**Avoids:** Pitfall 12 (ANSI color codes break assertions) via `NO_COLOR=1` in CI, Pitfall 11 (temp dir leaks) via `$BATS_TEST_TMPDIR` usage

**Research flags:** None — bats-action is official with clear documentation.

---

### Phase 5: Script Metadata Headers
**Rationale:** Headers enable future tooling (documentation generation, dependency auditing) but have zero behavioral impact (pure comments). Can be done in parallel with test writing but logically follows test infrastructure setup. Headers added after integration tests exist so `tests/scripts/header-metadata.bats` can validate them.

**Delivers:**
- Structured header format defined (shdoc-inspired `@tag` syntax)
- All 9 `lib/*.sh` modules updated with `@file`, `@brief`, `@description`, `@arg`, `@exitcode` annotations
- All 72 remaining scripts updated with `@name`, `@description`, `@tool`, `@category`, `@target`, `@requires` fields
- `tests/scripts/header-metadata.bats` validates all scripts have required fields

**Addresses:** Must-have features (structured script header on every .sh file), Should-have features (machine-parseable metadata)

**Uses:** grep/awk for header extraction (no external tool required)

**Avoids:** Pitfall 9 (metadata above shebang breaks SC1128), Pitfall 10 (ShellCheck directive scope changes), Pitfalls 16-17 (disrupting source/call order)

**Research flags:** None — header format is project-specific convention, not external integration.

---

### Phase Ordering Rationale

- **Infrastructure before tests:** Cannot write tests without framework. Submodules must be pinned. Test helper must handle strict mode conflicts.
- **Unit before integration:** Library functions are dependencies of scripts. Prove library behavior first. Unit test patterns inform integration test patterns.
- **Tests before headers:** Headers are comments (zero behavioral change). Tests validate existing behavior, headers document it.
- **CI after local tests work:** Prove tests pass locally before adding CI overhead. bats-action config mirrors local submodule setup.
- **Migration last:** Keep legacy tests running until BATS tests fully cover their assertions. Compare test counts to ensure nothing lost.

### Research Flags

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Infrastructure):** Official BATS tutorial covers submodule setup, test_helper pattern. Direct implementation.
- **Phase 2 (Unit tests):** Existing `test-library-loads.sh` shows what to test. Library functions have clear contracts.
- **Phase 3 (Integration tests):** Existing `test-arg-parsing.sh` shows CLI contract tests. Pattern proven.
- **Phase 4 (CI):** bats-action is official with documented inputs. Workflow mirrors existing shellcheck.yml.
- **Phase 5 (Headers):** Comment format, not external integration. No unknowns.

**Phases needing deeper research:** None. All patterns documented in official sources or existing codebase.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | BATS versions verified via GitHub releases. Git submodule approach verified via official tutorial. npm blocker confirmed via bats-core issue #493. bats-action v4.0.0 inputs verified via GitHub Marketplace. |
| Features | HIGH | All features derived from existing test harnesses (268 + 39 = 307 assertions) and BATS official documentation. No speculative features. |
| Architecture | HIGH | Directory structure follows official BATS tutorial. Test helper pattern documented in tutorial. Strict mode conflicts documented in bats-core issues #36, #81, #213, #423. Integration test pattern proven by existing ad-hoc tests. |
| Pitfalls | HIGH | Critical pitfalls (1-5) verified by reading codebase source (`strict.sh`, `cleanup.sh`, `validation.sh`, `output.sh`) and cross-referencing against BATS gotchas documentation and GitHub issues. Moderate pitfalls (6-12) verified against official docs and ShellCheck wiki. |

**Overall confidence:** HIGH

### Gaps to Address

No significant gaps. All recommendations backed by official documentation or existing codebase patterns. Two areas warrant attention during implementation:

- **shdoc annotation coverage:** Header format uses shdoc-inspired `@tag` syntax but does NOT require shdoc as a build dependency. If future milestone wants to auto-generate docs from headers, evaluate shdoc v1.2 vs alternatives at that time. Decision deferred intentionally — headers are designed to be forward-compatible.

- **Bash version coverage:** Project targets Bash 4.0+ but dev environment uses Bash 5.3.9 via Homebrew on macOS. CI uses ubuntu-latest (Bash 5.2.x). BATS itself requires Bash 3.2+. No compatibility issues expected, but `inherit_errexit` (used in `strict.sh` line 14) requires Bash 4.4+. Verify CI bash version during Phase 4.

## Sources

### Primary (HIGH confidence)
- [bats-core official documentation](https://bats-core.readthedocs.io/en/stable/) — Installation, writing tests, gotchas, tutorial (all phases)
- [bats-core GitHub releases](https://github.com/bats-core/bats-core/releases) — v1.13.0 version verification
- [bats-assert GitHub releases](https://github.com/bats-core/bats-assert/releases) — v2.2.0 version verification, stderr assertion functions
- [bats-support GitHub releases](https://github.com/bats-core/bats-support/releases) — v0.3.0 version verification
- [bats-file GitHub releases](https://github.com/bats-core/bats-file/releases) — v0.4.0 version verification
- [bats-core/bats-action GitHub Marketplace](https://github.com/marketplace/actions/setup-bats-and-bats-libraries) — v4.0.0 inputs/defaults
- [bats-core issue #493](https://github.com/bats-core/bats-core/issues/493) — npm limitation for helper libraries
- [ShellCheck SC1128 wiki](https://www.shellcheck.net/wiki/SC1128) — Shebang must be on first line
- Codebase analysis: `tests/test-arg-parsing.sh` (268 checks), `tests/test-library-loads.sh` (39 checks), `scripts/lib/*.sh` (9 modules), `.github/workflows/shellcheck.yml`

### Secondary (MEDIUM confidence)
- [bats-core issues #36, #81, #213, #423](https://github.com/bats-core/bats-core/issues) — Strict mode support discussion, set -u conflicts
- [shdoc](https://github.com/reconquest/shdoc) — Annotation format inspiration for headers
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) — Header conventions reference
- [ShellCheck issues #1877, #3191](https://github.com/koalaman/shellcheck/issues) — Directive scoping, comment parsing

### Tertiary (LOW confidence)
- None — all recommendations verified against official sources or existing code patterns

---
*Research completed: 2026-02-11*
*Ready for roadmap: yes*
