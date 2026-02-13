# Roadmap: Networking Tools

## Milestones

- ✅ **v1.0 Networking Tools Expansion** — Phases 1-7 (shipped 2026-02-11)
- ✅ **v1.1 Site Visual Refresh** — Phases 8-11 (shipped 2026-02-11)
- ✅ **v1.2 Script Hardening** — Phases 12-17 (shipped 2026-02-11)
- ✅ **v1.3 Testing & Script Headers** — Phases 18-22 (shipped 2026-02-12)
- 🚧 **v1.4 JSON Output Mode** — Phases 23-27 (in progress)

## Phases

<details>
<summary>✅ v1.0 Networking Tools Expansion (Phases 1-7) — SHIPPED 2026-02-11</summary>

Archived to `.planning/milestones/v1.0-ROADMAP.md`

7 phases, 19 plans, 47 tasks completed in 2 days.

</details>

<details>
<summary>✅ v1.1 Site Visual Refresh (Phases 8-11) — SHIPPED 2026-02-11</summary>

Archived to `.planning/milestones/v1.1-ROADMAP.md`

4 phases, 4 plans, 7 tasks completed in ~4.5 hours.

</details>

<details>
<summary>✅ v1.2 Script Hardening (Phases 12-17) — SHIPPED 2026-02-11</summary>

Archived to `.planning/milestones/v1.2-ROADMAP.md`

6 phases, 18 plans completed in ~1.3 hours.

</details>

<details>
<summary>✅ v1.3 Testing & Script Headers (Phases 18-22) — SHIPPED 2026-02-12</summary>

Archived to `.planning/milestones/v1.3-ROADMAP.md`

5 phases, 9 plans completed in ~42 minutes.

- [x] Phase 18: BATS Infrastructure (1/1 plans) — completed 2026-02-12
- [x] Phase 19: Library Unit Tests (3/3 plans) — completed 2026-02-12
- [x] Phase 20: Script Integration Tests (1/1 plans) — completed 2026-02-12
- [x] Phase 21: CI Integration (1/1 plans) — completed 2026-02-12
- [x] Phase 22: Script Metadata Headers (3/3 plans) — completed 2026-02-12

</details>

### 🚧 v1.4 JSON Output Mode (In Progress)

**Milestone Goal:** Add structured JSON output to all 46 use-case scripts via `-j`/`--json` flag backed by `lib/json.sh`, enabling piping into `jq` and downstream automation.

- [x] **Phase 23: JSON Library & Flag Integration** - Build lib/json.sh module and wire -j flag into argument parsing and output infrastructure (completed 2026-02-13)
- [x] **Phase 24: Library Unit Tests** - Validate JSON library functions and -j flag parsing with BATS before migrating scripts (completed 2026-02-13)
- [ ] **Phase 25: Script Migration** - Add JSON support to all 46 use-case scripts
- [ ] **Phase 26: Integration Tests** - Validate every migrated script produces correct, parseable JSON output
- [ ] **Phase 27: Documentation** - Update help text and metadata headers to reflect JSON output capability

## Phase Details

### Phase 23: JSON Library & Flag Integration
**Goal**: Users can pass `-j`/`--json` to any script and the library infrastructure correctly activates JSON mode with clean stdout separation
**Depends on**: Phase 22 (v1.3 complete)
**Requirements**: JSON-01, JSON-02, JSON-03, JSON-04, JSON-05, JSON-06, FLAG-01, FLAG-02, FLAG-03, FLAG-04, FLAG-05
**Success Criteria** (what must be TRUE):
  1. Running any use-case script with `-j -x` activates JSON mode and produces an envelope with `meta`, `results`, and `summary` keys on stdout, while all human-readable output goes to stderr
  2. Running a script with `-j` (without `-x`) outputs example commands structured as JSON rather than plain text
  3. `jq` is only required when `-j` is actually passed -- scripts without `-j` work identically to before even if jq is not installed
  4. All JSON values are correctly escaped per RFC 8259 (special characters, quotes, newlines in tool output do not break the JSON structure)
  5. Interactive prompts from `confirm_execute()` are automatically suppressed in JSON mode, and color codes are disabled via `NO_COLOR=1`
