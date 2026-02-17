# Phase 29: Core Tool Skills - Research

**Researched:** 2026-02-17
**Domain:** Claude Code skills for pentesting tool wrappers
**Confidence:** HIGH

## Summary

Phase 29 creates the first 5 Claude Code skills (nmap, tshark, metasploit, sqlmap, nikto) to validate the tool skill pattern before scaling to all 17 tools in Phase 31. The research confirms that Claude Code's skill system is purpose-built for this use case: skills package instructions with supporting resources, use `disable-model-invocation: true` to prevent auto-execution, and load on-demand to avoid context bloat.

The existing codebase already provides everything needed: 17 tools with `examples.sh` scripts, 28 specialized use-case scripts across 10 tools, and Phase 28's safety hooks (PreToolUse/PostToolUse) that validate targets and parse JSON output. The skill layer simply maps user intent (slash commands) to these existing scripts with zero modifications.

**Primary recommendation:** Create minimal skill files that act as navigation/discovery layers over existing scripts. Each SKILL.md should list available use-case scripts with descriptions, reference the tool's examples.sh for learning, and include clear guidance on the `-j` flag for structured output that feeds Phase 28's PostToolUse hook.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code Skills | Current (v2.1.3+) | Skill system with YAML frontmatter and markdown instructions | Official Claude Code extension mechanism, merged slash commands into unified system Jan 2026 |
| bash | 4.0+ | Shell scripting for wrapper scripts | Already used throughout project, required for associative arrays in safety hooks |
| jq | 1.6+ | JSON parsing in hooks and scripts | Already used in Phase 28 hooks, required dependency for JSON bridge |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| YAML frontmatter | - | Skill metadata (name, description, disable-model-invocation) | Every SKILL.md file for skill configuration |
| Markdown | - | Skill instructions content | Skill body after frontmatter separator |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Skills | `.claude/commands/*.md` files | Commands still work but skills add supporting file directories and better control over invocation |
| `disable-model-invocation: true` | `user-invocable: false` | Wrong semantics — user-invocable: false hides from menu but description still loads; we need model to never auto-invoke these tools |

**Installation:**
No installation needed — Claude Code skills are built-in, existing scripts already exist.

## Architecture Patterns

### Recommended Project Structure
```
.claude/skills/
├── nmap/
│   └── SKILL.md              # Tool skill for nmap
├── tshark/
│   └── SKILL.md              # Tool skill for tshark
├── metasploit/
│   └── SKILL.md              # Tool skill for metasploit
├── sqlmap/
│   └── SKILL.md              # Tool skill for sqlmap
├── nikto/
│   └── SKILL.md              # Tool skill for nikto
└── netsec-health/
    └── SKILL.md              # Already exists from Phase 28
```

Skills reference existing scripts at:
```
scripts/
├── nmap/
│   ├── examples.sh                     # 10 generic examples
│   ├── discover-live-hosts.sh          # Use-case: host discovery
│   ├── identify-ports.sh               # Use-case: port scanning
│   └── scan-web-vulnerabilities.sh     # Use-case: web vuln scanning
├── tshark/
│   ├── examples.sh
│   ├── capture-http-credentials.sh
│   ├── analyze-dns-queries.sh
│   └── extract-files-from-capture.sh
├── metasploit/
│   ├── examples.sh
│   ├── generate-reverse-shell.sh
│   ├── scan-network-services.sh
│   └── setup-listener.sh
├── sqlmap/
│   ├── examples.sh
│   ├── dump-database.sh
│   ├── test-all-parameters.sh
│   └── bypass-waf.sh
└── nikto/
    ├── examples.sh
    ├── scan-specific-vulnerabilities.sh
    ├── scan-multiple-hosts.sh
    └── scan-with-auth.sh
```

### Pattern 1: Tool Skill as Navigation Layer
**What:** Each skill is a discovery/navigation wrapper over existing scripts, not a reimplementation
**When to use:** Always for tool skills — wrapper pattern is architectural decision from v1.5

