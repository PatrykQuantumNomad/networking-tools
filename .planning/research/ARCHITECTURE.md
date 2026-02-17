# Architecture Research

**Domain:** Claude Code skill pack integration with existing bash pentesting toolkit
**Researched:** 2026-02-17
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Claude Code Interface                           │
│  /netsec-scan <target>      /netsec-diagnose <domain>              │
│  /netsec-lab-up              /netsec-check-tools                    │
├─────────────────────────────────────────────────────────────────────┤
│                     Skill Layer (.claude/skills/)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ netsec-scan/ │  │ netsec-lab/  │  │ netsec-diagnose/         │  │
│  │  SKILL.md    │  │  SKILL.md    │  │  SKILL.md                │  │
│  └──────┬───────┘  └──────┬───────┘  └────────────┬─────────────┘  │
│         │                 │                        │                │
├─────────┼─────────────────┼────────────────────────┼────────────────┤
│         │       Agent Layer (.claude/agents/)       │                │
│         │  ┌──────────────────────────────────────┐ │                │
│         │  │ netsec-scanner.md                    │ │                │
│         │  │ netsec-diagnostician.md              │ │                │
│         │  └──────────────┬───────────────────────┘ │                │
│         │                 │                         │                │
├─────────┴─────────────────┴─────────────────────────┴────────────────┤
│                     Hook Layer (.claude/hooks/)                       │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │ netsec-json-bridge.sh                                        │   │
│  │ PostToolUse:Bash — detects netsec JSON envelopes,            │   │
│  │ feeds structured context back to Claude                      │   │
│  └───────────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────────┤
│                     Existing Script Layer (UNCHANGED)                │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌──────────────┐      │
│  │ common.sh│  │ lib/*.sh │  │ <tool>/    │  │ diagnostics/ │      │
│  │ (entry)  │  │ (10 mods)│  │ examples.sh│  │ *.sh         │      │
│  │          │  │ incl.    │  │ use-case.sh│  │              │      │
│  │          │  │ json.sh  │  │ (81 total) │  │              │      │
│  └──────────┘  └──────────┘  └────────────┘  └──────────────┘      │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `.claude/skills/netsec-*/SKILL.md` | Map user intents to bash script invocations with proper flags | Markdown files with YAML frontmatter. Instruct Claude which scripts to run, how to interpret results |
| `.claude/hooks/netsec-json-bridge.sh` | Detect netsec JSON envelopes in Bash tool output; provide structured context guidance to Claude | Shell script reading PostToolUse input from stdin, returning `additionalContext` via JSON stdout |
| `.claude/agents/netsec-*.md` | Orchestrate multi-step scanning/diagnostic workflows in isolated context | Markdown files with YAML frontmatter defining tool access, model, and system prompt |
| `.claude/settings.json` | Register PostToolUse hook for the JSON bridge | JSON config (additive modification to existing file) |
| `scripts/**/*.sh` (existing) | Execute pentesting tool wrappers, produce educational output or JSON envelopes | Bash scripts using the shared lib. Run via Claude's Bash tool exactly as from CLI |

## Recommended Project Structure

New files are prefixed with `NEW`. Modified files are prefixed with `MOD`. Existing unchanged files are not listed.

```
.claude/
├── CLAUDE.md                              # MOD — add skill pack usage section
├── settings.json                          # MOD — add PostToolUse hook registration
├── settings.local.json                    # UNCHANGED
├── hooks/
│   ├── gsd-check-update.js                # UNCHANGED (GSD framework)
│   ├── gsd-statusline.js                  # UNCHANGED (GSD framework)
│   └── netsec-json-bridge.sh              # NEW — PostToolUse hook for JSON capture
├── skills/
│   ├── netsec-scan/
│   │   └── SKILL.md                       # NEW — scanning workflow skill
│   ├── netsec-diagnose/
│   │   └── SKILL.md                       # NEW — network diagnostics skill
│   ├── netsec-lab/
│   │   └── SKILL.md                       # NEW — Docker lab management skill
│   ├── netsec-check-tools/
│   │   └── SKILL.md                       # NEW — tool availability checker skill
│   ├── netsec-examples/
│   │   └── SKILL.md                       # NEW — educational examples browser skill
│   └── netsec-crack/
│       └── SKILL.md                       # NEW — password cracking workflow skill
├── agents/
│   ├── netsec-scanner.md                  # NEW — multi-step scanning subagent
│   └── netsec-diagnostician.md            # NEW — comprehensive diagnostic subagent
└── commands/
    └── gsd/                               # UNCHANGED (GSD framework commands)
