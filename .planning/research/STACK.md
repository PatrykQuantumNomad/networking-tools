# Stack Research: skills.sh Publishing

**Domain:** Publishing standalone Claude Code skills to skills.sh from an existing pentesting toolkit
**Researched:** 2026-03-06
**Confidence:** HIGH

## Executive Summary

Publishing to skills.sh requires **zero new dependencies**. The platform uses git-based discovery -- skills live in a public GitHub repo, users install them via `npx skills add owner/repo`, and skills.sh indexes repos automatically through anonymous CLI telemetry. There is no submission process, no API, no registry. The existing 32 SKILL.md files already follow the Agent Skills open standard (agentskills.io) and need only format adjustments to work as standalone installable skills.

The critical insight: skills.sh discovers skills in `.claude/skills/` directories automatically. The networking-tools repo already has this structure. The work is not about adding technology -- it is about refining existing SKILL.md content so skills function independently of the repo's wrapper scripts, and structuring the repo so `npx skills add PatrykQuantumNomad/networking-tools` discovers all 32 skills correctly.

## Recommended Stack

### Core Technologies (No Changes Needed)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| SKILL.md (YAML + Markdown) | Agent Skills spec v1 | Skill definition format | The open standard adopted by Anthropic, Microsoft, OpenAI, Cursor, and 15+ agent platforms. Already in use in this repo. |
| Git / GitHub | Current | Distribution mechanism | skills.sh uses GitHub as the source of truth. Repos are fetched directly. No package registry needed. |
| Bash + jq | System-installed | Hook scripts | Already in use for netsec-pretool.sh, netsec-posttool.sh, netsec-health.sh. No changes needed. |
| `npx skills` (Vercel CLI) | Latest on npm | Installation CLI | The CLI that powers skills.sh. Users run `npx skills add` to install. Publishers do NOT need to install it themselves. |

### Supporting Tools (Optional, for Testing)

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `npx skills` CLI | npm `skills` package | Test installation locally | Run `npx skills add ./` to test self-install during development |
| `skills-ref` validator | github.com/agentskills/agentskills | Validate SKILL.md frontmatter | Run `skills-ref validate ./my-skill` to catch naming/format errors before publishing |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `npx skills init` | Scaffold new SKILL.md files | Creates properly formatted frontmatter template. Useful if adding new skills. |
| `npx skills list` | Verify installed skills | Test that installation puts skills in correct locations |

## How skills.sh Publishing Works

### The Publishing Pipeline (There Is None)

skills.sh has NO explicit publish step. The flow is:

1. Put SKILL.md files in a **public GitHub repo** following the standard directory structure
2. Share the install command: `npx skills add PatrykQuantumNomad/networking-tools`
3. When users run that command, anonymous telemetry registers installs on skills.sh
4. The skill appears on the skills.sh leaderboard, ranked by install count
5. There is no approval process, no review queue, no API key

### How the CLI Discovers Skills

The `npx skills add` CLI searches these locations in order:

1. Root directory (if it contains `SKILL.md`)
2. `skills/` directory and subdirectories
3. `skills/.curated/`, `skills/.experimental/`, `skills/.system/`
4. `.agents/skills/` directory
5. **`.claude/skills/` directory** (this is where networking-tools stores its skills)
6. `.cursor/skills/`, `.codex/skills/`, and other agent-specific paths
7. Recursive fallback search if nothing found in standard paths
8. `.claude-plugin/marketplace.json` or `.claude-plugin/plugin.json` manifest files

Since networking-tools already uses `.claude/skills/<name>/SKILL.md`, the CLI will discover all 32 skills automatically.

### Installing Specific Skills

Users can install individual skills:
```bash
npx skills add PatrykQuantumNomad/networking-tools --skill nmap
npx skills add PatrykQuantumNomad/networking-tools --skill recon --skill scan
```

Or install all skills at once:
```bash
npx skills add PatrykQuantumNomad/networking-tools
```

Target specific agents:
```bash
npx skills add PatrykQuantumNomad/networking-tools -a claude-code
npx skills add PatrykQuantumNomad/networking-tools -a cursor
```

### Where Skills Get Installed

The CLI installs to `.agents/skills/` and creates symlinks to each detected agent's directory (`.claude/skills/`, `.cursor/skills/`, `.codex/skills/`, etc.). Users can choose symlinks (recommended) or independent copies.

## SKILL.md Format Specification

### Required Frontmatter Fields (Agent Skills Standard)

