# Phase 34: Plugin Scaffold and GSD Separation - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish `netsec-skills/` plugin directory with manifest, marketplace catalog, and clean GSD boundary. Users can load a clean netsec-only plugin directory that contains zero GSD framework artifacts. Skills are symlinked from existing `.claude/skills/` during this phase — later phases (36+) replace symlinks with standalone copies.

</domain>

<decisions>
## Implementation Decisions

### Plugin identity
- Name: `netsec-skills`
- Description: "Pentesting skills pack — 17 tool skills, 6 workflows, 3 agent personas for network security testing with Claude Code"
- Version: `1.0.0` (fresh start, independent of repo milestone versioning)
- Keywords: mixed broad pentesting terms + specific tool names for maximum discoverability (pentesting, security, red-team, CTF, network-security, nmap, sqlmap, hashcat, metasploit, nikto, gobuster)

### Skill categorization
- Grouped by type inside `skills/`: `tools/`, `workflows/`, `agents/`, `utility/`
- 4 skill types: tool (17+1 traceroute), workflow (6), agent (3), utility (scope, health, check-tools)
- Traceroute included as a tool skill despite not being in the original 10-tool list
- Report skill included in plugin (useful standalone for any pentester)

### Marketplace catalog (marketplace.json)
- Rich metadata per entry: name, type, trigger, description, tags, requires (tool dependency)
- Separate top-level sections for skills, hooks, and agents (not flattened into one list)
- Hooks section lists PreToolUse (scope check) and PostToolUse (audit) with event types
- Agents section lists pentester, defender, analyst with role descriptions

### GSD boundary enforcement
- Allowlist approach: only explicitly permitted file types exist in `netsec-skills/`
- Allowed: `skills/**/*.md`, `hooks/*.sh`, `agents/*.md`, `scripts/*.sh`, `plugin.json`, `marketplace.json`, `README.md`
- Anything not on the allowlist is rejected — no blocklist/grep pattern matching

### File strategy during development
- Symlinks from `netsec-skills/skills/` back to `.claude/skills/` during Phase 34
- Phase 36+ replaces symlinks with modified standalone copies
- Hooks copied as-is from `.claude/hooks/` into `netsec-skills/hooks/` (Phase 35 modifies for portability)

### Repo-only skills (excluded from plugin)
- `/lab` — depends on repo-specific `labs/docker-compose.yml`, not useful standalone
- `/pentest-conventions` — defines repo-specific script conventions (common.sh pattern, examples.sh structure)

### Plugin README
- Full README.md at `netsec-skills/` root: installation instructions, skill list, usage examples, safety notes, quick start with `/netsec-health`

### Claude's Discretion
- Exact plugin.json schema fields beyond name/description/version/keywords
- README.md formatting and section ordering
- How to validate the allowlist (script, manual check, or CI step)
- Symlink creation approach (relative vs absolute paths)

</decisions>

<specifics>
## Specific Ideas

- Plugin should present itself as a complete pentesting toolkit, not a collection of individual skills
- Keywords strategy: broad terms (pentesting, security, red-team, CTF) for discovery + tool names (nmap, sqlmap) for precision search
- marketplace.json should be the single source of truth for what the plugin contains — downstream phases reference it

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 34-plugin-scaffold-and-gsd-separation*
*Context gathered: 2026-03-06*