```

### Structure Rationale

- **`.claude/skills/netsec-*/` (not `.claude/commands/netsec/`):** Skills are the current system in Claude Code. Commands have been merged into skills and while they still work, skills provide frontmatter for invocation control (`disable-model-invocation`, `allowed-tools`), supporting files, and automatic discovery by Claude. The GSD framework uses the legacy `commands/` path, but new project-specific integrations should use `skills/`. The `netsec-` prefix avoids any namespace collision with GSD's `gsd:*` commands.

- **Separate `.claude/hooks/netsec-json-bridge.sh`:** A single bridge hook script rather than per-tool hooks because the JSON envelope schema from `scripts/lib/json.sh` is uniform across all scripts. One hook handles all tools.

- **`.claude/agents/netsec-*.md` for multi-step workflows:** Subagents isolate verbose scan output from the main conversation context. A full nmap scan produces hundreds of lines -- better to summarize in a subagent and return a concise report. Subagents also support tool restrictions (read-only for diagnosticians).

- **No plugin packaging:** Direct files in `.claude/` because this is single-project integration. Plugin conversion (adding `.claude-plugin/plugin.json`, moving to a separate directory) is a file-move operation for later if distribution is needed.

## Architectural Patterns

### Pattern 1: Skill-as-Orchestrator (Primary Pattern)

**What:** Each SKILL.md contains instructions for Claude on which bash scripts to invoke, with what flags, and how to interpret their output. The skill is a prompt, not code. It references existing scripts by path.
**When to use:** Every skill-to-script mapping. This is the dominant pattern for the entire skill pack.
**Trade-offs:** + Scripts remain independently testable and CLI-usable. + Skills can combine multiple scripts into workflows. + Zero script modifications required. - Skills must enumerate script paths and flags explicitly (Claude does not discover scripts on its own without guidance).

**Example:**
```yaml
---
name: netsec-scan
description: Scan a network target for open ports, services, and vulnerabilities. Use when the user wants to scan, probe, or enumerate a target.
argument-hint: "[target]"
allowed-tools: Bash, Read, Grep, Glob
---

# Network Scanning

Scan the target using the appropriate nmap script.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `bash scripts/nmap/examples.sh $0 -j` | General nmap examples |
| `bash scripts/nmap/discover-live-hosts.sh $0 -j -x` | Find alive hosts |
| `bash scripts/nmap/identify-ports.sh $0 -j -x` | Identify open ports |
| `bash scripts/nmap/scan-web-vulnerabilities.sh $0 -j -x` | Web vuln scan |

## Execution Protocol

1. Always use `-j` flag for JSON output (structured results)
2. Add `-x` flag to execute commands (not just show examples)
3. If the tool is not installed, run `bash scripts/check-tools.sh` first
4. Parse the JSON envelope from stdout for structured findings
5. Present a summary: what was found, security implications, next steps
```

### Pattern 2: JSON Bridge Hook

**What:** A PostToolUse hook that fires after Bash commands, detects when a netsec script produced a JSON envelope, and provides structured context guidance back to Claude. This closes the feedback loop between script execution and Claude's understanding of results.
**When to use:** Automatically, on every Bash tool call that matches a netsec script invocation with `-j` flag.
**Trade-offs:** + Claude receives a concise summary without re-parsing large JSON. + Existing fd3 redirect means JSON is already cleanly separated on stdout. - Adds a small amount of latency to every Bash command (mitigated by fast early-exit for non-netsec commands). - Requires `jq` on the system (already a dependency for `-j` scripts).

**Example:**
```bash
#!/usr/bin/env bash
# .claude/hooks/netsec-json-bridge.sh
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Fast exit: only process netsec script invocations with -j
[[ "$COMMAND" == *"scripts/"* && "$COMMAND" == *"-j"* ]] || exit 0

STDOUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // empty' 2>/dev/null)

