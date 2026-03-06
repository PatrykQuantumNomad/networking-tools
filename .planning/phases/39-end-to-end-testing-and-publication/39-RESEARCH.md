# Phase 39: End-to-End Testing and Publication - Research

**Researched:** 2026-03-06
**Domain:** Claude Code plugin publication, skills.sh distribution, E2E testing
**Confidence:** MEDIUM (skills.sh auto-discovery is not fully documented; plugin marketplace format is well-documented)

## Summary

Phase 39 is the final phase of v1.6. The netsec-skills/ plugin directory is fully built (Phases 34-38): 27 SKILL.md files, 3 agent persona files, 2 hook scripts, scope management script, health check, plugin.json manifest, marketplace.json catalog, and README. All files are real copies (zero symlinks). The remaining work is (1) validating the plugin works via both distribution channels, (2) publication mechanics, and (3) a comprehensive E2E test to verify fresh install works end-to-end.

There are two completely independent distribution channels that must both work: **skills.sh** (`npx skills add`) and **Claude Code plugin marketplace** (`/plugin install`). These channels have different discovery mechanisms, different installation paths, and different namespacing behaviors. Skills.sh installs individual SKILL.md files directly into `.claude/skills/` (flat, no namespace prefix). Plugin marketplace installs the full plugin directory and namespaces skills as `netsec-skills:skill-name`. Both channels use the GitHub repo as source, but process it differently.

