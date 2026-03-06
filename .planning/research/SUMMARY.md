# Project Research Summary

**Project:** networking-tools v1.6 -- skills.sh Publication
**Domain:** Claude Code skill/plugin packaging and distribution for pentesting toolkit
**Researched:** 2026-03-06
**Confidence:** HIGH

## Executive Summary

Publishing 32 pentesting skills, 3 safety hooks, and 3 agent personas from the networking-tools repo to skills.sh requires one fundamental architectural change: decoupling skills from the bash wrapper scripts they currently reference by path. The research unanimously points to the **Claude Code plugin format** as the correct distribution mechanism. Raw `npx skills add` only distributes SKILL.md files -- it cannot ship hooks or agents, which are the project's primary differentiator. The plugin format bundles all three component types into a single installable package via `.claude-plugin/plugin.json`, `hooks/hooks.json`, and `agents/` directories. A dedicated `netsec-skills/` directory at the repo root becomes the single source of truth, cleanly separated from the GSD framework files that coexist in `.claude/`.

The core design pattern across all 24 action skills (18 tool + 6 workflow) is **dual-mode wrapper detection**: each SKILL.md uses `!`command`` preprocessing to check whether wrapper scripts exist. When they do (in-repo), skills reference structured wrapper scripts with `-j -x` flags for JSON envelope output and hook-mediated feedback. When they do not (standalone install), skills fall back to direct tool commands with inline educational context. No competitor does this -- and no competitor ships executable safety hooks alongside security skills. The combination of scope validation, audit logging, and health checks is genuinely novel in the ecosystem and should be the headline marketing feature.

The key risks are: (1) GSD framework files leaking into the published package if the separation boundary is not established first, (2) hooks hard-failing on fresh installs where `.pentest/scope.json` does not yet exist, and (3) agent-to-skill namespace resolution in plugins being undocumented and needing empirical testing. All three are addressable with the phased approach outlined below. The stack requires zero new dependencies -- the entire delivery is YAML frontmatter, markdown, bash scripts, and JSON manifests.

## Key Findings

### Recommended Stack

No new build tools, languages, or dependencies are needed. The "stack" is the existing technology already in use.