# Validate netsec JSON envelope structure
if echo "$STDOUT" | jq -e '.meta.tool and .results and .summary' &>/dev/null; then
  TOOL=$(echo "$STDOUT" | jq -r '.meta.tool')
  TARGET=$(echo "$STDOUT" | jq -r '.meta.target')
  TOTAL=$(echo "$STDOUT" | jq -r '.summary.total')
  OK=$(echo "$STDOUT" | jq -r '.summary.succeeded')
  FAIL=$(echo "$STDOUT" | jq -r '.summary.failed')

  jq -n --arg ctx "Netsec JSON result: $TOOL scanned $TARGET. $TOTAL checks: $OK succeeded, $FAIL failed. Full JSON envelope is in Bash stdout." \
    '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx}}'
else
  exit 0
fi
```

### Pattern 3: Dynamic Context Injection via !`command`

**What:** Skills use the `!`command`` syntax to run shell commands before Claude sees the skill content. The output replaces the placeholder, giving Claude live system state.
**When to use:** When a skill's behavior should adapt based on which tools are installed, whether the Docker lab is running, or what network interfaces exist.
**Trade-offs:** + No extra conversation turn needed for context gathering. + Claude receives real-time data, not stale assumptions. - Commands must complete quickly (they block skill rendering). - Cannot use for long-running operations.

**Example:**
```yaml
---
name: netsec-scan
description: Scan targets using available tools
---

## System State
- Available tools: !`bash scripts/check-tools.sh 2>/dev/null | grep "INSTALLED" | wc -l || echo "0"` installed
- Lab containers: !`docker compose -f labs/docker-compose.yml ps --format "{{.Name}}: {{.State}}" 2>/dev/null || echo "Not running"`

Based on the tools above, select the best scanning approach...
```

### Pattern 4: Diagnostic Subagent for Context Isolation

**What:** A custom subagent that runs multi-step diagnostics in an isolated context window, preventing verbose output from consuming the main conversation.
**When to use:** Comprehensive diagnostic workflows (connectivity + DNS + performance), long-running scans, or any task producing hundreds of lines of output.
**Trade-offs:** + Main conversation context stays clean. + Subagent can run in background. + Can enforce read-only tool restrictions. - Subagents cannot spawn sub-subagents. - Results must be summarized on return to main context.

**Example:**
```markdown
---
name: netsec-diagnostician
description: Run comprehensive network diagnostics against a target. Use when diagnosing connectivity issues, DNS problems, or performance bottlenecks.
tools: Bash, Read, Grep, Glob
model: inherit
---

You are a network diagnostic specialist working with the networking-tools project.

Run diagnostic scripts in this order:
1. `bash scripts/diagnostics/connectivity.sh [target]` -- layered connectivity check
2. `bash scripts/diagnostics/dns.sh [target]` -- DNS resolution analysis
3. `bash scripts/diagnostics/performance.sh [target]` -- latency and throughput

Synthesize findings into a report:
- What is working normally
- What is broken or degraded
- Root cause analysis
- Recommended remediation steps
```

## Data Flow

### Request Flow: Skill Invocation

```
User types: /netsec-scan 192.168.1.1
    |
    v
Claude Code loads skills/netsec-scan/SKILL.md
    |
    v
!`command` preprocessing runs (tool checks, lab status)
    |
    v
Claude reads skill instructions + preprocessed system state
    |
    v
Claude invokes Bash tool:
    bash scripts/nmap/discover-live-hosts.sh 192.168.1.1 -j -x
    |
    v
Script execution (existing infrastructure, zero changes):
    common.sh -> lib modules loaded
    args.sh: parses -j, sets JSON_MODE=1, exec 3>&1 1>&2
    json.sh: json_set_meta("nmap", "192.168.1.1")
    output.sh: run_or_show captures command output via json_add_result()
    json.sh: json_finalize() writes envelope to fd3 (-> Bash tool stdout)
    |
    v
Bash tool captures:
    stdout: {"meta":{...},"results":[...],"summary":{...}}
    stderr: [INFO] === Host Discovery === ...
    |
    v
PostToolUse hook fires: netsec-json-bridge.sh
    Receives: tool_input.command + tool_response (stdout/stderr)
    Detects: netsec JSON envelope in stdout
    Returns: {"hookSpecificOutput":{"additionalContext":"Netsec result: nmap..."}}
    |
    v
Claude receives: Bash tool output + hook context
    |
    v
Claude presents findings to user:
    "Discovered 12 live hosts on 192.168.1.0/24. 3 have web servers..."
