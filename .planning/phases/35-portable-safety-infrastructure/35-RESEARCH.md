# Phase 35: Portable Safety Infrastructure - Research

**Researched:** 2026-03-06
**Domain:** Bash hook portability, Claude Code plugin path resolution, scope management
**Confidence:** HIGH

## Summary

Phase 35 transforms the netsec safety hooks from repo-coupled scripts into portable plugin components. The current hooks at `.claude/hooks/netsec-pretool.sh` and `netsec-posttool.sh` hardcode `$CLAUDE_PROJECT_DIR` for path resolution, assume wrapper scripts exist under `scripts/`, and depend on `.pentest/scope.json` being in a git repo. The plugin copies at `netsec-skills/hooks/` need to resolve paths via `${CLAUDE_PLUGIN_ROOT}`, degrade gracefully when wrapper scripts are absent, and create scope files on demand.

The core challenge is dual-context support: hooks must work identically when loaded from `.claude/hooks/` (in-repo) and from `netsec-skills/hooks/` (plugin). The hooks.json already references `${CLAUDE_PLUGIN_ROOT}` for the command paths, and Claude Code documentation confirms this variable is reliably set for PreToolUse and PostToolUse events (the SessionStart bug in issue #27145 does not affect this phase). A secondary challenge is the Bash 4.0+ requirement for `declare -A` associative arrays -- macOS ships with bash 3.2 at `/bin/bash`, but `#!/usr/bin/env bash` resolves to Homebrew bash 5.x when installed. A defensive check or fallback is needed.

SAFE-04 requires creating a standalone scope management solution. The current `/scope` skill uses hardcoded `.pentest/scope.json` paths relative to the project directory. For plugin portability, the scope skill and hook scripts need to resolve the scope file relative to the current working directory (the project where the user is working), not relative to the plugin installation path.

**Primary recommendation:** Modify only the `netsec-skills/hooks/` copies (never the in-repo originals), adding dual-context path resolution with `${CLAUDE_PLUGIN_ROOT}` awareness, bash 3.2 compatibility fallback, graceful scope auto-creation, and a portable scope management script at `netsec-skills/scripts/netsec-scope.sh`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SAFE-01 | PreToolUse hook works outside the networking-tools repo via `${CLAUDE_PLUGIN_ROOT}` portable path resolution | Plugin root detection pattern, dual-context PROJECT_DIR resolution, bash 3.2 fallback for `declare -A` |
| SAFE-02 | PostToolUse hook works outside the networking-tools repo with graceful degradation | Wrapper script detection pattern, audit dir creation at CWD, graceful JSON bridge skip |
| SAFE-03 | Health check diagnostic verifies infrastructure in both in-repo and plugin contexts | Plugin-aware health check that checks hook files relative to plugin root OR project root, adapts expected paths |
| SAFE-04 | User can init/add/remove/show scope targets without any repo-specific paths or Makefile | Standalone `netsec-scope.sh` script, portable `/scope` skill pointing to script, CWD-relative scope file |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash | 3.2+ (compat) / 5.x (preferred) | Hook script runtime | macOS ships 3.2 at /bin/bash; Homebrew provides 5.x; hooks MUST work on both |
| jq | 1.6+ | JSON parsing in hooks | Already required; used for scope.json, audit JSONL, hook stdin/stdout |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| shellcheck | any | Lint hook scripts | During development to catch portability issues |
| BATS | 1.x (installed) | Test hook behavior | Existing test framework in tests/bats/ |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bash associative arrays | case/if-elif chain | Loses the elegant lookup but gains bash 3.2 compatibility -- RECOMMENDED for portability |
| Script-based scope management | Skill-only (no script) | Script is reusable from CLI outside Claude; skill alone only works in Claude sessions |

## Architecture Patterns

### Current vs Portable Hook Architecture

```
CURRENT (in-repo):
.claude/hooks/netsec-pretool.sh
  -> reads $CLAUDE_PROJECT_DIR (= git root)
  -> scope at $PROJECT_DIR/.pentest/scope.json
  -> blocks raw tools pointing to scripts/ (in repo)
  -> audit log at $PROJECT_DIR/.pentest/

PORTABLE (plugin):
netsec-skills/hooks/netsec-pretool.sh
  -> reads $CLAUDE_PLUGIN_ROOT (= plugin install dir)
  -> scope at $CWD/.pentest/scope.json (user's project)
  -> blocks raw tools but wrapper redirect is informational only
  -> audit log at $CWD/.pentest/
```

### Pattern 1: Dual-Context Project Directory Resolution
**What:** Determine where the user's project is (for scope and audit files) regardless of whether we are running in-repo or as a plugin.
**When to use:** Every hook script that reads/writes `.pentest/` data.
**Example:**
```bash
# Source: Claude Code plugin docs + project analysis
# Priority: CLAUDE_PROJECT_DIR (set by Claude Code) > git root > CWD
resolve_project_dir() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    echo "$CLAUDE_PROJECT_DIR"
  elif git rev-parse --show-toplevel 2>/dev/null; then
    : # git rev-parse already printed the path
  else
    pwd
  fi
}
PROJECT_DIR="$(resolve_project_dir)"
```

### Pattern 2: Bash 3.2 Compatibility for Tool-to-Script Mapping
**What:** Replace `declare -A` associative array with a function-based lookup that works on all bash versions.
**When to use:** The TOOL_SCRIPT_DIR mapping in the pretool hook.
**Example:**
```bash
# Source: project analysis -- replaces declare -A TOOL_SCRIPT_DIR
get_tool_script_dir() {
  case "$1" in
    nmap)          echo "scripts/nmap/" ;;
    tshark)        echo "scripts/tshark/" ;;
    msfconsole|msfvenom|msfdb) echo "scripts/metasploit/" ;;
    sqlmap)        echo "scripts/sqlmap/" ;;
    nikto)         echo "scripts/nikto/" ;;
    hashcat)       echo "scripts/hashcat/" ;;
    john)          echo "scripts/john/" ;;
    hping3)        echo "scripts/hping3/" ;;
    skipfish)      echo "scripts/skipfish/" ;;
    aircrack-ng|airodump-ng|aireplay-ng|airmon-ng) echo "scripts/aircrack-ng/" ;;
    gobuster)      echo "scripts/gobuster/" ;;
    ffuf)          echo "scripts/ffuf/" ;;
    foremost)      echo "scripts/foremost/" ;;
    dig)           echo "scripts/dig/" ;;
    curl)          echo "scripts/curl/" ;;
    nc|netcat|ncat) echo "scripts/netcat/" ;;
    traceroute|mtr) echo "scripts/traceroute/" ;;
    *)             echo "" ;;
  esac
}

# Iterate tools without associative array
TOOL_BINS="nmap tshark msfconsole msfvenom msfdb sqlmap nikto hashcat john hping3 skipfish aircrack-ng airodump-ng aireplay-ng airmon-ng gobuster ffuf foremost dig curl nc netcat ncat traceroute mtr"

for tool_bin in $TOOL_BINS; do
  if echo "$COMMAND" | grep -qE "^(sudo[[:space:]]+)?${tool_bin}(\\b|\$)"; then
    local_dir="$(get_tool_script_dir "$tool_bin")"
    # ... rest of logic
  fi
done
```

### Pattern 3: Graceful Scope Auto-Creation on Fresh Install
**What:** When no scope file exists, auto-create a default one instead of hard-blocking.
**When to use:** PreToolUse hook when scope file is missing and a wrapper script invocation needs validation.
**Example:**
```bash
# Source: success criteria #5 -- "Hooks auto-create default scope"
SCOPE_FILE="$PROJECT_DIR/.pentest/scope.json"

if [[ ! -f "$SCOPE_FILE" ]]; then
  # Auto-create default scope with safe localhost targets
  mkdir -p "$(dirname "$SCOPE_FILE")"
  echo '{"targets":["localhost","127.0.0.1"],"notes":"Auto-created by netsec safety hook. Add your targets with /scope add <target>"}' > "$SCOPE_FILE"
  # Log the auto-creation
  write_audit "scope_created" "system" "" "" "auto-created default scope" ""
fi
```

### Pattern 4: PostToolUse Graceful Degradation
**What:** When running outside the repo, wrapper scripts are absent. The hook should still log the command but skip JSON bridge parsing if no structured output is expected.
**When to use:** PostToolUse hook in plugin context.
**Example:**
```bash
# Source: SAFE-02 requirement + success criteria #2
# Graceful degradation: if command contains scripts/ but scripts aren't local,
# still log the command but don't fail
if [[ "$COMMAND" != *"scripts/"* ]]; then
  # Not a wrapper script invocation. In plugin context, tools may run directly.
  # Still check if it matches a known security tool for audit purposes.
  if echo "$COMMAND" | grep -qEw "$SECURITY_TOOLS_RE"; then
    # Log direct tool usage for audit trail
    write_audit "direct_tool" "${SCRIPT_TOOL:-unknown}" "$COMMAND" "" "" ""
  fi
  exit 0
fi
```

### Pattern 5: Plugin-Aware Health Check
**What:** Health check adapts its checks based on whether it detects plugin context or in-repo context.
**When to use:** netsec-health.sh when verifying hook files and registration.
**Example:**
```bash
# Source: SAFE-03 requirement
# Detect context: plugin or in-repo
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  CONTEXT="plugin"
  HOOK_DIR="$CLAUDE_PLUGIN_ROOT/hooks"
  HOOK_CONFIG="$CLAUDE_PLUGIN_ROOT/hooks/hooks.json"
else
  CONTEXT="in-repo"
  HOOK_DIR="$PROJECT_DIR/.claude/hooks"
  HOOK_CONFIG="$PROJECT_DIR/.claude/settings.json"
fi

# Check hook files based on context
check "PreToolUse hook file exists" \
  "$( [[ -f "$HOOK_DIR/netsec-pretool.sh" ]] && echo true || echo false )"

# Registration check adapts
if [[ "$CONTEXT" == "plugin" ]]; then
  check "Hooks registered in hooks.json" \
    "$( jq -e '.hooks.PreToolUse' "$HOOK_CONFIG" &>/dev/null && echo true || echo false )"
else
  check "Hooks registered in settings.json" \
    "$( jq -e '.hooks.PreToolUse' "$HOOK_CONFIG" &>/dev/null && echo true || echo false )"
fi
```

### Pattern 6: Portable Scope Management Script
**What:** Standalone bash script for scope operations (init/add/remove/show/clear) that works from any directory.
**When to use:** SAFE-04 -- replaces Makefile-based scope management.
**Example:**
```bash
#!/usr/bin/env bash
# netsec-scope.sh -- Portable scope management for pentesting engagements
# Usage: netsec-scope.sh <init|add|remove|show|clear> [target]

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SCOPE_FILE="$PROJECT_DIR/.pentest/scope.json"

case "${1:-show}" in
  init)
    mkdir -p "$(dirname "$SCOPE_FILE")"
    echo '{"targets":["localhost","127.0.0.1"]}' > "$SCOPE_FILE"
    echo "Scope initialized at $SCOPE_FILE"
    cat "$SCOPE_FILE"
    ;;
  add)
    [[ -z "${2:-}" ]] && echo "Usage: netsec-scope.sh add <target>" && exit 1
    [[ ! -f "$SCOPE_FILE" ]] && echo "No scope file. Run: netsec-scope.sh init" && exit 1
    jq --arg t "$2" '.targets += [$t] | .targets |= unique' "$SCOPE_FILE" > "${SCOPE_FILE}.tmp" \
      && mv "${SCOPE_FILE}.tmp" "$SCOPE_FILE"
    echo "Added '$2' to scope"
    jq -r '.targets[]' "$SCOPE_FILE"
    ;;
  remove)
    [[ -z "${2:-}" ]] && echo "Usage: netsec-scope.sh remove <target>" && exit 1
    [[ ! -f "$SCOPE_FILE" ]] && echo "No scope file." && exit 1
    jq --arg t "$2" '.targets -= [$t]' "$SCOPE_FILE" > "${SCOPE_FILE}.tmp" \
      && mv "${SCOPE_FILE}.tmp" "$SCOPE_FILE"
    echo "Removed '$2' from scope"
    jq -r '.targets[]' "$SCOPE_FILE"
    ;;
  show)
    if [[ -f "$SCOPE_FILE" ]]; then
      jq . "$SCOPE_FILE"
    else
      echo "No scope file found. Run: netsec-scope.sh init"
      exit 1
    fi
    ;;
  clear)
    [[ ! -f "$SCOPE_FILE" ]] && echo "No scope file." && exit 1
    echo '{"targets":[]}' > "$SCOPE_FILE"
    echo "Scope cleared. All pentesting commands will be blocked until targets are added."
    ;;
  *)
    echo "Usage: netsec-scope.sh <init|add|remove|show|clear> [target]"
    exit 1
    ;;
esac
```

### Anti-Patterns to Avoid

- **Modifying in-repo hooks:** Never change `.claude/hooks/netsec-pretool.sh` or `.claude/hooks/netsec-posttool.sh`. Only modify the copies in `netsec-skills/hooks/`. The in-repo hooks serve the v1.5 use case and must remain stable.
- **Hardcoding plugin cache paths:** Never use absolute paths to `~/.claude/plugins/cache/`. Always use `${CLAUDE_PLUGIN_ROOT}` which Claude Code resolves at runtime.
- **Scope file relative to plugin root:** The scope file `.pentest/scope.json` belongs in the USER's PROJECT, not in the plugin directory. Always resolve to `$PROJECT_DIR/.pentest/scope.json` where `$PROJECT_DIR` is the user's working project.
- **Symlinking hook scripts:** Phase 34 decided to COPY hooks (not symlink) specifically to allow independent portability edits in Phase 35. Do not revert to symlinks.
- **Testing with /bin/bash on macOS:** Always test hooks with both `bash` (Homebrew 5.x) and `/bin/bash` (macOS 3.2) to catch compatibility issues.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON parsing in bash | Custom awk/sed JSON parser | jq | Already a dependency; handles escaping, nested objects, arrays correctly |
| Scope file validation | Manual string parsing | `jq -e '.targets \| type == "array"'` | Handles malformed JSON, type checking, edge cases |
| Path resolution | Complex if/elif chain | `${CLAUDE_PROJECT_DIR:-$(git rev-parse ... \|\| pwd)}` | Standard Claude Code pattern, covers all contexts |
| Audit log formatting | echo/printf timestamps | `jq -n -c --arg ts "$(date -u ...)" ...` | Consistent JSONL format, proper escaping |

**Key insight:** The hooks are pure bash+jq by design decision. Don't introduce node.js, python, or other runtime dependencies. The "deterministic safety hooks via bash+jq" decision is a locked project constraint.

## Common Pitfalls

### Pitfall 1: macOS Bash 3.2 Associative Array Crash
**What goes wrong:** The pretool hook uses `declare -A TOOL_SCRIPT_DIR=(...)` which silently fails or crashes on bash 3.2 (macOS default /bin/bash).
**Why it happens:** macOS still ships bash 3.2 (GPLv2) at /bin/bash. Associative arrays require bash 4.0+ (GPLv3).
**How to avoid:** Replace `declare -A` with a `case` statement function lookup. Use `#!/usr/bin/env bash` which picks up Homebrew bash 5.x when installed, AND add a bash version check with a helpful error message.
**Warning signs:** Hook works on developer machine (has Homebrew bash) but fails silently for users with only system bash.

### Pitfall 2: CLAUDE_PLUGIN_ROOT Not Available During Hook Script Body
**What goes wrong:** Confusing when `${CLAUDE_PLUGIN_ROOT}` is available in hooks.json commands versus inside the hook script itself.
**Why it happens:** `${CLAUDE_PLUGIN_ROOT}` is resolved by Claude Code when executing the hooks.json `command` field. Inside the script itself, it is available as an environment variable. But during SessionStart hooks, it may not be set (issue #27145). This does NOT affect PreToolUse/PostToolUse.
**How to avoid:** For PreToolUse and PostToolUse hooks (which is what we use), `CLAUDE_PLUGIN_ROOT` is reliably available as an environment variable inside the script. Use it for locating plugin-bundled files but NOT for locating user project files.
**Warning signs:** Works in `hooks.json` `command` field but referencing it inside the script body fails.

### Pitfall 3: Scope File Location Confusion
**What goes wrong:** Hook looks for scope.json at the plugin installation location instead of the user's project directory.
**Why it happens:** When running as a plugin, `CLAUDE_PLUGIN_ROOT` points to the plugin cache, not the user's project. If the hook resolves scope relative to `CLAUDE_PLUGIN_ROOT`, it creates scope files inside the cached plugin directory.
**How to avoid:** Always use `$CLAUDE_PROJECT_DIR` or CWD for scope file location. `CLAUDE_PLUGIN_ROOT` is only for plugin-internal files (like the hook scripts themselves).
**Warning signs:** Scope file appears in `~/.claude/plugins/cache/netsec-skills/.pentest/` instead of in the user's project.

### Pitfall 4: Raw Tool Interception in Plugin Context
**What goes wrong:** The pretool hook blocks raw `nmap` calls and redirects to `scripts/nmap/examples.sh`, but those wrapper scripts don't exist outside the repo.
**Why it happens:** The raw tool interception was designed for in-repo use where wrapper scripts are always available.
**How to avoid:** In plugin context, raw tool interception should still warn about best practices but the redirect message should reference the `/nmap` skill instead of `scripts/nmap/examples.sh`. Detect context: if `CLAUDE_PLUGIN_ROOT` is set, user is in plugin mode -- redirect to skill triggers.
**Warning signs:** Users see "use wrapper scripts in scripts/nmap/" but no such directory exists in their project.

### Pitfall 5: Hard Fail on Missing Scope File
**What goes wrong:** Fresh plugin install immediately blocks all pentesting commands because `.pentest/scope.json` doesn't exist.
**Why it happens:** Current hook denies all commands when scope file is absent. This is safe but hostile to new users.
**How to avoid:** Auto-create a default scope file with `["localhost","127.0.0.1"]` on first encounter. Log the auto-creation. This satisfies success criteria #5.
**Warning signs:** User installs plugin, tries `/nmap scan localhost`, gets blocked with a confusing error about missing scope file.

### Pitfall 6: PostToolUse Hook Fails When No Git Repo
**What goes wrong:** `git rev-parse --show-toplevel` fails when user is not in a git repository.
**Why it happens:** PROJECT_DIR resolution falls back to git, which errors in non-git directories.
**How to avoid:** The existing pattern `git rev-parse --show-toplevel 2>/dev/null || pwd` already handles this, but verify it works with the full `resolve_project_dir` function.
**Warning signs:** Hooks crash when running in a directory that isn't a git repo.

## Code Examples

Verified patterns from official sources:

### Claude Code PreToolUse Deny Output Format
```bash
# Source: https://code.claude.com/docs/en/hooks (PreToolUse decision control)
# Exit 0 with JSON stdout to deny a tool call
jq -n -c \
  --arg reason "Target not in scope" \
  --arg context "BLOCKED: target '10.0.0.1' not in scope." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason,additionalContext:$context}}'
```

### Claude Code PostToolUse Context Injection
```bash
# Source: https://code.claude.com/docs/en/hooks (PostToolUse decision control)
# PostToolUse uses top-level decision field (not hookSpecificOutput) for blocking
# But for context injection, it uses hookSpecificOutput
jq -n -c \
  --arg ctx "Scan completed: 5 hosts found, 3 with open ports" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
```

### Plugin hooks.json Format (Already Correct)
```json
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
    ]
  }
}
```

### Bash Version Guard
```bash
# Source: project analysis -- protecting against bash 3.2
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  # Fall back to case-based lookup instead of associative array
  USE_ASSOC_ARRAY=false
else
  USE_ASSOC_ARRAY=true
fi
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `$CLAUDE_PROJECT_DIR` only | `$CLAUDE_PROJECT_DIR` + `$CLAUDE_PLUGIN_ROOT` | Claude Code plugin system (2025) | Hooks can now be distributed as plugins |
| Hardcoded `.claude/settings.json` registration | `hooks/hooks.json` in plugin root | Claude Code plugin system (2025) | Hooks auto-register when plugin is installed |
| Makefile scope targets | Standalone script + skill | Phase 35 (now) | Scope management works outside the repo |

**Deprecated/outdated:**
- `pretool-scope-guard.sh` / `posttool-audit-log.sh`: These were the original filenames mentioned in phase context. The actual in-repo files are `netsec-pretool.sh` / `netsec-posttool.sh`.

## Open Questions

1. **CLAUDE_PLUGIN_ROOT availability inside hook script body**
   - What we know: The variable is reliably set for PreToolUse and PostToolUse events based on official docs. It is NOT reliably set for SessionStart (issue #27145).
   - What's unclear: Whether the variable is set as an environment variable inside the script or only resolved in the hooks.json command string.
   - Recommendation: Test empirically during implementation. Add `echo "PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT:-unset}" >&2` debug line. If not available as env var inside script, parse it from the command invocation path (`dirname "$0"` approach as fallback).

2. **Plugin cache behavior for scope files**
   - What we know: Marketplace plugins are cached at `~/.claude/plugins/cache/`. Plugin files are copied there.
   - What's unclear: Whether `$CLAUDE_PROJECT_DIR` is available and correct when running from a cached plugin.
   - Recommendation: `$CLAUDE_PROJECT_DIR` is a standard Claude Code env var set for all hooks regardless of plugin context. If missing, fall back to CWD. Test during implementation.

3. **Dual-mode wrapper script detection in hooks**
   - What we know: In-repo, hooks check for `scripts/` in the command. Outside the repo, wrapper scripts won't be invoked.
   - What's unclear: Whether Phase 36 (dual-mode tool skills) will change how commands are structured, potentially breaking hook detection.
   - Recommendation: Design the portable hooks to be forward-compatible. Check for both `scripts/` path patterns AND direct tool invocations. Phase 36 will build on top of whatever we establish here.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | BATS 1.x (installed at tests/bats/) |
| Config file | None -- BATS uses direct invocation |
| Quick run command | `./tests/bats/bin/bats tests/test-*.sh` |
| Full suite command | `./tests/bats/bin/bats tests/` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SAFE-01 | PreToolUse hook resolves paths portably | unit | `./tests/bats/bin/bats tests/test-portable-pretool.sh -x` | No -- Wave 0 |
| SAFE-01 | PreToolUse blocks out-of-scope targets | unit | `./tests/bats/bin/bats tests/test-portable-pretool.sh -x` | No -- Wave 0 |
| SAFE-01 | Bash 3.2 compatibility (no declare -A) | unit | `/bin/bash -c 'bash netsec-skills/hooks/netsec-pretool.sh < /dev/null; echo $?'` | manual-only: requires mocking stdin |
| SAFE-02 | PostToolUse logs audit entries | unit | `./tests/bats/bin/bats tests/test-portable-posttool.sh -x` | No -- Wave 0 |
| SAFE-02 | PostToolUse degrades gracefully | unit | `./tests/bats/bin/bats tests/test-portable-posttool.sh -x` | No -- Wave 0 |
| SAFE-03 | Health check works in plugin context | smoke | `CLAUDE_PLUGIN_ROOT=netsec-skills bash netsec-skills/hooks/netsec-health.sh` | No -- Wave 0 |
| SAFE-04 | Scope init/add/remove/show work | unit | `./tests/bats/bin/bats tests/test-netsec-scope.sh -x` | No -- Wave 0 |
| SAFE-04 | Scope script works without Makefile | smoke | `bash netsec-skills/scripts/netsec-scope.sh init && bash netsec-skills/scripts/netsec-scope.sh show` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `./tests/bats/bin/bats tests/test-portable-*.sh --timing`
- **Per wave merge:** `./tests/bats/bin/bats tests/ --timing`
- **Phase gate:** Full suite green + manual smoke test of `claude --plugin-dir ./netsec-skills`

### Wave 0 Gaps
- [ ] `tests/test-portable-pretool.sh` -- covers SAFE-01 (pretool portable behavior)
- [ ] `tests/test-portable-posttool.sh` -- covers SAFE-02 (posttool portable behavior)
- [ ] `tests/test-netsec-scope.sh` -- covers SAFE-04 (scope management script)

## Sources

### Primary (HIGH confidence)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Plugin manifest schema, `${CLAUDE_PLUGIN_ROOT}` documentation, hooks.json structure, directory layout
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- PreToolUse/PostToolUse JSON input/output schemas, exit code behavior, decision control, matcher patterns
- [Claude Code Hook Development SKILL.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md) -- Hook development best practices, output format examples

### Secondary (MEDIUM confidence)
- [GitHub Issue #27145](https://github.com/anthropics/claude-code/issues/27145) -- CLAUDE_PLUGIN_ROOT not set during SessionStart (confirmed does NOT affect PreToolUse/PostToolUse)
- [GitHub Issue #24529](https://github.com/anthropics/claude-code/issues/24529) -- Hook executor CLAUDE_PLUGIN_ROOT tracking issue (parent issue for #27145)
- Local verification: macOS bash version check -- `/bin/bash` = 3.2.57, `/usr/bin/env bash` = 5.3.9 (Homebrew)

### Tertiary (LOW confidence)
- [GitHub Issue #18527](https://github.com/anthropics/claude-code/issues/18527) -- Windows `${CLAUDE_PLUGIN_ROOT}` path separator bugs (out of scope per REQUIREMENTS.md)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- bash+jq is a locked decision, well-understood
- Architecture: HIGH -- patterns derived from existing working hooks + official plugin docs
- Pitfalls: HIGH -- bash 3.2 issue verified locally, CLAUDE_PLUGIN_ROOT behavior verified from official sources
- Scope management: HIGH -- straightforward bash/jq script, no external dependencies

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable domain -- bash scripting + Claude Code plugin system)
