# Research Summary: Claude Code Skill Pack

**Domain:** Claude Code skill pack / plugin for pentesting toolkit
**Researched:** 2026-02-17
**Overall confidence:** HIGH

## Executive Summary

This research establishes the technology stack, architecture, and distribution strategy for building a Claude Code skill pack that wraps the existing 81 bash pentesting scripts. The skill pack creates an AI-powered interface layer (skills, agents, hooks) on top of the validated bash toolkit, enabling users to invoke tools via slash commands, receive structured results via the existing `-j/--json` envelope protocol, and benefit from safety guardrails enforced through the hook system.

The core architectural decision is **plugin wraps, never modifies**. The existing bash scripts remain untouched. Skills reference scripts by path, hooks validate commands before execution, and agents orchestrate multi-tool workflows. The existing fd3 JSON redirect protocol (`-j` flag) provides clean structured output that Claude can parse and reason about -- no additional script modifications are needed for Claude Code integration.

The second key decision is **start with project-level `.claude/skills/` files, defer plugin packaging**. Direct files in `.claude/` are simpler, version-control with the project, and require zero distribution infrastructure. Converting to a distributable plugin later is a file-move operation (add `.claude-plugin/plugin.json`, reorganize into plugin directory layout) with no code changes. This approach is validated by the official Claude Code documentation, which explicitly recommends starting standalone and converting to plugins when distribution is needed.

The third key decision is **deterministic safety hooks over LLM-based hooks**. The PreToolUse hook uses pattern matching (bash+jq) to validate commands before execution -- fast, free, deterministic. The `type: "prompt"` and `type: "agent"` hook options add LLM latency and non-determinism that is inappropriate for safety-critical validation of pentesting commands.

## Key Findings

**Stack:** Claude Code's plugin system (skills, agents, hooks, marketplace) is the complete stack. No additional frameworks, build tools, or runtime dependencies needed beyond existing bash+jq. Skills are Markdown+YAML frontmatter files. Hooks are JSON config pointing to bash scripts. Distribution uses GitHub-based marketplace.json.

**Architecture:** Skills invoke existing scripts via Bash tool. PostToolUse hook detects JSON envelope output and provides structured context to Claude. Subagents isolate verbose scan output from the main conversation. `netsec-` prefix separates from existing GSD commands.

**Critical pitfall:** Autonomous scanning. Claude must NEVER auto-invoke active scanning skills. All scanning skills require `disable-model-invocation: true` in frontmatter, and the PreToolUse hook validates targets before execution.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Foundation: Plugin structure + safety hooks** - Create plugin manifest/directory layout, implement PreToolUse safety hook, SessionStart tool availability check
   - Addresses: Plugin identity, safety guardrails, environment awareness
   - Avoids: Building skills before safety infrastructure is in place

2. **Core skills: Top 5 tool skills + lab integration** - Create SKILL.md for nmap, nikto, sqlmap, tshark, hashcat + Docker lab management skills
   - Addresses: Core tool coverage, immediate user value, lab practice environment
   - Avoids: All-at-once skill creation (validate pattern with 5 before scaling to 17)

3. **Complete skills: Remaining tools + utility skills** - Scale to all 17 tools, add check-tools, find-script, examples-browser skills
   - Addresses: Full tool coverage, discoverability
   - Avoids: Premature agent creation (agents reference skills, so skills must exist first)

4. **Agents + workflows** - Create specialized subagents (pentester, defender, analyst), multi-tool workflow skills
   - Addresses: Guided workflows, context isolation for verbose output, specialized personas
   - Avoids: Complexity before foundation is proven

5. **Distribution (optional)** - Convert to plugin package, create marketplace.json, publish to GitHub
   - Addresses: Sharing with other users/projects
   - Avoids: Distribution overhead before the skill pack is feature-complete

**Phase ordering rationale:**
- Safety first: Hooks must be in place before any skills can run scans
- Skills before agents: Agents orchestrate skills, so skills must exist and be validated first
- Validate with subset: Build 5 tool skills, verify the pattern works, then scale to all 17
- Distribution last: No point distributing an incomplete skill pack

**Research flags for phases:**
- Phase 1: Standard patterns, well-documented -- no further research needed
- Phase 2: Validate skill content pattern with real tool invocations -- may need iteration
- Phase 4: Agent memory (`memory: project`) is newer feature -- validate behavior in practice
- Phase 5: Plugin distribution mechanics are well-documented but npm source is flagged as "not yet fully implemented" -- stick to GitHub source

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (plugin system) | HIGH | All APIs verified against official Claude Code documentation via WebFetch. Multiple source types confirmed. |
| Stack (hooks API) | HIGH | Complete hook event schemas, I/O protocols, and matcher patterns extracted from official reference docs. |
| Stack (skills format) | HIGH | Skill frontmatter fields, invocation control, and dynamic context injection verified against official docs. |
| Features (skill list) | HIGH | Features derived directly from existing codebase analysis (81 scripts, 17 tools, lab targets). |
| Architecture (integration) | HIGH | fd3 JSON redirect protocol already works with Claude's Bash tool -- no modifications needed. |
| Pitfalls (safety) | HIGH | Safety concerns well-documented in pentesting domain. `disable-model-invocation` verified in official docs. |
| Distribution (marketplace) | MEDIUM | Marketplace format verified against official docs and Anthropic's own marketplace.json. npm source flagged as incomplete. |

## Gaps to Address

- **Skill description budget**: The 2% context window limit for skill descriptions (~16KB) may become a concern at 15+ skills. Monitor with `/context` command during Phase 3. Use `disable-model-invocation: true` to exclude rarely-used skills from auto-loading.
- **PostToolUse hook access to stdout**: The architecture assumes `tool_response.stdout` is available in PostToolUse hooks. This needs validation -- the official docs list `tool_response` in PostToolUse input but the exact field names for Bash tool responses should be confirmed during Phase 1.
- **Agent memory durability**: The `memory: project` feature creates files in `.claude/agent-memory/`. The interaction with git (should these be gitignored?) and with compaction needs practical testing during Phase 4.
- **Plugin conversion path**: When converting from project-level `.claude/skills/` to plugin format, the `$CLAUDE_PROJECT_DIR` references in hooks must change to `${CLAUDE_PLUGIN_ROOT}`. This is documented but needs testing during Phase 5.

## Sources

### HIGH Confidence (Official documentation, verified via WebFetch)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/slash-commands)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents)
- [Anthropic Official Plugin Marketplace](https://github.com/anthropics/claude-code/blob/main/.claude-plugin/marketplace.json)

### MEDIUM Confidence (Community examples, cross-referenced)
- [awesome-claude-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security)
- [Trail of Bits Claude Code Skills](https://github.com/trailofbits/skills)
- [Claude Code OWASP Skills](https://github.com/agamm/claude-code-owasp)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
