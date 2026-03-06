# Feature Research

**Domain:** Claude Code skill publication for pentesting toolkit (skills.sh + plugin marketplace)
**Researched:** 2026-03-06
**Confidence:** MEDIUM-HIGH

## Context: What Changed Since v1 Research (2026-02-17)

The previous research (v1, Feb 17) designed skills that wrap wrapper scripts inside the repo. This research addresses a different problem: **standalone publication** where skills work WITHOUT the repository's `scripts/` directory. The 32 skills, 3 hooks, and 3 agents are already built. The question now is: what features do they need to be publishable on skills.sh and as a Claude Code plugin?

Key shifts:
- skills.sh launched Jan 2026 with 69K+ skills and 2M+ CLI installs -- it is THE discovery platform
- Claude Code plugin marketplace is now mature (v1.0.33+) with `/plugin install` flow
- Two competing distribution channels exist: `npx skills add` (cross-agent) and `/plugin marketplace add` (Claude Code native)
- No competitor ships executable safety hooks alongside security skills -- this is the differentiator

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Self-contained SKILL.md with inline tool knowledge | Every skill on skills.sh works as a standalone folder. Users run `npx skills add` and expect skills to work immediately. Current skills say `bash scripts/nmap/discover-live-hosts.sh -j -x` -- those scripts do not exist outside the repo. | HIGH | This is the single largest transformation: 17 tool skills and 6 workflow skills must contain inline command knowledge so they work without wrapper scripts. Each tool skill needs the actual nmap/sqlmap/nikto commands, flags, and interpretation guidance inline. |
| YAML frontmatter (name, description) | The skills CLI and Claude Code both require frontmatter for discovery and invocation. Without it, skills are invisible on skills.sh. | DONE | Already present on all 32 skills. Verify `name` uses lowercase-hyphen format (max 64 chars) -- currently compliant. |
| `disable-model-invocation: true` on action skills | Standard practice for skills with side effects. All security skill competitors use this. Users do not want Claude autonomously launching nmap scans against targets. | DONE | Already set on 28 of 32 skills. The 4 without it (check-tools, lab, netsec-health, pentest-conventions) are correct -- those are reference/utility skills. |
| Tool installation detection per skill | Users install the skill pack but may not have nmap, sqlmap, or hashcat installed. Skills must detect and provide install guidance. | MEDIUM | Currently handled by wrapper scripts (`require_cmd`). For standalone skills, each SKILL.md needs inline detection: "Run `which nmap` -- if not found, install with `brew install nmap` / `apt install nmap`." Alternatively, use `!` dynamic context injection to detect at skill load time. |
| Clear descriptions with trigger keywords | Claude uses descriptions to decide when to auto-load skills. Top skills on skills.sh (100K+ installs) write descriptions optimized for relevance matching. | LOW | Current descriptions are functional but miss natural language triggers. Example: nmap description says "Network scanning and host discovery using nmap wrapper scripts" -- should say "Network scanning and host discovery with nmap. Use for port scans, service detection, OS fingerprinting, and vulnerability checks." Drop "wrapper scripts" (meaningless to standalone users). |
| Plugin manifest (.claude-plugin/plugin.json) | Required for Claude Code plugin marketplace distribution. Without it, `/plugin install` does not work. | LOW | New file. Name, description, version, author, homepage, repository, license, keywords. |
| marketplace.json | Required for plugin marketplace catalog. Lists all skills, agents, and hooks in the package. | LOW | New file at `.claude-plugin/marketplace.json`. Maps the 32 skills + hooks to their source directories. |
| Scope management that works standalone | The PreToolUse hook validates targets against `.pentest/scope.json`. This file must be creatable without the repo's Makefile or scripts. | LOW | `/scope init` skill already creates scope.json directly. Verify it works without any repo-specific paths. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Safety hooks shipped with package | **No competitor ships executable safety hooks.** awesome-claude-skills-security (Eyadkelleh) has no enforcement. transilienceai/communitytools says "always get permission" with no technical controls. Trail of Bits focuses on code analysis, not runtime scanning guardrails. Shipping PreToolUse scope validation + PostToolUse audit logging is genuinely novel in the ecosystem. | MEDIUM | Plugin format supports `hooks/hooks.json` for auto-registration. Hook scripts must be portable: use `${CLAUDE_PLUGIN_ROOT}` for path resolution instead of `$CLAUDE_PROJECT_DIR`. Current hooks depend on `jq` -- document this dependency. |
| Dual-mode execution (wrapper-aware + standalone) | Skills detect if wrapper scripts exist (inside the repo) and use them for the full experience (JSON bridge, structured output). Otherwise, fall back to direct tool commands with inline knowledge. No competitor does this. | HIGH | Core architectural pattern. Each tool skill needs: "If `${CLAUDE_SKILL_DIR}/../../../scripts/nmap/discover-live-hosts.sh` exists, run it with `-j -x`. Otherwise, run `nmap -sn <target>` directly and interpret the output." The wrapper path provides the JSON bridge advantage; the standalone path provides universal portability. |
| Structured JSON output bridge | PostToolUse hook parses JSON from wrapper scripts and injects structured summaries via `additionalContext`. Tool output is automatically parsed and summarized for the agent. No competitor has this automated feedback loop. | DONE | Already built. Only works when wrapper scripts are available (dual-mode wrapper path). In standalone mode, Claude interprets raw tool output directly (still works, just less structured). |
| Three persona agents (pentester, defender, analyst) | Competitors have generic security agents. Having offensive/defensive/analytical role-based perspectives on the same scan data is pedagogically unique and practically valuable. | LOW | Already built. For plugin distribution, agents go in `agents/` directory at plugin root. Verify they reference skills correctly in the plugin namespace (may need `networking-tools:nmap` instead of just `nmap`). |
| Multi-tool workflow orchestration | 6 workflow skills (`/recon`, `/scan`, `/crack`, `/fuzz`, `/sniff`, `/diagnose`) compose 3-6 tool operations with decision logic and conditional execution. Transilience has similar scope but with less structured step-by-step methodology. | DONE | Already built. For standalone mode, workflow skills need to reference standalone tool skills (not wrapper scripts). Each step needs the dual-mode pattern. |
| Audit logging | PostToolUse hook writes to `.pentest/audit.log` with timestamps and commands. Useful for reporting and compliance documentation. No competitor tracks what was executed. | DONE | Already built in netsec-posttool.sh. Ships automatically with the hook package. |
| Health check (`/netsec-health`) | Self-diagnostic verifying hooks are registered, scope file exists, dependencies present. No competitor has "is my safety infrastructure working?" as a first-run verification. | DONE | Already built. Critical for onboarding: user runs `/netsec-health` immediately after plugin install to verify setup. Must be updated to check plugin-context paths. |
| Educational inline content | Each skill explains WHY commands work, not just WHAT to run. For standalone mode, this teaching content must be inline in SKILL.md or in supporting `references/` files. | MEDIUM | Current wrapper scripts have this knowledge. For standalone skills, the educational content moves inline. This transforms skills from "run this command" to "here is what this command does, why it matters, and how to interpret results." Competitors list commands; this teaches. |
| Two-channel distribution | Plugin marketplace for full experience (skills + hooks + agents). skills.sh for broad reach (skills only, works across 37+ agents). No competitor explicitly targets both channels. | LOW | Structural decision. Plugin lives in repo root. skills.sh installation uses `npx skills add patrykquantumnomad/networking-tools`. Both read from the same `skills/` directory. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Auto-execution of security tools without confirmation | Users want `/recon target` to just run everything | Security tools should never auto-execute without explicit consent. Could scan unauthorized targets, trigger IDS alerts, violate laws. Claude autonomously running nmap is a liability. | Keep `disable-model-invocation: true` on all action skills. Require user invocation via `/skill-name`. Scope validation as hard gate before any scanning. |
| Bundled wordlists and payloads | awesome-claude-skills-security bundles SecLists. Seems comprehensive. | Massively inflates package size. Wordlists change frequently. Bundling attack payloads creates distribution risk -- GitHub may flag repo. skills.sh security audits (partnered with Snyk, Socket, Gen) may reject packages with payloads. | Reference external wordlist paths. Skills should expect standard install locations (`/usr/share/wordlists/`, SecLists) and detect them. |
| Raw tool passthrough (bypass skills) | "Let me just run `nmap -sV -p- target`" | Bypasses scope validation, audit logging, and structured output. Defeats the safety architecture. | PreToolUse hook intercepts raw tool invocations. In standalone mode, skills provide inline knowledge so users have no reason to bypass. |
| Cross-agent hook compatibility | skills.sh supports 37+ agents. Ship hooks for all. | Only Claude Code and Cline support hooks (per npx skills compatibility table). Other agents have no hook system. | Plugin format for Claude Code (full hooks). skills.sh for cross-agent (skills only, no hooks). Two channels, not one compromised channel. |
| Automatic target discovery | Skills that auto-scan the local network for targets | Scanning without explicit targeting is legally problematic. "It found your neighbor's router" is dangerous. | Always require explicit target. Default to localhost. Require scope.json entry before scanning. |
| One monolithic skill file | Single SKILL.md containing all 17 tools | Exceeds Claude's skill description budget. Violates the SKILL.md < 500 lines recommendation. Impossible to maintain. | One skill per tool directory. Keep SKILL.md focused, move details to supporting files (references/, examples/). |
| Interactive terminal passthrough | Users want msfconsole, john --stdin interactive sessions via Claude | Claude Code cannot handle sustained interactive I/O. These tools require terminal control. | Show commands and flags. User runs interactive tools in separate terminal. Claude helps interpret results afterward. |
| Custom agent for every tool | 17 separate subagents (nmap-agent, sqlmap-agent, etc.) | Agent overhead per invocation. Exceeds useful granularity. Users do not think "I need the nikto agent." | Three role-based agents (pentester, defender, analyst) that load tool skills as context. Role abstraction, not tool abstraction. |

