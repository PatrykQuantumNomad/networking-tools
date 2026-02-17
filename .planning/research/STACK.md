# Stack Research: Claude Code Skill Pack

**Domain:** Claude Code plugin/skill pack for pentesting toolkit
**Researched:** 2026-02-17
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Claude Code Plugin System | 1.0.33+ | Primary distribution format | Official packaging mechanism for skills, agents, hooks, and MCP servers. Supports marketplace distribution, versioning, and team sharing. The plugin system supersedes standalone `.claude/commands/` files for distributable packages. |
| SKILL.md (Agent Skills format) | Current | Skill definitions | The modern replacement for `.claude/commands/*.md` files. Skills support directories with supporting files, model-invocation control, subagent context forking, and dynamic context injection via `!`command`` syntax. Commands still work but skills are the recommended path forward. |
| Markdown + YAML frontmatter | N/A | Skill/agent/command authoring | All Claude Code extensibility uses Markdown body with YAML frontmatter for configuration. No build step, no compilation, pure text files. |
| JSON | N/A | Hook/MCP/settings configuration | `hooks.json`, `plugin.json`, `marketplace.json`, `.mcp.json` all use JSON. No YAML, no TOML -- JSON only for configuration files. |
| Bash | 4.0+ | Script runtime and hook commands | The project is bash-first. Hook commands execute bash scripts. The existing 81 scripts with `-j/--json` structured output are directly usable by Claude via hooks and skills. |
| Node.js | 18+ | Hook scripts (when complex JSON parsing needed) | Claude Code hooks receive JSON via stdin. For complex JSON processing, Node.js scripts are more robust than bash+jq. The existing GSD hooks (`gsd-check-update.js`, `gsd-statusline.js`) already demonstrate this pattern in this repo. |
| jq | 1.6+ | JSON parsing in hook commands | Lightweight alternative to Node.js for simple hook commands. Official Claude Code docs recommend jq for extracting fields from hook JSON input. Already a validated dependency in this project from the JSON output milestone. |

### Plugin Directory Structure

| Component | Location | Purpose | When to Use |
|-----------|----------|---------|-------------|
| `.claude-plugin/plugin.json` | Plugin root | Manifest: name, version, description, author | Always required. Defines the plugin identity and namespace. |
| `skills/<skill-name>/SKILL.md` | Plugin root | Skill directories with main instructions + supporting files | Primary way to expose tool commands and workflows. Each pentesting tool gets a skill directory. |
| `agents/` | Plugin root | Custom subagent definitions as .md files | Specialized personas: `pentester.md`, `defender.md`, `recon-analyst.md` |
| `hooks/hooks.json` | Plugin root | Event handlers: PreToolUse, PostToolUse, SessionStart, etc. | Safety guardrails (warn before destructive commands), environment setup, output formatting |
| `commands/` | Plugin root | Simple slash commands (legacy, still supported) | Quick single-file commands that don't need supporting files |
| `scripts/` | Plugin root | Bash/Node scripts invoked by hooks or referenced by skills | Hook command targets, helper scripts bundled with the plugin |

### Skill Frontmatter Reference (Complete)

| Field | Required | Purpose | Relevant Values for This Project |
|-------|----------|---------|----------------------------------|
| `name` | No (defaults to directory name) | Slash command name. Lowercase, hyphens, max 64 chars | `nmap-scan`, `recon-workflow`, `lab-setup` |
| `description` | Recommended | When Claude should use this skill. Claude reads this to auto-invoke | "Scan a target network with nmap for open ports and services" |
| `argument-hint` | No | Autocomplete hint for user arguments | `[target-ip]`, `[url]`, `[interface]` |
| `disable-model-invocation` | No | `true` = only user can invoke via `/name`. Prevents Claude auto-triggering | `true` for destructive operations (exploitation, active scanning) |
| `user-invocable` | No | `false` = hidden from `/` menu, only Claude can invoke | `false` for background knowledge skills (conventions, safety rules) |
| `allowed-tools` | No | Tools Claude can use without permission when skill is active | `Bash, Read, Grep, Glob` for read-only; add `Write` for report generation |
| `model` | No | Override model for this skill | Generally omit (inherit from session) |
| `context` | No | `fork` = run in isolated subagent context | `fork` for long-running scans that shouldn't consume main context |
| `agent` | No | Which subagent type when `context: fork` | `Explore` for read-only research, custom agent names for specialized work |
| `hooks` | No | Lifecycle hooks scoped to this skill's active period | Per-skill safety validation hooks |