| Field | Required | Constraints | Example |
|-------|----------|-------------|---------|
| `name` | **Yes** | 1-64 chars, lowercase alphanumeric + hyphens, no leading/trailing/consecutive hyphens, must match parent directory name | `nmap` |
| `description` | **Yes** | 1-1024 chars, describe what it does AND when to use it | `Network scanning and host discovery. Use when you need port scans, service detection, or host enumeration.` |

### Optional Frontmatter Fields (Agent Skills Standard)

| Field | Purpose | Example |
|-------|---------|---------|
| `license` | License identifier or reference | `MIT` |
| `compatibility` | Environment requirements (max 500 chars) | `Requires nmap and bash. Designed for Claude Code.` |
| `metadata` | Arbitrary key-value pairs (string-to-string map) | `author: PatrykQuantumNomad`, `version: "2.0"` |
| `allowed-tools` | Space-delimited pre-approved tools (experimental) | `Bash Read Grep` |

### Claude Code Extension Fields (Beyond Standard)

These fields work in Claude Code but may be ignored by other agents:

| Field | Purpose | Current Usage in Repo |
|-------|---------|----------------------|
| `disable-model-invocation` | Prevent Claude from auto-invoking (manual `/name` only) | Used by all 17 tool skills and most workflow skills |
| `user-invocable` | Set `false` to hide from `/` menu (background knowledge only) | Used by `pentest-conventions` |
| `argument-hint` | Autocomplete hint for expected arguments | Used by workflow skills (`<target>`, `<hashfile-or-hash>`) |
| `context` | Set to `fork` to run in subagent | Not currently used |
| `agent` | Which subagent to use with `context: fork` | Not currently used |
| `model` | Override model for this skill | Not currently used |
| `hooks` | Skill-scoped lifecycle hooks | Not currently used |

### String Substitution Variables

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking the skill |
| `$ARGUMENTS[N]` / `$N` | Access specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md |

### Body Content Guidelines (from Agent Skills Spec)

- Keep SKILL.md under 500 lines / 5000 tokens
- Move detailed reference material to separate files (REFERENCE.md, examples/, scripts/)
- Reference supporting files from SKILL.md so Claude knows they exist
- Include step-by-step instructions, examples, edge cases
- Recommended sections: instructions, examples of inputs/outputs, common edge cases

### Skill Directory Structure

```
skill-name/
  SKILL.md           # Required -- main instructions
  REFERENCE.md       # Optional -- detailed docs loaded on demand
  examples/          # Optional -- example outputs
  scripts/           # Optional -- executable scripts
  assets/            # Optional -- templates, images, data files
```

### Example: Complete Standalone Skill

```yaml
---
name: nmap
description: Network scanning and host discovery using nmap. Use when you need port scans, service detection, host enumeration, or web vulnerability detection with NSE scripts.
license: MIT
compatibility: Requires nmap and bash. Designed for Claude Code.
metadata:
  author: PatrykQuantumNomad
  version: "2.0"
allowed-tools: Bash
disable-model-invocation: true
---

# Nmap Network Scanner

[Standalone instructions for running nmap scans...]
```

## Hooks Distribution

### Current State

Hooks in `.claude/hooks/` are configured via `.claude/settings.json`:
- `netsec-pretool.sh` -- PreToolUse: validates targets against scope, blocks raw tool invocations
- `netsec-posttool.sh` -- PostToolUse: parses JSON output, provides structured summaries
- `netsec-health.sh` -- Health check: verifies safety architecture

### How Hooks Are Distributed

Hooks are **NOT part of the Agent Skills standard**. The agentskills.io spec defines only SKILL.md files with optional scripts/, references/, and assets/ directories. Hooks are a Claude Code-specific feature configured in `.claude/settings.json`.

**Distribution options:**

| Method | How It Works | Pros | Cons |
|--------|-------------|------|------|
| Git clone / fork | Users clone the repo, get hooks via `.claude/settings.json` automatically | Complete experience, zero extra setup | Requires full repo clone, not selective |
| Skills with bundled scripts | A skill includes hook scripts in its `scripts/` directory and documents manual configuration | Portable via skills.sh | User must manually edit settings.json |
| Plugin distribution | `.claude-plugin/` format bundles hooks with skills | Automatic hook installation | Requires plugin format packaging |
| Documentation skill | A `setup` skill that tells users how to install hooks | Simple, transparent | Manual user effort |

