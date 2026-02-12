# Roadmap: Networking Tools

## Milestones

- SHIPPED **v1.0 Networking Tools Expansion** — Phases 1-7 (shipped 2026-02-11)
- SHIPPED **v1.1 Site Visual Refresh** — Phases 8-11 (shipped 2026-02-11)
- SHIPPED **v1.2 Script Hardening** — Phases 12-17 (shipped 2026-02-11)
- IN PROGRESS **v1.3 Testing & Script Headers** — Phases 18-22

## Phases

<details>
<summary>v1.0 Networking Tools Expansion (Phases 1-7) — SHIPPED 2026-02-11</summary>

Archived to `.planning/milestones/v1.0-ROADMAP.md`

7 phases, 19 plans, 47 tasks completed in 2 days.

</details>

<details>
<summary>v1.1 Site Visual Refresh (Phases 8-11) — SHIPPED 2026-02-11</summary>

Archived to `.planning/milestones/v1.1-ROADMAP.md`

4 phases, 4 plans, 7 tasks completed in ~4.5 hours.

</details>

<details>
<summary>v1.2 Script Hardening (Phases 12-17) — SHIPPED 2026-02-11</summary>

Archived to `.planning/milestones/v1.2-ROADMAP.md`

6 phases, 18 plans completed in ~1.3 hours.

- [x] Phase 12: Pre-Refactor Cleanup (1/1 plans) — completed 2026-02-11
- [x] Phase 13: Library Infrastructure (2/2 plans) — completed 2026-02-11
- [x] Phase 14: Argument Parsing + Dual-Mode (2/2 plans) — completed 2026-02-11
- [x] Phase 15: Examples Script Migration (4/4 plans) — completed 2026-02-11
- [x] Phase 16: Use-Case Script Migration (8/8 plans) — completed 2026-02-11
- [x] Phase 17: ShellCheck Compliance + CI (1/1 plan) — completed 2026-02-11

</details>

### v1.3 Testing & Script Headers (In Progress)

**Milestone Goal:** Add BATS test framework with library unit tests, script integration tests, CI enforcement, and structured metadata headers on all scripts.

- [x] **Phase 18: BATS Infrastructure** — Test framework foundation with submodules, shared helper, and Makefile targets (completed 2026-02-12)
- [x] **Phase 19: Library Unit Tests** — Unit tests for all lib/ modules proving library function behavior (completed 2026-02-12)
- [x] **Phase 20: Script Integration Tests** — CLI contract tests for --help, -x rejection, and flag handling across all scripts (completed 2026-02-12)
- [x] **Phase 21: CI Integration** — GitHub Actions BATS workflow with JUnit PR annotations (completed 2026-02-12)
- [ ] **Phase 22: Script Metadata Headers** — Structured Description/Usage/Dependencies headers on all scripts

## Phase Details

### Phase 18: BATS Infrastructure
**Goal:** BATS test framework is installed, configured, and proven to work with the project's strict mode and trap chain
**Depends on:** Nothing (first phase of v1.3)
**Requirements:** INFRA-01, INFRA-02, INFRA-03, INFRA-04
**Success Criteria** (what must be TRUE):
  1. `make test` runs BATS test suite and exits cleanly with TAP output
  2. `make test-verbose` shows per-test results with timing information
  3. A smoke test sources project libraries and asserts behavior without strict mode or trap conflicts crashing BATS
  4. BATS helper libraries (bats-assert, bats-file) are available and loadable via shared test helper
**Plans:** 1 plan

Plans:
- [x] 18-01-PLAN.md -- Install BATS submodules, shared test helper, Makefile targets, and smoke test

### Phase 19: Library Unit Tests
**Goal:** Every library module in scripts/lib/ has unit tests proving its public functions behave correctly
**Depends on:** Phase 18
**Requirements:** UNIT-01, UNIT-02, UNIT-03, UNIT-04, UNIT-05, UNIT-06
**Success Criteria** (what must be TRUE):
  1. `parse_common_args` correctly sets VERBOSE, QUIET, EXECUTE_MODE, and passes through unknown flags for all flag combinations (-h, -v, -q, -x, --, mixed ordering)
  2. `require_cmd` exits non-zero for missing commands and `check_cmd` returns correct boolean for present/absent commands
  3. Logging functions (info/warn/error/debug) respect LOG_LEVEL filtering and NO_COLOR suppresses ANSI codes
  4. `make_temp` creates files/directories and EXIT trap cleans them up on process exit
  5. `run_or_show` prints commands in show mode and `retry_with_backoff` retries the correct number of times with increasing delays
