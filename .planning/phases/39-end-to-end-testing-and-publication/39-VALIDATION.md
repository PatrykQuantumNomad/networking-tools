# Phase 39: End-to-End Testing and Publication - Validation

**Generated:** 2026-03-06
**Source:** 39-RESEARCH.md Validation Architecture section

## Test Framework

| Property | Value |
|----------|-------|
| Framework | BATS (via git submodule at tests/bats/) |
| Config file | tests/test_helper/common-setup.bash |
| Quick run command | `./tests/bats/bin/bats tests/test-agent-personas.bats` |
| Full suite command | `./tests/bats/bin/bats tests/` |

## Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLUG-04 | Two-channel installation (skills.sh + plugin marketplace) | smoke | `bash scripts/test-e2e-publication.sh` | No -- created in 39-01 |
| PUBL-01 | `npx skills add PatrykQuantumNomad/networking-tools` installs all skills | smoke | `npx skills add PatrykQuantumNomad/networking-tools --list` (manual verify output shows ~27-31 skills, not 54+ duplicates) | No -- manual verification |
| PUBL-02 | Plugin installation works: skills, hooks, agents function after `claude --plugin-dir ./netsec-skills` | smoke | `claude --plugin-dir ./netsec-skills` then verify: `/netsec-skills:netsec-health`, `/netsec-skills:nmap` (tool), `/netsec-skills:recon` (workflow), `/netsec-skills:pentester` (agent) | No -- manual verification |
| PUBL-03 | Skills appear on skills.sh/patrykquantumnomad/networking-tools | manual-only | Visit skills.sh page after first `npx skills add` by a user triggers telemetry indexing. **NOTE:** Cannot be verified pre-publication; confirmation is post-publication. | No -- post-publication |
| GSD-boundary | Zero GSD files in published package | unit | `bash scripts/validate-plugin-boundary.sh netsec-skills` | Yes |

## Sampling Rate

- **Per task commit:** `bash scripts/validate-plugin-boundary.sh && bash scripts/test-e2e-publication.sh`
- **Per wave merge:** Full BATS suite: `./tests/bats/bin/bats tests/`
- **Phase gate:** Full suite green + manual smoke test of `claude --plugin-dir ./netsec-skills` covering full E2E chain (health -> scope -> tool skill -> workflow skill -> agent invoke)

## Wave 0 Gaps

- [x] `scripts/test-e2e-publication.sh` -- comprehensive E2E validation script (39-01 Task 1)
- [x] `.claude-plugin/marketplace.json` at repo root -- marketplace catalog for plugin distribution (39-01 Task 1)
- [x] Update `netsec-skills/README.md` -- document two-channel installation (39-01 Task 2)

## Full E2E Verification Chain

The following sequence validates the complete fresh-install experience (Success Criterion 4 from ROADMAP):

1. **Install:** `claude --plugin-dir ./netsec-skills` (loads plugin)
2. **Health:** `/netsec-skills:netsec-health` (verifies hooks, tools, scope)
3. **Scope:** `/netsec-skills:scope init` (creates .pentest/scope.json)
4. **Tool skill:** `/netsec-skills:nmap` (verifies a tool skill loads and responds)
5. **Workflow skill:** `/netsec-skills:recon` (verifies multi-step workflow executes)
6. **Agent invoke:** `/netsec-skills:pentester` (verifies agent persona launches with correct skill preloads)

## Notes

- PUBL-03 (skills.sh listing) cannot be verified pre-publication. skills.sh listings appear automatically via anonymous telemetry when users run `npx skills add`. First install triggers indexing. Confirmation is post-publication only.