**Plans:** 1 plan
Plans:
- [x] 23-01-PLAN.md -- Create lib/json.sh, wire -j flag into args.sh, add JSON branches to output.sh

### Phase 24: Library Unit Tests
**Goal**: The JSON library and flag parsing are proven correct via automated tests before any scripts are modified
**Depends on**: Phase 23
**Requirements**: TEST-01, TEST-02
**Success Criteria** (what must be TRUE):
  1. BATS unit tests cover all 4 public json.sh functions (`json_is_active`, `json_set_meta`, `json_add_result`, `json_finalize`) including edge cases like empty results and special character escaping
  2. BATS unit tests validate that `parse_common_args` recognizes `-j`/`--json`, sets `OUTPUT_FORMAT=json`, and correctly interacts with `-x`/`-h`/`-v`/`-q` flags
  3. All new tests pass in both local runs and CI (GitHub Actions)
**Plans:** 2 plans
Plans:
- [x] 24-01-PLAN.md -- Create tests/lib-json.bats with unit tests for all json.sh functions
- [x] 24-02-PLAN.md -- Add -j flag tests to lib-args.bats and JSON-mode tests to lib-output.bats

### Phase 25: Script Migration
**Goal**: All 46 use-case scripts produce structured JSON output when invoked with `-j`
**Depends on**: Phase 24
**Requirements**: SCRIPT-01, SCRIPT-02, SCRIPT-03, SCRIPT-04
**Success Criteria** (what must be TRUE):
  1. Every one of the 46 use-case scripts calls `json_set_meta` with correct tool name, script name, and category, and calls `json_finalize` at exit
  2. Scripts that use `run_or_show` get JSON result accumulation automatically via library-level changes (no per-script JSON wiring needed for command capture)
  3. Scripts that use `info`+`echo` patterns for educational output have those outputs captured as JSON results via accumulation helpers
  4. Running any use-case script with `-j -x <target>` produces a complete JSON envelope that passes `jq .` validation
**Plans**: TBD

### Phase 26: Integration Tests
**Goal**: Automated tests prove every script's JSON output is valid and structurally correct
**Depends on**: Phase 25
**Requirements**: TEST-03, TEST-04
**Success Criteria** (what must be TRUE):
  1. BATS integration tests exercise every one of the 46 use-case scripts with `-j` and validate the output passes `jq .` (valid JSON)
  2. Integration tests verify the JSON envelope structure contains required keys (`meta.tool`, `meta.script`, `meta.timestamp`, `results`, `summary`)
  3. All integration tests pass in CI alongside existing 265-test suite
**Plans**: TBD

### Phase 27: Documentation
**Goal**: Users can discover and understand the `-j`/`--json` flag through help text and script headers
**Depends on**: Phase 25
**Requirements**: DOC-01, DOC-02
**Success Criteria** (what must be TRUE):
  1. Running any use-case script with `-h` shows `-j`/`--json` in the flags list with a clear description of what it does
  2. All 46 use-case scripts' metadata headers include JSON output as a documented capability
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-7 | v1.0 | 19/19 | Complete | 2026-02-11 |
| 8-11 | v1.1 | 4/4 | Complete | 2026-02-11 |
| 12-17 | v1.2 | 18/18 | Complete | 2026-02-11 |
| 18-22 | v1.3 | 9/9 | Complete | 2026-02-12 |
| 23. JSON Library & Flag Integration | v1.4 | 1/1 | Complete | 2026-02-13 |
| 24. Library Unit Tests | v1.4 | 2/2 | Complete | 2026-02-13 |
| 25. Script Migration | v1.4 | 0/TBD | Not started | - |
| 26. Integration Tests | v1.4 | 0/TBD | Not started | - |
| 27. Documentation | v1.4 | 0/TBD | Not started | - |

**Total: 4 milestones shipped (22 phases, 50 plans) + 1 milestone in progress (5 phases, 2/5 complete)**
