---
phase: 21-ci-integration
plan: 01
subsystem: infra
tags: [github-actions, bats, junit, ci, pr-annotations]

# Dependency graph
requires:
  - phase: 18-bats-framework
    provides: BATS test infrastructure with submodule-based libraries
  - phase: 20-script-integration-tests
    provides: Full BATS test suite in tests/ directory
provides:
  - GitHub Actions BATS workflow triggered on push/PR to main
  - JUnit XML report generation with PR annotations
  - Independent CI pipeline (no coupling to ShellCheck workflow)
affects: [22-docs-site-refresh]

# Tech tracking
tech-stack:
  added: [bats-core/bats-action@4.0.0, mikepenz/action-junit-report@v6]
  patterns: [pinned-action-versions, submodule-based-library-loading, independent-ci-jobs]

key-files:
  created: [.github/workflows/tests.yml]
  modified: []

key-decisions:
  - "Disable all bats-action library installs -- submodules provide pinned versions"
  - "Non-recursive bats tests/ to avoid bats-core internal fixtures"
  - "JUnit output to RUNNER_TEMP with --report-formatter (not --formatter)"
  - "checks: write permission for action-junit-report Check Runs"

patterns-established:
  - "CI workflow pattern: pin action versions, use submodules for dependencies"
  - "Report pattern: JUnit XML with if: always() for test failure visibility"

# Metrics
duration: 2min
completed: 2026-02-12
---

# Phase 21 Plan 01: BATS CI Workflow Summary

**GitHub Actions BATS workflow with JUnit PR annotations via bats-action@4.0.0 and action-junit-report@v6**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-12T17:14:21Z
- **Completed:** 2026-02-12T17:16:09Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Created `.github/workflows/tests.yml` with BATS test suite running on every push/PR to main
- JUnit XML report generation via `--report-formatter junit` feeds into PR annotations
- Workflow is fully independent from existing ShellCheck workflow (CI-03 satisfied)
- All 17 validation checks pass (CI-01, CI-02, CI-03 plus anti-patterns)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BATS CI workflow with JUnit reporting** - `0b4b338` (feat)
2. **Task 2: Validate workflow satisfies all three requirements** - validation-only, no file changes

**Plan metadata:** (pending) (docs: complete plan)

## Files Created/Modified
- `.github/workflows/tests.yml` - GitHub Actions workflow: BATS test suite with JUnit reporting and PR annotations

## Decisions Made
- Disabled all four bats-action library installs (support, assert, detik, file) since submodules provide libraries at pinned versions
- Used `bats tests/` without `--recursive` to avoid bats-core internal test fixtures in `tests/bats/test/`
- Used `--report-formatter junit` (not `--formatter junit`) to write JUnit XML to file while keeping terminal output
- Set `TERM: xterm` to prevent terminal detection issues in CI
- Used `$RUNNER_TEMP` for JUnit output to keep workspace clean
- Added `checks: write` permission for action-junit-report to create GitHub Check Runs

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- CI pipeline is complete: ShellCheck linting + BATS tests both trigger independently on push/PR
- Ready for phase 22 (docs-site-refresh) -- CI protects against regressions during documentation updates
- First push to main or PR will trigger both workflows

---
*Phase: 21-ci-integration*
*Completed: 2026-02-12*

## Self-Check: PASSED