### Agent Frontmatter Reference (Complete)

| Field | Required | Purpose | Relevant Values |
|-------|----------|---------|-----------------|
| `name` | Yes | Agent identifier, lowercase + hyphens | `pentester`, `defender`, `recon-analyst` |
| `description` | Yes | When Claude should delegate to this agent | Detailed description of specialization |
| `tools` | No | Allowlist of tools. Inherits all if omitted | `Read, Grep, Glob, Bash` (restrict per role) |
| `disallowedTools` | No | Denylist: removed from inherited tools | `Write, Edit` for read-only agents |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` | `haiku` for fast recon, `inherit` for complex analysis |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `plan`, `bypassPermissions` | `default` for safety. Never `bypassPermissions` for pentesting. |
| `maxTurns` | No | Maximum agentic turns before agent stops | Set to prevent runaway scanning loops |
| `skills` | No | Skills to preload into agent context at startup | Preload safety guidelines, tool conventions |
| `memory` | No | Persistent memory scope: `user`, `project`, `local` | `project` for learning target-specific patterns |
| `hooks` | No | Agent-scoped lifecycle hooks | PreToolUse validation for command safety |
| `mcpServers` | No | MCP servers available to this agent | Generally not needed -- direct bash execution suffices |

### Hook Event Types (Complete Reference)

| Event | When | Can Block? | Matcher Field | Key Use for This Project |
|-------|------|-----------|---------------|--------------------------|
| `SessionStart` | Session begins/resumes | No (can add context) | Source: startup/resume/clear/compact | Inject safety reminders, check tool availability |
| `UserPromptSubmit` | User submits prompt | Yes | None (always fires) | Validate prompts don't request unauthorized targets |
| `PreToolUse` | Before tool executes | Yes (allow/deny/ask) | Tool name | Block dangerous bash commands, validate targets |
| `PermissionRequest` | Permission dialog shown | Yes (allow/deny) | Tool name | Auto-allow safe read-only commands |
| `PostToolUse` | After tool succeeds | No (can provide feedback) | Tool name | Log executed commands, format output |
| `PostToolUseFailure` | After tool fails | No | Tool name | Suggest troubleshooting steps |
| `Notification` | Claude sends notification | No | Notification type | Desktop notification for long scans |
| `SubagentStart` | Subagent spawned | No (can add context) | Agent type | Inject target-specific context |
| `SubagentStop` | Subagent finishes | Yes | Agent type | Validate scan results before reporting |
| `Stop` | Claude finishes responding | Yes | None (always fires) | Ensure safety summary included |
| `PreCompact` | Before context compaction | No | manual/auto | Preserve critical scan findings |
| `SessionEnd` | Session terminates | No | Exit reason | Cleanup temp files, save session log |

### Hook I/O Protocol

| Aspect | Detail |
|--------|--------|
| **Input** | JSON via stdin: `session_id`, `cwd`, `hook_event_name`, `tool_name`, `tool_input`, `permission_mode` |
| **Exit 0** | Allow action. Stdout parsed as JSON for structured control. For SessionStart/UserPromptSubmit, stdout added to Claude's context. |
| **Exit 2** | Block action. Stderr fed back to Claude as error message. |
| **Other exits** | Non-blocking error. Stderr shown in verbose mode only (`Ctrl+O`). |
| **PreToolUse decisions** | JSON via stdout: `hookSpecificOutput.permissionDecision` = `"allow"` / `"deny"` / `"ask"` |
| **PostToolUse/Stop decisions** | Top-level `decision: "block"` with `reason` field |
| **Context injection** | `hookSpecificOutput.additionalContext` string added to Claude's context |
| **Modified input** | `hookSpecificOutput.updatedInput` modifies tool parameters before execution |
| **Environment** | `$CLAUDE_PROJECT_DIR` = project root, `${CLAUDE_PLUGIN_ROOT}` = plugin install dir, `$CLAUDE_ENV_FILE` = env persistence (SessionStart only) |

### Dynamic Context Injection in Skills

| Syntax | Purpose | Example |
|--------|---------|---------|
| `$ARGUMENTS` | All user arguments | `/nmap-scan 192.168.1.0/24` -> `$ARGUMENTS` = `192.168.1.0/24` |
| `$ARGUMENTS[N]` or `$N` | Positional argument (0-based) | `$0` = first arg, `$1` = second |
| `${CLAUDE_SESSION_ID}` | Current session ID | Logging, session-specific files |
| `` !`command` `` | Shell command output injected before Claude sees the skill | `` !`make check 2>/dev/null` `` to show installed tools |

### Distribution: Marketplace Configuration

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `name` | string | Yes | Marketplace identifier (kebab-case). Users see this: `/plugin install tool@name` |
| `owner.name` | string | Yes | Marketplace maintainer name |
| `owner.email` | string | No | Contact email |
| `metadata.description` | string | No | Brief marketplace description |
| `metadata.version` | string | No | Marketplace format version |
| `plugins[].name` | string | Yes | Plugin identifier |
| `plugins[].source` | string or object | Yes | Where to fetch: `"./path"`, `{source: "github", repo: "owner/repo"}` |
| `plugins[].description` | string | No | Plugin description |
| `plugins[].version` | string | No | Plugin version (semver). If also in plugin.json, plugin.json wins. |

### Plugin Source Types

| Source | Format | Best For |
|--------|--------|----------|
| Relative path | `"./plugins/my-plugin"` | Monorepo marketplace with all plugins in one repo |
| GitHub | `{source: "github", repo: "owner/repo", ref: "v1.0", sha: "abc123"}` | Independent plugin repos. Recommended for this project. |
| Git URL | `{source: "url", url: "https://gitlab.com/team/plugin.git"}` | Non-GitHub git hosts |
| npm | `{source: "npm", package: "name", version: "^1.0"}` | **Not yet fully implemented per official docs. Avoid.** |
| pip | `{source: "pip", package: "name"}` | Python-based plugins (not relevant here) |

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `claude --plugin-dir ./path` | Local plugin testing without installation | Supports multiple `--plugin-dir` flags for loading multiple plugins simultaneously |
| `claude plugin validate .` | Validate marketplace/plugin JSON syntax | Also available as `/plugin validate .` within Claude Code |
| `claude --debug` | Debug hook execution | Shows matched hooks, exit codes, stdout/stderr output |
| `/hooks` menu | Interactive hook management | View, add, delete hooks. Changes take effect immediately. |
| `/plugin` menu | Interactive plugin management | Install, enable, disable, update plugins |
| `/context` | Check skill loading status | Shows if skills are excluded due to character budget limits |
| `Ctrl+O` | Toggle verbose mode | See hook output in transcript |
| BATS | Test bash scripts bundled with plugin | Existing 435-test suite. Test scripts independently before packaging. |

## Installation

```bash
# The plugin itself is pure markdown/json/bash -- no build step, no npm install