**Plans:** 3 plans

Plans:
- [x] 19-01-PLAN.md -- Argument parsing and command validation tests (UNIT-01, UNIT-02)
- [x] 19-02-PLAN.md -- Logging and temp file cleanup tests (UNIT-03, UNIT-04)
- [x] 19-03-PLAN.md -- Output functions and retry logic tests (UNIT-05, UNIT-06)

### Phase 20: Script Integration Tests
**Goal:** All scripts pass CLI contract tests for help output, execute-mode safety, and flag handling -- discovered dynamically, not hardcoded
**Depends on:** Phase 18 (framework), Phase 19 (library behavior proven)
**Requirements:** INTG-01, INTG-02, INTG-03, INTG-04
**Success Criteria** (what must be TRUE):
  1. Every script exits 0 on `--help` and its output contains "Usage:"
  2. Every script with `-x` flag rejects piped (non-interactive) stdin
  3. Scripts are discovered via glob pattern -- adding a new script automatically includes it in tests
  4. Tests pass on CI runners that lack pentesting tools (nmap, sqlmap, etc.) via mock commands
**Plans:** 1 plan

Plans:
- [x] 20-01-PLAN.md -- Dynamic CLI contract tests: help output, execute-mode rejection, and mock commands

### Phase 21: CI Integration
**Goal:** BATS tests run automatically on every push and PR via GitHub Actions with test result annotations
**Depends on:** Phase 18 (framework), Phase 19-20 (tests exist to run)
**Requirements:** CI-01, CI-02, CI-03
**Success Criteria** (what must be TRUE):
  1. A GitHub Actions workflow runs the full BATS test suite on push/PR events
  2. Test failures appear as GitHub annotations on the PR (via JUnit XML report)
  3. BATS tests and ShellCheck linting run as independent jobs (neither blocks the other)
**Plans:** 1 plan

Plans:
- [x] 21-01-PLAN.md -- BATS CI workflow with JUnit reporting and independent execution

### Phase 22: Script Metadata Headers
**Goal:** Every script file has a structured, machine-parseable metadata header documenting its purpose, usage, and dependencies
**Depends on:** Phase 18 (HDR-06 needs BATS for validation test)
**Requirements:** HDR-01, HDR-02, HDR-03, HDR-04, HDR-05, HDR-06
**Success Criteria** (what must be TRUE):
  1. A defined header format exists with Description, Usage, and Dependencies fields placed between the shebang and the first `source` line
  2. All 17 examples.sh scripts, all use-case scripts, all lib/*.sh modules, and all utility scripts have conformant headers
  3. A BATS test validates that every .sh file in the project contains the required header fields
  4. Headers are pure comments with zero behavioral change to any script
**Plans:** 3 plans

Plans:
- [ ] 22-01-PLAN.md -- Add headers to examples.sh, lib modules, and utility/diagnostics scripts (33 files)
- [x] 22-02-PLAN.md -- Add headers to all 46 use-case scripts
- [ ] 22-03-PLAN.md -- BATS validation test for header conformance (HDR-06)

## Progress

**Execution Order:**
Phases execute in numeric order: 18 -> 19 -> 20 -> 21 -> 22

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-7 | v1.0 | 19/19 | Complete | 2026-02-11 |
| 8-11 | v1.1 | 4/4 | Complete | 2026-02-11 |
| 12-17 | v1.2 | 18/18 | Complete | 2026-02-11 |
| 18. BATS Infrastructure | v1.3 | 1/1 | Complete | 2026-02-12 |
| 19. Library Unit Tests | v1.3 | 3/3 | Complete | 2026-02-12 |
| 20. Script Integration Tests | v1.3 | 1/1 | Complete | 2026-02-12 |
| 21. CI Integration | v1.3 | 1/1 | Complete | 2026-02-12 |
| 22. Script Metadata Headers | v1.3 | 1/3 | In progress | - |