**Primary recommendation:** Create a pre-publish validation script that simulates both installation paths locally, run boundary enforcement, then publish by pushing to GitHub (skills.sh appears automatically via telemetry when users install; plugin marketplace requires either a self-hosted marketplace.json or submission to Anthropic's official marketplace).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLUG-04 | User can install skills via both `npx skills add` (skills.sh) and plugin marketplace | Two-channel distribution pattern: skills.sh discovers SKILL.md files from repo, plugin marketplace uses .claude-plugin/plugin.json; both sourced from same GitHub repo |
| PUBL-01 | End-to-end standalone installation works: `npx skills add PatrykQuantumNomad/networking-tools` installs all skills | skills.sh CLI discovers SKILL.md files in skills/ directories AND .claude-plugin/marketplace.json; installation creates symlinks (or copies with --copy flag) into target agent's skills directory |
| PUBL-02 | Plugin installation works: skills, hooks, and agents function correctly after plugin install | Plugin loaded via `claude --plugin-dir ./netsec-skills` for local test, or via marketplace for distribution; hooks loaded from hooks/hooks.json; agents from agents/ directory |
| PUBL-03 | Skills appear on skills.sh/patrykquantumnomad/networking-tools | skills.sh listings appear automatically via anonymous telemetry when users run `npx skills add`; no separate publish step needed; first install triggers indexing |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `npx skills` | latest (npm) | skills.sh CLI for discovery and installation | Official Vercel-maintained CLI; supports 40+ agents |
| `claude --plugin-dir` | Claude Code 1.0.33+ | Local plugin testing | Official testing mechanism; loads plugin without installation |
| `claude plugin validate` | Claude Code 1.0.33+ | Manifest validation | Official validation tool; checks plugin.json and directory structure |
| `bash` + `jq` | bash 3.2+, jq 1.6+ | Build/validation scripts | Already used throughout project; macOS compatible |
| BATS | via submodule | Automated structural tests | Already used in Phases 36-38 for skill validation |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `scripts/validate-plugin-boundary.sh` | GSD boundary enforcement | Pre-publish check; already exists from Phase 34 |
| `gh` (GitHub CLI) | Repository operations | If needed for marketplace setup or PR automation |
| `find` + `diff` | File comparison | E2E validation of installed vs source files |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Self-hosted marketplace | Anthropic official marketplace | Official marketplace requires submission form at claude.ai/settings/plugins/submit; self-hosted marketplace via repo is immediate and self-controlled |
| npm package for plugin | GitHub-sourced plugin | npm source supported but unnecessary complexity; GitHub source is simpler and already how the project is hosted |

## Architecture Patterns

### Two-Channel Distribution Model

The netsec-skills/ directory serves both distribution channels from the same GitHub repo:

```
PatrykQuantumNomad/networking-tools (GitHub repo)
    |
    +-- npx skills add PatrykQuantumNomad/networking-tools
    |     |
    |     +-- skills.sh CLI scans for SKILL.md files
    |     +-- Finds files in: netsec-skills/skills/**/ AND .claude/skills/**/
    |     +-- Also reads .claude-plugin/marketplace.json if present
    |     +-- Installs SKILL.md files to user's .claude/skills/ or project .claude/skills/
    |     +-- Skills accessed as /nmap, /recon, etc. (no namespace prefix)
    |
    +-- /plugin marketplace add PatrykQuantumNomad/networking-tools
    |     |
    |     +-- Claude Code reads .claude-plugin/marketplace.json
    |     +-- marketplace.json points to netsec-skills/ as plugin source
    |     +-- Plugin installed to ~/.claude/plugins/cache/
    |     +-- Skills accessed as /netsec-skills:nmap, /netsec-skills:recon, etc.
    |     +-- Hooks, agents loaded from plugin directory
    |
    +-- claude --plugin-dir ./netsec-skills (local dev testing)
          |
          +-- Reads .claude-plugin/plugin.json directly
          +-- Loads all components from plugin root
          +-- Skills namespaced as /netsec-skills:skill-name
```

### Pattern 1: skills.sh Discovery Mechanism
**What:** The `npx skills` CLI discovers SKILL.md files by scanning known directories in a repo. It checks `skills/`, `.claude/skills/`, `.agents/skills/`, and 30+ agent-specific paths. It also reads `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` for declared skills.
**When to use:** For understanding how skills are found during `npx skills add`
**Key insight:** Since our SKILL.md files live in `netsec-skills/skills/` (under the plugin root), skills.sh will discover them via the `.claude-plugin/marketplace.json` compatibility path. The CLI also supports `--list` to preview what will be installed without actually installing.

### Pattern 2: Plugin Marketplace Self-Hosting
**What:** Any GitHub repo with `.claude-plugin/marketplace.json` can serve as its own plugin marketplace. Users add it with `/plugin marketplace add owner/repo`.
**When to use:** For distributing the plugin through Claude Code's plugin system
**Key insight:** The existing `.claude-plugin/marketplace.json` in the repo root (currently at `netsec-skills/.claude-plugin/`) needs to either be at the repo root OR the marketplace needs a source path pointing to `netsec-skills/`.

### Pattern 3: E2E Test Script Structure
**What:** A bash script that simulates fresh install, runs health checks, and validates all components work
**When to use:** Pre-publish and as a regression test

```bash
#!/usr/bin/env bash
# test-e2e-plugin.sh -- End-to-end plugin validation
set -euo pipefail

PLUGIN_DIR="${1:-netsec-skills}"
PASS=0
FAIL=0

# Test 1: Plugin manifest validation
echo "--- Test: Plugin manifest valid ---"
if claude plugin validate "$PLUGIN_DIR" 2>/dev/null; then
    echo "  PASS"; PASS=$((PASS + 1))
else
    echo "  FAIL"; FAIL=$((FAIL + 1))
fi

# Test 2: All SKILL.md files have required frontmatter
echo "--- Test: SKILL.md frontmatter ---"
# ... check name: and description: fields in all SKILL.md files

# Test 3: Hooks are executable
echo "--- Test: Hook executability ---"
# ... check chmod +x on hook scripts

# Test 4: No GSD files (boundary check)
echo "--- Test: GSD boundary ---"
bash scripts/validate-plugin-boundary.sh "$PLUGIN_DIR"

# Test 5: JSON files valid
# Test 6: marketplace.json skill count matches actual skills
# Test 7: All agents referenced in marketplace.json exist
# ... etc
```

### Pattern 4: Marketplace JSON at Repo Root
**What:** For the plugin marketplace channel, `.claude-plugin/marketplace.json` must exist at the repo root level (not inside netsec-skills/)
**When to use:** When setting up marketplace distribution
**Key insight:** There is a critical structural decision here. Currently, `.claude-plugin/plugin.json` lives inside `netsec-skills/.claude-plugin/`. For marketplace distribution from the repo root, we need EITHER:
  - (A) A **repo-root** `.claude-plugin/marketplace.json` that points to `"source": "./netsec-skills"` as the plugin
  - (B) Users add the marketplace pointing directly to the netsec-skills subdirectory

Option A is cleaner: a repo-root marketplace.json pointing to the plugin subdirectory. The existing `netsec-skills/marketplace.json` is a content catalog (not a plugin marketplace file) -- it lists skills/hooks/agents for human reference. The actual plugin marketplace needs to be at `.claude-plugin/marketplace.json` in the repo root.

### Anti-Patterns to Avoid
- **Conflicting marketplace.json files:** The `netsec-skills/marketplace.json` is a content catalog, NOT a Claude Code marketplace. Do not confuse them. The repo-root `.claude-plugin/marketplace.json` is the actual plugin marketplace file.
- **Installing both channels simultaneously:** Users should use ONE channel. skills.sh gives flat skills (no hooks/agents). Plugin marketplace gives the full package (skills + hooks + agents). The README should guide users to choose.
- **Hardcoded absolute paths in hooks:** All hook scripts already use `${CLAUDE_PLUGIN_ROOT}` for portable resolution. Verified in Phase 35.
- **Bumping version before testing:** Always run the full E2E suite before incrementing version in plugin.json.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plugin manifest validation | Custom JSON schema checker | `claude plugin validate .` | Official tool catches structural issues the spec defines |
| SKILL.md frontmatter parsing | Custom YAML parser | Existing BATS awk-based extractors from Phase 36 tests | Already proven and macOS-compatible |
| skills.sh listing | Manual registry submission | Push to GitHub + first `npx skills add` triggers auto-indexing | No separate publish step exists; telemetry-based |
| Plugin distribution hosting | Custom server | GitHub repo as marketplace source | Claude Code natively supports `owner/repo` format |

**Key insight:** skills.sh has no publish step. Skills appear on the leaderboard automatically through anonymous telemetry when users install. The "publication" for skills.sh is simply making the repo public and documenting the install command. The plugin marketplace channel requires a marketplace.json at the repo root.

## Common Pitfalls

### Pitfall 1: Marketplace JSON Location Confusion
**What goes wrong:** The repo has TWO files that could be confused as "marketplace.json": (1) `netsec-skills/marketplace.json` (content catalog for human reference) and (2) the needed `.claude-plugin/marketplace.json` at repo root (actual plugin marketplace).
**Why it happens:** Phase 34 created the content catalog inside the plugin directory. Plugin marketplace distribution requires a DIFFERENT file at the repo root.
**How to avoid:** Create `.claude-plugin/marketplace.json` at the repo root with proper marketplace schema (name, owner, plugins array with source pointing to `./netsec-skills`). Leave the existing `netsec-skills/marketplace.json` as-is -- it serves a different purpose.
**Warning signs:** `claude plugin validate` fails on the repo root, or `/plugin marketplace add` can't find any plugins.

### Pitfall 2: Skills.sh Discovers In-Repo AND Plugin Skills
**What goes wrong:** `npx skills add PatrykQuantumNomad/networking-tools` might discover SKILL.md files from BOTH `.claude/skills/` (in-repo) AND `netsec-skills/skills/` (plugin). Users get duplicate skill installations.
**Why it happens:** The skills.sh CLI recursively searches for SKILL.md files in known directories. Both paths contain identical skills.
**How to avoid:** The `npx skills add` command offers `--list` to preview discovered skills. Test with `npx skills add PatrykQuantumNomad/networking-tools --list` before publishing. If duplicates appear, use the `--skill` flag to select specific skills, OR configure which directory skills.sh should prioritize. The `.claude-plugin/plugin.json` in `netsec-skills/` should help skills.sh prefer the plugin path.
**Warning signs:** `--list` output shows 54+ skills instead of 27.

### Pitfall 3: ${CLAUDE_PLUGIN_ROOT} Not Set During Local Testing
**What goes wrong:** Hooks reference `${CLAUDE_PLUGIN_ROOT}` but the variable isn't set when testing outside the plugin system (e.g., running hooks directly).
**Why it happens:** `${CLAUDE_PLUGIN_ROOT}` is only set by Claude Code when loading a plugin via `--plugin-dir` or installed via marketplace.
**How to avoid:** Already handled in Phase 35 -- hooks fall back to script directory resolution when the variable isn't set. Verify this fallback works in E2E tests.
**Warning signs:** Hook scripts exit with "file not found" errors.

### Pitfall 4: Plugin Cache Stale After Updates
**What goes wrong:** After updating plugin files and testing with `claude --plugin-dir`, changes work. But marketplace-installed users don't see updates.
**Why it happens:** Marketplace plugins are cached at `~/.claude/plugins/cache/`. Version must be bumped in plugin.json for cache invalidation.
**How to avoid:** Always bump version in `netsec-skills/.claude-plugin/plugin.json` before announcing updates. Use semver properly.
**Warning signs:** Users report old behavior despite repo being updated.

### Pitfall 5: skills.sh Channel Lacks Hooks and Agents
**What goes wrong:** Users install via `npx skills add` expecting full functionality but don't get safety hooks or agent personas.
**Why it happens:** skills.sh installs SKILL.md files only -- it doesn't install hooks, agents, or scripts. Only the plugin marketplace channel provides the full package.
**How to avoid:** README must clearly explain the two channels and what each provides. Recommend the plugin channel for full functionality. skills.sh channel is for "skills only" users who want individual skills without the full infrastructure.
**Warning signs:** Users report `/netsec-health` failing because hooks aren't installed.

### Pitfall 6: Skill Namespace Differences Between Channels
**What goes wrong:** Skills installed via skills.sh are accessed as `/nmap`, `/recon`, etc. Skills from the plugin marketplace are accessed as `/netsec-skills:nmap`, `/netsec-skills:recon`, etc.
**Why it happens:** Plugin marketplace namespaces all skills under the plugin name. skills.sh installs them flat.
**How to avoid:** Document both access patterns in README. The SKILL.md content works identically regardless of namespace -- only the trigger differs.
**Warning signs:** Documentation says `/nmap` but plugin users need `/netsec-skills:nmap`.

## Code Examples

### Repo-Root Marketplace JSON for Plugin Distribution

```json
// File: .claude-plugin/marketplace.json (at REPO ROOT, not inside netsec-skills/)
// Source: https://code.claude.com/docs/en/plugin-marketplaces
{
  "name": "netsec-tools",
  "owner": {
    "name": "PatrykQuantumNomad",
    "email": ""
  },
  "metadata": {
    "description": "Pentesting skills pack for Claude Code"
  },
  "plugins": [
    {
      "name": "netsec-skills",
      "source": "./netsec-skills",
      "description": "17 tool skills, 6 workflows, 3 agent personas for network security testing",
      "version": "1.0.0",
      "homepage": "https://github.com/PatrykQuantumNomad/networking-tools",
      "repository": "https://github.com/PatrykQuantumNomad/networking-tools",
      "license": "MIT",
      "keywords": ["pentesting", "security", "nmap", "sqlmap", "hashcat", "metasploit"],
      "category": "security",
      "tags": ["pentesting", "red-team", "CTF", "network-security"]
    }
  ]
}
```

### E2E Validation Script Structure

```bash
#!/usr/bin/env bash
# scripts/test-e2e-publication.sh
set -euo pipefail

PLUGIN_DIR="${1:-netsec-skills}"
PASS=0; FAIL=0; TOTAL=0

_check() {
    TOTAL=$((TOTAL + 1))
    if eval "$2" > /dev/null 2>&1; then
        echo "  PASS: $1"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $1"; FAIL=$((FAIL + 1))
    fi
}

echo "=== E2E Publication Validation ==="

# Structural checks
_check "plugin.json exists" "test -f $PLUGIN_DIR/.claude-plugin/plugin.json"
_check "plugin.json valid JSON" "jq . $PLUGIN_DIR/.claude-plugin/plugin.json"
_check "marketplace.json valid JSON" "jq . $PLUGIN_DIR/marketplace.json"
_check "hooks.json valid JSON" "jq . $PLUGIN_DIR/hooks/hooks.json"

# Skill count verification
_check "27 SKILL.md files present" \
    '[ "$(find $PLUGIN_DIR/skills -name SKILL.md | wc -l | tr -d " ")" -eq 27 ]'

# Frontmatter validation (every SKILL.md has name: and description:)
_check "All SKILL.md have name: field" \
    '! find $PLUGIN_DIR/skills -name SKILL.md -exec grep -L "^name:" {} +'

# Hook executability
_check "pretool hook executable" "test -x $PLUGIN_DIR/hooks/netsec-pretool.sh"
_check "posttool hook executable" "test -x $PLUGIN_DIR/hooks/netsec-posttool.sh"

# Agent files
_check "3 agent files present" \
    '[ "$(ls $PLUGIN_DIR/agents/*.md 2>/dev/null | wc -l | tr -d " ")" -eq 3 ]'

# GSD boundary
_check "GSD boundary clean" "bash scripts/validate-plugin-boundary.sh $PLUGIN_DIR"

# Zero symlinks
_check "No symlinks remain" \
    '[ "$(find $PLUGIN_DIR -type l | wc -l | tr -d " ")" -eq 0 ]'

# Summary
echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

### skills.sh Preview Command

```bash
# Preview what skills.sh discovers before actually installing
npx skills add PatrykQuantumNomad/networking-tools --list

# Install all skills for Claude Code only
npx skills add PatrykQuantumNomad/networking-tools -a claude-code --all -y

# Install specific skills
npx skills add PatrykQuantumNomad/networking-tools --skill nmap --skill recon -a claude-code
```

### Plugin Marketplace Distribution Commands

```bash
# Users add the marketplace
/plugin marketplace add PatrykQuantumNomad/networking-tools

# Users install the plugin
/plugin install netsec-skills@netsec-tools

# Or if submitted to official Anthropic marketplace:
/plugin install netsec-skills@claude-plugins-official
```

### Local Plugin Testing

```bash
# Test locally before any publication
claude --plugin-dir ./netsec-skills

# Inside Claude Code, verify skills are namespaced:
/netsec-skills:netsec-health
/netsec-skills:scope init
/netsec-skills:nmap
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual skill file copying | `npx skills add owner/repo` | Jan 2026 (skills.sh launch) | One-command installation from any GitHub repo |
| No plugin system | `claude plugin install` + marketplaces | Claude Code 1.0.33+ (early 2026) | Full plugin distribution with hooks, agents, MCP servers |
| Single channel (in-repo only) | Two-channel distribution (skills.sh + marketplace) | Current | Users choose: skills-only (lightweight) or full plugin (hooks+agents+skills) |

**Deprecated/outdated:**
- Symlinks in plugin directories: Replaced with real copies in Phase 36-38 for portability
- `declare -A` in bash scripts: Replaced with case statements for bash 3.2 macOS compatibility (Phase 35)

## Open Questions

1. **skills.sh duplicate discovery**
   - What we know: skills.sh scans multiple directories for SKILL.md files. Our repo has identical skills in both `.claude/skills/` and `netsec-skills/skills/`.
   - What's unclear: Will `npx skills add` show duplicates? Does the `.claude-plugin/plugin.json` cause skills.sh to treat the plugin as a single unit?
   - Recommendation: Run `npx skills add PatrykQuantumNomad/networking-tools --list` empirically during E2E testing. If duplicates appear, consider adding `metadata.internal: true` to the `.claude/skills/` copies to hide them from skills.sh discovery, or use a `.skillsignore` mechanism if one exists.

2. **Plugin marketplace: self-hosted vs official**
   - What we know: Self-hosted marketplace works immediately via GitHub repo. Official Anthropic marketplace requires submission at claude.ai/settings/plugins/submit.
   - What's unclear: Review timeline for official marketplace submission. Whether the netsec domain (security tools) has special review requirements.
   - Recommendation: Start with self-hosted marketplace (repo-root `.claude-plugin/marketplace.json`). Submit to official marketplace as a follow-up (can be async, not blocking Phase 39 completion). Document both installation paths.

3. **${CLAUDE_PLUGIN_ROOT} known bugs**
   - What we know: Issue #18527 (Windows path separators) and #27145 (SessionStart hook timing).
   - What's unclear: Whether these affect macOS/Linux plugin installations for E2E testing.
   - Recommendation: Test on macOS (the primary platform). Windows is explicitly out of scope per REQUIREMENTS.md. SessionStart issue should not affect PreToolUse/PostToolUse hooks.

4. **SKILL.md frontmatter field: name vs directory name**
   - What we know: Claude Code uses directory name as skill name if `name:` is omitted from frontmatter. Plugin skills are namespaced as `plugin-name:skill-name`.
   - What's unclear: Whether skills.sh prioritizes `name:` from frontmatter or directory name when both exist.
   - Recommendation: All our SKILL.md files already have `name:` in frontmatter matching the directory name. This should be fine for both channels.

5. **Repo-root .claude-plugin/ directory**
   - What we know: The repo already has `.claude/` at root (with GSD framework files). Creating `.claude-plugin/` at root is a separate concern and does not conflict.
   - What's unclear: Whether having `.claude-plugin/` at both root AND `netsec-skills/` causes any confusion for tools.
   - Recommendation: The repo-root `.claude-plugin/marketplace.json` is the marketplace catalog. The `netsec-skills/.claude-plugin/plugin.json` is the plugin manifest. These serve different purposes and the Claude Code plugin system handles this correctly -- marketplace points to plugin via source path.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | BATS (via git submodule at tests/bats/) |
| Config file | tests/test_helper/common-setup.bash |
| Quick run command | `./tests/bats/bin/bats tests/test-agent-personas.bats` |
| Full suite command | `./tests/bats/bin/bats tests/` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLUG-04 | Two-channel installation | smoke | `bash scripts/test-e2e-publication.sh` | No -- Wave 0 |
| PUBL-01 | npx skills add installs all skills | smoke | `npx skills add PatrykQuantumNomad/networking-tools --list` (manual verify output) | No -- manual |
| PUBL-02 | Plugin installation works | smoke | `claude --plugin-dir ./netsec-skills` + verify skills load | No -- manual |
| PUBL-03 | Skills appear on skills.sh | manual-only | Visit skills.sh page after first install | No -- manual |
| GSD-boundary | Zero GSD files in published package | unit | `bash scripts/validate-plugin-boundary.sh` | Yes |

### Sampling Rate
- **Per task commit:** `bash scripts/validate-plugin-boundary.sh && bash scripts/test-e2e-publication.sh`
- **Per wave merge:** Full BATS suite: `./tests/bats/bin/bats tests/`
- **Phase gate:** Full suite green + manual smoke test of `claude --plugin-dir ./netsec-skills`

### Wave 0 Gaps
- [ ] `scripts/test-e2e-publication.sh` -- comprehensive E2E validation script
- [ ] `.claude-plugin/marketplace.json` at repo root -- marketplace catalog for plugin distribution
- [ ] Update `netsec-skills/README.md` -- document two-channel installation with clear guidance on what each provides

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) - SKILL.md format, frontmatter fields, discovery, plugin integration
- [Claude Code Plugins docs](https://code.claude.com/docs/en/plugins) - Plugin structure, plugin.json schema, testing with --plugin-dir
- [Claude Code Plugin Marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces) - marketplace.json format, self-hosting, plugin entries, source types
- [Claude Code Plugins Reference docs](https://code.claude.com/docs/en/plugins-reference) - Complete plugin manifest schema, component locations, debugging
- [Claude Code Discover Plugins docs](https://code.claude.com/docs/en/discover-plugins) - Installation commands, scoping, marketplace management

### Secondary (MEDIUM confidence)
- [vercel-labs/skills GitHub](https://github.com/vercel-labs/skills) - skills.sh CLI documentation, discovery paths, installation options
- [skills.sh](https://skills.sh) - Leaderboard format, listing display, security audit badges
- [skills.sh FAQ](https://skills.sh/docs/faq) - Auto-indexing via telemetry, no publish step, anonymous tracking

### Tertiary (LOW confidence)
- [skills.sh find-skills listing page](https://skills.sh/vercel-labs/skills/find-skills) - Example of how a skill listing appears (weekly installs, security audits, agent compatibility)
- skills.sh/patrykquantumnomad/networking-tools returns 404 (expected -- not yet published)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Claude Code docs thoroughly document plugin system
- Architecture (two-channel model): MEDIUM - skills.sh auto-discovery from plugin directories documented but exact behavior with duplicate skills unclear
- Pitfalls: MEDIUM - Based on official docs + project-specific structural analysis
- Publication mechanics: MEDIUM - skills.sh auto-indexing confirmed by FAQ but exact timing and metadata propagation undocumented
- E2E testing patterns: HIGH - Local testing with `--plugin-dir` well-documented; BATS framework already proven in project

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (30 days -- plugin system is relatively stable)
