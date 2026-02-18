# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations -- run one command, get what you need.
**Current focus:** Phase 32 - Workflow Skills (v1.5 Claude Skill Pack)

## Current Position

Phase: 32 of 33 (Workflow Skills) — COMPLETE
Plan: 3 of 3 in current phase
Status: Phase complete, ready for Phase 33
Last activity: 2026-02-18 — Completed 32-03 Management Workflow Skills (/report, /scope)

Progress: [████████░░] 73% (v1.5)

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
| v1.4 | 5 | 10 | ~78min |
| v1.5 | 6 | TBD | — |

## Accumulated Context

### Decisions

All decisions archived in milestone ROADMAP archives:
- v1.0: .planning/milestones/v1.0-ROADMAP.md
- v1.1: .planning/milestones/v1.1-ROADMAP.md
- v1.2: .planning/milestones/v1.2-ROADMAP.md
- v1.3: .planning/milestones/v1.3-ROADMAP.md
- v1.4: .planning/milestones/v1.4-ROADMAP.md

Full cumulative decision table in PROJECT.md.

v1.5 research decisions:
- Plugin wraps, never modifies (existing scripts untouched)
- Start with project-level `.claude/skills/`, defer plugin packaging
- Deterministic safety hooks (bash+jq), not LLM-based
- Validate tool skill pattern with 5 before scaling to 17
- Tool skills use `disable-model-invocation: true` (zero context overhead)

Phase 28 execution decisions:
- jq for all hook JSON construction (no string concatenation)
- curl/dig exception: only intercept bare IP/hostname, not URL-based commands
- CIDR /24 via 3-octet prefix match (sufficient for lab scope)
- Strip shell metacharacters from extracted targets for robustness

Phase 29-01 execution decisions:
- Accurate argument docs per script (interface vs target vs LHOST/LPORT) rather than generic [target]
- Included tool-specific default behavior section in each skill
- Used double-dash (--) for markdown list descriptions to match project style

Phase 30-01 execution decisions:
- No disable-model-invocation on utility skills -- Claude should auto-invoke check-tools and lab when relevant
- pentest-conventions uses user-invocable: false to stay out of / menu but load into Claude context
- Kept pentest-conventions under 80 lines for context budget (well under 200 line limit)

Phase 31-01 execution decisions:
- Used offline-tool Target Validation variant for hashcat, john, foremost (no network scope needed)
- Aircrack-ng gets unique wireless Target Validation (BSSID scope applies to wireless interfaces)
- Followed per-script accurate argument documentation pattern from Phase 29

Phase 31-02 execution decisions:
- Documented per-script default targets for skipfish (Juice Shop 3030, DVWA 8080) rather than a single tool default
- Documented netcat variant detection as a Defaults bullet rather than a separate section
- Used [port] argument notation for setup-listener to distinguish from [target] used by other netcat scripts

Phase 31-03 execution decisions:
- Dig skill documents domain argument (not IP/URL) matching dig's actual interface
- Gobuster and ffuf skills document optional second wordlist argument for custom wordlists
- Ffuf skill intentionally smallest (1 use-case + examples) -- no padding added

Phase 32-01 execution decisions:
- Used disable-model-invocation: true on all 3 workflow skills -- user must invoke explicitly, prevents auto-triggering
- /diagnose Pattern B: diagnostics/ scripts invoked without -j -x, tool wrappers with -j -x; documented clearly inline
- Scope validation pattern identical across all 3 skills (check scope.json, ask user to /scope add if missing)

Phase 32-02 execution decisions:
- All 3 offensive workflow skills use disable-model-invocation: true (consistent with Phase 32-01)
- /crack uses identification-then-attack flow: Step 1 always runs, Steps 2-5 are conditional on hash type
- crack-linux-passwords.sh takes no positional arg (handles /etc/shadow internally) -- documented in skill
- /crack offline variant: no network scope validation needed for local hash files and archives
- /sniff dual-mode: $ARGUMENTS accepts network interface (live) or .pcap file (offline analysis)

Phase 32-03 execution decisions:
- Used disable-model-invocation: true for both /report and /scope per plan must_haves
- /report synthesizes from conversation context only -- explicitly prohibits reading audit log files
- /scope default operation is show when no subcommand provided
- jq deduplication via .targets |= unique prevents duplicate scope entries on add
- /scope requires user confirmation before add, remove, and clear operations

### Pending Todos

None.

### Blockers/Concerns

- ~~PostToolUse hook access to `tool_response.stdout` needs validation during Phase 28~~ RESOLVED: field accessible as `.tool_response.stdout`
- ~~Skill description budget (2% context window, ~16KB) -- monitor during Phase 31~~ RESOLVED: 17 tool skills with disable-model-invocation add 0 bytes to context. 4 utility skills use ~8KB (50% of budget)
- Agent `memory: project` feature needs practical testing during Phase 33

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Remove light theme and theme selector, enforce dark-mode only | 2026-02-11 | 1d9f9f0 | [001-remove-light-theme-and-theme-selector-en](./quick/001-remove-light-theme-and-theme-selector-en/) |
| 002 | Review markdown files for LLM writing patterns | 2026-02-11 | 16bf6ee | [002-review-md-files-for-llm-writing-patterns](./quick/002-review-md-files-for-llm-writing-patterns/) |

## Session Continuity

Last session: 2026-02-18
Stopped at: Completed 32-03-PLAN.md (Management Workflow Skills). Phase 32 complete (3/3 plans).
Resume file: None
