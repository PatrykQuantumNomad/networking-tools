# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-13)

**Core value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.
**Current focus:** Milestone v1.4 — JSON Output Mode (Phase 27: Documentation)

## Current Position

Phase: 27 (Documentation) — fifth of 5 in v1.4
Plan: 02 complete (2/2 plans in phase)
Status: Phase 27 complete. v1.4 milestone complete.
Last activity: 2026-02-14 — Completed 27-02 (BATS verification tests for JSON flag documentation)

Progress: [##########] 100% (v1.4 — 5/5 phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 60 (across v1.0-v1.4)
- Average duration: 4min
- Total execution time: 4.14 hours

**By Milestone:**

| Milestone | Phases | Plans | Duration |
|-----------|--------|-------|----------|
| v1.0 | 7 | 19 | ~79min |
| v1.1 | 4 | 4 | ~8min |
| v1.2 | 6 | 18 | ~79min |
| v1.3 | 5 | 9 | ~42min |
| v1.4 | 5/5 | 10 | ~78min |

## Accumulated Context

### Decisions

All decisions archived in milestone ROADMAP archives:
- v1.0: .planning/milestones/v1.0-ROADMAP.md
- v1.1: .planning/milestones/v1.1-ROADMAP.md
- v1.2: .planning/milestones/v1.2-ROADMAP.md
- v1.3: .planning/milestones/v1.3-ROADMAP.md

Full cumulative decision table in PROJECT.md.

**v1.4 decisions:**
- Phase 23-01: fd3 for JSON output (exec 3>&1 saves stdout, exec 1>&2 redirects to stderr)
- Phase 23-01: Lazy jq dependency (check at source time, require only when -j parsed)
- Phase 23-01: Color vars reset at parse time (colors.sh evaluates at source, -j resets at runtime)
- Phase 25-01: Category parameter optional (empty string default) for backward compatibility
- Phase 25-01: json_add_example for bare info+echo examples to capture all 10 results in JSON
- Phase 25-02: Category taxonomy extended with password-cracker (hashcat/john) and exploitation (aircrack-ng/metasploit)
- Phase 25-04: json_add_example only for bare info+echo (run_or_show captured automatically by library)
- Phase 25-03: NC_VARIANT branching: json_add_example inside each conditional branch for variant-specific commands
- Phase 26-01: bash -c wrapper for BATS fd3 JSON capture (run mixes stdout+stderr; bash -c with 2>/dev/null isolates JSON)
- Phase 27-01: -j after -h in Options for Pattern A scripts; separate Flags section for Pattern B scripts; 5-flag variant for curl/dig
- Phase 27-02: No macOS exclusion needed for DOC tests (--help and header parsing don't require sudo)

### Pending Todos

None.

### Blockers/Concerns

None. (Phase 24 fd3 concern resolved: subprocess `exec 3>&-` pattern works, no need for `run --separate-stderr`)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Remove light theme and theme selector, enforce dark-mode only | 2026-02-11 | 1d9f9f0 | [001-remove-light-theme-and-theme-selector-en](./quick/001-remove-light-theme-and-theme-selector-en/) |
| 002 | Review markdown files for LLM writing patterns | 2026-02-11 | 16bf6ee | [002-review-md-files-for-llm-writing-patterns](./quick/002-review-md-files-for-llm-writing-patterns/) |

## Session Continuity

Last session: 2026-02-14
Stopped at: Completed 27-02-PLAN.md (documentation verification tests). Phase 27 and v1.4 milestone complete.
Resume file: None
