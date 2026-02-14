# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-13)

**Core value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.
**Current focus:** Milestone v1.4 — JSON Output Mode (Phase 25: Script Migration)

## Current Position

Phase: 25 (Script Migration) — third of 5 in v1.4
Plan: 04 complete (3/4 plans in phase, 03 in progress)
Status: Executing phase 25
Last activity: 2026-02-14 — Completed 25-04 (Group B mixed script migration, 14 scripts)

Progress: [######░░░░] 58% (v1.4 — 2.75/5 phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 56 (across v1.0-v1.4)
- Average duration: 4min
- Total execution time: 3.87 hours

**By Milestone:**

| Milestone | Phases | Plans | Duration |
|-----------|--------|-------|----------|
| v1.0 | 7 | 19 | ~79min |
| v1.1 | 4 | 4 | ~8min |
| v1.2 | 6 | 18 | ~79min |
| v1.3 | 5 | 9 | ~42min |
| v1.4 | 2.75/5 | 6 | ~52min |

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
Stopped at: Completed 25-04-PLAN.md (Group B mixed script migration)
Resume file: None