## Feature Dependencies

```
[SKILL.md standalone transformation]
    |
    +--requires--> [Dual-mode execution pattern]
    |                   |
    |                   +--requires--> [Inline tool command knowledge per skill]
    |                   +--requires--> [Tool installation detection (inline)]
    |                   +--requires--> [Wrapper script detection logic]
    |
    +--enhances--> [Educational inline content]

[Plugin packaging]
    |
    +--requires--> [.claude-plugin/plugin.json manifest]
    +--requires--> [marketplace.json catalog]
    +--requires--> [hooks/hooks.json with portable hook scripts]
    |                   |
    |                   +--requires--> [Portable PreToolUse (scope validation)]
    |                   |                   +--requires--> [$CLAUDE_PLUGIN_ROOT path resolution]
    |                   |
    |                   +--requires--> [Portable PostToolUse (JSON bridge + audit)]
    |                                       +--requires--> [$CLAUDE_PLUGIN_ROOT path resolution]
    |
    +--enhances--> [Health check skill (plugin-aware)]

[Scope management (standalone)]
    |
    +--requires--> [.pentest/scope.json initialization via /scope init]
    +--required-by--> [PreToolUse hook]
    +--required-by--> [All 17 tool skills + 6 workflow skills]

[Workflow skills (standalone)]
    |
    +--requires--> [Standalone tool skills (all 17)]
    +--requires--> [Scope management]

[Persona agents (portable)]
    |
    +--requires--> [agents/ directory at plugin root]
    +--requires--> [Skill namespace resolution (plugin: prefix)]
    +--requires--> [Standalone workflow skills]

[Description optimization]
    |
    +--independent (can be done anytime)
    +--enhances--> [skills.sh discovery and ranking]
```