- **SKILL.md (YAML + Markdown):** Skill definition format -- the Agent Skills open standard (agentskills.io) adopted by Anthropic, Cursor, Codex, and 15+ agent platforms. Already in use for all 32 skills.
- **Claude Code Plugin Format:** Distribution mechanism -- bundles skills + hooks + agents + scripts into a single installable package with `plugin.json` manifest. Required because `npx skills add` alone cannot distribute hooks or agents.
- **Bash + jq:** Hook scripts -- already used by netsec-pretool.sh, netsec-posttool.sh, netsec-health.sh. `jq` is the only external dependency that must be documented as a prerequisite.
- **Git / GitHub:** Source of truth -- skills.sh indexes GitHub repos automatically via CLI telemetry. No submission process, no API, no registry. Push to GitHub and share the install command.
- **`npx skills` CLI:** Installation tool (Vercel's CLI) -- users run `npx skills add` to install. Publishers do NOT need to install it. Used for testing only.

**Critical version requirements:**
- Node.js 18+ (for `npx skills` CLI)
- Bash 4.0+ for hook scripts that use `declare -A` (macOS ships 3.2; hooks need a guard or rewrite)
- `jq` for JSON parsing in hooks

### Expected Features

**Must have (table stakes):**
- Self-contained SKILL.md with inline tool knowledge (standalone mode) -- users expect `npx skills add` to produce working skills immediately
- YAML frontmatter with `name` and `description` (already done on all 32 skills)
- `disable-model-invocation: true` on all action skills (already done on 28/32, correct)
- Tool installation detection per skill (currently in wrapper scripts; needs inline migration)
- Description keyword optimization for skills.sh discovery ranking
- Plugin manifest (`.claude-plugin/plugin.json`) and marketplace catalog (`marketplace.json`)
- Scope management that works without the repo's Makefile

**Should have (differentiators -- no competitor has these):**
- Safety hooks shipped with the package (PreToolUse scope validation + PostToolUse audit logging)
- Dual-mode execution (wrapper-aware + standalone fallback)
- Three persona agents (pentester, defender, analyst) for role-based security perspectives
- Multi-tool workflow orchestration (6 workflows composing 3-6 tool operations each)
- Structured JSON output bridge via PostToolUse hook
- Health check skill (`/netsec-health`) for first-run verification
- Two-channel distribution (plugin marketplace for depth + skills.sh for broad reach)

**Defer (v2+):**
- MCP server for tool management (hooks work now; MCP adds complexity)
- Lab environment portability (Docker compose is repo-specific)
- Custom wordlist management (paths are environment-specific)
- Multi-agent coordination (agent teams are experimental)
- Educational mode toggle (learner vs practitioner)

### Architecture Approach

The target architecture is a **plugin directory** (`netsec-skills/`) at the repo root that serves as the single source of truth for all publishable content. In-repo development uses `claude --plugin-dir ./netsec-skills`. Distribution uses `npx skills add` for discovery and `claude plugin install` for the complete experience. The plugin contains `skills/` (32 skill dirs), `agents/` (3 persona files), `hooks/hooks.json` (hook configuration), and `scripts/` (3 portable hook scripts).

**Major components:**
1. **Tool Skills (18)** -- Dual-mode SKILL.md files that detect wrapper scripts via `!`command`` and branch between wrapper-mode (structured JSON output) and direct-mode (raw tool commands with educational context)
2. **Workflow Skills (6)** -- Multi-step orchestration skills (recon, scan, fuzz, crack, sniff, diagnose) that chain tool skills with decision logic; each step needs dual-mode branching
3. **Safety Hooks (3)** -- PreToolUse (scope validation + raw tool interception), PostToolUse (JSON bridge + audit logging), health check; portable via `${CLAUDE_PLUGIN_ROOT}`
4. **Agent Personas (3)** -- Pentester, defender, analyst subagents that preload skills by name; require plugin-namespaced references (`netsec-skills:recon`)
5. **Utility/Reference Skills (5)** -- Scope, lab, check-tools, pentest-conventions, report; varying portability levels

### Critical Pitfalls

1. **GSD framework files leaking into publication** -- The `.claude/` directory contains both netsec content and GSD framework files (14 agents, 3 hooks, ~50 commands, templates). Publishing from `.claude/` without filtering would ship project management tooling to pentesting users. **Prevention:** Create a dedicated `netsec-skills/` plugin directory containing ONLY netsec content. Add build validation that fails if any `gsd-` prefixed files appear in the published directory.

2. **Hooks hard-fail on fresh installs** -- The PreToolUse hook blocks ALL commands when `.pentest/scope.json` is missing ("No scope file found... BLOCKED"). Fresh installs have no scope file. **Prevention:** Hooks must auto-create default scope or skip scope validation on first run. Ship a `/netsec-setup` first-run flow.

3. **Skills reference wrapper scripts that only exist in-repo** -- All 17 tool skills and 6 workflow skills reference paths like `bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x`. These scripts do not exist after standalone install. **Prevention:** Dual-mode pattern with `!`command`` detection. Every skill must contain inline direct-tool commands as fallback.

4. **Safety controls stripped in standalone mode** -- Publishing skills without hooks gives users nmap/sqlmap/nikto instructions with zero guardrails. **Prevention:** Always distribute hooks alongside skills (plugin format ensures this). Add safety disclaimers directly into every tool SKILL.md, not just in hooks.

5. **Agent-skill namespace mismatch in plugins** -- Plugin skills are namespaced (`netsec-skills:scan`). Agent `skills:` references that use bare names (`scan`) may fail to resolve. **Prevention:** Test with a minimal plugin (1 agent + 1 skill) before porting all 3 agents. Keep skill names stable.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Plugin Scaffold and GSD Separation
**Rationale:** Everything depends on the plugin container structure existing first. The GSD separation boundary MUST be established before any content work to prevent the critical pitfall of framework file leakage. This is the foundation.
**Delivers:** `netsec-skills/` directory with `.claude-plugin/plugin.json` manifest, `marketplace.json`, clean directory structure
**Addresses:** Plugin manifest (table stakes), GSD separation (critical pitfall #1), settings.json cleanup (pitfall #6)
**Avoids:** Premature content work in a structure that later needs reorganization

### Phase 2: Portable Hooks and Utility Skills
**Rationale:** Hooks validate tool invocations, so they must be proven portable BEFORE tool skills are ported. Utility skills (scope, health check) are the first-run experience and must work before users encounter tool skills.
**Delivers:** 3 portable hook scripts using `${CLAUDE_PLUGIN_ROOT}`, `hooks/hooks.json`, scope init skill, netsec-health skill, check-tools skill, lab skill (graceful degradation), 2 reference skills (pentest-conventions, report -- fully portable, no dual-mode needed)
**Addresses:** Safety infrastructure portability (differentiator), scope management (table stakes), first-run experience (UX pitfall)
**Avoids:** Building tool skills before hooks are proven; fresh-install hard-fail (critical pitfall #2)

### Phase 3: Dual-Mode Tool Skills (Pilot then Scale)
**Rationale:** The dual-mode wrapper detection pattern is the most complex transformation. Validate it on 3 simple tools before applying to all 18. Dig, curl, and netcat have low complexity and minimal wrapper scripts.
**Delivers:** 18 dual-mode tool skills with inline command knowledge and educational context
**Addresses:** Self-contained SKILL.md (table stakes #1), tool installation detection, description keyword optimization
**Avoids:** Applying an unproven pattern to all 18 tools at once; wrapper-script-only skills that break standalone (critical pitfall #3)

### Phase 4: Workflow Skills
**Rationale:** Workflow skills chain tool skills. All 18 tool skills must be dual-mode before workflows can reference them. Each workflow step needs its own dual-mode branching.
**Delivers:** 6 multi-step workflow skills (recon, scan, fuzz, crack, sniff, diagnose) with dual-mode branching at every step
**Addresses:** Multi-tool workflow orchestration (differentiator), safety disclaimers in workflow context
**Avoids:** Porting workflows before the tool skills they reference are ready

### Phase 5: Agent Personas and Agent Invoker Skills
**Rationale:** Agents preload skills by name. All skills must be finalized and correctly named before agents can reference them. Plugin namespace resolution (`netsec-skills:recon` vs bare `recon`) must be empirically tested.
**Delivers:** 3 portable agent definitions, 3 agent invoker skills with `context: fork`, verified namespace resolution
**Addresses:** Persona agent portability (differentiator), plugin-internal skill references
**Avoids:** Namespace resolution issues discovered at publication time (critical pitfall #5)

### Phase 6: End-to-End Testing and Publication
**Rationale:** Everything must be tested in plugin mode (`claude --plugin-dir`) before publishing. Verify standalone installation, hook registration, skill discovery, agent loading, and scope management all work end-to-end.
**Delivers:** Verified plugin, skills.sh listing, publication documentation, install instructions
**Addresses:** Quality assurance, two-channel distribution (differentiator), legal disclaimers (security requirement)
**Avoids:** Publishing untested skills; GSD leakage; missing safety disclaimers; skills that fail on first use

### Phase Ordering Rationale

- Plugin scaffold first because all components depend on the container structure
- Hooks before tool skills because hooks validate tool invocations and must be proven portable first
- Simple tool skills before complex ones to validate the dual-mode pattern cheaply
- Workflows after tools because workflows chain tool skills and each step needs dual-mode
- Agents last because they depend on all skills being finalized with correct names
- GSD separation in phase 1 prevents the highest-impact pitfall (leaking framework files)
- Safety hooks in phase 2 ensures the differentiating feature is built before the content it protects

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** Bash 4.0+ requirement in hooks needs macOS compatibility investigation (`declare -A` in pretool hook). Also: `${CLAUDE_PLUGIN_ROOT}` has known bugs on Windows (#18527) and during SessionStart (#27145)
- **Phase 5:** Plugin-internal agent-to-skill namespace resolution is undocumented. Needs empirical testing with a minimal plugin before porting all 3 agents. Also: does `skills:` field in agent frontmatter support namespaced names?
- **Phase 6:** Does skills.sh auto-detect `.claude-plugin/plugin.json`? Or does it only index `skills/` directories? May need both structures

Phases with standard patterns (skip research):
- **Phase 1:** Plugin manifest format is well-documented in Claude Code plugin reference
- **Phase 3:** Dual-mode pattern is straightforward conditional Markdown; the `!`command`` preprocessing is documented
- **Phase 4:** Same dual-mode pattern applied to workflow steps; no new patterns needed

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero new dependencies. All technologies verified against official docs. User has prior experience publishing skills from claude-in-a-box. |
| Features | MEDIUM-HIGH | Table stakes and differentiators clearly identified from competitor analysis and official docs. skills.sh ecosystem scale (69K+ skills) is verified. |
| Architecture | HIGH | Plugin format, hooks.json, path resolution variables all verified against official Claude Code plugin reference. Dual-mode pattern uses documented `!`command`` feature. |
| Pitfalls | HIGH | Based on direct examination of all 32 skills, 3 hooks, and settings.json. Known platform bugs (CLAUDE_PLUGIN_ROOT) sourced from GitHub issues. |

**Overall confidence:** HIGH

### Gaps to Address

- **Agent skill reference format in plugin context:** Do agents use `skills: [recon]` or `skills: [netsec-skills:recon]`? Needs empirical testing in phase 5. Mitigation: test with 1 agent + 1 skill first.
- **skills.sh plugin auto-discovery:** Does skills.sh detect `.claude-plugin/plugin.json` or only `skills/` directories? May need both a plugin structure and skills.sh-compatible layout. Mitigation: test during phase 6.
- **Hook conflict when plugin AND repo hooks coexist:** If a user installs the plugin AND has the repo with `.claude/hooks/`, do both sets fire? Needs testing. Mitigation: document expected behavior.
- **Bash 3.2 compatibility:** macOS ships bash 3.2; hooks using `declare -A` need bash 4.0+. Mitigation: rewrite associative arrays as sequential checks, or require Homebrew bash.
- **Skill description context budget:** 32 skills may exceed the 2% context window budget for skill descriptions. Mitigation: measure total description byte count in phase 3; most skills already use `disable-model-invocation: true`.
- **Windows support:** `${CLAUDE_PLUGIN_ROOT}` has known path issues on Windows. Mitigation: document as macOS/Linux initially; address Windows in v1.x.

## Sources

### PRIMARY (HIGH confidence -- official documentation, verified)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Complete skills reference, frontmatter fields, `!`command`` injection, description budget
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Plugin manifest, `${CLAUDE_PLUGIN_ROOT}`, hooks.json, component paths, caching
- [Claude Code Subagents Documentation](https://code.claude.com/docs/en/sub-agents) -- Agent `skills:` field, namespace behavior
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- Hook configuration in plugins, event types, matcher patterns
- [Agent Skills Specification](https://agentskills.io/specification) -- Cross-platform SKILL.md format, YAML validation rules
- [Anthropic Skills Repository](https://github.com/anthropics/skills) -- Official skill examples, plugin structure patterns
- Direct codebase analysis of all 32 skills, 3 hooks, 3 agents, wrapper scripts, settings.json

### SECONDARY (MEDIUM confidence -- verified via multiple sources)
- [skills.sh Documentation](https://skills.sh/docs) -- Platform overview, installation mechanics, telemetry-based indexing
- [Vercel Labs Skills CLI](https://github.com/vercel-labs/skills) -- CLI source, discovery paths, multi-skill repo support
- [skills.sh/patrykquantumnomad](https://skills.sh/patrykquantumnomad) -- User's existing published skills from claude-in-a-box
- [Vercel Skills Night](https://vercel.com/blog/skills-night-69000-ways-agents-are-getting-smarter) -- Ecosystem scale (69K+ skills, 2M+ installs)

### TERTIARY (LOW confidence -- single source, needs validation)
- CLAUDE_PLUGIN_ROOT bugs: issues #9354, #27145, #18527 -- reported but may be fixed by publication time
- Plugin-internal skill namespace resolution -- inferred from docs, not empirically tested

---
*Research completed: 2026-03-06*
*Ready for roadmap: yes*