**Recommendation:** Distribute hooks through the git repo (clone/fork), not through skills.sh. Skills.sh is for SKILL.md files. Hooks require `.claude/settings.json` configuration that `npx skills add` does not handle. Create a `netsec-setup` skill that documents hook installation for users who install skills standalone.

## Agents Distribution

### Current State

Agents in `.claude/agents/`:
- `pentester.md` -- Offensive specialist with preloaded skills
- `defender.md` -- Defensive analysis subagent
- `analyst.md` -- Report synthesis subagent

### How Agents Are Distributed

Agents (subagent definitions in `.claude/agents/`) are also **NOT part of the Agent Skills standard**. They are a Claude Code-specific feature.

**Distribution options:**

| Method | How It Works | Pros | Cons |
|--------|-------------|------|------|
| Git clone / fork | Users clone the repo, get agents automatically | Complete experience | Requires full repo clone |
| Skill-as-agent | Convert agent personas into skills with `context: fork` | Installable via skills.sh | Loses agent-specific fields (memory, maxTurns) |
| Skills referencing agents | A skill with `context: fork` and `agent: pentester` | Clean separation | Agent file must already exist on user's system |

**Recommendation:** Convert the 3 agent personas into skills that use `context: fork`. This makes them installable via `npx skills add` without requiring users to manually set up `.claude/agents/` files. The existing `pentester`, `defender`, and `analyst` skills already exist in `.claude/skills/` and invoke the agents -- they just need to be made self-contained.

## What Needs to Change in Existing Skills

### Problem: Wrapper Script Dependencies

All 32 existing skills reference wrapper scripts like `bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x`. When installed to another project via `npx skills add`, those scripts do not exist.

### Solution: Dual-Mode Skills

Each skill should detect whether wrapper scripts exist and adapt:
- When installed standalone: provide direct tool instructions (e.g., `nmap -sV target`)
- When in the networking-tools repo: use wrapper scripts with `-j -x` flags

| Approach | Pros | Cons | Recommended |
|----------|------|------|-------------|
| **Standalone instructions only** | Works anywhere, no dependencies | Loses wrapper script benefits (JSON output, safety hooks) | No |
| **Reference source repo only** | Preserves all functionality | Requires cloning networking-tools, not truly standalone | No |
| **Bundle scripts in skill dirs** | Self-contained, portable | Duplicates code, maintenance burden, large skill dirs | No |
| **Dual-mode (detect and adapt)** | Works both standalone and with repo | More complex SKILL.md content | **Yes** |

Example dual-mode pattern in SKILL.md:
```markdown
## Running Scans

### With networking-tools wrapper scripts (recommended)
If you have the full networking-tools repo, use wrapper scripts for JSON output and safety hooks:
- `bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x`

### Standalone (no wrapper scripts)
- `nmap -sV -sC $ARGUMENTS` -- Service version detection with default scripts
- `nmap -p- --min-rate 1000 $ARGUMENTS` -- Full port scan
```

## Installation

### For Publishers (This Repo)

No installation needed. The repo structure already works. After SKILL.md refinements:

```bash
# Test that skills are discoverable
cd /tmp && mkdir test-project && cd test-project
npx skills add PatrykQuantumNomad/networking-tools --skill nmap
ls -la .agents/skills/nmap/ .claude/skills/nmap/ 2>/dev/null
```

### For Users (Installing Skills)