### Dependency Notes

- **Standalone transformation is the critical path**: Nothing else matters if skills do not work outside the repo. This blocks all other features.
- **Plugin packaging depends on portable hooks**: Hooks must use `${CLAUDE_PLUGIN_ROOT}` instead of `$CLAUDE_PROJECT_DIR`. Current hooks hardcode project paths.
- **Workflow skills depend on tool skills being standalone**: `/recon` calls nmap, dig, curl, gobuster. Each must work standalone before the workflow can.
- **Persona agents need namespace awareness**: In plugin context, skills are namespaced (`networking-tools:nmap`). Agent definitions that reference `/nmap` may need updating to `/networking-tools:nmap`.
- **Description optimization is independent**: Can be done at any point. High impact for skills.sh ranking with zero dependency on other work.
- **Scope management is a foundation**: Everything depends on scope.json. The `/scope init` skill must work standalone first.

## MVP Definition

### Launch With (v1)

Minimum viable product for skills.sh listing and Claude Code plugin marketplace.

- [ ] **17 tool skills rewritten for standalone** -- Each contains inline command knowledge with dual-mode detection (wrapper if available, direct commands otherwise). This is the blocking work.
- [ ] **6 workflow skills updated for standalone** -- `/recon`, `/scan`, `/crack`, `/fuzz`, `/sniff`, `/diagnose` reference standalone tool skills, not wrapper scripts.
- [ ] **Plugin manifest** (`.claude-plugin/plugin.json`) -- Name: networking-tools, version: 1.0.0, author, homepage, license (Apache-2.0 or MIT), keywords.
- [ ] **marketplace.json** -- Lists all 32 skills + hooks for Claude Code plugin marketplace.
- [ ] **Portable hooks** (`hooks/hooks.json`) -- PreToolUse scope validation and PostToolUse audit logging using `${CLAUDE_PLUGIN_ROOT}` for path resolution.
- [ ] **Scope init standalone** -- `/scope init` creates `.pentest/scope.json` without any repo-specific dependencies.
- [ ] **Health check updated** -- `/netsec-health` works in plugin context, checks plugin-relative paths.
- [ ] **Description keyword optimization** -- All 32 skill descriptions rewritten with natural language trigger keywords. Drop "wrapper scripts" language.
- [ ] **4 utility skills verified** -- check-tools, lab, pentest-conventions, netsec-health work standalone or degrade gracefully.

