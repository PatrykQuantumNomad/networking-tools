## Roadmap: Networking Tools

## Milestones

- ✅ **v1.0 Networking Tools Expansion** — Phases 1-7 (shipped 2026-02-11)
- ✅ **v1.1 Site Visual Refresh** — Phases 8-11 (shipped 2026-02-11)
- ✅ **v1.2 Script Hardening** — Phases 12-17 (shipped 2026-02-11)
- ✅ **v1.3 Testing & Script Headers** — Phases 18-22 (shipped 2026-02-12)
- ✅ **v1.4 JSON Output Mode** — Phases 23-27 (shipped 2026-02-14)
- ✅ **v1.5 Claude Skill Pack** — Phases 28-33 (shipped 2026-02-18)
- ✅ **v1.6 Skills.sh Publication** — Phases 34-39 (shipped 2026-03-07)

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

</details>

<details>
<summary>✅ v1.5 Claude Skill Pack (Phases 28-33) — SHIPPED 2026-02-18</summary>

Archived to `.planning/milestones/v1.5-ROADMAP.md`

6 phases, 13 plans, 60 commits completed in 2 days.

- [x] Phase 28: Safety Architecture (2/2 plans) — completed 2026-02-17
- [x] Phase 29: Core Tool Skills (2/2 plans) — completed 2026-02-17
- [x] Phase 30: Utility Skills & Lab Integration (1/1 plan) — completed 2026-02-18
- [x] Phase 31: Remaining Tool Skills (3/3 plans) — completed 2026-02-18
- [x] Phase 32: Workflow Skills (3/3 plans) — completed 2026-02-18
- [x] Phase 33: Subagent Personas (2/2 plans) — completed 2026-02-18

</details>

### ✅ v1.6 Skills.sh Publication (SHIPPED 2026-03-07)

**Milestone Goal:** Publish standalone pentesting skills pack (skills + hooks + agents) to skills.sh, installable via `npx skills add` and Claude plugin marketplace, with zero GSD framework leakage and full safety infrastructure portability.

- [x] **Phase 34: Plugin Scaffold and GSD Separation** - Establish netsec-skills/ plugin directory with manifest, marketplace catalog, and clean GSD boundary (completed 2026-03-06)
- [x] **Phase 35: Portable Safety Infrastructure** - Make hooks, scope management, and health check work outside the repo via portable path resolution (completed 2026-03-06)
- [x] **Phase 36: Dual-Mode Tool Skills** - Transform 17 tool skills to work standalone (direct commands) and in-repo (wrapper scripts) with install detection (completed 2026-03-06)
- [x] **Phase 37: Standalone Workflow Skills** - Port 6 workflow skills with dual-mode branching at every step (completed 2026-03-06)
- [x] **Phase 38: Agent Personas** - Port 3 agent definitions and invoker skills with verified plugin namespace resolution (completed 2026-03-06)
- [x] **Phase 39: End-to-End Testing and Publication** - Verify full plugin installation, publish to skills.sh, confirm two-channel distribution (completed 2026-03-07)

## Phase Details

### Phase 34: Plugin Scaffold and GSD Separation
**Goal**: Users can load a clean netsec-only plugin directory that contains zero GSD framework artifacts
**Depends on**: Nothing (first phase of v1.6)
**Requirements**: PLUG-01, PLUG-02, PLUG-03
**Success Criteria** (what must be TRUE):
  1. `netsec-skills/` directory exists with a valid `.claude-plugin/plugin.json` manifest and `claude --plugin-dir ./netsec-skills` loads without errors
  2. `marketplace.json` in the plugin root lists all skills, hooks, and agents that will be published
  3. The `netsec-skills/` directory contains zero files with `gsd-` prefix, zero GSD agents, zero GSD hooks, zero GSD commands or templates
  4. Plugin directory structure has `skills/`, `agents/`, `hooks/`, and `scripts/` subdirectories matching the Claude Code plugin format
**Plans**: 2 plans

Plans:
- [x] 34-01-PLAN.md — Plugin directory scaffold with manifest, hooks, symlinks, marketplace catalog, and README
- [x] 34-02-PLAN.md — Boundary validation script and comprehensive scaffold verification

### Phase 35: Portable Safety Infrastructure
**Goal**: Users can validate scope, audit tool invocations, and check netsec health from a plugin install outside the networking-tools repo
**Depends on**: Phase 34
**Requirements**: SAFE-01, SAFE-02, SAFE-03, SAFE-04
**Success Criteria** (what must be TRUE):
  1. PreToolUse hook resolves paths via `${CLAUDE_PLUGIN_ROOT}` and correctly blocks out-of-scope targets when loaded as a plugin (not from `.claude/hooks/`)
  2. PostToolUse hook logs audit entries and injects JSON bridge context when running outside the repo, with graceful degradation when wrapper scripts are absent
  3. `/netsec-health` skill verifies tool availability, hook registration, and scope file status in both in-repo and plugin contexts
  4. User can run `/netsec-scope init`, `/netsec-scope add`, `/netsec-scope remove`, and `/netsec-scope show` without Makefile or repo-specific paths
  5. Hooks auto-create default scope or skip scope validation gracefully on fresh installs (no hard-fail when `.pentest/scope.json` is missing)
**Plans**: 2 plans

Plans:
- [x] 35-01-PLAN.md — Portable PreToolUse and PostToolUse hooks with bash 3.2 compat and dual-context resolution
- [x] 35-02-PLAN.md — Portable scope management script and dual-context health check

