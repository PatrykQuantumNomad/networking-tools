# Requirements: Networking Tools — v1.5 Claude Skill Pack

**Defined:** 2026-02-17
**Core Value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations — run one command, get what you need.

## v1.5 Requirements

Requirements for Claude Code skill pack. Each maps to roadmap phases.

### Safety & Hooks

- [ ] **SAFE-01**: PreToolUse hook validates all Bash commands against target allowlist before execution
- [ ] **SAFE-02**: PreToolUse hook intercepts raw tool commands (nmap, sqlmap, etc.) that bypass wrapper scripts
- [ ] **SAFE-03**: PostToolUse hook parses `-j` JSON envelope output and injects structured `additionalContext` to Claude
- [ ] **SAFE-04**: All skill invocations and results are logged to audit trail file
- [ ] **SAFE-05**: User can run health-check command to verify hooks are firing correctly

### Workflow Skills

- [ ] **WKFL-01**: User can invoke `/recon` to run reconnaissance workflows (host discovery, DNS, OSINT)
- [ ] **WKFL-02**: User can invoke `/scan` to run vulnerability scanning workflows (port scans, web scans)
- [ ] **WKFL-03**: User can invoke `/diagnose` to run network diagnostic workflows (DNS, connectivity, latency)
- [ ] **WKFL-04**: User can invoke `/fuzz` to run fuzzing workflows (directory brute-force, parameter fuzzing)
- [ ] **WKFL-05**: User can invoke `/crack` to run password cracking workflows (hashes, archives, web)
- [ ] **WKFL-06**: User can invoke `/sniff` to run traffic capture and analysis workflows
- [ ] **WKFL-07**: User can invoke `/report` to generate structured findings report from session
- [ ] **WKFL-08**: User can invoke `/scope` to define and manage target scope for the engagement

### Tool Skills

- [ ] **TOOL-01**: Skill for nmap with `disable-model-invocation: true`
- [ ] **TOOL-02**: Skill for tshark with `disable-model-invocation: true`
- [ ] **TOOL-03**: Skill for metasploit with `disable-model-invocation: true`
- [ ] **TOOL-04**: Skill for sqlmap with `disable-model-invocation: true`
- [ ] **TOOL-05**: Skill for nikto with `disable-model-invocation: true`
- [x] **TOOL-06**: Skill for hashcat with `disable-model-invocation: true`
- [x] **TOOL-07**: Skill for john with `disable-model-invocation: true`
- [x] **TOOL-08**: Skill for hping3 with `disable-model-invocation: true`
- [x] **TOOL-09**: Skill for skipfish with `disable-model-invocation: true`
- [x] **TOOL-10**: Skill for aircrack-ng with `disable-model-invocation: true`
- [ ] **TOOL-11**: Skill for dig with `disable-model-invocation: true`
- [ ] **TOOL-12**: Skill for curl with `disable-model-invocation: true`
- [x] **TOOL-13**: Skill for netcat with `disable-model-invocation: true`
- [x] **TOOL-14**: Skill for traceroute/mtr with `disable-model-invocation: true`
- [ ] **TOOL-15**: Skill for gobuster with `disable-model-invocation: true`
- [ ] **TOOL-16**: Skill for ffuf with `disable-model-invocation: true`
- [x] **TOOL-17**: Skill for foremost with `disable-model-invocation: true`

### Utility Skills

- [x] **UTIL-01**: User can invoke check-tools skill to verify tool availability
- [x] **UTIL-02**: User can invoke lab skill to manage Docker vulnerable targets (start, stop, status)
- [x] **UTIL-03**: Background `pentest-conventions` skill provides Claude with pentesting context automatically

### Subagent Personas

- [ ] **AGNT-01**: Pentester subagent orchestrates multi-tool attack workflows with context isolation
- [ ] **AGNT-02**: Defender subagent analyzes findings from defensive perspective
- [ ] **AGNT-03**: Analyst subagent synthesizes results across multiple scans into structured analysis

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Distribution

- **DIST-01**: Convert skill pack to plugin format with `.claude-plugin/plugin.json`
- **DIST-02**: Publish plugin to GitHub-based marketplace
- **DIST-03**: npm package distribution (pending Claude Code npm source maturity)

### Advanced Features

- **ADV-01**: Multi-phase `/pentest` orchestration command (full engagement workflow)
- **ADV-02**: `/practice` guided walkthroughs using lab targets
- **ADV-03**: Agent memory persistence across sessions for engagement state

## Out of Scope

| Feature | Reason |
|---------|--------|
| Auto-execute active scans without confirmation | Safety — active scanning tools must always require user approval |
| Automatic exploitation chains | Safety — exploitation requires explicit human authorization per target |
| Credential storage in skill files | Security — never store credentials in version-controlled skill files |
| One skill per script (81 skills) | Context budget — would flood Claude's context window; tool skills aggregate per-tool |
| LLM-based safety hooks (type: "prompt") | Determinism — safety validation must be fast, free, and deterministic (bash+jq) |
| Windows native support | Platform — Unix-only project, WSL is sufficient |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-01 | Phase 28 | Pending |
| SAFE-02 | Phase 28 | Pending |
| SAFE-03 | Phase 28 | Pending |
| SAFE-04 | Phase 28 | Pending |
| SAFE-05 | Phase 28 | Pending |
| WKFL-01 | Phase 32 | Pending |
| WKFL-02 | Phase 32 | Pending |
| WKFL-03 | Phase 32 | Pending |
| WKFL-04 | Phase 32 | Pending |
| WKFL-05 | Phase 32 | Pending |
| WKFL-06 | Phase 32 | Pending |
| WKFL-07 | Phase 32 | Pending |
| WKFL-08 | Phase 32 | Pending |
| TOOL-01 | Phase 29 | Pending |
| TOOL-02 | Phase 29 | Pending |
| TOOL-03 | Phase 29 | Pending |
| TOOL-04 | Phase 29 | Pending |
| TOOL-05 | Phase 29 | Pending |
| TOOL-06 | Phase 31 | Complete |
| TOOL-07 | Phase 31 | Complete |
| TOOL-08 | Phase 31 | Complete |
| TOOL-09 | Phase 31 | Complete |
| TOOL-10 | Phase 31 | Complete |
| TOOL-11 | Phase 31 | Pending |
| TOOL-12 | Phase 31 | Pending |
| TOOL-13 | Phase 31 | Complete |
| TOOL-14 | Phase 31 | Complete |
| TOOL-15 | Phase 31 | Pending |
| TOOL-16 | Phase 31 | Pending |
| TOOL-17 | Phase 31 | Complete |
| UTIL-01 | Phase 30 | Complete |
| UTIL-02 | Phase 30 | Complete |
| UTIL-03 | Phase 30 | Complete |
| AGNT-01 | Phase 33 | Pending |
| AGNT-02 | Phase 33 | Pending |
| AGNT-03 | Phase 33 | Pending |

**Coverage:**
- v1.5 requirements: 36 total
- Mapped to phases: 36
- Unmapped: 0

---
*Requirements defined: 2026-02-17*
*Last updated: 2026-02-17 after roadmap creation*
