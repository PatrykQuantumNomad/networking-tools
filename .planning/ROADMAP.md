## Roadmap: Networking Tools

## Milestones

- ✅ **v1.0 Networking Tools Expansion** — Phases 1-7 (shipped 2026-02-11)
- ✅ **v1.1 Site Visual Refresh** — Phases 8-11 (shipped 2026-02-11)
- ✅ **v1.2 Script Hardening** — Phases 12-17 (shipped 2026-02-11)
- ✅ **v1.3 Testing & Script Headers** — Phases 18-22 (shipped 2026-02-12)
- ✅ **v1.4 JSON Output Mode** — Phases 23-27 (shipped 2026-02-14)
- 🚧 **v1.5 Claude Skill Pack** — Phases 28-33 (in progress)

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

</details>

<details>
<summary>✅ v1.4 JSON Output Mode (Phases 23-27) — SHIPPED 2026-02-14</summary>

Archived to `.planning/milestones/v1.4-ROADMAP.md`

5 phases, 10 plans completed in ~78 minutes.

- [x] Phase 23: JSON Library & Flag Integration (1/1 plans) — completed 2026-02-13
- [x] Phase 24: Library Unit Tests (2/2 plans) — completed 2026-02-13
- [x] Phase 25: Script Migration (4/4 plans) — completed 2026-02-14
- [x] Phase 26: Integration Tests (1/1 plans) — completed 2026-02-14
- [x] Phase 27: Documentation (2/2 plans) — completed 2026-02-14

</details>

### 🚧 v1.5 Claude Skill Pack (In Progress)

**Milestone Goal:** Package the 17-tool, 81-script pentesting toolkit as a self-contained Claude Code skill pack with task-level and tool-level slash commands, safety/feedback hooks, and audit logging.

- [x] **Phase 28: Safety Architecture** - PreToolUse/PostToolUse hooks, audit logging, and health check — completed 2026-02-17
- [ ] **Phase 29: Core Tool Skills** - First 5 tool skills (nmap, tshark, metasploit, sqlmap, nikto) to validate the pattern
- [ ] **Phase 30: Utility Skills & Lab Integration** - Check-tools, lab management, and conventions background skill
- [ ] **Phase 31: Remaining Tool Skills** - Scale validated pattern to all 17 tools (12 remaining)
- [ ] **Phase 32: Workflow Skills** - Task-oriented slash commands that orchestrate tool skills
- [ ] **Phase 33: Subagent Personas** - Pentester, defender, and analyst subagents for multi-tool orchestration

## Phase Details

### Phase 28: Safety Architecture
**Goal**: All Claude Code tool invocations pass through deterministic safety validation before execution, with structured feedback and a complete audit trail
**Depends on**: Nothing (first phase of v1.5)
**Requirements**: SAFE-01, SAFE-02, SAFE-03, SAFE-04, SAFE-05
**Success Criteria** (what must be TRUE):
  1. Running a bash command with a target not in the allowlist is blocked by the PreToolUse hook before execution
  2. Running a raw tool command (e.g., `nmap 10.0.0.1`) that bypasses wrapper scripts is intercepted and blocked
  3. After a skill script runs with `-j`, Claude receives parsed JSON context describing the results (not raw output)
  4. Every skill invocation produces a timestamped entry in the audit log file
  5. User can run a health-check command that confirms hooks are installed and firing correctly
**Plans:** 2 plans

Plans:
- [x] 28-01-PLAN.md — PreToolUse/PostToolUse hooks with target validation, raw tool interception, JSON bridge, and audit logging
- [x] 28-02-PLAN.md — Health-check bash script, Claude Code skill, and live verification

### Phase 29: Core Tool Skills
**Goal**: Users can invoke the 5 most-used pentesting tools via Claude Code slash commands with zero-context-overhead skill files
**Depends on**: Phase 28 (safety hooks must validate commands before tool skills can run)
**Requirements**: TOOL-01, TOOL-02, TOOL-03, TOOL-04, TOOL-05
**Success Criteria** (what must be TRUE):
  1. User can invoke nmap skill and Claude runs the appropriate wrapper script against a specified target
  2. User can invoke tshark, metasploit, sqlmap, and nikto skills the same way
  3. All 5 tool skills have `disable-model-invocation: true` so Claude never auto-invokes them
  4. Each skill's instructions reference the correct existing scripts by path and describe available use-case scripts
**Plans**: 2 plans

Plans:
- [ ] 29-01-PLAN.md — Create nmap, tshark, and metasploit skills
- [ ] 29-02-PLAN.md — Create sqlmap and nikto skills, verify all 5 work end-to-end