### Add After Validation (v1.x)

Features to add once core plugin is working and listed.

- [ ] **Supporting reference files** -- `references/cheatsheet.md` per tool skill with flag reference, common scenarios, output interpretation. Triggered by user feedback requesting more depth.
- [ ] **Persona agent portability** -- Verify pentester, defender, analyst agents work in plugin namespace. Fix any `/nmap` -> `/networking-tools:nmap` references.
- [ ] **Report skill enhancement** -- `/report` generates structured findings as markdown artifact, not just conversation text.
- [ ] **Inline version detection** -- Skills detect tool version and adjust command flags accordingly.
- [ ] **Educational mode toggle** -- A variant that explains every command before suggesting it (learner mode vs. practitioner mode).

### Future Consideration (v2+)

Features to defer until initial traction is established.

- [ ] **MCP server for tool management** -- Instead of bash hooks, an MCP server managing scope, audit, and invocation. Defer: hooks work now, MCP adds complexity.
- [ ] **Lab environment portability** -- Docker lab management portable outside repo. Defer: lab targets are repo-specific docker-compose.
- [ ] **Custom wordlist management** -- Skills that detect and manage SecLists, custom dictionaries. Defer: paths are environment-specific.
- [ ] **Multi-agent coordination** -- Pentester + defender simultaneously. Defer: agent teams are experimental.
- [ ] **skills.sh category submission** -- Submit to skills.sh curated security category once it exists.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| 17 tool skills standalone rewrite | HIGH | HIGH | P1 |
| 6 workflow skills standalone update | HIGH | MEDIUM | P1 |
| Plugin manifest + marketplace.json | HIGH | LOW | P1 |
| Portable safety hooks | HIGH | MEDIUM | P1 |
| Scope init standalone | HIGH | LOW | P1 |
| Health check update | MEDIUM | LOW | P1 |
| Description keyword optimization | MEDIUM | LOW | P1 |
| 4 utility skills verification | MEDIUM | LOW | P1 |
| Supporting reference files | MEDIUM | MEDIUM | P2 |
| Persona agent portability | MEDIUM | MEDIUM | P2 |
| Report skill enhancement | MEDIUM | MEDIUM | P2 |
| Inline version detection | LOW | MEDIUM | P3 |
| Educational mode toggle | LOW | MEDIUM | P3 |
| MCP server replacement | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch on skills.sh and plugin marketplace
- P2: Should have, add after initial listing and user feedback
- P3: Nice to have, defer until established traction

## Competitor Feature Analysis

| Feature | Trail of Bits | Transilience | awesome-claude-skills-security | alirezarezvani/claude-skills | Our Approach |
|---------|---------------|--------------|-------------------------------|------------------------------|--------------|
| **Distribution** | Plugin marketplace | Manual .claude/ copy | Plugin format | Marketplace + manual | Dual: plugin marketplace + npx skills add |
| **Skill count** | ~20 security skills | 7 skills + 35 agents | 7 categories + 5 commands | 169 skills (all domains) | 32 skills + 3 agents + 3 hooks |
| **Safety enforcement** | None (trust user) | Docs only ("get permission") | Docs only ("authorized use") | Skill security auditor (static) | Technical: PreToolUse scope validation, PostToolUse audit logging |
| **Hook shipping** | None | None | None | None | 3 hooks: PreToolUse, PostToolUse, health check |
| **Tool dependencies** | Assumes installed | Assumes installed | Bundles wordlists | Zero-dep Python tools | Detect + guide: check tool, show install if missing |
| **Workflow orchestration** | Single-tool skills | Agent-based workflows | Slash commands only | Skill-by-skill | Multi-step workflows composing tool skills with decision logic |
| **Educational content** | Minimal | PortSwigger walkthroughs | Wordlist descriptions | Domain-specific guides | Inline explanations of why each command works |
| **Cross-agent support** | Claude Code only | Claude Code only | Claude Code only | Claude Code + Codex | Claude Code plugin (full) + skills.sh 37+ agents (skills only) |
| **Audit trail** | None | None | None | None | Timestamped .pentest/audit.log |
| **Standalone operation** | Yes (no tool deps) | Yes (uses curl/httpx) | Yes (bundles data) | Yes (stdlib Python) | Dual-mode: uses wrappers if available, direct commands otherwise |