**Example:**
```yaml
---
name: nmap
description: Network scanning and host discovery using nmap wrapper scripts
disable-model-invocation: true
---

# Nmap Network Scanner

Run nmap wrapper scripts that provide educational examples and structured JSON output.

## Available Scripts

### Discovery
- `bash scripts/nmap/discover-live-hosts.sh [target] [-j] [-x]` — Find active hosts on network
- `bash scripts/nmap/identify-ports.sh [target] [-j] [-x]` — Scan for open ports

### Web Scanning
- `bash scripts/nmap/scan-web-vulnerabilities.sh [target] [-j] [-x]` — Detect web vulnerabilities

### Learning Mode
- `bash scripts/nmap/examples.sh [target]` — View 10 common nmap patterns with explanations

## Flags
- `-j` / `--json` — Output structured JSON (enables PostToolUse hook summary)
- `-x` / `--execute` — Execute commands instead of displaying them

## Target Validation
All scripts validate targets against `.pentest/scope.json`. Run `/netsec-health` if blocked.
```

### Pattern 2: Skill Frontmatter Standards
**What:** Every tool skill uses identical frontmatter structure with `disable-model-invocation: true`
**When to use:** All 5 core tool skills (and the 12 in Phase 31)

**Example:**
```yaml
---
name: tshark
description: Packet capture and network traffic analysis using tshark wrapper scripts
disable-model-invocation: true
---
```

**Why this matters:**
- `disable-model-invocation: true` prevents Claude from auto-invoking pentesting tools (safety requirement)
- Description is still visible to Claude for context but full skill only loads on explicit `/tool-name` invocation
- Name field creates the slash command (must be lowercase, hyphens only, max 64 chars)

### Pattern 3: Script Reference Format
**What:** List all available scripts with one-line descriptions, grouped by category
**When to use:** Every tool skill SKILL.md body

**Example:**
```markdown
## Available Scripts

### Credential Capture
- `bash scripts/tshark/capture-http-credentials.sh [interface] [-j] [-x]` — Extract HTTP credentials from traffic

### Analysis
- `bash scripts/tshark/analyze-dns-queries.sh [pcap-file] [-j] [-x]` — Analyze DNS query patterns
- `bash scripts/tshark/extract-files-from-capture.sh [pcap-file] [-j] [-x]` — Carve files from packet capture

### Learning Mode
- `bash scripts/tshark/examples.sh [target]` — View 10 common tshark patterns
```

**Why this structure:**
- Category headers group related operations (Discovery, Analysis, Exploitation, etc.)
- Full relative paths from project root (bash scripts/TOOL/SCRIPT.sh)
- Brief descriptions (one verb phrase: "Extract...", "Analyze...", "Detect...")
- Consistent flag documentation ([-j] [-x] pattern)

### Anti-Patterns to Avoid
- **Embedding tool commands in skills**: Skills reference wrapper scripts, never raw tool invocations
- **Auto-invocation for tools**: `disable-model-invocation: true` must be set — user explicitly invokes pentesting tools
- **Duplicating script help text**: Link to existing help (`script.sh --help`), don't copy it
- **Large skill files**: Keep SKILL.md under 500 lines (current scripts already handle complexity)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Target validation | Custom bash scope checking | Phase 28 PreToolUse hook | Already implemented, validates against .pentest/scope.json |
| JSON output parsing | Custom jq in skills | Phase 28 PostToolUse hook | Already parses -j envelope and injects additionalContext |
| Audit logging | Custom logging in skills | Phase 28 hooks | Every tool invocation already logged to .pentest/audit-*.jsonl |
| Script argument handling | New CLI parser | Existing `parse_common_args` from common.sh | Already handles -j, -x, --help consistently |
| Tool installation checks | New verification | Existing `require_cmd` from common.sh | Already checks tool availability with install hints |

