# Roadmap: Networking Tools

## Milestones

- SHIPPED **v1.0 Networking Tools Expansion** — Phases 1-7 (shipped 2026-02-11)
- SHIPPED **v1.1 Site Visual Refresh** — Phases 8-11 (shipped 2026-02-11)
- ACTIVE **v1.2 Script Hardening** — Phases 12-17

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

- [x] Phase 8: Theme Foundation (1/1 plans) — completed 2026-02-11
- [x] Phase 9: Brand Identity (1/1 plans) — completed 2026-02-11
- [x] Phase 10: Navigation Cleanup (1/1 plans) — completed 2026-02-11
- [x] Phase 11: Homepage Redesign (1/1 plans) — completed 2026-02-11

</details>

### v1.2 Script Hardening

**Milestone Goal:** Transform 66 educational bash scripts into production-grade dual-mode CLI tools backed by a modular library with strict mode, structured logging, argument parsing, and ShellCheck compliance.

- [ ] **Phase 12: Pre-Refactor Cleanup** - Normalize inconsistencies before structural changes
- [ ] **Phase 13: Library Infrastructure** - Split common.sh into modules with strict mode, logging, traps, and helpers
- [ ] **Phase 14: Argument Parsing and Dual-Mode Pattern** - Build the arg parser and run_or_show mechanism, prove with pilot
- [ ] **Phase 15: Examples Script Migration** - Upgrade all 17 examples.sh to dual-mode
- [ ] **Phase 16: Use-Case Script Migration** - Upgrade all 28 use-case scripts to dual-mode
- [ ] **Phase 17: ShellCheck Compliance and CI** - Zero warnings across all scripts with CI gating

## Phase Details

### Phase 12: Pre-Refactor Cleanup
**Goal**: Codebase is normalized and ready for structural changes -- no inconsistencies that would cause missed scripts during migration
**Depends on**: Phase 11 (v1.1 complete)
**Requirements**: NORM-01, NORM-02, NORM-03
**Success Criteria** (what must be TRUE):
  1. Every script with an interactive guard uses identical `[[ ! -t 0 ]] && exit 0` syntax (zero variants)
  2. Running any script with Bash 3.x produces a clear version error instead of cryptic failures
  3. ShellCheck resolves `source common.sh` paths without manual overrides when run from any directory
**Plans**: 1 plan

Plans:
- [ ] 12-01-PLAN.md — Normalize guards, add bash version check, create .shellcheckrc

### Phase 13: Library Infrastructure
**Goal**: Scripts source a modular library that provides strict mode, stack traces on error, log-level filtering, automatic temp cleanup, and retry logic -- all behind the existing common.sh entry point
**Depends on**: Phase 12
**Requirements**: STRICT-01, STRICT-02, STRICT-03, STRICT-04, STRICT-05, LOG-01, LOG-02, LOG-03, LOG-04, LOG-05, INFRA-01, INFRA-02, INFRA-03, INFRA-04
**Success Criteria** (what must be TRUE):
  1. All 66 scripts run with their existing `source common.sh` line unchanged and produce identical output to before
  2. An unhandled error in any script prints a stack trace (file, line, function) to stderr before exiting
  3. Running `VERBOSE=1 bash scripts/nmap/examples.sh scanme.nmap.org` shows debug-level messages and timestamps; running without VERBOSE shows normal output
  4. Piping any script through `cat` (non-terminal stdout) produces output with zero ANSI escape codes
  5. A script that creates temp files via `make_temp()` cleans them up on normal exit, error exit, and Ctrl+C
**Plans**: TBD

Plans:
- [ ] 13-01: TBD
- [ ] 13-02: TBD

