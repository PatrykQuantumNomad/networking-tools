# Phase 30: Utility Skills & Lab Integration - Research

**Researched:** 2026-02-17
**Domain:** Claude Code skills (utility/background type), Docker lab management, tool availability checking
**Confidence:** HIGH

## Summary

Phase 30 creates three skills that serve as infrastructure rather than tool-specific wrappers: a check-tools skill (UTIL-01), a lab management skill (UTIL-02), and a background pentest-conventions skill (UTIL-03). Unlike the Phase 29 tool skills which use `disable-model-invocation: true` to prevent automatic loading, this phase introduces two different skill invocation patterns: user-invocable utility skills and a Claude-only background knowledge skill.

The existing codebase already contains all the underlying scripts and configuration needed. `scripts/check-tools.sh` already detects 18 tools (the original 10 plus foremost, dig, curl, nc, traceroute, mtr, gobuster, ffuf). The `labs/docker-compose.yml` and Makefile already provide `lab-up`, `lab-down`, and `lab-status` targets. The skills just need to wrap these existing capabilities following the established Phase 29 pattern.

The most architecturally interesting requirement is UTIL-03: the `pentest-conventions` background skill. This uses `user-invocable: false` (without `disable-model-invocation`) so Claude automatically has the skill description in context, and can invoke the full skill content when pentesting topics arise -- without the user needing to do anything.

**Primary recommendation:** Create three skills following two patterns -- UTIL-01 and UTIL-02 as standard user-invocable skills (without `disable-model-invocation: true` since they have no security tool side effects), and UTIL-03 as a background reference skill with `user-invocable: false`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UTIL-01 | User can invoke check-tools skill to verify tool availability | Wrap existing `scripts/check-tools.sh` which already handles 18 tools. Skill describes the script and its output format. |
| UTIL-02 | User can invoke lab skill to manage Docker vulnerable targets (start, stop, status) | Wrap existing Makefile targets (`lab-up`, `lab-down`, `lab-status`) which use `docker compose -f labs/docker-compose.yml`. Skill describes the three operations and the four lab targets with ports/credentials. |
| UTIL-03 | Background `pentest-conventions` skill provides Claude with pentesting context automatically | Use `user-invocable: false` frontmatter so description is always in Claude's context and Claude auto-invokes when relevant. Contains target notation, output conventions, safety rules, and project-specific patterns. |
</phase_requirements>

## Standard Stack

### Core

| Component | Location | Purpose | Why Standard |
|-----------|----------|---------|--------------|
| Claude Code Skills | `.claude/skills/<name>/SKILL.md` | Extend Claude capabilities via markdown instruction files | Official Claude Code extension mechanism |
| YAML Frontmatter | Top of SKILL.md | Configure skill behavior (name, description, invocation control) | Standard skills configuration format |
| Bash scripts | `scripts/check-tools.sh`, `Makefile` | Underlying functionality the skills wrap | Already built and tested in prior phases |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Docker Compose | v2 (compose v2 syntax) | Lab target management | Lab skill operations |
| `jq` | Any | JSON processing in hooks | Already a dependency from Phase 28 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `user-invocable: false` for UTIL-03 | CLAUDE.md content | CLAUDE.md is always loaded; a skill loads on-demand, saving context budget until needed |
| Separate skills for lab-up/lab-down/lab-status | Single lab skill with argument routing | Single skill is cleaner; Claude interprets "start the lab" naturally and runs the right command |
| `disable-model-invocation: true` for UTIL-01/UTIL-02 | Default (model can invoke) | Check-tools and lab commands are safe utility operations with no security tool side effects; allowing Claude to invoke them when relevant (e.g., "is nmap installed?") improves UX |

## Architecture Patterns

### Skill Directory Structure (Phase 30)

```
.claude/skills/
  check-tools/
    SKILL.md              # UTIL-01: Wraps scripts/check-tools.sh
  lab/
    SKILL.md              # UTIL-02: Wraps Docker lab management commands
  pentest-conventions/
    SKILL.md              # UTIL-03: Background reference skill (user-invocable: false)
```

### Pattern 1: User-Invocable Utility Skill (UTIL-01, UTIL-02)

**What:** A skill the user can invoke with `/check-tools` or `/lab`, AND Claude can also invoke automatically when relevant.

**When to use:** For utility operations that are safe, have no security tool side effects, and the user might want to trigger directly or Claude might need to run.

**Key difference from Phase 29 tool skills:** No `disable-model-invocation: true` because these are safe operations. Unlike `nmap` or `sqlmap` where Claude must never auto-invoke, checking tool availability or starting a lab is harmless.