### Key Competitive Insight

**No competitor ships executable safety hooks alongside pentesting skills.** The combination of scope validation + audit logging + health checks is genuinely differentiated. This should be the headline feature: "The only pentesting skill pack with built-in safety controls."

Secondary differentiator: dual-mode execution. Skills that work better inside the repo (JSON bridge, structured output) but still work everywhere else (direct commands, Claude interprets output). No competitor does this.

## Distribution Strategy

### Channel 1: Claude Code Plugin (Full Experience)

```
Install: /plugin marketplace add patrykquantumnomad/networking-tools
         /plugin install networking-tools@patrykquantumnomad-networking-tools
```

- All 32 skills (namespaced as `/networking-tools:nmap`, `/networking-tools:recon`)
- 3 persona agents (pentester, defender, analyst)
- Safety hooks auto-registered via `hooks/hooks.json`
- Scope management operational
- JSON bridge active when wrapper scripts present
- Full audit logging

### Channel 2: skills.sh / npx skills (Broad Reach)

```
Install: npx skills add patrykquantumnomad/networking-tools
```

- All 32 skills (no namespace prefix)
- Works across Claude Code, Cursor, Codex, Goose, and 37+ agents
- No hooks (most agents do not support them)
- Skills operate in standalone mode with inline knowledge
- Safety relies on skill instructions rather than hook enforcement

### Why Two Channels

The plugin format is the superior experience (hooks, agents, structured output). But skills.sh has 2M+ CLI installs and 69K+ skills -- it is the discovery platform. Publishing both maximizes reach (skills.sh for discovery) while the plugin provides depth (full safety architecture). The same skill files serve both channels -- no duplication needed.

## Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- SKILL.md format, frontmatter reference, invocation control, `$ARGUMENTS`, `${CLAUDE_SKILL_DIR}`, supporting files, skill description budget (HIGH confidence)
- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins) -- Plugin structure, hooks.json, manifest, marketplace distribution, `${CLAUDE_PLUGIN_ROOT}` (HIGH confidence)
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) -- marketplace.json schema, hosting, distribution, plugin sources, strict mode (HIGH confidence)
- [Claude Code Discover Plugins](https://code.claude.com/docs/en/discover-plugins) -- Official marketplace, install commands, plugin management (HIGH confidence)
- [skills.sh](https://skills.sh/) -- Skills directory and leaderboard, 69K+ skills, 2M+ installs (HIGH confidence)
- [npx skills CLI (vercel-labs/skills)](https://github.com/vercel-labs/skills) -- Installation tool, symlink vs copy, agent compatibility matrix, hooks support only Claude Code + Cline (HIGH confidence)
- [Vercel Skills Night](https://vercel.com/blog/skills-night-69000-ways-agents-are-getting-smarter) -- Ecosystem scale and security partnerships (MEDIUM confidence)
- [Trail of Bits Skills](https://github.com/trailofbits/skills) -- Competitor: security research skills, plugin marketplace, ~91 commits (MEDIUM confidence)
- [Transilience Community Tools](https://github.com/transilienceai/communitytools) -- Competitor: 7 pentesting skills, 35+ agents, no hooks (MEDIUM confidence)
- [awesome-claude-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) -- Competitor: SecLists-based security skills, no enforcement (MEDIUM confidence)
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) -- Competitor: 169 skills, 2,300+ stars, zero-dep Python tools (MEDIUM confidence)
- [Claude Code FAQ on Skills vs Plugins](https://x.com/claude_code/status/2009479585172242739) -- "Plugins are containers for distributing skills" (MEDIUM confidence)

---
*Feature research for: Claude Code pentesting skill publication to skills.sh*
*Researched: 2026-03-06*