### Phase 14: Argument Parsing and Dual-Mode Pattern
**Goal**: Every script can accept `-h`, `-v`, `-q`, `-x` flags through a shared parser, and `run_or_show()` either displays educational content or executes commands based on the flag
**Depends on**: Phase 13
**Requirements**: ARGS-01, ARGS-02, ARGS-03, ARGS-04, DUAL-01
**Success Criteria** (what must be TRUE):
  1. Running `scripts/nmap/examples.sh --help` prints usage information; `-h` does the same
  2. Running `scripts/nmap/examples.sh scanme.nmap.org` shows educational examples (backward compatible, no behavioral change)
  3. Running `scripts/nmap/examples.sh -x scanme.nmap.org` prompts for confirmation then executes the commands
  4. Running `make nmap TARGET=scanme.nmap.org` still works identically (positional arg backward compatibility)
  5. Unknown flags like `--custom-thing` pass through without error (available in REMAINING_ARGS for per-script use)
**Plans**: TBD

Plans:
- [ ] 14-01: TBD
- [ ] 14-02: TBD

### Phase 15: Examples Script Migration
**Goal**: All 17 examples.sh scripts work in dual mode with consistent flags across every tool
**Depends on**: Phase 14
**Requirements**: DUAL-02, DUAL-04, DUAL-05
**Success Criteria** (what must be TRUE):
  1. Every examples.sh script accepts `-x`/`--execute`, `-v`/`--verbose`, `-q`/`--quiet`, `-h`/`--help` flags
  2. Running any examples.sh without `-x` produces the same educational output as before the migration
  3. Running any examples.sh with `-x` displays a confirmation prompt before executing active scanning commands
  4. All `make <tool> TARGET=<ip>` Makefile targets produce identical behavior to pre-migration
**Plans**: TBD

Plans:
- [ ] 15-01: TBD
- [ ] 15-02: TBD

### Phase 16: Use-Case Script Migration
**Goal**: All 28 use-case scripts work in dual mode with argument parsing
**Depends on**: Phase 15
**Requirements**: DUAL-03
**Success Criteria** (what must be TRUE):
  1. Every use-case script accepts `-x`/`--execute`, `-v`/`--verbose`, `-q`/`--quiet`, `-h`/`--help` flags
  2. Running any use-case script without `-x` shows educational content explaining what the script does
  3. Running any use-case script with `-x` executes the commands with appropriate safety prompts
**Plans**: TBD

Plans:
- [ ] 16-01: TBD
- [ ] 16-02: TBD

### Phase 17: ShellCheck Compliance and CI
**Goal**: Every script passes ShellCheck at warning severity with CI enforcement preventing regressions
**Depends on**: Phase 16
**Requirements**: LINT-01, LINT-02, LINT-03, LINT-04
**Success Criteria** (what must be TRUE):
  1. `shellcheck --severity=warning` returns exit 0 on every `.sh` file in the repository
  2. `make lint` runs ShellCheck validation and reports results
  3. A PR that introduces a ShellCheck warning fails CI checks
  4. No `local var=$(cmd)` patterns remain (SC2155 fully resolved)
**Plans**: TBD

Plans:
- [ ] 17-01: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-7 | v1.0 | 19/19 | Complete | 2026-02-11 |
| 8. Theme Foundation | v1.1 | 1/1 | Complete | 2026-02-11 |
| 9. Brand Identity | v1.1 | 1/1 | Complete | 2026-02-11 |
| 10. Navigation Cleanup | v1.1 | 1/1 | Complete | 2026-02-11 |
| 11. Homepage Redesign | v1.1 | 1/1 | Complete | 2026-02-11 |
| 12. Pre-Refactor Cleanup | v1.2 | 0/1 | Not started | - |
| 13. Library Infrastructure | v1.2 | 0/TBD | Not started | - |
| 14. Argument Parsing + Dual-Mode | v1.2 | 0/TBD | Not started | - |
| 15. Examples Script Migration | v1.2 | 0/TBD | Not started | - |
| 16. Use-Case Script Migration | v1.2 | 0/TBD | Not started | - |
| 17. ShellCheck Compliance + CI | v1.2 | 0/TBD | Not started | - |