### Phase 36: Dual-Mode Tool Skills
**Goal**: Users can invoke any of 17 tool skills and get working commands whether or not the networking-tools wrapper scripts are present
**Depends on**: Phase 35
**Requirements**: TOOL-01, TOOL-02, TOOL-03, TOOL-04
**Success Criteria** (what must be TRUE):
  1. Each of the 17 tool skills contains inline command knowledge sufficient to guide the user without any wrapper scripts (standalone mode produces usable tool commands)
  2. When wrapper scripts are detected via `!`command -v``, skills reference them with `-j -x` flags for structured JSON output (in-repo mode)
  3. Each tool skill checks tool installation status and provides platform-specific install guidance (brew, apt, pip) when the tool is missing
  4. Skill descriptions use natural trigger keywords that match how users ask for pentesting tasks (optimized for Claude auto-matching and skills.sh search ranking)
  5. Dual-mode pattern validated on 3 simple tools (dig, curl, netcat) before scaling to all 17
**Plans**: 3 plans

Plans:
- [x] 36-01-PLAN.md — BATS test scaffold and 3-tool pilot (dig, curl, netcat) dual-mode transformation
- [x] 36-02-PLAN.md — Scale dual-mode pattern to remaining 14 tool skills
- [x] 36-03-PLAN.md — Replace plugin symlinks with real files, sync marketplace.json, full validation

### Phase 37: Standalone Workflow Skills
**Goal**: Users can run multi-tool workflows (/recon, /scan, /fuzz, /crack, /sniff, /diagnose) that produce complete results whether installed standalone or in-repo
**Depends on**: Phase 36
**Requirements**: WORK-01, WORK-02
**Success Criteria** (what must be TRUE):
  1. Each of the 6 workflow skills executes a complete multi-step sequence without requiring wrapper scripts (standalone mode uses direct tool commands at every step)
  2. Each workflow step includes dual-mode branching that detects and uses wrapper scripts when available, falling back to direct commands when not
  3. Workflows produce coherent end-to-end results (not just individual tool outputs) with clear step numbering and decision points
**Plans**: 2 plans

Plans:
- [x] 37-01-PLAN.md — BATS test scaffold and pilot dual-mode transformation (recon + crack)
- [x] 37-02-PLAN.md — Scale dual-mode to remaining 4 workflows and full validation

### Phase 38: Agent Personas
**Goal**: Users can invoke pentester, defender, and analyst subagents that correctly load their associated skills in plugin namespace
**Depends on**: Phase 37
**Requirements**: AGEN-01, AGEN-02
**Success Criteria** (what must be TRUE):
  1. All 3 agent persona files (pentester, defender, analyst) exist in the plugin `agents/` directory with correct role definitions and skill preloads
  2. `/pentester`, `/defender`, and `/analyst` invoker skills launch their respective agents with `context: fork` and correct plugin-namespaced skill references
  3. Agent skill references resolve correctly in plugin context (empirically tested with at least one agent + one skill before porting all three)
**Plans**: 2 plans

Plans:
- [x] 38-01-PLAN.md — BATS scaffold and pentester pilot with pentest-conventions dual-mode transformation
- [x] 38-02-PLAN.md — Scale to defender, analyst, and remaining utility skills with full validation

### Phase 39: End-to-End Testing and Publication
**Goal**: Users can install the complete netsec skills pack from skills.sh or plugin marketplace and have all skills, hooks, and agents working on first use
**Depends on**: Phase 38
**Requirements**: PLUG-04, PUBL-01, PUBL-02, PUBL-03
**Success Criteria** (what must be TRUE):
  1. `npx skills add PatrykQuantumNomad/networking-tools` installs all skills and they appear in Claude Code's skill list
  2. Plugin installation via `claude plugin install` registers hooks, loads agents, and makes all skills available
  3. Skills pack appears on skills.sh/patrykquantumnomad/networking-tools with correct metadata
  4. Fresh install end-to-end test passes: install -> `/netsec-health` -> scope init -> tool skill -> workflow skill -> agent invoke all succeed without errors
  5. Published package contains zero GSD framework files (validated by build check before publish)
**Plans**: 2 plans

Plans:
- [x] 39-01-PLAN.md — Repo-root marketplace catalog, E2E validation script, and two-channel README
- [x] 39-02-PLAN.md — Full validation suite and publication readiness smoke test

## Progress

**Execution Order:**
Phases execute in numeric order: 34 -> 35 -> 36 -> 37 -> 38 -> 39

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-7 | v1.0 | 19/19 | Complete | 2026-02-11 |
| 8-11 | v1.1 | 4/4 | Complete | 2026-02-11 |
| 12-17 | v1.2 | 18/18 | Complete | 2026-02-11 |
| 18-22 | v1.3 | 9/9 | Complete | 2026-02-12 |
| 23-27 | v1.4 | 10/10 | Complete | 2026-02-14 |
| 28-33 | v1.5 | 13/13 | Complete | 2026-02-18 |
| 34. Plugin Scaffold | v1.6 | 2/2 | Complete | 2026-03-06 |
| 35. Portable Safety | v1.6 | 2/2 | Complete | 2026-03-06 |
| 36. Tool Skills | v1.6 | 3/3 | Complete | 2026-03-06 |
| 37. Workflow Skills | v1.6 | 2/2 | Complete | 2026-03-06 |
| 38. Agent Personas | v1.6 | 2/2 | Complete | 2026-03-06 |
| 39. Publication | v1.6 | 2/2 | Complete | 2026-03-07 |

**Total: 7 milestones shipped (39 phases, 86 plans completed)**
