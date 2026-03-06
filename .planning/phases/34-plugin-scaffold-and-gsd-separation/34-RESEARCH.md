# Phase 34: Plugin Scaffold and GSD Separation - Research

**Researched:** 2026-03-06
**Domain:** Claude Code plugin architecture, directory scaffolding, GSD boundary enforcement
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Plugin identity
- Name: `netsec-skills`
- Description: "Pentesting skills pack -- 17 tool skills, 6 workflows, 3 agent personas for network security testing with Claude Code"
- Version: `1.0.0` (fresh start, independent of repo milestone versioning)
- Keywords: mixed broad pentesting terms + specific tool names for maximum discoverability (pentesting, security, red-team, CTF, network-security, nmap, sqlmap, hashcat, metasploit, nikto, gobuster)

#### Skill categorization
- Grouped by type inside `skills/`: `tools/`, `workflows/`, `agents/`, `utility/`
- 4 skill types: tool (17+1 traceroute), workflow (6), agent (3), utility (scope, health, check-tools)
- Traceroute included as a tool skill despite not being in the original 10-tool list
- Report skill included in plugin (useful standalone for any pentester)

#### Marketplace catalog (marketplace.json)
- Rich metadata per entry: name, type, trigger, description, tags, requires (tool dependency)
- Separate top-level sections for skills, hooks, and agents (not flattened into one list)
- Hooks section lists PreToolUse (scope check) and PostToolUse (audit) with event types
- Agents section lists pentester, defender, analyst with role descriptions

#### GSD boundary enforcement
- Allowlist approach: only explicitly permitted file types exist in `netsec-skills/`
- Allowed: `skills/**/*.md`, `hooks/*.sh`, `agents/*.md`, `scripts/*.sh`, `plugin.json`, `marketplace.json`, `README.md`
- Anything not on the allowlist is rejected -- no blocklist/grep pattern matching

#### File strategy during development
- Symlinks from `netsec-skills/skills/` back to `.claude/skills/` during Phase 34
- Phase 36+ replaces symlinks with modified standalone copies
- Hooks copied as-is from `.claude/hooks/` into `netsec-skills/hooks/` (Phase 35 modifies for portability)

#### Repo-only skills (excluded from plugin)
- `/lab` -- depends on repo-specific `labs/docker-compose.yml`, not useful standalone
- `/pentest-conventions` -- defines repo-specific script conventions (common.sh pattern, examples.sh structure)

#### Plugin README
- Full README.md at `netsec-skills/` root: installation instructions, skill list, usage examples, safety notes, quick start with `/netsec-health`

### Claude's Discretion
- Exact plugin.json schema fields beyond name/description/version/keywords
- README.md formatting and section ordering
- How to validate the allowlist (script, manual check, or CI step)
- Symlink creation approach (relative vs absolute paths)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLUG-01 | User can install the netsec skills pack via a `.claude-plugin/plugin.json` manifest | Plugin manifest schema documented below with all required and recommended fields; directory structure verified against official docs |
| PLUG-02 | User can discover all skills, agents, and hooks listed in `marketplace.json` | Custom marketplace.json catalog schema designed; skill inventory verified (30 skills total, 28 included in plugin) |
| PLUG-03 | Published plugin package contains zero GSD framework files (agents, hooks, commands, templates) | GSD file inventory completed (12 agents, 3 hooks, full get-shit-done directory identified); allowlist validation approach documented |
</phase_requirements>

## Summary

Phase 34 creates the `netsec-skills/` plugin directory that users can load with `claude --plugin-dir ./netsec-skills`. The plugin uses Claude Code's official plugin format: a `.claude-plugin/plugin.json` manifest at the metadata level, with `skills/`, `agents/`, `hooks/`, and `scripts/` directories at the plugin root. Skills are symlinked back to `.claude/skills/` during this phase (later phases replace symlinks with standalone copies). A custom `marketplace.json` at the plugin root serves as the single source of truth for what the plugin contains.

The primary technical challenge is ensuring a clean GSD boundary. The existing `.claude/` directory contains 12 GSD agents, 3 GSD hooks (JS), and the entire `get-shit-done/` framework alongside the netsec content. The allowlist approach means only explicitly permitted file patterns exist in `netsec-skills/` -- anything else is a build error. The GSD boundary is enforced by construction (only netsec files are symlinked/copied) rather than by filtering (no grep-based exclusion).

The plugin hooks configuration differs from the repo-local approach. Instead of registering hooks in `.claude/settings.json`, plugins use `hooks/hooks.json` with the same event/matcher/command structure but referencing scripts via `${CLAUDE_PLUGIN_ROOT}`. The hooks themselves (netsec-pretool.sh, netsec-posttool.sh, netsec-health.sh) are copied as-is into the plugin during Phase 34, with portability modifications deferred to Phase 35.