### Phase 30: Utility Skills & Lab Integration
**Goal**: Users can check tool availability, manage Docker lab targets, and benefit from automatic pentesting conventions context
**Depends on**: Phase 28 (audit logging covers utility invocations)
**Requirements**: UTIL-01, UTIL-02, UTIL-03
**Success Criteria** (what must be TRUE):
  1. User can invoke check-tools skill and see which of the 17 tools are installed
  2. User can invoke lab skill to start, stop, and check status of Docker vulnerable targets
  3. Claude automatically has pentesting conventions context (target notation, output expectations, safety rules) without the user loading anything
**Plans**: TBD

Plans:
- [ ] 30-01: TBD

### Phase 31: Remaining Tool Skills
**Goal**: All 17 tools have Claude Code skill files, completing full tool coverage
**Depends on**: Phase 29 (pattern validated with first 5 tools)
**Requirements**: TOOL-06, TOOL-07, TOOL-08, TOOL-09, TOOL-10, TOOL-11, TOOL-12, TOOL-13, TOOL-14, TOOL-15, TOOL-16, TOOL-17
**Success Criteria** (what must be TRUE):
  1. User can invoke skill for each of the 12 remaining tools (hashcat, john, hping3, skipfish, aircrack-ng, dig, curl, netcat, traceroute/mtr, gobuster, ffuf, foremost)
  2. All 12 skills follow the same pattern validated in Phase 29 (frontmatter, instructions, script references)
  3. All 12 skills have `disable-model-invocation: true`
  4. Total skill description budget stays within Claude's 2% context window limit
**Plans**: TBD

Plans:
- [ ] 31-01: TBD
- [ ] 31-02: TBD

### Phase 32: Workflow Skills
**Goal**: Users can invoke task-oriented slash commands that orchestrate multiple tool skills into coherent pentesting workflows
**Depends on**: Phase 31 (workflow skills reference tool skills that must exist)
**Requirements**: WKFL-01, WKFL-02, WKFL-03, WKFL-04, WKFL-05, WKFL-06, WKFL-07, WKFL-08
**Success Criteria** (what must be TRUE):
  1. User can invoke `/recon` and Claude orchestrates host discovery, DNS enumeration, and OSINT gathering
  2. User can invoke `/scan`, `/diagnose`, `/fuzz`, `/crack`, and `/sniff` to run their respective multi-tool workflows
  3. User can invoke `/report` and Claude generates a structured findings report from the session
  4. User can invoke `/scope` to define target scope that the safety hooks enforce
  5. Each workflow skill references the correct tool skills and scripts for its domain
**Plans**: TBD

Plans:
- [ ] 32-01: TBD
- [ ] 32-02: TBD

### Phase 33: Subagent Personas
**Goal**: Specialized subagents provide context-isolated, role-specific analysis for multi-tool pentesting workflows
**Depends on**: Phase 32 (agents orchestrate workflow and tool skills)
**Requirements**: AGNT-01, AGNT-02, AGNT-03
**Success Criteria** (what must be TRUE):
  1. User can invoke pentester subagent that orchestrates multi-tool attack workflows with verbose output isolated from main conversation
  2. User can invoke defender subagent that analyzes scan findings from a defensive/mitigation perspective
  3. User can invoke analyst subagent that synthesizes results across multiple scans into a structured analysis report
**Plans**: TBD

Plans:
- [ ] 33-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 28 → 29 → 30 → 31 → 32 → 33

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-7 | v1.0 | 19/19 | Complete | 2026-02-11 |
| 8-11 | v1.1 | 4/4 | Complete | 2026-02-11 |
| 12-17 | v1.2 | 18/18 | Complete | 2026-02-11 |
| 18-22 | v1.3 | 9/9 | Complete | 2026-02-12 |
| 23-27 | v1.4 | 10/10 | Complete | 2026-02-14 |
| 28. Safety Architecture | v1.5 | 2/2 | Complete | 2026-02-17 |
| 29. Core Tool Skills | v1.5 | 0/2 | Not started | - |
| 30. Utility Skills & Lab | v1.5 | 0/TBD | Not started | - |
| 31. Remaining Tool Skills | v1.5 | 0/TBD | Not started | - |
| 32. Workflow Skills | v1.5 | 0/TBD | Not started | - |
| 33. Subagent Personas | v1.5 | 0/TBD | Not started | - |

**Total: 5 milestones shipped (27 phases, 60 plans) + v1.5 in progress (6 phases)**
