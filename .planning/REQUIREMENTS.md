# Requirements: v1.2 Script Hardening

**Defined:** 2026-02-11
**Core Value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.

## v1.2 Requirements

Requirements for the script hardening milestone. Each maps to roadmap phases.

### Pre-Refactor Cleanup

- [ ] **NORM-01**: All 63 interactive guard patterns use one consistent syntax (`[[ ! -t 0 ]] && exit 0`)
- [ ] **NORM-02**: Bash 4.0+ version check in common.sh exits with clear error on older versions
- [ ] **NORM-03**: `.shellcheckrc` created with `source-path` and `external-sources=true` for project structure

### Strict Mode & Error Handling

- [ ] **STRICT-01**: All scripts run with `set -eEuo pipefail` (upgraded from `set -euo pipefail`)
- [ ] **STRICT-02**: ERR trap prints stack trace (file, line, function) to stderr on unhandled errors
- [ ] **STRICT-03**: `shopt -s inherit_errexit` enabled when Bash 4.4+ is detected
- [ ] **STRICT-04**: EXIT trap runs cleanup functions on any exit path (normal, error, Ctrl+C)
- [ ] **STRICT-05**: Source guards (`_MODULE_LOADED` pattern) prevent double-sourcing of library modules

### Logging & Output

- [ ] **LOG-01**: `info/warn/error/success` functions support `LOG_LEVEL` filtering (debug/info/warn/error)
- [ ] **LOG-02**: New `debug()` function available, invisible by default, visible when `VERBOSE=1` or `LOG_LEVEL=debug`
- [ ] **LOG-03**: ANSI color codes disabled when stdout is not a terminal or `NO_COLOR` env var is set
- [ ] **LOG-04**: `-v`/`--verbose` flag enables debug output and timestamps on all scripts
- [ ] **LOG-05**: `-q`/`--quiet` flag suppresses non-error output on all scripts

### Argument Parsing

- [ ] **ARGS-01**: `parse_common_args()` function handles `-h`/`--help`, `-v`/`--verbose`, `-q`/`--quiet`, `-x`/`--execute`
- [ ] **ARGS-02**: Argument parser uses manual `while/case/shift` pattern (no getopts/getopt)
- [ ] **ARGS-03**: Unknown flags pass through to `REMAINING_ARGS` array for per-script handling
- [ ] **ARGS-04**: Positional `$1` as target still works for backward compatibility with Makefile targets

### Dual-Mode Execution

- [ ] **DUAL-01**: `run_or_show()` function shows educational output by default, executes commands when `-x`/`--execute` is passed
- [ ] **DUAL-02**: All 17 examples.sh scripts upgraded to dual-mode with consistent `-x`/`-v`/`-q` flags
- [ ] **DUAL-03**: All 28 use-case scripts upgraded to dual-mode with argument parsing
- [ ] **DUAL-04**: Confirmation prompt displayed before executing active scanning commands in `-x` mode
- [ ] **DUAL-05**: `make <tool> TARGET=<ip>` still works identically after migration

### Script Infrastructure

- [ ] **INFRA-01**: `common.sh` split into `scripts/lib/` modules behind backward-compatible entry point
- [ ] **INFRA-02**: All 66 scripts keep their existing `source "$(dirname "$0")/../common.sh"` line unchanged
- [ ] **INFRA-03**: `make_temp()` function creates temp files/dirs tracked for automatic EXIT trap cleanup
- [ ] **INFRA-04**: `retry_with_backoff()` function available for network operations with configurable max retries

### Code Quality

- [ ] **LINT-01**: ShellCheck returns zero warnings at `--severity=warning` across all scripts
- [ ] **LINT-02**: SC2155 violations fixed (separate `local` declaration from assignment) across all scripts
- [ ] **LINT-03**: `make lint` target runs ShellCheck validation
- [ ] **LINT-04**: CI workflow gates PRs on ShellCheck compliance

## Deferred (v2+)

### Polish

- **POLISH-01**: Bash completion scripts for all tools
- **POLISH-02**: JSON output mode (`--json` flag)
- **POLISH-03**: Execution timer showing elapsed time after `-x` mode
- **POLISH-04**: Script metadata headers with version, description, author
- **POLISH-05**: `--output` flag for saving results to file

## Out of Scope

| Feature | Reason |
|---------|--------|
| JSON structured logging | No downstream consumer exists; adds `jq` dependency for zero user benefit |
| Configuration files (`.rc`) | Overkill for 1-3 argument scripts; environment variables suffice |
| Plugin/extension system | "Copy the pattern" approach is sufficient for 17 tools |
| Automatic tool installation | Running `sudo`/`brew` without consent is unacceptable for security tools |
| Interactive TUI menus | Breaks scriptability, piping, and composition |
| Rewriting in Python/Go | The educational value IS the bash |
| Unit testing framework (bats/shunit2) | External dependency; ShellCheck + smoke tests provide better ROI |
| `IFS=$'\n\t'` global override | Breaks space-separated command construction throughout codebase |
| `getopts`/`getopt` arg parsing | `getopts` lacks long options; macOS BSD `getopt` is broken |
| Per-tool state/history files | Statefulness in security tools is a liability |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| NORM-01 | — | Pending |
| NORM-02 | — | Pending |
| NORM-03 | — | Pending |
| STRICT-01 | — | Pending |
| STRICT-02 | — | Pending |
| STRICT-03 | — | Pending |
| STRICT-04 | — | Pending |
| STRICT-05 | — | Pending |
| LOG-01 | — | Pending |
| LOG-02 | — | Pending |
| LOG-03 | — | Pending |
| LOG-04 | — | Pending |
| LOG-05 | — | Pending |
| ARGS-01 | — | Pending |
| ARGS-02 | — | Pending |
| ARGS-03 | — | Pending |
| ARGS-04 | — | Pending |
| DUAL-01 | — | Pending |
| DUAL-02 | — | Pending |
| DUAL-03 | — | Pending |
| DUAL-04 | — | Pending |
| DUAL-05 | — | Pending |
| INFRA-01 | — | Pending |
| INFRA-02 | — | Pending |
| INFRA-03 | — | Pending |
| INFRA-04 | — | Pending |
| LINT-01 | — | Pending |
| LINT-02 | — | Pending |
| LINT-03 | — | Pending |
| LINT-04 | — | Pending |

**Coverage:**
- v1.2 requirements: 30 total
- Mapped to phases: 0
- Unmapped: 30 (pending roadmap creation)

---
*Requirements defined: 2026-02-11*
*Last updated: 2026-02-11 after initial definition*