**Key insight:** Phase 28 safety hooks and existing script infrastructure solve the hard problems. Skills are just navigation/discovery — they map user intent to scripts, nothing more.

## Common Pitfalls

### Pitfall 1: Setting `user-invocable: false` instead of `disable-model-invocation: true`
**What goes wrong:** Claude can still auto-invoke the skill via the Skill tool, just hidden from menu
**Why it happens:** Confusing the two fields — they control different things
**How to avoid:** Always use `disable-model-invocation: true` for tool skills, never `user-invocable: false`
**Warning signs:** Skill description shows in Claude's context during regular conversation (use `/context` to check)

**Correct behavior:**
| Field | Effect on Invocation | Effect on Context |
|-------|---------------------|-------------------|
| `disable-model-invocation: true` | User only (via `/tool-name`) | Description NOT in context, full skill loads on explicit invocation |
| `user-invocable: false` | Claude only (via Skill tool) | Description always in context, hidden from `/` menu |
| (default / both false) | User and Claude | Description always in context, both can invoke |

### Pitfall 2: Embedding raw tool commands instead of wrapper scripts
**What goes wrong:** PreToolUse hook blocks raw tool invocations with redirect to wrapper scripts
**Why it happens:** Not understanding the wrapper pattern — hooks intercept `nmap X` and deny it
**How to avoid:** Always reference `bash scripts/TOOL/SCRIPT.sh` paths, never raw tool commands
**Warning signs:** Hook deny messages like "Blocked: direct 'nmap' call. Use wrapper scripts in scripts/nmap/"

**Phase 28 hook behavior:**
- ✅ `bash scripts/nmap/discover-live-hosts.sh localhost -j` — Allowed (wrapper script)
- ❌ `nmap -sn 192.168.1.0/24` — Blocked by PreToolUse hook (raw tool)
- ❌ `sudo nmap -sS 192.168.1.1` — Blocked by PreToolUse hook (raw tool with sudo)

### Pitfall 3: Not documenting the `-j` flag prominently
**What goes wrong:** Users don't add `-j`, miss out on structured JSON output and PostToolUse hook summaries
**Why it happens:** Treating `-j` as optional detail instead of core feature
**How to avoid:** Show `-j` in every script example, add dedicated "Flags" section explaining it
**Warning signs:** Users report "Claude doesn't understand results" (Claude got raw stdout, not parsed JSON)

**Good example:**
```markdown
## Flags
- `-j` / `--json` — Output structured JSON (enables PostToolUse hook summary)
- `-x` / `--execute` — Execute commands instead of displaying them

All scripts support `-j` for machine-readable output. The PostToolUse hook parses
this output and injects a summary into Claude's context automatically.
```

### Pitfall 4: Context window bloat from too many skills
**What goes wrong:** Skill descriptions exceed the 2% context window budget, some skills get excluded
**Why it happens:** Not understanding that descriptions load into context by default (unless `disable-model-invocation: true`)
**How to avoid:** Use `disable-model-invocation: true` for all tool skills (prevents description loading)
**Warning signs:** `/context` command shows warning about excluded skills

**Budget math:**
- Default: 2% of context window (~3,200 tokens for 200k window)
- Override: Set `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var
- Tool skills with `disable-model-invocation: true`: NOT counted (descriptions not in context)
- Utility/workflow skills: DO count (descriptions loaded for auto-invocation)

### Pitfall 5: Forgetting target validation requirements
**What goes wrong:** Users try scripts against out-of-scope targets, get blocked, don't know why
**Why it happens:** Not documenting the scope.json requirement
**How to avoid:** Every skill must mention target validation and reference `/netsec-health`
**Warning signs:** User reports "commands always blocked" (no scope file or target not in scope)

**Required in every tool skill:**
```markdown
## Target Validation
All scripts validate targets against `.pentest/scope.json`. If commands are blocked:
1. Run `/netsec-health` to check safety architecture status
2. Add your target to `.pentest/scope.json` or create the file if missing
3. Allowed targets: localhost, 127.0.0.1, lab targets (8080, 3030, 8888, 8180)
```

## Code Examples

Verified patterns from project codebase and official Claude Code docs:

### Minimal Tool Skill (nmap)
```yaml
---
name: nmap
description: Network scanning and host discovery using nmap wrapper scripts
disable-model-invocation: true
---

