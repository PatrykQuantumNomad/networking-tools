# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-11)

**Core value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.
**Current focus:** v1.2 Script Hardening -- Phase 15 Examples Script Migration

## Current Position

Phase: 15 of 17 (Examples Script Migration) -- IN PROGRESS
Plan: 3 of 4 in current phase (01, 02, 03 done -- 04 remaining)
Status: Completed 15-02 edge-case target scripts migration
Last activity: 2026-02-11 -- Completed 15-02 (curl, traceroute, netcat, foremost)

Progress: [██████░░░░] 63%

## Performance Metrics

**Velocity:**
- Total plans completed: 31
- Average duration: 4min
- Total execution time: 1.90 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundations | 3 | 7min | 2min |
| 02-core-networking-tools | 3 | 11min | 4min |
| 03-diagnostic-scripts | 2 | 7min | 4min |
| 04-content-migration-and-tool-pages | 3 | 17min | 6min |
| 05-advanced-tools | 2 | 11min | 6min |
| 06-site-polish-and-learning-paths | 3 | 16min | 5min |
| 07-web-enumeration-tools | 3 | 10min | 3min |
| 08-theme-foundation | 1 | 2min | 2min |
| 09-brand-identity | 1 | 2min | 2min |
| 10-navigation-cleanup | 1 | 2min | 2min |
| 11-homepage-redesign | 1 | 2min | 2min |
| 12-pre-refactor-cleanup | 1 | 6min | 6min |
| 13-library-infrastructure | 2 | 10min | 5min |
| 14-argument-parsing-and-dual-mode-pattern | 2 | 5min | 3min |
| 15-examples-script-migration | 3 | 15min | 5min |

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0 decisions archived -- see .planning/milestones/v1.0-ROADMAP.md for full history.
All v1.1 decisions archived -- see .planning/milestones/v1.1-ROADMAP.md for full history.

Recent decisions affecting v1.2:
- Research: 8-file library split (not 2-file) for maintainability
- Research: Manual while/case arg parsing (not getopts/getopt)
- Research: ERR trap prints stack trace to stderr (not silent log file)
- Research: Unknown flags pass through to REMAINING_ARGS (permissive)
- Research: Enhance existing info/warn/error in-place (not parallel log_* functions)
- 12-01: Standard comment "# Interactive demo (skip if non-interactive)" for all guards
- 12-01: Version guard before set -euo pipefail using only Bash 2.x+ syntax
- 12-01: Three source-path entries in .shellcheckrc (SCRIPTDIR, SCRIPTDIR/.., SCRIPTDIR/../lib)
- 13-01: ERR trap uses plain echo (not library functions) to avoid recursion
- 13-01: EXIT trap only (not INT/TERM) per Greg's Wiki -- avoids double execution
- 13-01: Colors disabled via empty strings (not unset) preserving variable references
- 13-01: VERBOSE >= 1 overrides LOG_LEVEL to debug for single-knob verbosity
- 13-02: Base temp directory instead of array tracking for make_temp -- avoids subshell array loss
- 14-01: EXECUTE_MODE defaults to "show" -- all scripts backward compatible without code changes
- 14-01: Unknown flags pass through to REMAINING_ARGS (permissive) for per-script extensibility
- 14-01: confirm_execute refuses non-interactive stdin in execute mode -- prevents silent automated pentesting
- 14-01: Example 9 (hardcoded subnet) kept as static info+echo -- run_or_show only for $TARGET commands
- 14-02: warn() outputs to stdout not stderr -- tests check combined output for interactive terminal warning
- 14-02: Unit tests reset globals between parse_common_args calls for isolation
- 15-01: Static/annotated examples kept as info+echo (no $TARGET, placeholders, or multi-line comments)
- 15-01: exit 0 removed from show_help() in scripts that had embedded exit (skipfish, nikto, sqlmap)
- 15-01: EXECUTE_MODE guard wraps entire interactive demo section, not just the tty check
- 15-03: No run_or_show conversions for no-target scripts -- all 50 examples are static reference commands
- 15-03: confirm_execute called without argument for no-target scripts
- 15-03: Sample file creation (hashcat/john) left after parse_common_args -- --help exits before creating samples
- 15-02: Complex format strings (curl timing) and missing-tool commands (mtr) kept as info+echo
- 15-02: Variant-specific case/if examples (netcat) are inherently show-only -- kept as info+echo
- 15-02: Optional target scripts (foremost) call confirm_execute with empty arg
- 15-02: Platform conditionals (traceroute) wrap run_or_show calls, not the other way around

### Pending Todos

None.

### Blockers/Concerns

- Exact ShellCheck warning count unknown until Phase 17 planning (run shellcheck first to scope)
- Pattern B diagnostic scripts (3 scripts) may not need dual-mode -- clarify during Phase 16

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Remove light theme and theme selector, enforce dark-mode only | 2026-02-11 | 1d9f9f0 | [001-remove-light-theme-and-theme-selector-en](./quick/001-remove-light-theme-and-theme-selector-en/) |

## Session Continuity

Last session: 2026-02-11
Stopped at: Completed 15-02-PLAN.md (edge-case target scripts migration) -- Plans 01, 02, 03 done, 15-04 next
Resume file: None
