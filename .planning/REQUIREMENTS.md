# Requirements: Networking Tools — Skills.sh Publication

**Defined:** 2026-03-06
**Core Value:** Ready-to-run scripts and accessible documentation that eliminate the need to remember tool flags and configurations — run one command, get what you need.

## v1.6 Requirements

Requirements for skills.sh publication. Each maps to roadmap phases.

### Plugin Infrastructure

- [x] **PLUG-01**: User can install the netsec skills pack via a `.claude-plugin/plugin.json` manifest
- [x] **PLUG-02**: User can discover all skills, agents, and hooks listed in `marketplace.json`
- [x] **PLUG-03**: Published plugin package contains zero GSD framework files (agents, hooks, commands, templates)
- [ ] **PLUG-04**: User can install skills via both `npx skills add` (skills.sh) and plugin marketplace

### Standalone Tool Skills

- [ ] **TOOL-01**: User can use any of 17 tool skills without wrapper scripts present (standalone mode with inline tool knowledge)
- [ ] **TOOL-02**: Tool skills detect and use wrapper scripts when available for structured JSON output (in-repo mode)
- [ ] **TOOL-03**: Each tool skill detects whether the tool is installed and provides platform-specific install guidance
- [ ] **TOOL-04**: Each skill description uses natural trigger keywords optimized for Claude auto-matching and skills.sh search

### Standalone Workflow Skills

- [ ] **WORK-01**: User can use any of 6 workflow skills (/recon, /scan, /fuzz, /crack, /sniff, /diagnose) without wrapper scripts
- [ ] **WORK-02**: Workflow skills reference standalone tool skills with dual-mode branching at each step

### Safety Infrastructure

- [ ] **SAFE-01**: PreToolUse hook works outside the networking-tools repo via `${CLAUDE_PLUGIN_ROOT}` portable path resolution
- [ ] **SAFE-02**: PostToolUse hook works outside the networking-tools repo with graceful degradation
- [ ] **SAFE-03**: Health check diagnostic verifies infrastructure in both in-repo and plugin contexts
- [ ] **SAFE-04**: User can init/add/remove/show scope targets without any repo-specific paths or Makefile

### Agent Personas

- [ ] **AGEN-01**: Pentester, defender, and analyst agents are distributed via plugin `agents/` directory
- [ ] **AGEN-02**: Agent invoker skills (/pentester, /defender, /analyst) work correctly in plugin namespace

### Publication

- [ ] **PUBL-01**: End-to-end standalone installation works: `npx skills add PatrykQuantumNomad/networking-tools` installs all skills
- [ ] **PUBL-02**: Plugin installation works: skills, hooks, and agents function correctly after plugin install
- [ ] **PUBL-03**: Skills appear on skills.sh/patrykquantumnomad/networking-tools

## Future Requirements

### Enhanced Distribution

- **DIST-01**: Skill grouping support for selective installation (e.g., install only recon skills)
- **DIST-02**: Version pinning for skills.sh installations
- **DIST-03**: Automated CI validation of skill portability before publish

### Extended Content

- **CONT-01**: Interactive tutorial skills for each tool
- **CONT-02**: CTF challenge skills with built-in hints

## Out of Scope

| Feature | Reason |
|---------|--------|
| Windows support for hooks | `$CLAUDE_PLUGIN_ROOT` has path separator bugs on Windows (issue #18527); pentesting toolkit is macOS/Linux |
| Bundling wrapper scripts into skills | Defeats standalone purpose; skills should contain knowledge, not bash scripts |
| Publishing GSD framework | Third-party tool, not project-specific content |
| Auto-exploitation without confirmation | Safety requires explicit human authorization |
| Wordlist bundling in skills | Security risk flagged by skills.sh partners (Snyk, Socket); reference external sources |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLUG-01 | Phase 34 | Complete |
| PLUG-02 | Phase 34 | Complete |
| PLUG-03 | Phase 34 | Complete |
| PLUG-04 | Phase 39 | Pending |
| TOOL-01 | Phase 36 | Pending |
| TOOL-02 | Phase 36 | Pending |
| TOOL-03 | Phase 36 | Pending |
| TOOL-04 | Phase 36 | Pending |
| WORK-01 | Phase 37 | Pending |
| WORK-02 | Phase 37 | Pending |
| SAFE-01 | Phase 35 | Pending |
| SAFE-02 | Phase 35 | Pending |
| SAFE-03 | Phase 35 | Pending |
| SAFE-04 | Phase 35 | Pending |
| AGEN-01 | Phase 38 | Pending |
| AGEN-02 | Phase 38 | Pending |
| PUBL-01 | Phase 39 | Pending |
| PUBL-02 | Phase 39 | Pending |
| PUBL-03 | Phase 39 | Pending |

**Coverage:**
- v1.6 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0

---
*Requirements defined: 2026-03-06*
*Last updated: 2026-03-06 after roadmap creation*