```bash
# Install all skills
npx skills add PatrykQuantumNomad/networking-tools

# Install specific skills
npx skills add PatrykQuantumNomad/networking-tools --skill nmap --skill recon

# Install for specific agent only
npx skills add PatrykQuantumNomad/networking-tools -a claude-code
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|------------------------|
| skills.sh via `npx skills add` | Claude Plugin Marketplace (`/plugin install`) | When you need to bundle hooks + settings.json + skills as a complete package. Plugin marketplace uses `.claude-plugin/` format and handles hook installation automatically. |
| skills.sh via `npx skills add` | Manual sharing (README + git clone) | When targeting users who prefer full repo clone with hooks, agents, and wrapper scripts intact. |
| skills.sh via `npx skills add` | LobeHub / PlayBooks.com | When targeting non-Claude agents primarily. These are alternative skill directories with different audiences. |
| Git-based hooks distribution | Plugin-bundled hooks | When hooks are critical and must be installed automatically alongside skills. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Custom npm package for publishing | Unnecessary. skills.sh already indexes GitHub repos directly via CLI telemetry. | `npx skills add owner/repo` |
| API-based submission to skills.sh | Does not exist. Indexing is automatic via install telemetry. | Push to GitHub, share install command |
| `add-skill` npm package | Alternative CLI by a different author. Less widely adopted than Vercel's `skills` package. | `npx skills` (Vercel's CLI, powers skills.sh) |
| `.claude-plugin/` format for skills-only publishing | Adds unnecessary complexity. Plugin format is for bundling hooks + settings + skills together. For skills-only distribution, plain `.claude/skills/` is simpler. | Plain `.claude/skills/` directory structure |
| Custom metadata fields outside `metadata:` | Non-standard top-level fields are ignored by the CLI and other agents. | Use the `metadata:` map for any custom key-values |
| `skillsmp.com` / other marketplaces | Fragment discovery across platforms. skills.sh has the most installs and broadest agent support. | skills.sh as primary distribution |

## Stack Patterns by Variant

**If publishing skills only (recommended first step):**
- Keep existing `.claude/skills/` structure
- Refine SKILL.md files for standalone use (dual-mode: wrapper + raw tool instructions)
- Add `license`, `compatibility`, and `metadata` fields to frontmatter
- Push to GitHub and share `npx skills add PatrykQuantumNomad/networking-tools`
- Zero new dependencies, zero build steps

**If publishing skills + hooks + agents as a complete toolkit (later):**
- Use `.claude-plugin/` format to bundle everything
- Create a `plugin.json` manifest pointing to skills, hooks, and agent definitions
- Users install via `/plugin install` in Claude Code
- More complex but provides the complete safety-guarded experience

**If targeting cross-agent compatibility (Cursor, Codex, Windsurf):**
- Stick to agentskills.io standard fields only (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`)
- Remove Claude Code-specific fields from frontmatter (or accept they'll be ignored)
- Avoid `$ARGUMENTS` substitution and `!`command`` syntax (Claude Code only)
- Write instructions as plain Markdown that any agent can follow

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| Agent Skills spec v1 | Claude Code, Cursor, Codex CLI, GitHub Copilot, Windsurf, VSCode, 15+ agents | Open standard maintained at agentskills.io |
| `npx skills` CLI | Node.js 18+ | Runs via npx, no global install needed |
| Claude Code extension fields | Claude Code only | `disable-model-invocation`, `user-invocable`, `context`, `agent`, `hooks` ignored by other agents |
| `$ARGUMENTS` substitution | Claude Code only | Other agents may not support this |
| `!`command`` (dynamic context) | Claude Code only | Shell preprocessing before skill execution |
| Hooks (`.claude/hooks/`) | Claude Code and Cline only | Per skills.sh compatibility table |

## Existing User Publications

The user has already published 4 skills from `PatrykQuantumNomad/claude-in-a-box`:
- `k8s-analyzer`
- `compose-validator`
- `dockerfile-analyzer`
- Plus one additional skill

These live in `.claude/skills/` in that repo and appear on `skills.sh/patrykquantumnomad`. The same pattern applies to networking-tools -- push refined SKILL.md files to GitHub, share the install command, skills appear on skills.sh automatically.

## Sources

### HIGH Confidence (Official documentation, verified via WebFetch)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Complete skills reference, all frontmatter fields, invocation control, dynamic context injection, supporting files, cross-agent compatibility
- [Agent Skills Specification](https://agentskills.io/specification) -- Open standard defining SKILL.md format, required/optional fields, directory structure, naming constraints, validation
- [skills.sh Docs](https://skills.sh/docs) -- Platform overview, installation mechanics
- [skills.sh FAQ](https://skills.sh/docs/faq) -- How telemetry-based indexing works, no explicit publish step
- [Vercel Labs skills CLI](https://github.com/vercel-labs/skills) -- CLI source, discovery paths, installation behavior, multi-skill repo support, `--skill` flag, `-a` agent targeting
- [Anthropic skills repository](https://github.com/anthropics/skills) -- Reference implementation, plugin marketplace integration
- [Vercel Agent Skills Guide](https://vercel.com/kb/guide/agent-skills-creating-installing-and-sharing-reusable-agent-context) -- Publishing workflow, format, distribution

### MEDIUM Confidence (Verified via multiple consistent sources)
- [skills.sh/patrykquantumnomad](https://skills.sh/patrykquantumnomad) -- User's existing published skills from claude-in-a-box repo
- [PatrykQuantumNomad/claude-in-a-box](https://github.com/PatrykQuantumNomad/claude-in-a-box) -- Reference for how skills are already structured in user's other repo

---
*Stack research for: skills.sh publishing of pentesting skills*
*Researched: 2026-03-06*