**Primary recommendation:** Build the directory scaffold with symlinks for all 28 included skills (organized into `tools/`, `workflows/`, `agents/`, `utility/` subdirectories), copy netsec hooks as-is, create plugin.json manifest and marketplace.json catalog, write README.md, then validate the GSD boundary with an allowlist check script.

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Claude Code Plugin Format | Current (2026) | Plugin directory structure with `.claude-plugin/plugin.json` | Official Anthropic plugin specification; required for `claude --plugin-dir` and marketplace distribution |
| `ln -s` (POSIX symlinks) | System | Create skill directory symlinks back to `.claude/skills/` | Standard POSIX; macOS and Linux compatible; followed during plugin cache copy |
| `jq` | 1.6+ | JSON validation for plugin.json, marketplace.json, hooks.json | Already a project dependency (used by hooks); validates JSON correctness |
| Bash | 4.0+ | Hook scripts, validation scripts | Already required by netsec-pretool.sh (`declare -A`); macOS ships 3.2 but Homebrew provides 5.x |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `find` + `test` | Allowlist validation script | Phase 34 verification step: scan `netsec-skills/` and reject any file not matching the allowlist |
| `chmod +x` | Ensure hook scripts are executable | After copying hooks into plugin directory |
| `file` command | Detect broken symlinks | Verification that all skill symlinks resolve correctly |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Relative symlinks | Absolute symlinks | Absolute symlinks break when the repo moves; relative symlinks are portable within the repo |
| Symlinks | File copies | Copies would diverge from source; symlinks maintain single source of truth during Phase 34 |
| Custom marketplace.json | Standard `.claude-plugin/marketplace.json` | The standard format is for marketplace distribution catalogs (Phase 39); the plugin-root marketplace.json is a custom content catalog for human discovery and downstream phase reference |

## Architecture Patterns

### Recommended Plugin Directory Structure

```
netsec-skills/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (name, version, description, keywords)
├── skills/
│   ├── tools/
│   │   ├── nmap/               -> ../../.claude/skills/nmap (symlink)
│   │   ├── tshark/             -> ../../.claude/skills/tshark (symlink)
│   │   ├── metasploit/         -> ... (symlink)
│   │   ├── aircrack-ng/        -> ...
│   │   ├── hashcat/            -> ...
│   │   ├── skipfish/           -> ...
│   │   ├── sqlmap/             -> ...
│   │   ├── hping3/             -> ...
│   │   ├── john/               -> ...
│   │   ├── nikto/              -> ...
│   │   ├── foremost/           -> ...
│   │   ├── dig/                -> ...
│   │   ├── curl/               -> ...
│   │   ├── netcat/             -> ...
│   │   ├── traceroute/         -> ...
│   │   ├── gobuster/           -> ...
│   │   └── ffuf/               -> ...
│   ├── workflows/
│   │   ├── recon/              -> ../../.claude/skills/recon (symlink)
│   │   ├── scan/               -> ...
│   │   ├── fuzz/               -> ...
│   │   ├── crack/              -> ...
│   │   ├── sniff/              -> ...
│   │   └── diagnose/           -> ...
│   ├── agents/
│   │   ├── pentester/          -> ../../.claude/skills/pentester (symlink)
│   │   ├── defender/           -> ...
│   │   └── analyst/            -> ...
│   └── utility/
│       ├── scope/              -> ../../.claude/skills/scope (symlink)
│       ├── netsec-health/      -> ...
│       ├── check-tools/        -> ...
│       └── report/             -> ...
├── agents/
│   ├── pentester.md            -> ../.claude/agents/pentester.md (symlink)
│   ├── defender.md             -> ../.claude/agents/defender.md (symlink)
│   └── analyst.md              -> ../.claude/agents/analyst.md (symlink)
├── hooks/
│   ├── hooks.json              # Hook registration config (NEW file)
│   ├── netsec-pretool.sh       # Copied from .claude/hooks/ (as-is for now)
│   ├── netsec-posttool.sh      # Copied from .claude/hooks/ (as-is for now)
│   └── netsec-health.sh        # Copied from .claude/hooks/ (as-is for now)
├── scripts/                    # Empty for now; Phase 35+ may add utility scripts
├── marketplace.json            # Custom content catalog (skills, hooks, agents inventory)
└── README.md                   # Plugin documentation
```

### Pattern 1: Plugin Manifest (plugin.json)

**What:** The `.claude-plugin/plugin.json` file defines plugin identity and component discovery.
**When to use:** Required for any plugin loaded via `claude --plugin-dir` or marketplace install.

```json
// Source: https://code.claude.com/docs/en/plugins-reference
{
  "name": "netsec-skills",
  "version": "1.0.0",
  "description": "Pentesting skills pack -- 17 tool skills, 6 workflows, 3 agent personas for network security testing with Claude Code",
  "author": {
    "name": "PatrykQuantumNomad",
    "url": "https://github.com/PatrykQuantumNomad"
  },
  "repository": "https://github.com/PatrykQuantumNomad/networking-tools",
  "license": "MIT",
  "keywords": [
    "pentesting",
    "security",
    "red-team",
    "CTF",
    "network-security",
    "nmap",
    "sqlmap",
    "hashcat",
    "metasploit",
    "nikto",
    "gobuster"
  ]
}
```