# Development: Test plugin locally
claude --plugin-dir ./networking-tools-plugin

# Distribution Option 1: Direct from GitHub marketplace
# User adds the marketplace once:
#   /plugin marketplace add owner/networking-tools-marketplace
# Then installs:
#   /plugin install networking-tools@marketplace-name

# Distribution Option 2: Project-level auto-discovery
# Add to .claude/settings.json in any project:
# {
#   "extraKnownMarketplaces": {
#     "networking-tools": {
#       "source": { "source": "github", "repo": "owner/networking-tools-plugin" }
#     }
#   },
#   "enabledPlugins": { "networking-tools@networking-tools": true }
# }

# User dependencies (pentesting tools the plugin wraps):
brew install nmap nikto sqlmap john hashcat jq  # macOS
# or: apt install nmap nikto sqlmap john hashcat jq  # Linux
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Plugin system (skills + agents + hooks) | Standalone `.claude/commands/` only | If distribution is not a goal and skills are only for personal/project use. Commands work without plugin infrastructure. |
| SKILL.md format (skills/) | commands/*.md format | Commands still work and are simpler (single file, no directory). Use for very simple slash commands that need no supporting files. |
| Bash hook scripts with jq | Node.js hook scripts | Use Node.js when JSON parsing is complex (deeply nested objects, array manipulation). For simple field extraction, bash+jq is lighter. |
| GitHub marketplace distribution | npm source | npm source is "not yet fully implemented" per official docs (warning shown in validation). GitHub repo source is the mature, recommended path. |
| Plugin with marketplace.json | Raw git repo with `.claude/` files | Raw `.claude/` approach requires users to manually copy files. Plugin system handles installation, updates, versioning, and namespacing automatically. |
| Separate marketplace repo | Marketplace in same repo as plugin | Keeps distribution config separate from plugin code. Allows one marketplace to host multiple plugins. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| npm source in marketplace.json | Documented as "not yet fully implemented" in official docs. Validation emits warning. | GitHub repo source or relative path source |
| `type: "prompt"` hooks for safety checks | Adds LLM call latency and non-determinism to safety guardrails that should be deterministic | `type: "command"` hooks with bash scripts for deterministic validation |
| Complex MCP servers for wrapping bash scripts | Overkill. Adds Node.js server runtime requirement, complex setup. | Skills that invoke bash scripts directly via `!`command`` injection or allowed Bash tool |
| `bypassPermissions` on subagents | Pentesting tools can be destructive. Bypassing permissions removes the safety net. | `default` or `acceptEdits` permission mode with explicit tool allowlists |
| Inline hook configs in plugin.json | Harder to maintain than a separate file; mixes metadata with behavior | Separate `hooks/hooks.json` file referenced from plugin.json |
| `.claude/commands/` for distribution | Not portable. Requires manual file copying. No versioning, no namespacing. | Plugin system with skills/ directory |
| Agent teams for this use case | Experimental feature requiring env var flag. Overkill for skill pack. | Standard subagents (well-supported, stable API) |

## Stack Patterns by Variant

**If building a minimal skill pack (Phase 1):**
- Use `skills/` directory with SKILL.md files only
- Each tool gets its own skill directory (e.g., `skills/nmap-scan/SKILL.md`)
- No hooks, no agents, no MCP servers
- Users invoke via `/networking-tools:nmap-scan <target>`
- Because: Simplest to build, test, and maintain. Validates the approach before adding complexity.

**If building a full plugin with safety (Phase 2):**
- Add `hooks/hooks.json` with PreToolUse safety checks
- Add `agents/` with specialized pentesting personas
- Skills reference agents for complex workflows
- Because: Provides guided workflows, safety guardrails, and specialized AI behavior.

**If distributing via marketplace (Phase 3):**
- Create a separate marketplace repo with `.claude-plugin/marketplace.json`
- Plugin source points to the networking-tools repo via GitHub source
- Version tracked in plugin.json (single source of truth)
- Because: Clean separation between the tool and its distribution mechanism. Users get automatic updates.

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| Plugin system | Claude Code >= 1.0.33 | Minimum version for `/plugin` command and plugin infrastructure |
| Skills (SKILL.md) | Claude Code >= 1.0 | Skills merged with commands; both formats work |
| Hooks API (all events) | Claude Code >= 1.0 | All 14 hook events documented above are stable |
| `context: fork` | Claude Code >= 1.0 | Runs skill in isolated subagent context |
| `` !`command` `` injection | Claude Code >= 1.0 | Preprocesses shell commands before skill content sent to Claude |
| `$ARGUMENTS` / `$N` | Claude Code >= 1.0 | String substitution in skill content |
| `${CLAUDE_PLUGIN_ROOT}` | Claude Code >= 1.0.33 | Environment variable for plugin-relative paths in hooks/MCP |
| Agent teams | Claude Code (experimental) | Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Not recommended for this project. |
| LSP servers in plugins | Claude Code >= 1.0.33 | Not relevant for this project (no code intelligence needed) |

## Sources

### HIGH Confidence (Official documentation, verified via WebFetch)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/slash-commands) -- Complete skills/commands reference, frontmatter fields, invocation control, dynamic context injection
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) -- Hook automation walkthrough, common patterns
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- Complete hook event schemas, JSON I/O format, all 14 events, matcher patterns
- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins) -- Plugin creation, structure, quickstart, migration from .claude/
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Complete plugin manifest schema, CLI commands, debugging tools
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) -- marketplace.json schema, source types, distribution, hosting
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents) -- Agent definition format, frontmatter, built-in agents, persistent memory
- [Anthropic Official Plugin Marketplace](https://github.com/anthropics/claude-code/blob/main/.claude-plugin/marketplace.json) -- Real-world marketplace.json structure

### MEDIUM Confidence (Community examples, cross-referenced with official docs)
- [awesome-claude-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) -- Existing security skill pack with pentesting agents
- [Trail of Bits Claude Code Skills](https://github.com/trailofbits/skills) -- Security research skills by established security firm
- [Claude Code OWASP Skills](https://github.com/agamm/claude-code-owasp) -- Security best practices skill example
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) -- Curated list of skills, hooks, commands, plugins
- [Anthropic Claude Plugins Official](https://github.com/anthropics/claude-plugins-official) -- Anthropic-managed plugin directory

---
*Stack research for: Claude Code Skill Pack for Networking/Pentesting Tools*
*Researched: 2026-02-17*