# Nmap Network Scanner

Run nmap wrapper scripts that provide educational examples and structured JSON output.

## Available Scripts

### Discovery
- `bash scripts/nmap/discover-live-hosts.sh [target] [-j] [-x]` — Find active hosts on network
- `bash scripts/nmap/identify-ports.sh [target] [-j] [-x]` — Scan for open ports

### Web Scanning
- `bash scripts/nmap/scan-web-vulnerabilities.sh [target] [-j] [-x]` — Detect web vulnerabilities

### Learning Mode
- `bash scripts/nmap/examples.sh [target]` — View 10 common nmap patterns with explanations

## Flags
- `-j` / `--json` — Output structured JSON (enables PostToolUse hook summary)
- `-x` / `--execute` — Execute commands instead of displaying them
- `--help` — Show detailed help for any script

## Target Validation
All scripts validate targets against `.pentest/scope.json`. If blocked, run `/netsec-health`.

Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
```
**Source:** Official docs pattern adapted to pentesting tool context

### Multi-Category Tool Skill (metasploit)
```yaml
---
name: metasploit
description: Exploitation framework wrapper scripts for payloads, scanning, and listeners
disable-model-invocation: true
---

# Metasploit Framework

Run metasploit wrapper scripts (msfconsole, msfvenom, msfdb) with guided examples.

## Available Scripts

### Payload Generation
- `bash scripts/metasploit/generate-reverse-shell.sh [lhost] [lport] [-j] [-x]` — Create reverse shell payloads

### Network Scanning
- `bash scripts/metasploit/scan-network-services.sh [target] [-j] [-x]` — Identify services and versions

### Listeners
- `bash scripts/metasploit/setup-listener.sh [lhost] [lport] [-j] [-x]` — Configure handler for reverse connections

### Learning Mode
- `bash scripts/metasploit/examples.sh [target]` — View 10 common metasploit patterns

## Flags
- `-j` / `--json` — Output structured JSON (enables PostToolUse hook summary)
- `-x` / `--execute` — Execute commands instead of displaying them

## Target Validation
All scripts validate targets against `.pentest/scope.json`. Run `/netsec-health` if blocked.
```
**Source:** Project scripts/metasploit/ directory structure

### Invocation from User (slash command)
```
User: /nmap
Claude: [Skill tool loads .claude/skills/nmap/SKILL.md]
        I've loaded the nmap skill. This provides wrapper scripts for:
        - Host discovery (discover-live-hosts.sh)
        - Port scanning (identify-ports.sh)
        - Web vulnerability detection (scan-web-vulnerabilities.sh)

        What target would you like to scan? (Must be in .pentest/scope.json)

User: Scan localhost for open ports
Claude: [Invokes] bash scripts/nmap/identify-ports.sh localhost -j -x
        [PreToolUse hook validates localhost is in scope]
        [Script executes, outputs JSON envelope]
        [PostToolUse hook parses JSON, injects summary]
        [Claude receives additionalContext: "Netsec result: nmap (identify-ports) against localhost in execute mode. 5 items: 5 succeeded, 0 failed."]