```

### JSON Protocol (Existing, Leveraged As-Is)

The fd3 redirect mechanism in `scripts/lib/args.sh` is the key enabler:

```
parse_common_args -j -x:
    exec 3>&1       # fd3 = original stdout (captured by Bash tool)
    exec 1>&2       # stdout -> stderr (visible to user, not mixed with JSON)
    |
run_or_show in JSON+execute mode:
    capture command output to temp files
    json_add_result(description, exit_code, stdout, stderr)
    |
json_finalize:
    assembles envelope: {meta, results[], summary}
    writes to fd3 (= Bash tool's stdout)
    exit 0
```

**Critical insight:** The existing fd3 protocol means Claude's Bash tool captures clean JSON on stdout and human-readable messages on stderr. No script modifications are needed for skill pack integration.

### Key Data Flows

1. **Skill -> Script:** Skill instructs Claude to run `bash scripts/<tool>/<script>.sh <target> -j -x`. Claude uses the Bash tool. The script runs identically to CLI invocation.

2. **Script -> Hook -> Claude:** Script produces JSON on stdout (via fd3). Hook detects the envelope pattern and returns a concise `additionalContext` summary. Claude receives both the full JSON and the summary.

3. **Subagent -> Main context:** Subagent runs multiple scripts, accumulates findings in its own context, then returns a synthesized report to the main conversation. Verbose output stays in the subagent's context.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 6 skills (initial) | Direct SKILL.md files. No indexing or discovery issues. Well within the 16KB skill description budget. |
| 15-20 skills | May approach skill description budget limit. Split into more focused skills with `disable-model-invocation: true` for rarely-used ones. |
| Distribution to other projects | Convert to plugin structure: move `.claude/skills/netsec-*/` to `netsec-plugin/skills/`, add `.claude-plugin/plugin.json`. File-move, not rewrite. |

### Scaling Priorities

1. **First concern at ~15 skills:** Skill description budget (2% of context window, ~16KB fallback). Monitor with `/context` command. Use `disable-model-invocation: true` for infrequent skills to exclude them from description loading.

2. **Second concern at distribution time:** Namespace collisions with user's existing skills. Solved by converting to a plugin, which auto-namespaces as `netsec-plugin:skill-name`.

## Anti-Patterns

### Anti-Pattern 1: Duplicating Script Logic in Skills

**What people do:** Write bash commands directly in SKILL.md (e.g., inline nmap flags) instead of calling existing scripts.
**Why it's wrong:** Logic exists in two places. Script improvements don't propagate to skills. Defeats the purpose of having a script library.
**Do this instead:** Skills reference scripts by path: `bash scripts/nmap/discover-live-hosts.sh $TARGET -j -x`. The skill orchestrates; the script executes.

### Anti-Pattern 2: One Monolithic Skill

**What people do:** Create a single `/netsec` skill covering all 81 scripts.
**Why it's wrong:** Exceeds the 500-line SKILL.md recommendation. Loads too much context. Claude cannot auto-discover it effectively with a vague description.
**Do this instead:** Create focused skills by domain: scan, diagnose, lab, crack, examples. Each has a specific description for intent matching.

### Anti-Pattern 3: Hook That Processes All Bash Output

**What people do:** Write a PostToolUse hook that runs expensive parsing on every Bash command (git, npm, ls, etc.).
**Why it's wrong:** Adds latency to every Bash tool invocation, not just netsec scripts.
**Do this instead:** Fast early-exit in the hook: `[[ "$COMMAND" == *"scripts/"* && "$COMMAND" == *"-j"* ]] || exit 0`. Only process commands that match the netsec pattern.

### Anti-Pattern 4: Using commands/ Instead of skills/

**What people do:** Place new netsec commands in `.claude/commands/netsec/` because that's where GSD lives.
**Why it's wrong:** `commands/` is legacy (merged into skills). Skills support frontmatter, supporting files, auto-discovery, and subagent execution. Mixing netsec into the GSD command namespace creates confusion.
**Do this instead:** Use `.claude/skills/netsec-*/SKILL.md` for all new skill files. The `netsec-` prefix naturally separates from GSD.

### Anti-Pattern 5: Requiring Script Modifications for Claude Compatibility

**What people do:** Add Claude-specific output formatting, new flags, or different behavior to scripts.
**Why it's wrong:** Breaks CLI interface. May break existing BATS tests. Violates the constraint that existing scripts remain unchanged.
**Do this instead:** The `-j` flag and JSON envelope protocol already exist. Skills teach Claude how to use scripts as-is.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Docker (lab targets) | `docker compose` via Bash tool | Skill checks container state before suggesting lab-based scanning |
| Pentesting tools (nmap, nikto, etc.) | Direct CLI invocation via `bash scripts/<tool>/` | `require_cmd` in scripts handles missing tools gracefully |
| jq | Required for `-j` flag and hook JSON parsing | Already a project dependency. Hook script depends on it. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Skill -> Script | Bash tool invocation with specific flags | Skills never import or source scripts. They invoke them as CLI commands. |
| Script -> Hook | JSON on Bash stdout (via fd3 redirect) | Hook reads from PostToolUse `tool_response.stdout`. No direct coupling. |
| Hook -> Claude | `additionalContext` in JSON response | Hook provides guidance text; Claude still has full Bash output for detail. |
| Subagent -> Main context | Summarized return value | Subagent's verbose output stays in its own context window. |
| Skills <-> GSD commands | No interaction | Separate namespaces (`netsec-*` vs `gsd:*`). Coexist in `.claude/` without conflict. |

### settings.json Modification

The existing `settings.json` has GSD hooks. Adding the netsec hook is additive:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node .claude/hooks/gsd-check-update.js"
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
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/netsec-json-bridge.sh"
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "node .claude/hooks/gsd-statusline.js"
  }
}
```

**Risk:** LOW. Adding a new event (`PostToolUse`) does not conflict with the existing `SessionStart` hook. The matcher limits it to Bash tool calls only.

## New vs Modified Components Summary

### New Components (10 files)

| File | Type | Est. Lines | Purpose |
|------|------|-----------|---------|
| `.claude/skills/netsec-scan/SKILL.md` | Skill | ~80 | Scanning workflow (nmap, nikto, sqlmap) |
| `.claude/skills/netsec-diagnose/SKILL.md` | Skill | ~50 | Network diagnostics |
| `.claude/skills/netsec-lab/SKILL.md` | Skill | ~40 | Docker lab management |
| `.claude/skills/netsec-check-tools/SKILL.md` | Skill | ~30 | Tool availability check |
| `.claude/skills/netsec-examples/SKILL.md` | Skill | ~60 | Educational examples browser |
| `.claude/skills/netsec-crack/SKILL.md` | Skill | ~60 | Password cracking workflows |
| `.claude/hooks/netsec-json-bridge.sh` | Hook | ~40 | JSON envelope detection and context feedback |
| `.claude/agents/netsec-scanner.md` | Agent | ~40 | Multi-step scanning subagent |
| `.claude/agents/netsec-diagnostician.md` | Agent | ~40 | Comprehensive diagnostic subagent |
| Tests for hook script | Test | ~30 | Validate hook input/output behavior |

### Modified Components (2 files)

| File | What Changes | Lines Changed |
|------|-------------|---------------|
| `.claude/settings.json` | Add `PostToolUse` hook entry | +10 lines |
| `.claude/CLAUDE.md` | Add skill pack usage documentation section | +20 lines |

### Unchanged Components (everything else)

| Component | Why Unchanged |
|-----------|---------------|
| `scripts/**/*.sh` (all 81 scripts) | Skills invoke them via Bash tool. No modifications. |
| `scripts/lib/*.sh` (all 10 modules) | fd3 JSON protocol works with Claude's Bash tool as-is |
| `scripts/common.sh` | Entry point unchanged |
| `tests/**/*.bats` (all test files) | Existing tests continue validating script behavior |
| `Makefile` | CLI interface preserved; skills are a parallel access path |
| `labs/docker-compose.yml` | Lab environment unchanged |
| `site/**` | Astro docs site unchanged |
| `.claude/commands/gsd/` | GSD framework unchanged |
| `.claude/hooks/gsd-*.js` | GSD hooks unchanged |

## Bundling Strategy

**Decision: Direct files in `.claude/`, no symlinks, copies, or build steps.**

| Strategy | Verdict | Rationale |
|----------|---------|-----------|
| Direct files in `.claude/` | **USE THIS** | Skills are small markdown files (~40-80 lines). They version-control with the project. Zero-config, zero build step. |
| Symlinks from scripts/ to .claude/ | REJECT | Skills are prompts, not bash scripts. They conceptually belong in `.claude/`, not `scripts/`. Symlinks add fragility. |
| Build/copy step | REJECT | Over-engineering for markdown files. No transformation needed. |
| Plugin package | DEFER | Correct for distribution but premature for single-project use. Convert when/if sharing with other repos. |
| npm package | REJECT | Wrong distribution model for AI skill files. |

**Future plugin conversion path:** Create `netsec-skills/` directory, add `.claude-plugin/plugin.json`, move skills/hooks/agents there. Install via `claude --plugin-dir ./netsec-skills`. This is a file-move operation, not a rewrite. Skills become namespaced as `netsec-skills:netsec-scan` etc.

## Build Order (Dependency-Aware)

| Phase | Component | Depends On | Rationale |
|-------|-----------|-----------|-----------|
| 1 | `netsec-json-bridge.sh` hook + `settings.json` update | Nothing | Foundation for all structured feedback. Can test independently with manual bash commands. |
| 2 | `netsec-check-tools` skill | Nothing | Simplest possible skill. Validates the skill-invokes-script pattern. |
| 3 | `netsec-lab` skill | Nothing | Simple Docker management. Tests skill frontmatter, no JSON involved. |
| 4 | `netsec-examples` skill | Hook (optional) | Wraps all `examples.sh` scripts. Tests show-mode. |
| 5 | `netsec-scan` skill | Hook, check-tools skill | Core scanning skill. Benefits from JSON bridge for structured feedback. |
| 6 | `netsec-diagnose` skill | Hook | Wraps diagnostic scripts. |
| 7 | `netsec-crack` skill | Hook, check-tools skill | Password cracking workflows. |
| 8 | `netsec-scanner` agent | netsec-scan skill (conceptually) | Multi-step subagent. Build after scan skill is proven. |
| 9 | `netsec-diagnostician` agent | netsec-diagnose skill (conceptually) | Diagnostic subagent. |
| 10 | `CLAUDE.md` updates | All skills/agents | Document available skills after they all work. |

## Cross-Platform Considerations

### Shell Invocation

All skill-to-script invocations must use explicit `bash` prefix: `bash scripts/nmap/examples.sh` (matching the Makefile pattern). Claude Code's Bash tool uses the system shell (zsh on macOS by default), but scripts require bash 4.0+ (enforced by `common.sh` guard). The explicit `bash` prefix ensures the correct interpreter.

### Path Handling

- Hook scripts use `$CLAUDE_PROJECT_DIR` for paths (Claude Code environment variable, always available)
- Existing scripts use `$PROJECT_ROOT` (resolved in `output.sh`)
- These are independent mechanisms that both resolve to the repo root

### Tool Availability

Scripts handle missing tools via `require_cmd` with install hints. Skills should instruct Claude to check tool availability first rather than blindly running scripts that may fail with "command not found."

### jq Dependency

The hook script requires `jq` for JSON parsing. This is the same dependency required by the `-j` flag in scripts. If jq is missing, the hook exits 0 (non-blocking) and Claude simply does not receive the structured summary -- it still has the raw Bash output.

## Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Skills system, frontmatter fields, `!`command`` preprocessing, supporting files, invocation control (HIGH confidence, official docs)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- PostToolUse event schema, matcher patterns, JSON output format, `additionalContext`, exit codes (HIGH confidence, official docs)
- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins) -- Plugin structure, namespace behavior, conversion from standalone config (HIGH confidence, official docs)
- [Claude Code Subagents Documentation](https://code.claude.com/docs/en/sub-agents) -- Agent frontmatter, tool restrictions, model selection, background execution (HIGH confidence, official docs)
- Direct codebase analysis: `scripts/lib/json.sh`, `scripts/lib/args.sh`, `scripts/lib/output.sh` -- fd3 JSON protocol, JSON envelope schema (HIGH confidence)
- Direct codebase analysis: `.claude/settings.json`, `.claude/hooks/` -- Current GSD hook patterns, settings structure (HIGH confidence)
- Direct codebase analysis: `.claude/commands/gsd/*.md` -- Existing command file patterns with frontmatter (HIGH confidence)

---
*Architecture research for: Claude Code skill pack integration with networking-tools*
*Researched: 2026-02-17*
