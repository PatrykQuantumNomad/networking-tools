# Requirements: v1.3 Testing & Script Headers

**Defined:** 2026-02-11
**Core Value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.

## v1.3 Requirements

Requirements for the testing and script headers milestone. Each maps to roadmap phases.

### BATS Infrastructure

- [ ] **INFRA-01**: BATS-core v1.13.0 + helper libraries installed via git submodules (bats-support v0.3.0, bats-assert v2.2.0, bats-file v0.4.0)
- [ ] **INFRA-02**: Shared test helper (`tests/test_helper/common-setup.bash`) handles library loading, PROJECT_ROOT, and strict mode conflict resolution
- [ ] **INFRA-03**: `make test` runs full BATS suite; `make test-verbose` shows TAP output
- [ ] **INFRA-04**: At least one smoke test proves infrastructure works and strict mode conflicts are handled

### Library Unit Tests

- [ ] **UNIT-01**: `parse_common_args` tested for all flag combinations (-h, -v, -q, -x, --, unknown flags, ordering)
- [ ] **UNIT-02**: `require_cmd`, `require_target`, `check_cmd` tested with present and missing commands
- [ ] **UNIT-03**: `info`/`warn`/`error`/`debug` tested for output, LOG_LEVEL filtering, VERBOSE, NO_COLOR
- [ ] **UNIT-04**: `make_temp` tested for file/dir creation and EXIT trap cleanup
- [ ] **UNIT-05**: `run_or_show`, `safety_banner`, `is_interactive` tested for show vs execute mode behavior
- [ ] **UNIT-06**: `retry_with_backoff` tested for retry count, delay, and success/failure paths

### Script Integration Tests

- [ ] **INTG-01**: All scripts exit 0 on `--help` and output contains "Usage:"
- [ ] **INTG-02**: All scripts with `-x` flag reject non-interactive stdin (piped input)
- [ ] **INTG-03**: Scripts discovered dynamically via glob pattern (no hardcoded script lists)
- [ ] **INTG-04**: Mock commands created for CI runners lacking pentesting tools

### CI Integration

- [ ] **CI-01**: GitHub Actions workflow runs BATS tests using bats-action@4.0.0
- [ ] **CI-02**: Test results reported in JUnit format for GitHub test annotations
- [ ] **CI-03**: BATS tests run alongside existing ShellCheck workflow (independent jobs)

### Script Headers

- [ ] **HDR-01**: Header format defined: bordered comment block with Description, Usage, Dependencies fields between shebang and `source` line
- [ ] **HDR-02**: All 17 `examples.sh` scripts have structured headers
- [ ] **HDR-03**: All use-case scripts have structured headers
- [ ] **HDR-04**: All `lib/*.sh` modules have structured headers
- [ ] **HDR-05**: All utility scripts (`common.sh`, `check-tools.sh`, diagnostics) have structured headers
- [ ] **HDR-06**: BATS test validates all `.sh` files have required header fields

## Deferred (v2+)

### Testing Polish

- **TEST-D01**: Mocking framework (bats-mock) for isolating tool dependencies
- **TEST-D02**: Code coverage via bashcov/kcov
- **TEST-D03**: End-to-end tests against Docker lab targets
- **TEST-D04**: Custom test reporter beyond built-in TAP/JUnit
- **TEST-D05**: Auto-generating `--help` output from script headers

## Out of Scope

| Feature | Reason |
|---------|--------|
| bats-mock mocking framework | Scripts are thin wrappers around real tools; mocking tests the mock, not the script |
| 100% code coverage target | Use-case scripts are educational templates; testing `info "1) Ping scan"` is low-value |
| E2E tests against Docker targets | Requires Docker running, images pulled, services healthy; makes CI fragile |
| shdoc build dependency | Overkill for CLI scripts that already have `show_help()` functions |
| Version field in headers | Git handles versioning; redundant metadata drifts |
| Author field in headers | Git handles attribution; redundant metadata drifts |
| shunit2 framework | BATS is the de facto standard for bash testing; no reason for alternatives |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | — | Pending |
| INFRA-02 | — | Pending |
| INFRA-03 | — | Pending |
| INFRA-04 | — | Pending |
| UNIT-01 | — | Pending |
| UNIT-02 | — | Pending |
| UNIT-03 | — | Pending |
| UNIT-04 | — | Pending |
| UNIT-05 | — | Pending |
| UNIT-06 | — | Pending |
| INTG-01 | — | Pending |
| INTG-02 | — | Pending |
| INTG-03 | — | Pending |
| INTG-04 | — | Pending |
| CI-01 | — | Pending |
| CI-02 | — | Pending |
| CI-03 | — | Pending |
| HDR-01 | — | Pending |
| HDR-02 | — | Pending |
| HDR-03 | — | Pending |
| HDR-04 | — | Pending |
| HDR-05 | — | Pending |
| HDR-06 | — | Pending |

**Coverage:**
- v1.3 requirements: 23 total
- Mapped to phases: 0
- Unmapped: 23

---
*Requirements defined: 2026-02-11*
*Last updated: 2026-02-11 after initial definition*