```
**Source:** Claude Code skill loading pattern from official docs

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Slash commands in `.claude/commands/*.md` | Skills in `.claude/skills/*/SKILL.md` | Jan 2026 (v2.1.3) | Unified system, commands still work but skills add supporting files and invocation control |
| Hardcoded tool usage in CLAUDE.md | On-demand skill loading with disable-model-invocation | 2026 | Skills don't bloat context until invoked, 2% budget for auto-invocable skills only |
| Raw tool commands | Safety hooks intercept and redirect to wrappers | Feb 2026 (Phase 28) | All tool invocations validated, logged, no raw tool execution |
| Unstructured stdout | JSON envelope output parsed by PostToolUse hook | Feb 2026 (Phase 28) | Claude gets structured summaries instead of raw terminal output |

**Deprecated/outdated:**
- `.claude/commands/` files: Still work but skills are recommended (better features)
- `user-invocable: false` for tool prevention: Wrong field — use `disable-model-invocation: true`
- Embedding tool help in CLAUDE.md: Context bloat — use skills with `disable-model-invocation: true` instead

## Open Questions

1. **Should skills provide target suggestions or require explicit user input?**
   - What we know: Lab targets (localhost, 127.0.0.1, container ports) are always safe
   - What's unclear: Should skills auto-suggest "localhost" or force user to specify every time?
   - Recommendation: Mention default safe targets in skill description, let scripts handle defaults (they already default to localhost)

2. **How verbose should script output be in skill descriptions?**
   - What we know: Scripts already have detailed help (`--help`), examples.sh provides learning
   - What's unclear: Should SKILL.md duplicate usage examples or just link to them?
   - Recommendation: One-line script descriptions in SKILL.md, link to `--help` for details (follows "don't duplicate" principle)

3. **Should workflow skills (Phase 32) invoke tool skills or scripts directly?**
   - What we know: Workflow skills will orchestrate multiple tools (e.g., /recon runs nmap + dig + tshark)
   - What's unclear: Should `/recon` invoke `/nmap` (skill) or `bash scripts/nmap/...` (script)?
   - Recommendation: Direct script invocation (workflows are Claude-invoked, skills are user-invoked navigation aids)

## Sources

### Primary (HIGH confidence)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills) — Skill structure, frontmatter fields, disable-model-invocation behavior
- [Inside Claude Code Skills: Structure, prompts, invocation | Mikhail Shilkov](https://mikhail.io/2025/10/claude-code-skills/) — Loading mechanics, context management
- Project codebase: `scripts/*/` directories — 28 use-case scripts across 5 core tools (verified via Glob)
- Project codebase: `scripts/nmap/discover-live-hosts.sh` (lines 1-50) — Wrapper script structure, -j flag, common.sh integration
- Phase 28 PLAN.md files — Safety hook implementation details, scope validation, JSON bridge

### Secondary (MEDIUM confidence)
- [Claude Code Skills: The Complete Guide for Developers | Fraway Blog](https://fraway.io/blog/claude-code-skills-guide/) — Best practices for slash commands
- [Understanding Claude Code: Skills vs Commands vs Subagents vs Plugins](https://www.youngleaders.tech/p/claude-skills-commands-subagents-plugins) — Architectural distinctions
- [Claude Code Merges Slash Commands Into Skills (Medium, Jan 2026)](https://medium.com/@joe.njenga/claude-code-merges-slash-commands-into-skills-dont-miss-your-update-8296f3989697) — Recent unification (v2.1.3)

### Tertiary (LOW confidence)
- [Bash Scripting Best Practices for Reliable Automation (Feb 2026)](https://oneuptime.com/blog/post/2026-02-13-bash-best-practices/view) — General bash patterns, not pentesting-specific
- [Top AI Pentesting Tools in 2025](https://www.penligent.ai/hackinglabs/top-ai-pentesting-tools-in-2025-pentestgpt-vs-penligent-vs-pentestai-reviewed/) — Market overview, not implementation guidance

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Claude Code skills are official, codebase scripts verified via direct file reads
- Architecture: HIGH — Patterns derived from official docs + existing Phase 28 implementation
- Pitfalls: HIGH — Drawn from official docs confusion points (user-invocable vs disable-model-invocation) + Phase 28 hook behavior

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (30 days — Claude Code stable, skills system mature as of v2.1.3)
