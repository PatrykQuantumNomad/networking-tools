# Architecture Research

**Domain:** Standalone skill publication to skills.sh from an existing in-repo pentesting skill pack
**Researched:** 2026-03-06
**Confidence:** HIGH

## Problem Statement

32 skills, 3 hooks, and 3 agents currently live in `.claude/` tightly coupled to `scripts/` wrapper scripts. The coupling is fundamental: every tool skill references paths like `bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x`, every workflow skill chains multiple such paths, and hooks enforce that raw tool invocation is redirected to these wrappers. Publishing to skills.sh requires these skills to work **without** the wrapper scripts when installed standalone via `npx skills add`.

The core tension: in-repo, the wrappers provide safety (scope validation, JSON envelopes, audit logging), educational value (10 examples per tool), and structured output. Standalone, none of that infrastructure exists. The skills must gracefully degrade to direct tool invocation while still being useful.

## System Overview

### Current Architecture (Tightly Coupled)

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Claude Code Interface                           │
│  /recon <target>         /scan <target>         /pentester <task>  │
├─────────────────────────────────────────────────────────────────────┤
│                     Skill Layer (.claude/skills/)                    │
│  32 skills: 18 tool skills, 6 workflow skills, 3 agent invokers,   │
│  3 utility skills, 2 convention/reference skills                   │
├──────────────────────────────┬──────────────────────────────────────┤
│  Agent Layer                 │  Hook Layer                          │
│  (.claude/agents/)           │  (.claude/hooks/)                    │
│  pentester.md                │  netsec-pretool.sh (SAFE-01/02)     │
│  defender.md                 │  netsec-posttool.sh (SAFE-03/04)    │
│  analyst.md                  │  netsec-health.sh (diagnostics)     │
├──────────────────────────────┴──────────────────────────────────────┤
│                     Wrapper Script Layer                            │
│  scripts/common.sh -> scripts/lib/*.sh (10 modules)               │
│  scripts/<tool>/examples.sh (18 tools)                            │
│  scripts/<tool>/<use-case>.sh (28 use-case scripts)               │
│  scripts/diagnostics/*.sh (3 auto-report scripts)                  │
│  .pentest/scope.json (target allowlist)                            │
└─────────────────────────────────────────────────────────────────────┘
```

### Target Architecture (Dual-Mode Skills)

```
┌─────────────────────────────────────────────────────────────────────┐
│          skills.sh Publication (standalone install)                  │
│  npx skills add patrykquantumnomad/networking-tools                 │
│  -> Installs to ~/.claude/skills/ (all projects)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Published Skill (e.g. nmap/SKILL.md)                        │  │
│  │                                                               │  │
│  │  if [wrappers detected]:                                      │  │
│  │    "bash scripts/nmap/discover-live-hosts.sh $TGT -j -x"    │  │
│  │  else [standalone]:                                           │  │
│  │    "nmap -sn $TGT"    (direct tool invocation)               │  │
│  │    "nmap -sV $TGT"    (with educational context)             │  │
│  │                                                               │  │
│  └──────────────┬──────────────────────┬────────────────────────┘  │
│                 │                      │                            │
│   [in-repo]     │       [standalone]   │                            │
│   uses wrappers,│       uses direct    │                            │
│   hooks active, │       tool commands, │                            │
│   scope enforced│       no hooks,      │                            │
│                 │       no scope       │                            │
│                 │                      │                            │
├─────────────────┴──────────────────────┴────────────────────────────┤
│  hooks/hooks.json (published with plugin)                           │
│  agents/*.md (published with plugin)                                │
│  ${CLAUDE_PLUGIN_ROOT} for portable paths                          │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | In-Repo Behavior | Standalone Behavior |
|-----------|----------------|-------------------|---------------------|
| Tool skills (18) | Teach Claude how to use individual pentesting tools | Reference wrapper scripts with `-j -x` flags | Provide direct CLI commands with educational context |
| Workflow skills (6) | Orchestrate multi-tool assessments | Chain wrapper script calls | Chain direct tool commands |
| Agent skills (3) | Invoke subagent personas | Fork to pentester/defender/analyst agents | Fork to agents (if agents are bundled) |
| Utility skills (3) | Scope, health check, check-tools | Reference project-specific files | Adapt or disable gracefully |
| Reference skills (2) | Conventions and report templates | Full context | Full context (portable as-is) |
| Hooks (3) | Safety enforcement and output parsing | Active via settings.json | Active via hooks/hooks.json in plugin |
| Agents (3) | Specialized system prompts with skill preloading | Reference skills by name | Reference skills by name (plugin-namespaced) |

## Recommended Distribution Architecture

### Decision: Claude Code Plugin (not raw skills.sh skills)

**Use the plugin format** because this skill pack has hooks and agents alongside skills. Raw skills.sh only distributes skill directories. The plugin format bundles all three component types and provides `${CLAUDE_PLUGIN_ROOT}` for portable path references.

| Distribution Method | Skills | Hooks | Agents | Scripts | Path Resolution | Verdict |
|---------------------|--------|-------|--------|---------|-----------------|---------|
| `npx skills add` (skills.sh) | Yes | No | No | Via skill dir | `${CLAUDE_SKILL_DIR}` | Insufficient -- no hooks or agents |
| Claude Code plugin | Yes | Yes | Yes | Via plugin dir | `${CLAUDE_PLUGIN_ROOT}` | **USE THIS** -- bundles everything |
| Plugin + skills.sh listing | Yes | Yes | Yes | Via plugin dir | Both variables | Best of both worlds |

**Strategy:** Publish as a Claude Code plugin, list on skills.sh for discoverability. Install via `claude plugin install netsec-skills@marketplace` or `npx skills add patrykquantumnomad/networking-tools --skill <name>` for individual skills.

### Plugin Directory Structure

```
netsec-skills/                              # Plugin root (new directory in repo)
├── .claude-plugin/
│   └── plugin.json                         # Plugin manifest
├── skills/
│   ├── nmap/
│   │   ├── SKILL.md                        # Dual-mode: wrappers or direct
│   │   └── reference.md                    # Nmap cheat sheet (portable)
│   ├── tshark/
│   │   └── SKILL.md
│   ├── sqlmap/
│   │   └── SKILL.md
│   ├── nikto/
│   │   └── SKILL.md
│   ├── hashcat/
│   │   └── SKILL.md
│   ├── john/
│   │   └── SKILL.md
│   ├── hping3/
│   │   └── SKILL.md
│   ├── skipfish/
│   │   └── SKILL.md
│   ├── aircrack-ng/
│   │   └── SKILL.md
│   ├── metasploit/
│   │   └── SKILL.md
│   ├── curl/
│   │   └── SKILL.md
│   ├── dig/
│   │   └── SKILL.md
│   ├── netcat/
│   │   └── SKILL.md
│   ├── traceroute/
│   │   └── SKILL.md
│   ├── gobuster/
│   │   └── SKILL.md
│   ├── ffuf/
│   │   └── SKILL.md
│   ├── foremost/
│   │   └── SKILL.md
│   ├── check-tools/
│   │   └── SKILL.md
│   ├── recon/                              # Workflow: multi-tool recon
│   │   └── SKILL.md
│   ├── scan/                               # Workflow: vulnerability scanning
│   │   └── SKILL.md
│   ├── fuzz/                               # Workflow: web fuzzing
│   │   └── SKILL.md
│   ├── crack/                              # Workflow: password cracking
│   │   └── SKILL.md
│   ├── sniff/                              # Workflow: traffic analysis
│   │   └── SKILL.md
│   ├── diagnose/                           # Workflow: network diagnostics
│   │   └── SKILL.md
│   ├── scope/                              # Utility: scope management
│   │   └── SKILL.md
│   ├── netsec-health/                      # Utility: health check
│   │   └── SKILL.md
│   ├── lab/                                # Utility: Docker lab
│   │   └── SKILL.md
│   ├── report/                             # Template: report generation
│   │   └── SKILL.md
│   ├── pentest-conventions/                # Reference: conventions
│   │   └── SKILL.md
│   ├── pentester/                          # Agent invoker
│   │   └── SKILL.md
│   ├── defender/                           # Agent invoker
│   │   └── SKILL.md
│   └── analyst/                            # Agent invoker
│       └── SKILL.md
├── agents/
│   ├── pentester.md                        # Offensive specialist
│   ├── defender.md                         # Defensive analyst
│   └── analyst.md                          # Report synthesizer
├── hooks/
│   └── hooks.json                          # Hook configuration
├── scripts/
│   ├── netsec-pretool.sh                   # PreToolUse: scope + raw tool guard
│   ├── netsec-posttool.sh                  # PostToolUse: JSON bridge
│   └── netsec-health.sh                    # Health check script
└── README.md                               # Usage documentation
```

### plugin.json Manifest

```json
{
  "name": "netsec-skills",
  "version": "1.0.0",
  "description": "Pentesting skills for Claude Code: 18 security tools, 6 workflows, 3 specialist agents",
  "author": {
    "name": "patrykquantumnomad",
    "url": "https://github.com/patrykquantumnomad"
  },
  "repository": "https://github.com/patrykquantumnomad/networking-tools",
  "license": "MIT",
  "keywords": ["pentesting", "security", "nmap", "netsec", "hacking"]
}
```

Component paths follow defaults (`skills/`, `agents/`, `hooks/hooks.json`), so no custom path fields needed.

### hooks.json Format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/netsec-pretool.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/netsec-posttool.sh"
          }
        ]
      }
    ]
  }
}
```

**Key detail:** `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin's installation directory regardless of where it was installed. This replaces the current `$CLAUDE_PROJECT_DIR` references.

## Architectural Patterns

### Pattern 1: Dual-Mode Wrapper Detection (Primary Pattern)

**What:** Each skill detects whether wrapper scripts are available and switches between wrapper mode (structured, safe) and direct mode (raw tool commands with educational context). Detection happens via `!`command`` preprocessing in the skill frontmatter.

**When to use:** Every tool skill (18 skills) and every workflow skill (6 skills).

**Trade-offs:**
- (+) Single skill file works in both contexts
- (+) In-repo users get the full wrapper experience
- (+) Standalone users still get useful, educational tool guidance
- (-) Skills are longer (dual instruction paths)
- (-) Standalone mode loses JSON envelopes, scope validation, audit logging

**Implementation approach:**

```yaml
---
name: nmap
description: Network scanning and host discovery using nmap
disable-model-invocation: true
---

# Nmap Network Scanner

## Environment Detection

Wrapper scripts available: !`test -f scripts/nmap/discover-live-hosts.sh && echo "YES" || echo "NO"`

## Instructions

### If wrapper scripts are available (YES above)

Run nmap wrapper scripts that provide educational examples and structured JSON output.

- `bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x`
- `bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x`
- `bash scripts/nmap/scan-web-vulnerabilities.sh $ARGUMENTS -j -x`

Add `-j` to every invocation for structured JSON output via the PostToolUse hook.

### If wrapper scripts are NOT available (NO above)

Use nmap directly. Target: $ARGUMENTS

**Host Discovery:**
```
nmap -sn $ARGUMENTS
```
Ping sweep to find live hosts without port scanning.

**Port Scanning with Service Detection:**
```
nmap -sV $ARGUMENTS
```
Identify open ports and probe service versions.

**Web Vulnerability Scanning:**
```
nmap --script=vuln $ARGUMENTS
```
Run NSE vulnerability scripts against the target.

Always confirm the target is authorized before scanning.
```

**Why this approach vs alternatives:**

| Alternative | Problem |
|-------------|---------|
| Require wrappers always | Breaks standalone install entirely |
| Direct tool commands only | Loses the rich wrapper experience for in-repo users |
| Separate skill files per mode | Doubles maintenance, namespace collision |
| Runtime script generation | Over-engineered, fragile |

### Pattern 2: Portable Hook Scripts

**What:** Hook scripts use `${CLAUDE_PLUGIN_ROOT}` for self-references and gracefully degrade when wrapper infrastructure is missing. The PreToolUse hook's raw-tool interception becomes optional (only active when wrappers exist to redirect to). The PostToolUse JSON bridge only fires when JSON envelopes are detected.

**When to use:** All 3 hook scripts.

**Key changes from current hooks:**

The current `netsec-pretool.sh` has two functions:
1. **SAFE-01**: Target allowlist validation (requires `.pentest/scope.json`)
2. **SAFE-02**: Raw tool interception (blocks `nmap` directly, redirects to `scripts/nmap/`)

For standalone mode:
- SAFE-01 works anywhere -- scope.json can exist in any project
- SAFE-02 only makes sense when wrappers exist -- skip if `scripts/` directory not found

```bash
# Portable pretool hook: skip raw-tool interception if wrappers don't exist
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if [[ ! -d "$PROJECT_DIR/scripts" ]]; then
  # No wrapper scripts available -- skip SAFE-02 raw tool interception
  # Still enforce SAFE-01 scope validation if scope.json exists
  ...
fi
```

**Trade-offs:**
- (+) Hooks work in both contexts
- (+) Scope validation is still useful standalone (prevents scanning unauthorized targets)
- (-) Standalone users lose the raw-tool interception safety net
- (-) Health check script needs updating to not fail on missing wrappers

### Pattern 3: Agent Skill References in Plugin Context

**What:** Agents reference skills by name in their `skills:` frontmatter. In a plugin context, skills are auto-namespaced as `plugin-name:skill-name`. Agent skill references must match.

**When to use:** All 3 agents that preload skills.

**Current agent frontmatter (pentester.md):**
```yaml
skills:
  - pentest-conventions
  - recon
  - scan
  - fuzz
  - crack
  - sniff
```

**Plugin-distributed agent frontmatter:**
```yaml
skills:
  - netsec-skills:pentest-conventions
  - netsec-skills:recon
  - netsec-skills:scan
  - netsec-skills:fuzz
  - netsec-skills:crack
  - netsec-skills:sniff
```

**Critical question:** Do plugin-internal skill references need the namespace prefix? Based on the plugin documentation, plugin skills use the `plugin-name:skill-name` namespace. Agent and skill references within the same plugin likely need the qualified name because Claude Code resolves skills globally.

**Risk mitigation:** Test with a minimal plugin first (1 agent + 1 skill) to verify internal reference resolution before converting all 3 agents.

### Pattern 4: Scope Management Portability

**What:** The `/scope` skill manages `.pentest/scope.json`. This is inherently project-specific (different targets per project), so it works the same standalone or in-repo. The path `.pentest/scope.json` is relative to the current working directory.

**When to use:** The `scope` skill and any skill that references scope validation.

**No changes needed.** The scope file location (`.pentest/scope.json` in the project directory) is already portable. The skill creates it if missing, and the PreToolUse hook checks `$CLAUDE_PROJECT_DIR/.pentest/scope.json`.

### Pattern 5: Dynamic Skill Content via `!`command``

**What:** Use `!`command`` injection to probe the environment at skill load time, then branch instructions accordingly. This avoids runtime detection failures.

**When to use:** Tool skills, workflow skills, lab skill, check-tools skill.

**Example for environment-adaptive behavior:**

```yaml
---
name: lab
description: Manage Docker-based vulnerable practice lab targets
---

# Lab Environment

Docker status: !`docker info --format '{{.ServerVersion}}' 2>/dev/null || echo "NOT_INSTALLED"`
Lab compose file: !`test -f labs/docker-compose.yml && echo "FOUND" || echo "NOT_FOUND"`

## If lab compose file is FOUND

Use make targets to manage the lab:
- `make lab-up` -- Start all containers
- `make lab-down` -- Stop all containers

## If lab compose file is NOT_FOUND

The Docker lab targets are part of the networking-tools repository.
To set up a practice lab, clone the repo: ...
```

## Data Flow

### Skill Invocation Flow (Dual-Mode)

```
User: /nmap 192.168.1.1
    |
    v
Claude Code loads skills/nmap/SKILL.md
    |
    v
!`test -f scripts/nmap/...` preprocessing runs
    |
    +-- "YES" (in-repo) ──────────────────────+
    |                                          |
    v                                          v
Claude reads wrapper instructions        Claude reads direct instructions
    |                                          |
    v                                          v
Bash: scripts/nmap/identify-ports.sh     Bash: nmap -sV 192.168.1.1
      192.168.1.1 -j -x                       |
    |                                          v
    v                                     Raw nmap output
JSON envelope on stdout                  (no structured parsing)
    |                                          |
    v                                          v
PostToolUse hook fires                   PostToolUse hook fires
  -> detects JSON envelope                 -> no envelope detected
  -> returns additionalContext             -> exit 0 (no-op)
    |                                          |
    v                                          v
Claude: structured summary +             Claude: interprets raw output
        hook context                      directly (still useful)
```

### Plugin Installation Flow

```
npx skills add patrykquantumnomad/networking-tools
    |
    v
skills.sh CLI clones/downloads repo
    |
    v
Detects netsec-skills/.claude-plugin/plugin.json
    |
    v
Copies plugin to ~/.claude/plugins/cache/netsec-skills/
    |
    v
skills/  -> discoverable as netsec-skills:<skill-name>
agents/  -> discoverable as netsec-skills:<agent-name>
hooks/   -> hooks.json registered automatically
scripts/ -> available via ${CLAUDE_PLUGIN_ROOT}/scripts/
    |
    v
User runs Claude Code in any project
    |
    v
Plugin hooks fire on Bash tool calls
Skills available via /netsec-skills:nmap etc.
Agents available for delegation
```

### Hook Portability Flow

```
PreToolUse hook fires (any Bash command)
    |
    v
Read stdin JSON: {tool_name, tool_input.command}
    |
    +-- Not Bash? -> exit 0
    |
    v
Does command contain a security tool binary?
    |
    +-- No -> exit 0
    |
    v
Is scripts/ directory available?
    |
    +-- YES: SAFE-02 active (redirect to wrappers)
    |   |
    |   v
    |   Does command use scripts/ path?
    |   +-- YES: validate target against scope.json -> allow/deny
    |   +-- NO: deny, suggest wrapper script
    |
    +-- NO: SAFE-02 disabled (standalone mode)
        |
        v
        Does scope.json exist?
        +-- YES: validate target -> allow/deny
        +-- NO: allow (no scope enforcement in standalone)
```

## Recommended Project Structure Changes

### New Components

```
netsec-skills/                              # NEW directory at repo root
├── .claude-plugin/
│   └── plugin.json                         # NEW — plugin manifest
├── skills/                                 # MOVED from .claude/skills/
│   └── (32 skill directories)              # MODIFIED — add dual-mode detection
├── agents/                                 # MOVED from .claude/agents/ (3 files)
│   ├── pentester.md                        # MODIFIED — namespaced skill refs
│   ├── defender.md                         # MODIFIED — namespaced skill refs
│   └── analyst.md                          # MODIFIED — namespaced skill refs
├── hooks/
│   └── hooks.json                          # NEW — hook configuration
├── scripts/
│   ├── netsec-pretool.sh                   # MODIFIED — portable paths, graceful degradation
│   ├── netsec-posttool.sh                  # MODIFIED — portable paths
│   └── netsec-health.sh                    # MODIFIED — portable, optional wrapper checks
└── README.md                               # NEW — usage and install docs
```

### Modified In-Repo Structure

```
.claude/
├── settings.json                           # MOD — add plugin enablement
├── skills/                                 # KEEP — symlink or duplicate for in-repo use?
├── agents/                                 # KEEP — symlink or duplicate for in-repo use?
└── hooks/                                  # KEEP — existing hooks still work for in-repo
```

### Decision: Symlink vs Copy vs Single Source

| Strategy | In-Repo | Standalone | Maintenance | Verdict |
|----------|---------|------------|-------------|---------|
| Plugin is single source, in-repo uses `--plugin-dir` | Plugin loads from local path | Plugin loads from cache | One copy | **BEST** |
| Symlinks from `.claude/` to `netsec-skills/` | Works | Breaks (symlinks not followed in cache) | One copy | REJECT |
| Copy files to both locations | Works | Works | Two copies to maintain | REJECT |
| Keep `.claude/` as source, publish from there | Settings.json conflicts | No manifest location | Awkward | REJECT |

**Recommendation:** Make `netsec-skills/` the single source of truth. For in-repo development, use `claude --plugin-dir ./netsec-skills`. For distribution, publish the `netsec-skills/` directory. The existing `.claude/skills/`, `.claude/agents/`, and `.claude/hooks/netsec-*.sh` files become the plugin directory.

**Migration path:** Move files from `.claude/` to `netsec-skills/`, update `.claude/settings.json` to reference the plugin, test in-repo, then publish.

## Integration Points

### Skills.sh Integration

| Aspect | Approach | Notes |
|--------|----------|-------|
| Publication | `npx skills add patrykquantumnomad/networking-tools` | Points to the repo; skills.sh discovers the plugin |
| Discovery | Listed on skills.sh/patrykquantumnomad | Automatic once installed by any user |
| Individual skill install | `npx skills add patrykquantumnomad/networking-tools --skill nmap` | Cherry-pick specific skills |
| Updates | Bump version in plugin.json | Users update via `claude plugin update` |

### In-Repo Integration

| Aspect | Approach | Notes |
|--------|----------|-------|
| Development | `claude --plugin-dir ./netsec-skills` | Loads plugin from local directory |
| CI/CD | Same flag in automation scripts | Plugin loaded per-session |
| Team sharing | Commit `netsec-skills/` to repo | Team uses `--plugin-dir` or installs from GitHub |
| Settings.json | Keep existing hooks for backward compat during migration | Remove after full plugin migration |

### Internal Boundaries (Plugin Context)

| Boundary | Communication | Portability Notes |
|----------|---------------|-------------------|
| Skill -> Wrapper scripts | `bash scripts/.../*.sh` (relative path) | Only works in-repo; skill detects and falls back |
| Skill -> Direct tool | `nmap ...`, `nikto ...` | Works everywhere tool is installed |
| Hook -> Scope file | `$CLAUDE_PROJECT_DIR/.pentest/scope.json` | Project-specific; works in any project with scope file |
| Hook -> Hook scripts | `${CLAUDE_PLUGIN_ROOT}/scripts/netsec-*.sh` | Portable via plugin root variable |
| Agent -> Skills | `skills: [netsec-skills:recon, ...]` | Plugin-namespaced; auto-resolved |
| Agent -> Hook scripts | Via hooks.json at plugin level | Scoped to plugin lifecycle |

## Skill Categories for Publication

### Category 1: Tool Skills (18) -- Dual-Mode Required

Each tool skill needs wrapper detection and fallback direct commands.

| Skill | Wrapper Scripts | Direct Tool | Complexity |
|-------|----------------|-------------|------------|
| nmap | 3 use-case + examples.sh | `nmap` commands | Medium |
| tshark | 3 use-case + examples.sh | `tshark` commands | Medium |
| sqlmap | 3 use-case + examples.sh | `sqlmap` commands | Medium |
| nikto | 3 use-case + examples.sh | `nikto` commands | Medium |
| hashcat | 3 use-case + examples.sh | `hashcat` commands | Medium |
| john | 3 use-case + examples.sh | `john` commands | Medium |
| metasploit | 3 use-case + examples.sh | `msfconsole` commands | Medium |
| hping3 | 2 use-case + examples.sh | `hping3` commands | Low |
| skipfish | 2 use-case + examples.sh | `skipfish` commands | Low |
| aircrack-ng | 3 use-case + examples.sh | `aircrack-ng` commands | Medium |
| curl | 2 use-case + examples.sh | `curl` commands | Low |
| dig | 3 use-case + examples.sh | `dig` commands | Low |
| netcat | examples.sh | `nc` commands | Low |
| traceroute | 1 use-case + examples.sh | `traceroute`/`mtr` | Low |
| gobuster | 1 use-case + examples.sh | `gobuster` commands | Low |
| ffuf | 1 use-case + examples.sh | `ffuf` commands | Low |
| foremost | examples.sh | `foremost` commands | Low |
| check-tools | check-tools.sh | `which`/`command -v` checks | Low |

### Category 2: Workflow Skills (6) -- Dual-Mode Required

Workflow skills chain multiple tool skills. Dual-mode means each step branches.

| Skill | Steps | In-Repo Commands | Standalone Commands |
|-------|-------|------------------|---------------------|
| recon | 6 | 6 wrapper script calls | 6 direct tool calls |
| scan | 5 | 5 wrapper script calls | 5 direct tool calls |
| fuzz | 3 | 3 wrapper script calls | 3 direct tool calls |
| crack | 5 | 5 wrapper script calls | 5 direct tool calls |
| sniff | 3 | 3 wrapper script calls | 3 direct tool calls |
| diagnose | 5 | 5 wrapper script calls | 5 direct tool calls |

### Category 3: Utility & Reference Skills (5) -- Varies

| Skill | Portability | Notes |
|-------|-------------|-------|
| scope | Fully portable | `.pentest/scope.json` is project-relative |
| netsec-health | Needs adaptation | Must not fail when wrappers missing |
| lab | In-repo only | Docker compose file is repo-specific; standalone shows setup instructions |
| pentest-conventions | Fully portable | Pure reference content, no path dependencies |
| report | Fully portable | Template content, no path dependencies |

### Category 4: Agent Invoker Skills (3) -- Require Agent Bundling

| Skill | Agent | Plugin Behavior |
|-------|-------|-----------------|
| pentester | pentester.md | `agent: netsec-skills:pentester` (if namespace required) |
| defender | defender.md | `agent: netsec-skills:defender` |
| analyst | analyst.md | `agent: netsec-skills:analyst` |

## Anti-Patterns

### Anti-Pattern 1: Embedding All Direct Commands in Every Skill

**What people do:** Add complete nmap/nikto/sqlmap documentation to each skill's standalone section, making skills 500+ lines.
**Why it's wrong:** Exceeds the 500-line SKILL.md recommendation. Bloats context when skills are loaded. Most users only need key commands, not a man page.
**Do this instead:** Keep standalone sections focused on 3-5 most useful commands per tool. Put extended reference in a separate `reference.md` file that Claude loads on demand.

### Anti-Pattern 2: Making Hooks Mandatory

**What people do:** Design hooks that crash or block all commands when wrapper scripts are missing.
**Why it's wrong:** Standalone users have no wrapper scripts. Hooks that fail hard break the entire experience.
**Do this instead:** Hooks should gracefully degrade. If no `scripts/` directory: skip raw-tool interception. If no `scope.json`: skip scope validation (or create a default).

### Anti-Pattern 3: Hardcoding Repository Paths

**What people do:** Use paths like `/Users/patryk/work/git/networking-tools/scripts/nmap/` in skills or hooks.
**Why it's wrong:** Breaks on any other machine or installation path.
**Do this instead:** Use `${CLAUDE_PLUGIN_ROOT}` for plugin-internal paths, `${CLAUDE_PROJECT_DIR}` for project-relative paths, and `!`command`` detection for wrapper availability.

### Anti-Pattern 4: Separate Repo for Published Skills

**What people do:** Create a new repo just for the publishable skills, copying content from the original.
**Why it's wrong:** Two repos to maintain. Skills drift from wrapper scripts. Changes to wrappers don't propagate to published skills.
**Do this instead:** Keep `netsec-skills/` directory in the same repo as the wrapper scripts. Publish from the same repo. One source of truth.

### Anti-Pattern 5: Removing In-Repo Functionality for Portability

**What people do:** Strip wrapper script references to make skills "cleaner" for standalone use.
**Why it's wrong:** Loses the primary value proposition for in-repo users. The wrapper scripts provide safety, JSON envelopes, and educational content that direct tool commands cannot match.
**Do this instead:** Dual-mode with `!`command`` detection. Both modes coexist in the same skill file.

## Build Order (Dependency-Aware)

| Phase | Component | Depends On | Rationale |
|-------|-----------|-----------|-----------|
| 1 | Plugin scaffold: `netsec-skills/.claude-plugin/plugin.json` | Nothing | Establish the container structure first |
| 2 | Port 2 reference skills: `pentest-conventions`, `report` | Plugin scaffold | Fully portable, no dual-mode needed. Validates plugin loads correctly. |
| 3 | Port 3 utility skills: `scope`, `lab`, `check-tools` | Plugin scaffold | Scope is fully portable. Lab/check-tools need minor adaptation. |
| 4 | Port `netsec-health` skill + health check script | Plugin scaffold + scripts/ | Health script needs `${CLAUDE_PLUGIN_ROOT}` paths |
| 5 | Port hooks: `netsec-pretool.sh`, `netsec-posttool.sh`, `hooks.json` | Plugin scaffold | Add `${CLAUDE_PLUGIN_ROOT}` paths, graceful degradation |
| 6 | Port 3 simplest tool skills (low-complexity): `dig`, `curl`, `netcat` | Hooks working | Test dual-mode pattern with simple tools first |
| 7 | Port remaining 15 tool skills | Pattern validated in phase 6 | Apply proven dual-mode pattern to all tools |
| 8 | Port 6 workflow skills: `recon`, `scan`, `fuzz`, `crack`, `sniff`, `diagnose` | Tool skills ported | Workflows reference tool commands; need dual-mode branching at each step |
| 9 | Port 3 agents + 3 agent invoker skills | All skills ported | Agents preload skills by name; need correct namespace references |
| 10 | Test standalone installation | Everything ported | Install via `claude --plugin-dir`, verify all skills/hooks/agents work |
| 11 | Publish to skills.sh | Standalone tested | Push repo, verify listing and install flow |

## Cross-Platform Considerations

### Path Resolution Variables

| Variable | Available In | Resolves To | Use For |
|----------|-------------|-------------|---------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks, scripts | Plugin installation directory | Hook script paths, bundled script references |
| `${CLAUDE_PROJECT_DIR}` | All hooks | Current project root | scope.json, audit logs, wrapper script detection |
| `${CLAUDE_SKILL_DIR}` | Skill content | Skill's own directory | Reference files bundled with the skill |

### Shell Compatibility

- Plugin hook scripts must use `#!/usr/bin/env bash` for portability
- macOS ships bash 3.2; hooks using associative arrays need bash 4.0+
- The `netsec-pretool.sh` uses `declare -A` (bash 4.0+) -- this needs a guard or rewrite for macOS without Homebrew bash
- Skills invoke commands via Claude's Bash tool, which respects the system shell

### Tool Availability

Standalone mode assumes tools are installed directly. Skills should handle missing tools gracefully:
- Check with `command -v <tool>` before attempting use
- Provide install instructions when a tool is missing
- Skills should list prerequisites in their description or reference.md

## Open Questions for Phase-Specific Research

1. **Plugin-internal skill references:** Do agents in a plugin reference skills with the `netsec-skills:` prefix or bare names? Needs testing with a minimal plugin.

2. **skills.sh plugin discovery:** Does skills.sh auto-discover plugins with `.claude-plugin/plugin.json`, or does it only index `skills/` directories? May need both a plugin structure and skills.sh-compatible layout.

3. **Hook conflict resolution:** If a user installs the plugin AND has the repo with `.claude/hooks/`, do both sets of hooks fire? Need to test and document expected behavior.

4. **Skill description budget:** 32 skills may exceed the 2% context window budget for skill descriptions. Need to measure total description length and potentially set more skills to `disable-model-invocation: true`.

5. **Agent `agent:` field namespace:** When a skill has `agent: pentester` and the agent is in a plugin, does Claude Code resolve `pentester` within the plugin namespace or globally? This affects all 3 agent invoker skills.

## Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Skills format, `${CLAUDE_SKILL_DIR}`, `!`command`` injection, description budget, invocation control (HIGH confidence, official docs)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Plugin manifest schema, `${CLAUDE_PLUGIN_ROOT}`, hooks.json format, component paths, caching behavior (HIGH confidence, official docs)
- [Claude Code Subagents Documentation](https://code.claude.com/docs/en/sub-agents) -- Agent `skills:` field, namespace behavior, hook scoping in agents (HIGH confidence, official docs)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- Hook configuration in plugins, event types, matcher patterns (HIGH confidence, official docs)
- [skills.sh CLI Documentation](https://skills.sh/docs/cli) -- Installation commands, `--skill` flag, telemetry (MEDIUM confidence, third-party docs)
- [Anthropic Skills Repository](https://github.com/anthropics/skills) -- Official skill examples, plugin structure patterns (HIGH confidence, official repo)
- [Agent Skills Specification](https://agentskills.io/specification) -- Cross-platform skill format, YAML frontmatter validation rules (HIGH confidence, official spec)
- Direct codebase analysis of all 32 skills, 3 hooks, 3 agents, wrapper scripts, and lib modules (HIGH confidence)

---
*Architecture research for: Standalone skill publication to skills.sh from networking-tools pentesting toolkit*
*Researched: 2026-03-06*