**Example frontmatter (UTIL-01):**
```yaml
---
name: check-tools
description: Check which pentesting tools are installed on this system. Shows version info and install instructions for missing tools.
---
```

**Example frontmatter (UTIL-02):**
```yaml
---
name: lab
description: Manage Docker vulnerable lab targets (DVWA, Juice Shop, WebGoat, VulnerableApp). Start, stop, or check status of practice environments.
argument-hint: [start|stop|status]
---
```

### Pattern 2: Background Reference Skill (UTIL-03)

**What:** A skill that is NOT visible to the user in the `/` menu, but whose description IS always in Claude's context. Claude auto-invokes it when pentesting topics arise, loading the full conventions content.

**When to use:** For domain knowledge that Claude should apply automatically without user intervention -- conventions, patterns, safety rules.

**Key frontmatter:**
```yaml
---
name: pentest-conventions
description: Pentesting conventions for this project -- target notation, output formats, safety rules, and lab target details. Loaded automatically when pentesting topics arise.
user-invocable: false
---
```

Source: [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- confirmed behavior table:

| Frontmatter | You can invoke | Claude can invoke | When loaded into context |
|-------------|----------------|-------------------|--------------------------|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

### Pattern 3: Consistent Skill Structure (from Phase 29)

All skills follow this structure from the Phase 29 pattern:

1. YAML frontmatter with `name`, `description`, and invocation control
2. H1 heading with tool/utility name
3. One-line summary of what the skill does
4. `## Available Commands` or `## How to Use` section with script paths
5. Section documenting arguments, flags, or operations
6. Section documenting defaults/behavior
7. Double-dash (`--`) for markdown list item descriptions (Phase 29 convention)

### Anti-Patterns to Avoid

- **Do NOT use `disable-model-invocation: true` for UTIL-01 or UTIL-02** -- These are safe utility commands. Blocking Claude from auto-invoking them hurts UX. A user saying "is nmap installed?" should let Claude run check-tools automatically.
- **Do NOT put pentest-conventions content in CLAUDE.md** -- That content loads in EVERY session regardless of relevance. A skill with `user-invocable: false` only loads the description (~30-50 tokens) by default, and the full content only when Claude decides it is relevant.
- **Do NOT create separate skills for lab-up, lab-down, lab-status** -- One `lab` skill with an `argument-hint: [start|stop|status]` is cleaner and uses less context budget. Claude naturally maps "start the lab" to the right command.
- **Do NOT hard-code the 17-tool count in the skill** -- The check-tools.sh script already has 18 entries in `TOOL_ORDER`. Let the script be the source of truth; the skill just describes what it does.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tool detection | Custom tool-checking logic | Existing `scripts/check-tools.sh` | Already handles 18 tools, PATH augmentation, version detection edge cases (msfconsole, dig, nc, traceroute) |
| Docker lab management | Custom Docker commands | Existing Makefile targets (`lab-up`, `lab-down`, `lab-status`) | Already configured with correct compose file path, service names, port mappings |
| Lab target info | Hard-coded in skill | Reference `labs/docker-compose.yml` and Makefile | Single source of truth for ports, images, and credentials |

**Key insight:** Phase 30 is a pure "skill wrapping" phase. Every underlying capability already exists and is tested. The skills provide the Claude Code interface layer and nothing more.

## Common Pitfalls

### Pitfall 1: Tool Count Mismatch

**What goes wrong:** The roadmap says "17 tools" but `check-tools.sh` has 18 entries in TOOL_ORDER (nmap, tshark, msfconsole, aircrack-ng, hashcat, skipfish, sqlmap, hping3, john, nikto, foremost, dig, curl, nc, traceroute, mtr, gobuster, ffuf).
**Why it happens:** msfconsole is the binary name for metasploit, and traceroute/mtr are counted as one "tool" in the roadmap. The script counts them individually.
**How to avoid:** The skill should say "18 tools" to match the script's actual TOOL_ORDER, or describe it generically as "all pentesting tools." Do NOT modify the existing script.
**Warning signs:** Skill saying "17 tools" while script output says "X/18 tools installed."

### Pitfall 2: Lab Port Mismatch Between Docs and Compose

**What goes wrong:** The CLAUDE.md says Juice Shop is on port 3000, but docker-compose.yml maps it to port 3030.
**Why it happens:** CLAUDE.md was written earlier and not updated. The actual compose file is the source of truth.
**How to avoid:** Use the actual port from `docker-compose.yml`: DVWA:8080, JuiceShop:3030, WebGoat:8888, VulnerableApp:8180.
**Warning signs:** Skill referencing port 3000 for Juice Shop.

### Pitfall 3: Context Budget Overflow

**What goes wrong:** Adding 3 more skills pushes total skill descriptions past the 2% context budget.
**Why it happens:** Each skill description consumes ~30-50 tokens. With 5 tool skills (Phase 29) + 1 health skill + 3 utility skills = 9 skills, plus future Phase 31 adds 12 more = 21 total.
**How to avoid:** Keep skill descriptions concise (1 sentence, under 150 characters). The `pentest-conventions` description is always loaded, so it especially must be brief. Monitor with `/context` command.
**Warning signs:** Skills appearing in `/context` warnings about excluded skills.

### Pitfall 4: Pentest-Conventions Skill Being Too Large

**What goes wrong:** The background skill content is loaded fully into context when Claude invokes it. If it is too long, it wastes context window.
**Why it happens:** Temptation to include exhaustive documentation.
**How to avoid:** Keep SKILL.md under 500 lines (official recommendation). Include only: target notation conventions, output format expectations, safety rules, lab target details, and project structure overview. Reference supporting files for anything detailed.
**Warning signs:** Skill file exceeding 200 lines for what should be a conventions reference.

### Pitfall 5: Docker Compose Command Compatibility

**What goes wrong:** Using `docker-compose` (hyphenated, v1) instead of `docker compose` (space, v2).
**Why it happens:** Old habits. The Makefile already uses the correct v2 syntax (`docker compose -f labs/docker-compose.yml`).
**How to avoid:** The skill should reference `make lab-up`, `make lab-down`, `make lab-status` -- not raw Docker commands. The Makefile handles the compose invocation.
**Warning signs:** Skill instructions containing `docker-compose` or `docker compose` instead of `make lab-*`.

## Code Examples

Verified patterns from the existing codebase and official documentation:

### UTIL-01: Check-Tools Skill Structure

```yaml
# Source: Phase 29 skill pattern + Claude Code skills docs
---
name: check-tools
description: Check which pentesting tools are installed on this system and show install instructions for missing ones
---

# Check Tools

Verify which pentesting tools are available on this system.

## How to Use

```bash
bash scripts/check-tools.sh
```

The script checks 18 tools and reports:
- Installed tools with version information
- Missing tools with install instructions
- Summary count (installed/total)

## Tools Checked

nmap, tshark, msfconsole, aircrack-ng, hashcat, skipfish, sqlmap, hping3, john, nikto, foremost, dig, curl, nc, traceroute, mtr, gobuster, ffuf

## Defaults

- No arguments required
- PATH is automatically augmented to include /opt/metasploit-framework/bin, /usr/local/bin, /opt/homebrew/bin
```

### UTIL-02: Lab Skill Structure

```yaml
# Source: Phase 29 skill pattern + Makefile targets
---
name: lab
description: Manage Docker vulnerable lab targets (DVWA, Juice Shop, WebGoat, VulnerableApp) -- start, stop, or check status
argument-hint: [start|stop|status]
---

# Lab Environment

Manage the Docker-based vulnerable practice targets.

## Operations

- `make lab-up` -- Start all lab containers in detached mode
- `make lab-down` -- Stop and remove all lab containers
- `make lab-status` -- Show running status of lab containers

## Lab Targets

| Service | URL | Credentials |
|---------|-----|-------------|
| DVWA | http://localhost:8080 | admin / password |
| Juice Shop | http://localhost:3030 | (register) |
| WebGoat | http://localhost:8888/WebGoat | (register) |
| VulnerableApp | http://localhost:8180/VulnerableApp | -- |

## Prerequisites

Docker must be running. The lab uses `docker compose` (v2) with `labs/docker-compose.yml`.
```

### UTIL-03: Background Pentest-Conventions Skill Structure

```yaml
# Source: Claude Code skills docs (user-invocable: false pattern)
---
name: pentest-conventions
description: Pentesting conventions for this project -- target notation, output formats, safety rules, and lab target details
user-invocable: false
---

# Pentesting Conventions

## Target Notation

- IP addresses: `10.0.0.1`, `192.168.1.0/24`
- Hostnames: `example.com`
- URLs: `http://localhost:8080`
- Localhost equivalents: `localhost` and `127.0.0.1` are interchangeable
- Lab targets: always use `localhost` with the correct port

## Output Expectations

- All use-case scripts support `-j` (JSON output) and `-x` (execute mode)
- Always add `-j` when running scripts so Claude receives structured results via the PostToolUse hook
- Without `-j`, Claude gets raw terminal output instead of parsed summaries
- `examples.sh` scripts do NOT support `-j` or `-x` (learning mode only)

## Safety Rules

- All commands are validated against `.pentest/scope.json` before execution
- Never run security tools directly -- always use wrapper scripts in `scripts/<tool>/`
- The PreToolUse hook blocks raw tool invocations (e.g., `nmap 10.0.0.1`)
- The PreToolUse hook blocks targets not in scope
- Run `bash .claude/hooks/netsec-health.sh` to verify safety architecture

## Scope File

Targets must be listed in `.pentest/scope.json`:
```json
{"targets":["localhost","127.0.0.1"]}
```

## Project Structure

- `scripts/<tool>/examples.sh` -- 10 educational examples per tool
- `scripts/<tool>/<use-case>.sh` -- Task-specific scripts with `-j` and `-x` support
- `scripts/common.sh` -- Shared utilities (colors, logging, validation, JSON)
- `labs/docker-compose.yml` -- Vulnerable Docker targets
- `.claude/hooks/` -- Safety hooks (PreToolUse, PostToolUse, health-check)
- `.claude/skills/` -- Claude Code skill files
- `.pentest/scope.json` -- Target allowlist (gitignored)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Skill descriptions consume tokens even with `disable-model-invocation: true` | `disable-model-invocation: true` removes skill from context entirely | Claude Code 2.1+ (late 2025) | Tool skills (Phase 29) have zero context overhead; utility skills without it have ~30-50 token cost |
| `.claude/commands/` for slash commands | `.claude/skills/` with SKILL.md and supporting files | Claude Code 2.0+ (2025) | Skills merged with commands; commands still work but skills are recommended |
| Full skill content loaded at startup | Only frontmatter (name+description) loaded; full content on invocation | Current behavior | Critical for context budget management |

**Deprecated/outdated:**
- `docker-compose` (hyphenated, v1) -- use `docker compose` (v2) or Makefile targets
- `.claude/commands/*.md` -- still works but `.claude/skills/<name>/SKILL.md` is recommended

## Open Questions

1. **Should check-tools skill trigger automatically?**
   - What we know: Without `disable-model-invocation`, Claude can invoke it when a user asks "is nmap installed?" This is likely desirable behavior.
   - What's unclear: Whether this might trigger unexpectedly in unrelated contexts.
   - Recommendation: Leave default (both user and Claude can invoke). The description is specific enough to prevent spurious invocation. If it becomes an issue, add `disable-model-invocation: true` later.

2. **Should pentest-conventions reference supporting files?**
   - What we know: The official docs recommend keeping SKILL.md under 500 lines and using supporting files for detailed reference material.
   - What's unclear: Whether the conventions content is small enough to fit in a single SKILL.md or should be split.
   - Recommendation: Start with all content in SKILL.md. The conventions content is concise (target notation, output format, safety rules, lab info, project structure). Only split if it exceeds ~200 lines.

3. **How does the lab skill interact with the PreToolUse hook?**
   - What we know: The PreToolUse hook only intercepts commands containing security tool names or `scripts/` paths. `make lab-up` contains neither, so it passes through without interception.
   - What's unclear: Nothing -- this is confirmed by reading the hook code.
   - Recommendation: No hook changes needed. The lab skill's Makefile commands are not security tools and are not in the hook's SECURITY_TOOLS_RE regex.

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Complete skills system reference including frontmatter fields, invocation control, context loading behavior
- Existing codebase: `scripts/check-tools.sh` (18 tools), `labs/docker-compose.yml` (4 targets), `Makefile` (lab targets)
- Phase 29 skills: `.claude/skills/nmap/SKILL.md`, `.claude/skills/tshark/SKILL.md`, etc. -- established pattern
- Phase 28 hooks: `.claude/hooks/netsec-pretool.sh`, `.claude/hooks/netsec-posttool.sh` -- security tool regex and interception logic

### Secondary (MEDIUM confidence)
- [GitHub Issue #19141](https://github.com/anthropics/claude-code/issues/19141) -- Clarification of `user-invocable` vs `disable-model-invocation` distinction
- [GitHub Issue #16616](https://github.com/anthropics/claude-code/issues/16616) -- Known issue about skills loading full content; confirms expected behavior is frontmatter-only at startup

### Tertiary (LOW confidence)
- None -- all findings verified against primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- using existing codebase and documented Claude Code skills features
- Architecture: HIGH -- patterns directly from official docs, confirmed with existing Phase 29 skills
- Pitfalls: HIGH -- identified from direct codebase inspection (port mismatch, tool count) and official docs (context budget)

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable domain; Claude Code skills system is mature)