**Key decisions (Claude's Discretion):**
- `author` field: Include name and URL for GitHub profile. Email is optional; omit for privacy.
- `repository` field: Points to the networking-tools repo (the plugin lives within it).
- `license` field: Use MIT (matches typical open-source pentesting tools).
- Component path fields (`skills`, `agents`, `hooks`) are NOT needed in plugin.json when using default directory names at the plugin root. Claude Code auto-discovers `skills/`, `agents/`, `hooks/hooks.json` automatically.

### Pattern 2: Plugin Hooks Registration (hooks.json)

**What:** The `hooks/hooks.json` file registers event handlers for the plugin.
**When to use:** Required when a plugin provides hooks that should fire on Claude Code events.

```json
// Source: https://code.claude.com/docs/en/plugins-reference
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/netsec-pretool.sh\""
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
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/netsec-posttool.sh\""
          }
        ]
      }
    ]
  }
}
```

**Critical detail:** Use `${CLAUDE_PLUGIN_ROOT}` instead of `$CLAUDE_PROJECT_DIR`. When the plugin is installed via marketplace, files are copied to `~/.claude/plugins/cache/` and `${CLAUDE_PLUGIN_ROOT}` resolves to that cached location. The hooks themselves still use `$CLAUDE_PROJECT_DIR` internally for scope files -- that portability fix is Phase 35's concern.

### Pattern 3: Symlink Creation (Relative Paths)

**What:** Create relative symlinks from `netsec-skills/skills/<category>/<skill>` back to `.claude/skills/<skill>`.
**When to use:** Phase 34 uses symlinks as the file strategy; Phase 36+ replaces with standalone copies.

```bash
# From netsec-skills/skills/tools/ directory, link back to repo skills
# The relative path goes: tools/ -> skills/ -> netsec-skills/ -> repo-root -> .claude/skills/<name>
ln -s ../../../.claude/skills/nmap nmap
ln -s ../../../.claude/skills/tshark tshark
# ... etc for all 17 tool skills
```

**Recommendation (Claude's Discretion):** Use relative symlinks, not absolute. Relative symlinks:
1. Work when the repo is cloned to any absolute path
2. Are followed during plugin cache copy (verified in official docs)
3. Keep the plugin self-contained within the repo

**Depth calculation for symlink targets:**
- `netsec-skills/skills/tools/<skill>` -> `../../../.claude/skills/<skill>` (3 levels up)
- `netsec-skills/skills/workflows/<skill>` -> `../../../.claude/skills/<skill>` (3 levels up)
- `netsec-skills/skills/agents/<skill>` -> `../../../.claude/skills/<skill>` (3 levels up)
- `netsec-skills/skills/utility/<skill>` -> `../../../.claude/skills/<skill>` (3 levels up)
- `netsec-skills/agents/<agent>.md` -> `../../.claude/agents/<agent>.md` (2 levels up)

### Pattern 4: Custom Marketplace Catalog (marketplace.json)

**What:** A plugin-root `marketplace.json` serving as the single source of truth for plugin contents.
**When to use:** Human discovery and downstream phase reference. NOT the same as `.claude-plugin/marketplace.json` (which is for marketplace distribution).

```json
{
  "name": "netsec-skills",
  "version": "1.0.0",
  "description": "Pentesting skills pack -- 17 tool skills, 6 workflows, 3 agent personas for network security testing with Claude Code",
  "skills": [
    {
      "name": "nmap",
      "type": "tool",
      "trigger": "/nmap",
      "description": "Network scanning and host discovery using nmap wrapper scripts",
      "tags": ["network", "scanning", "discovery", "ports"],
      "requires": "nmap"
    }
  ],
  "hooks": [
    {
      "name": "netsec-pretool",
      "event": "PreToolUse",
      "description": "Target allowlist validation and raw tool interception",
      "file": "hooks/netsec-pretool.sh"
    }
  ],
  "agents": [
    {
      "name": "pentester",
      "description": "Offensive pentesting specialist for multi-tool attack workflow orchestration",
      "file": "agents/pentester.md"
    }
  ]
}
```

### Pattern 5: GSD Boundary Validation Script

**What:** A bash script that validates the allowlist -- ensures only permitted file types exist in `netsec-skills/`.
**When to use:** Run after scaffold creation and before any commit. Can also be used as a CI step.

```bash
#!/usr/bin/env bash
# validate-plugin-boundary.sh -- Verify netsec-skills/ contains only allowed files
set -euo pipefail

PLUGIN_DIR="${1:-netsec-skills}"
VIOLATIONS=0

while IFS= read -r file; do
  # Skip directories and symlink targets
  [[ -d "$file" ]] && continue

  # Resolve relative path within plugin
  rel="${file#$PLUGIN_DIR/}"

  # Check against allowlist patterns
  case "$rel" in
    skills/**/*.md)          ;; # Skill markdown files
    hooks/*.sh)              ;; # Hook shell scripts
    hooks/*.json)            ;; # Hook configuration
    agents/*.md)             ;; # Agent definitions
    scripts/*.sh)            ;; # Utility scripts
    .claude-plugin/plugin.json) ;; # Plugin manifest
    marketplace.json)        ;; # Content catalog
    README.md)               ;; # Documentation
    *) echo "VIOLATION: $rel"; ((VIOLATIONS++)) ;;
  esac
done < <(find "$PLUGIN_DIR" -not -path '*/.*' -not -name '.claude-plugin' -type f -o -type l)

# Also check: no gsd- prefixed files anywhere
GSD_COUNT=$(find "$PLUGIN_DIR" -name "gsd-*" | wc -l | tr -d ' ')
if [[ "$GSD_COUNT" -gt 0 ]]; then
  echo "GSD LEAK: Found $GSD_COUNT gsd-prefixed files"
  find "$PLUGIN_DIR" -name "gsd-*"
  ((VIOLATIONS += GSD_COUNT))
fi

if [[ "$VIOLATIONS" -eq 0 ]]; then
  echo "PASS: Plugin boundary clean ($PLUGIN_DIR)"
  exit 0
else
  echo "FAIL: $VIOLATIONS boundary violations"
  exit 1
fi
```

**Recommendation (Claude's Discretion):** Create this as `scripts/validate-plugin-boundary.sh` in the repo root (not inside the plugin). Run it as part of task verification. A CI step can be added later (Phase 39) but a manual script is sufficient for Phase 34.

### Anti-Patterns to Avoid

- **Putting components inside `.claude-plugin/`:** Only `plugin.json` goes inside `.claude-plugin/`. Skills, agents, hooks, scripts all go at the plugin root. Claude Code will NOT discover components inside `.claude-plugin/`.
- **Using absolute symlinks:** Absolute symlinks break when the repo is cloned to a different path. Always use relative symlinks.
- **Including `commands/` directory:** The `commands/` directory is legacy. Use `skills/` with `SKILL.md` subdirectories for all skills. The planner should NOT create a `commands/` directory.
- **Mixing GSD and netsec in hooks.json:** The plugin's `hooks/hooks.json` must only register netsec hooks (pretool, posttool). No GSD hooks (gsd-check-update.js, gsd-context-monitor.js, gsd-statusline.js) should appear.
- **Nesting skills too deeply:** Claude Code discovers skills as `skills/<name>/SKILL.md`. With the category subdirectories (`skills/tools/nmap/SKILL.md`), Claude Code should still discover them since it scans recursively. However, this changes the namespace -- verify with `claude --plugin-dir ./netsec-skills` that skills appear correctly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plugin manifest schema | Custom metadata format | `.claude-plugin/plugin.json` per official spec | Claude Code validates this on load; custom formats are ignored |
| Hook registration | Manual settings.json editing | `hooks/hooks.json` with standard event/matcher/command structure | Plugin hook auto-discovery reads from this location; settings.json is for repo-local hooks only |
| Symlink management | Manual `ln -s` commands scattered in docs | A single bash scaffold script that creates all symlinks | 28 symlinks plus 3 agent symlinks = error-prone if done manually |
| JSON validation | Manual `cat` and eyeball checking | `jq . file.json > /dev/null` for syntax + `claude plugin validate .` for plugin structure | `jq` catches JSON syntax errors; `claude plugin validate` catches structural errors |

**Key insight:** The plugin format is fully standardized by Claude Code. Every file has a prescribed location and format. The only creative work is the custom `marketplace.json` catalog and the `README.md` -- everything else follows the spec exactly.

## Common Pitfalls

### Pitfall 1: Components inside .claude-plugin/ directory
**What goes wrong:** Skills, agents, or hooks placed inside `.claude-plugin/` are invisible to Claude Code.
**Why it happens:** Intuition says "plugin config goes in the plugin config directory." The spec says otherwise.
**How to avoid:** Only `plugin.json` goes inside `.claude-plugin/`. Everything else is at plugin root.
**Warning signs:** `claude --plugin-dir ./netsec-skills` loads but no skills appear with `/` commands.

### Pitfall 2: Broken symlinks after directory restructuring
**What goes wrong:** Symlinks point to non-existent paths because the relative depth was calculated wrong.
**Why it happens:** Skills are in `netsec-skills/skills/tools/<name>` (3 levels deep from repo root) but symlink target was calculated for 2 levels.
**How to avoid:** Test every symlink with `ls -la` and `cat <symlink>/SKILL.md` after creation.
**Warning signs:** `file` command shows "broken symbolic link" or `cat` shows "No such file or directory."

### Pitfall 3: Skill namespace collision with category subdirectories
**What goes wrong:** Claude Code might see skills as `tools/nmap` instead of just `nmap` when using category subdirectories inside `skills/`.
**Why it happens:** Claude Code discovers skills by scanning `skills/` recursively for `SKILL.md` files. The directory path between `skills/` and `SKILL.md` becomes the skill's identifier.
**How to avoid:** After creating the scaffold, test with `claude --plugin-dir ./netsec-skills` and check if `/nmap` works or if it requires `/tools/nmap`. If namespacing occurs, the `name` field in SKILL.md frontmatter should override the directory-derived name.
**Warning signs:** Slash commands require the category prefix (e.g., `/tools/nmap` instead of `/nmap`).

### Pitfall 4: GSD files leaking into plugin via symlinks
**What goes wrong:** A symlink accidentally points to a GSD-related file or directory.
**Why it happens:** Manual symlink creation is error-prone with 31 links to create.
**How to avoid:** Use the validation script (Pattern 5) after scaffold creation. Also explicitly enumerate only the 28 included skills -- never glob `.claude/skills/*`.
**Warning signs:** Validation script reports `gsd-` prefixed files or unexpected file types.

### Pitfall 5: hooks.json referencing $CLAUDE_PROJECT_DIR instead of $CLAUDE_PLUGIN_ROOT
**What goes wrong:** Plugin hooks fail to find their scripts when installed via marketplace (cached to `~/.claude/plugins/cache/`).
**Why it happens:** Copy-pasting from the repo-local `.claude/settings.json` hook registration.
**How to avoid:** Plugin hooks.json MUST use `${CLAUDE_PLUGIN_ROOT}` for script paths. Internal hook logic using `$CLAUDE_PROJECT_DIR` is a separate concern (Phase 35).
**Warning signs:** Hooks fire but get "command not found" or "no such file" errors.

### Pitfall 6: macOS Bash 3.2 incompatibility
**What goes wrong:** `netsec-pretool.sh` uses `declare -A` (associative arrays) which requires Bash 4.0+. macOS ships with Bash 3.2.
**Why it happens:** macOS bundles an old Bash due to GPLv3 licensing. Homebrew Bash is 5.x but not the default.
**How to avoid:** The hook already uses `#!/usr/bin/env bash` which picks up Homebrew bash if installed. The `netsec-health.sh` script checks `bash version >= 4.0` and warns. This is an existing concern, not new to the plugin -- documented in STATE.md blockers.
**Warning signs:** netsec-health.sh reports "[FAIL] bash version >= 4.0 (associative arrays)."

## Code Examples

Verified patterns from official sources:

### Creating the full skill symlink tree

```bash
# Source: Project-specific pattern based on official docs symlink guidance
# https://code.claude.com/docs/en/plugins-reference#plugin-caching-and-file-resolution

PLUGIN_DIR="netsec-skills"

# Create directory structure
mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$PLUGIN_DIR/skills/tools"
mkdir -p "$PLUGIN_DIR/skills/workflows"
mkdir -p "$PLUGIN_DIR/skills/agents"
mkdir -p "$PLUGIN_DIR/skills/utility"
mkdir -p "$PLUGIN_DIR/agents"
mkdir -p "$PLUGIN_DIR/hooks"
mkdir -p "$PLUGIN_DIR/scripts"

# Tool skills (17 total)
TOOL_SKILLS=(nmap tshark metasploit aircrack-ng hashcat skipfish sqlmap hping3 john nikto foremost dig curl netcat traceroute gobuster ffuf)
for skill in "${TOOL_SKILLS[@]}"; do
  ln -s "../../../.claude/skills/$skill" "$PLUGIN_DIR/skills/tools/$skill"
done

# Workflow skills (6 total)
WORKFLOW_SKILLS=(recon scan fuzz crack sniff diagnose)
for skill in "${WORKFLOW_SKILLS[@]}"; do
  ln -s "../../../.claude/skills/$skill" "$PLUGIN_DIR/skills/workflows/$skill"
done

# Agent invoker skills (3 total)
AGENT_SKILLS=(pentester defender analyst)
for skill in "${AGENT_SKILLS[@]}"; do
  ln -s "../../../.claude/skills/$skill" "$PLUGIN_DIR/skills/agents/$skill"
done

# Utility skills (4 total)
UTILITY_SKILLS=(scope netsec-health check-tools report)
for skill in "${UTILITY_SKILLS[@]}"; do
  ln -s "../../../.claude/skills/$skill" "$PLUGIN_DIR/skills/utility/$skill"
done

# Agent definitions (3 total -- these are .md files, not skill directories)
for agent in pentester defender analyst; do
  ln -s "../../.claude/agents/$agent.md" "$PLUGIN_DIR/agents/$agent.md"
done

# Copy hooks as-is (Phase 35 modifies for portability)
cp .claude/hooks/netsec-pretool.sh "$PLUGIN_DIR/hooks/"
cp .claude/hooks/netsec-posttool.sh "$PLUGIN_DIR/hooks/"
cp .claude/hooks/netsec-health.sh "$PLUGIN_DIR/hooks/"
chmod +x "$PLUGIN_DIR/hooks/"*.sh
```

### Verifying the scaffold

```bash
# Verify all symlinks resolve
echo "=== Checking symlinks ==="
find netsec-skills -type l | while read link; do
  if [[ ! -e "$link" ]]; then
    echo "BROKEN: $link -> $(readlink "$link")"
  else
    echo "OK: $link"
  fi
done

# Verify plugin loads
echo "=== Testing plugin load ==="
claude --plugin-dir ./netsec-skills --print "List all available skills" 2>&1 | head -20

# Verify no GSD files
echo "=== Checking GSD boundary ==="
find netsec-skills -name "gsd-*" -o -name "*.js"
# Should output nothing
```

### Complete marketplace.json structure

```json
{
  "name": "netsec-skills",
  "version": "1.0.0",
  "description": "Pentesting skills pack -- 17 tool skills, 6 workflows, 3 agent personas for network security testing with Claude Code",
  "skills": [
    { "name": "nmap", "type": "tool", "trigger": "/nmap", "description": "Network scanning and host discovery using nmap wrapper scripts", "tags": ["network", "scanning", "discovery", "ports"], "requires": "nmap" },
    { "name": "tshark", "type": "tool", "trigger": "/tshark", "description": "Packet capture and network traffic analysis using tshark wrapper scripts", "tags": ["traffic", "capture", "packets", "wireshark"], "requires": "tshark" },
    { "name": "metasploit", "type": "tool", "trigger": "/metasploit", "description": "Exploitation framework wrapper scripts for payloads, scanning, and listeners", "tags": ["exploitation", "payloads", "shells", "msfconsole"], "requires": "msfconsole" },
    { "name": "aircrack-ng", "type": "tool", "trigger": "/aircrack-ng", "description": "WiFi security auditing and WPA cracking using aircrack-ng wrapper scripts", "tags": ["wifi", "wireless", "WPA", "handshake"], "requires": "aircrack-ng" },
    { "name": "hashcat", "type": "tool", "trigger": "/hashcat", "description": "GPU-accelerated password hash cracking using hashcat wrapper scripts", "tags": ["password", "hash", "cracking", "GPU", "NTLM"], "requires": "hashcat" },
    { "name": "skipfish", "type": "tool", "trigger": "/skipfish", "description": "Active web application security scanner using skipfish wrapper scripts", "tags": ["web", "scanner", "crawler", "application"], "requires": "skipfish" },
    { "name": "sqlmap", "type": "tool", "trigger": "/sqlmap", "description": "SQL injection detection and database extraction using sqlmap wrapper scripts", "tags": ["SQL", "injection", "database", "exploitation"], "requires": "sqlmap" },
    { "name": "hping3", "type": "tool", "trigger": "/hping3", "description": "TCP/IP packet crafting and firewall testing using hping3 wrapper scripts", "tags": ["packets", "firewall", "TCP", "crafting"], "requires": "hping3" },
    { "name": "john", "type": "tool", "trigger": "/john", "description": "Password hash cracking and identification using John the Ripper wrapper scripts", "tags": ["password", "hash", "cracking", "john"], "requires": "john" },
    { "name": "nikto", "type": "tool", "trigger": "/nikto", "description": "Web server vulnerability scanning using nikto wrapper scripts", "tags": ["web", "server", "vulnerabilities", "scanning"], "requires": "nikto" },
    { "name": "foremost", "type": "tool", "trigger": "/foremost", "description": "File carving and forensic data recovery using foremost wrapper scripts", "tags": ["forensics", "carving", "recovery", "files"], "requires": "foremost" },
    { "name": "dig", "type": "tool", "trigger": "/dig", "description": "DNS record querying and zone transfer testing using dig wrapper scripts", "tags": ["DNS", "records", "zone-transfer", "nameserver"], "requires": "dig" },
    { "name": "curl", "type": "tool", "trigger": "/curl", "description": "HTTP request debugging and SSL inspection using curl wrapper scripts", "tags": ["HTTP", "SSL", "TLS", "requests", "headers"], "requires": "curl" },
    { "name": "netcat", "type": "tool", "trigger": "/netcat", "description": "TCP/UDP networking swiss-army knife using netcat wrapper scripts", "tags": ["TCP", "UDP", "networking", "connections", "listener"], "requires": "nc" },
    { "name": "traceroute", "type": "tool", "trigger": "/traceroute", "description": "Network path tracing and latency diagnosis using traceroute and mtr wrapper scripts", "tags": ["network", "path", "latency", "hops", "routing"], "requires": "traceroute" },
    { "name": "gobuster", "type": "tool", "trigger": "/gobuster", "description": "Directory and subdomain brute-forcing using gobuster wrapper scripts", "tags": ["directory", "subdomain", "brute-force", "enumeration"], "requires": "gobuster" },
    { "name": "ffuf", "type": "tool", "trigger": "/ffuf", "description": "Web fuzzing for parameters, directories, and endpoints using ffuf wrapper scripts", "tags": ["fuzzing", "web", "parameters", "brute-force"], "requires": "ffuf" },
    { "name": "recon", "type": "workflow", "trigger": "/recon", "description": "Run reconnaissance workflow -- host discovery, DNS enumeration, and OSINT gathering", "tags": ["reconnaissance", "discovery", "enumeration", "OSINT"] },
    { "name": "scan", "type": "workflow", "trigger": "/scan", "description": "Run vulnerability scanning workflow -- port scans, web vulnerability scans, and SQL injection testing", "tags": ["vulnerability", "scanning", "assessment", "CVE"] },
    { "name": "fuzz", "type": "workflow", "trigger": "/fuzz", "description": "Run fuzzing workflow -- directory brute-force, parameter fuzzing, and web scanning", "tags": ["fuzzing", "brute-force", "parameters", "discovery"] },
    { "name": "crack", "type": "workflow", "trigger": "/crack", "description": "Run password cracking workflow -- hash identification, dictionary attacks, and brute force", "tags": ["password", "cracking", "hashes", "dictionary"] },
    { "name": "sniff", "type": "workflow", "trigger": "/sniff", "description": "Run traffic capture and analysis workflow -- HTTP credentials, DNS queries, and file extraction", "tags": ["traffic", "capture", "credentials", "analysis"] },
    { "name": "diagnose", "type": "workflow", "trigger": "/diagnose", "description": "Run network diagnostic workflow -- DNS, connectivity, and latency checks", "tags": ["diagnostics", "DNS", "connectivity", "latency"] },
    { "name": "scope", "type": "utility", "trigger": "/scope", "description": "Define and manage target scope for pentesting engagements", "tags": ["scope", "targets", "management", "safety"] },
    { "name": "netsec-health", "type": "utility", "trigger": "/netsec-health", "description": "Check that all pentesting safety hooks are installed and working", "tags": ["health", "safety", "hooks", "diagnostics"] },
    { "name": "check-tools", "type": "utility", "trigger": "/check-tools", "description": "Check which pentesting tools are installed on this system", "tags": ["tools", "installation", "detection", "setup"] },
    { "name": "report", "type": "utility", "trigger": "/report", "description": "Generate a structured pentesting findings report from the current session", "tags": ["report", "findings", "summary", "deliverable"] }
  ],
  "hooks": [
    {
      "name": "netsec-pretool",
      "event": "PreToolUse",
      "description": "Target allowlist validation and raw tool interception -- blocks out-of-scope targets and direct tool calls",
      "file": "hooks/netsec-pretool.sh"
    },
    {
      "name": "netsec-posttool",
      "event": "PostToolUse",
      "description": "Audit logging and JSON bridge -- logs tool executions and injects structured context from JSON output",
      "file": "hooks/netsec-posttool.sh"
    }
  ],
  "agents": [
    {
      "name": "pentester",
      "description": "Offensive pentesting specialist for multi-tool attack workflow orchestration",
      "file": "agents/pentester.md"
    },
    {
      "name": "defender",
      "description": "Defensive security analyst for remediation guidance and risk assessment",
      "file": "agents/defender.md"
    },
    {
      "name": "analyst",
      "description": "Security analysis specialist for structured report synthesis across multiple scans",
      "file": "agents/analyst.md"
    }
  ]
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `commands/` directory for slash commands | `skills/` directory with `SKILL.md` subdirectories | 2025 (Claude Code plugin format evolution) | Use `skills/` not `commands/` for new plugins; `commands/` is legacy |
| settings.json hook registration | `hooks/hooks.json` in plugin root | 2025 (plugin format standardization) | Plugin hooks are auto-discovered from hooks.json, not configured in settings.json |
| `$CLAUDE_PROJECT_DIR` for all paths | `${CLAUDE_PLUGIN_ROOT}` for plugin-internal paths | 2025 (plugin portability) | Scripts within plugins MUST use `${CLAUDE_PLUGIN_ROOT}`; `$CLAUDE_PROJECT_DIR` is for repo context |
| Monolithic skill directories | Category-grouped skill subdirectories | Project-specific decision | Improves organization for 28+ skills; verify Claude Code discovers nested skills correctly |

**Deprecated/outdated:**
- `commands/` directory: Still supported but legacy. All new plugins should use `skills/` with `SKILL.md` structure.
- Inline hooks in plugin.json: Supported but `hooks/hooks.json` is the cleaner approach for separation of concerns.

## GSD File Inventory (Must Be Excluded)

Complete list of GSD framework files in `.claude/` that MUST NOT appear in `netsec-skills/`:

| Location | Files | Type |
|----------|-------|------|
| `.claude/agents/` | `gsd-codebase-mapper.md`, `gsd-debugger.md`, `gsd-executor.md`, `gsd-integration-checker.md`, `gsd-nyquist-auditor.md`, `gsd-phase-researcher.md`, `gsd-plan-checker.md`, `gsd-planner.md`, `gsd-project-researcher.md`, `gsd-research-synthesizer.md`, `gsd-roadmapper.md`, `gsd-verifier.md` | 12 GSD agents |
| `.claude/hooks/` | `gsd-check-update.js`, `gsd-context-monitor.js`, `gsd-statusline.js` | 3 GSD hooks |
| `.claude/get-shit-done/` | Entire directory (bin/, references/, templates/, workflows/, VERSION) | GSD framework |
| `.claude/settings.json` | Contains GSD hook registrations (SessionStart, PostToolUse context-monitor) | Config file (not copied) |

**Verification approach:** The allowlist script checks both:
1. Only permitted file patterns exist in the plugin directory
2. Zero files with `gsd-` prefix exist anywhere in the plugin directory

## Open Questions

1. **Skill namespace with category subdirectories**
   - What we know: Claude Code scans `skills/` recursively for `SKILL.md` files. The SKILL.md `name` field should define the skill identifier.
   - What's unclear: Whether `skills/tools/nmap/SKILL.md` will register as `/nmap` (from the `name` field) or `/tools/nmap` (from the directory path). With the plugin namespace, it could become `netsec-skills:nmap` or `netsec-skills:tools/nmap`.
   - Recommendation: Create the scaffold with category subdirectories as decided, then empirically test with `claude --plugin-dir ./netsec-skills`. If namespacing is wrong, the SKILL.md `name` field likely overrides it. Document findings for Phase 36.

2. **Plugin name appears in skill namespace**
   - What we know: Official docs say "the agent `agent-creator` for the plugin with name `plugin-dev` will appear as `plugin-dev:agent-creator`." This applies to agents; unclear if skills follow the same pattern.
   - What's unclear: Whether `/nmap` becomes `/netsec-skills:nmap` in plugin context.
   - Recommendation: Test during Phase 34 scaffold verification. This is informational, not blocking -- the skill still works regardless of the displayed name.

3. **Agent skill references in plugin context**
   - What we know: Agent .md files reference skills by name (e.g., `skills: [recon, scan, fuzz]` in pentester.md). Skills also reference `pentest-conventions` which is excluded from the plugin.
   - What's unclear: Whether skill references in agent definitions resolve correctly when skills are nested in category subdirectories. Also, `pentester` agent preloads `pentest-conventions` which won't exist in the plugin.
   - Recommendation: This is Phase 38's concern (AGEN-01, AGEN-02). For Phase 34, symlink the agent files as-is. Phase 38 will modify agent definitions to remove `pentest-conventions` dependency and fix skill references.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash scripts + jq (no test framework needed -- this is scaffolding) |
| Config file | None |
| Quick run command | `bash scripts/validate-plugin-boundary.sh` |
| Full suite command | `bash scripts/validate-plugin-boundary.sh && claude plugin validate netsec-skills/` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLUG-01 | Plugin loads via --plugin-dir | smoke | `claude --plugin-dir ./netsec-skills --print "List skills" 2>&1 \| grep -q nmap` | No -- Wave 0 |
| PLUG-02 | marketplace.json lists all 28 skills, 2 hooks, 3 agents | unit | `jq '.skills \| length' netsec-skills/marketplace.json` (expect 27) + `jq '.hooks \| length'` (expect 2) + `jq '.agents \| length'` (expect 3) | No -- Wave 0 |
| PLUG-03 | Zero GSD files in plugin directory | unit | `bash scripts/validate-plugin-boundary.sh` (exit code 0 = pass) | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `bash scripts/validate-plugin-boundary.sh`
- **Per wave merge:** Full validation + `claude plugin validate netsec-skills/`
- **Phase gate:** All validations pass + manual `claude --plugin-dir` smoke test

### Wave 0 Gaps
- [ ] `scripts/validate-plugin-boundary.sh` -- GSD boundary allowlist enforcement script
- [ ] Verify `claude plugin validate` accepts the scaffold (no framework install needed)

## Sources

### Primary (HIGH confidence)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Complete plugin.json schema, directory structure, hook configuration, `${CLAUDE_PLUGIN_ROOT}` usage, symlink behavior during cache copy
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) -- marketplace.json schema, distribution formats, plugin entry structure
- [Claude Code GitHub plugins/README.md](https://github.com/anthropics/claude-code/blob/main/plugins/README.md) -- Standard plugin layout, naming conventions, component organization

### Secondary (MEDIUM confidence)
- [Vercel skills CLI](https://github.com/vercel-labs/skills) -- skills.sh discovery mechanism, SKILL.md format, marketplace.json integration for skills installer
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- hooks.json format, event types, matcher patterns, stdin JSON schema

### Tertiary (LOW confidence)
- Skill namespace behavior with category subdirectories -- only training data; needs empirical testing (flagged in Open Questions)
- Plugin name prefix on skill invocation -- official docs confirm for agents, unclear for skills (flagged in Open Questions)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Plugin format is well-documented by Anthropic with complete schema reference
- Architecture: HIGH -- Directory structure follows official spec exactly; symlink strategy is a standard POSIX pattern
- Pitfalls: HIGH -- Most pitfalls are documented in official troubleshooting; namespace question is flagged as needing validation
- GSD boundary: HIGH -- Complete inventory of GSD files confirmed by filesystem scan; allowlist approach is deterministic

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (plugin format is stable; 30-day validity)
