# Phase 28: Safety Architecture - Research

**Researched:** 2026-02-17
**Domain:** Claude Code hooks (PreToolUse/PostToolUse), audit logging, bash safety validation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- No scope set = **block everything**. No commands pass without an explicit allowlist. Safest default.
- Block messages are **terse + actionable**: what was blocked and what to do about it. No lengthy explanations.
- When a raw tool command is intercepted (e.g., `nmap` called directly), the message **names the specific wrapper script** to use instead (e.g., "Use scripts/nmap/discover-live-hosts.sh instead")
- **Claude receives richer context** than the user on blocks -- structured data (blocked target, reason, current scope contents) so Claude can help the user fix the issue without re-reading files
- Log lives in **hidden directory**: `.pentest/` (gitignored)
- Format: **JSON Lines (.jsonl)** -- one JSON object per line, machine-parseable with jq
- **Log everything**: both successful invocations and blocked commands. Full picture of what was attempted.
- **Session-based files**: each session gets its own log file (e.g., `audit-2026-02-17.jsonl`). Natural rotation by date, easy to archive.
- **Full verification**: hook files exist, hooks are registered in Claude Code settings, scope file is loadable, audit directory is writable
- Output: **checklist with pass/fail** per check item
- Available as **both** a standalone bash script (for debugging outside Claude) and a Claude Code skill slash command
- When issues found: **offer to fix** each one interactively (e.g., "Scope file missing. Create one? [y/N]"). Guided repair, not silent auto-fix.

### Claude's Discretion
- Allowlist mechanism (scope file vs env var vs hybrid) -- Claude picks what integrates best with Claude Code hooks
- Whether Docker lab targets (localhost:8080, :3000, :8888, :8180) are auto-allowed or require explicit scope -- Claude picks what's most practical
- Whether PostToolUse parses `-j` JSON output into a summary or passes raw JSON through -- Claude picks based on context window budget and hook complexity tradeoffs
- Whether raw tool bypass is a hard block or a block-with-redirect -- Claude picks what fits hook mechanics best
- Exact fields per log entry (timestamp, tool, script, target, result, etc.)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SAFE-01 | PreToolUse hook validates all Bash commands against target allowlist before execution | PreToolUse hook with `permissionDecision: "deny"` blocks tool calls; hook reads scope file and extracts target from command; exit 2 or JSON deny both work |
| SAFE-02 | PreToolUse hook intercepts raw tool commands (nmap, sqlmap, etc.) that bypass wrapper scripts | Same PreToolUse hook checks if command starts with a raw tool name instead of `bash scripts/...`; returns deny with redirect message |
| SAFE-03 | PostToolUse hook parses `-j` JSON envelope output and injects structured `additionalContext` to Claude | PostToolUse hook receives `tool_response.stdout` containing JSON envelope; hook parses with jq and returns `additionalContext` via JSON stdout |
| SAFE-04 | All skill invocations and results are logged to audit trail file | Both PreToolUse (blocked/allowed decisions) and PostToolUse (results) hooks append JSONL entries to `.pentest/audit-YYYY-MM-DD.jsonl` |
| SAFE-05 | User can run health-check command to verify hooks are firing correctly | Standalone bash script + skill SKILL.md; script reads `.claude/settings.json`, checks for hook registrations, validates scope file, tests audit dir writability |
</phase_requirements>

## Summary

This phase implements the safety infrastructure for the Claude Code skill pack: PreToolUse hooks that validate targets and intercept raw tool usage before execution, a PostToolUse hook that parses JSON envelope output from scripts, JSONL audit logging, and a health-check system. All hooks are deterministic (bash+jq), not LLM-based.

The Claude Code hooks system is mature and well-documented. PreToolUse hooks receive the full bash command via `tool_input.command` on stdin, and can return structured JSON with `permissionDecision: "deny"` to block execution, or `permissionDecision: "allow"` to approve. PostToolUse hooks receive both `tool_input` and `tool_response` (including `stdout`, `stderr`, `exit_code` for Bash commands). Both hook types support `additionalContext` to inject information into Claude's context. The hook configuration goes in `.claude/settings.json` under the `hooks` key, using matchers to filter by tool name.

The existing project already has the hooks infrastructure working (GSD SessionStart hook), and the JSON envelope protocol from v1.4 (`scripts/lib/json.sh`) provides the structured output format that the PostToolUse hook will parse. The fd3 redirect mechanism means JSON output appears cleanly on stdout while human-readable output goes to stderr -- no script modifications needed.

**Primary recommendation:** Implement all safety hooks as a single bash script (`.claude/hooks/netsec-safety.sh`) that handles both PreToolUse and PostToolUse events by checking `hook_event_name`, keeping the codebase simple. Alternatively, use separate scripts for PreToolUse and PostToolUse for clarity and register them independently in settings.json. Separate scripts are recommended because PreToolUse and PostToolUse have fundamentally different responsibilities and different JSON schemas, and the settings.json matcher system already routes events to the right script.

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash | 4.0+ | Hook scripts, scope file parsing, health check | Already enforced by `common.sh` guard; associative arrays for tool mapping |
| jq | any | JSON parsing in hooks (stdin parsing, JSONL writing, scope file reading) | Already a project dependency for `-j` flag; deterministic, fast |
| Claude Code hooks | current | PreToolUse/PostToolUse event system | Official hook API; deterministic `type: "command"` hooks |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| date | system | ISO 8601 timestamps for audit log entries | Every audit log entry |
| mkdir -p | system | Create `.pentest/` directory on first use | Hook initialization |
| chmod | system | Make hook scripts executable | Setup/health-check |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bash+jq hooks | Python hooks | Python is cleaner for JSON but adds dependency; bash+jq matches project conventions and the official validator example uses Python but the project is bash-native |
| Separate scope file | Environment variable | Env vars lose state between sessions; file persists and is inspectable |
| `type: "prompt"` hooks | `type: "command"` hooks | LLM hooks add latency, cost, non-determinism; unacceptable for safety-critical validation per project constraints |

**Installation:**
```bash
# No additional installation needed. bash and jq are existing dependencies.
# Hook scripts are project files, not external packages.
```

## Architecture Patterns

### Recommended Project Structure
```
.claude/
  hooks/
    netsec-pretool.sh          # PreToolUse: target validation + raw tool interception
    netsec-posttool.sh         # PostToolUse: JSON bridge + audit logging
  settings.json                # MOD: add PreToolUse and PostToolUse hook registrations
  skills/
    netsec-health/
      SKILL.md                 # Health-check slash command (/netsec-health)
.pentest/                      # NEW: audit log directory (gitignored)
  scope.json                   # Target allowlist (user-managed)
  audit-2026-02-17.jsonl       # Session audit log (auto-generated)
scripts/
  (unchanged)                  # Existing 81 scripts remain untouched
```

### Pattern 1: PreToolUse Target Validation
**What:** A PreToolUse hook that intercepts Bash commands, extracts the target argument, and validates it against a scope file before allowing execution. Returns structured JSON with `permissionDecision: "deny"` for blocked commands or exits 0 for allowed ones.
**When to use:** Every Bash command that matches a pentesting tool pattern.
**Example:**
```bash
#!/usr/bin/env bash
# .claude/hooks/netsec-pretool.sh
# Source: https://code.claude.com/docs/en/hooks (PreToolUse reference)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only process Bash commands
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

# Fast exit: skip non-security-tool commands (git, npm, ls, etc.)
# Check if command involves a known pentesting tool or wrapper script
SECURITY_TOOLS="nmap|tshark|nikto|sqlmap|msfconsole|hashcat|john|hping3|skipfish|aircrack-ng|gobuster|ffuf|foremost|dig|curl|nc|netcat|traceroute|mtr"
if ! echo "$COMMAND" | grep -qE "(scripts/|${SECURITY_TOOLS})"; then
    exit 0
fi

# --- SAFE-02: Raw tool interception ---
# Check if command starts with a raw tool name (not through wrapper scripts)
RAW_TOOL=$(echo "$COMMAND" | grep -oE "^(sudo\s+)?(${SECURITY_TOOLS})\b" | tail -1)
if [[ -n "$RAW_TOOL" ]] && [[ "$COMMAND" != *"scripts/"* ]]; then
    # Map raw tool to wrapper script suggestion
    TOOL_CLEAN=$(echo "$RAW_TOOL" | sed 's/^sudo *//')
    jq -n \
        --arg reason "Blocked: raw '$TOOL_CLEAN' command. Use wrapper scripts instead: bash scripts/${TOOL_CLEAN}/examples.sh <target> -j" \
        '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: $reason
            }
        }'
    exit 0
fi

# --- SAFE-01: Target allowlist validation ---
SCOPE_FILE="$CLAUDE_PROJECT_DIR/.pentest/scope.json"

# No scope file = block everything
if [[ ! -f "$SCOPE_FILE" ]]; then
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: "No scope file found at .pentest/scope.json. Create one with allowed targets first."
        }
    }'
    exit 0
fi

# Extract target from command and validate against scope
# (target extraction logic varies by command pattern)
# ... validate against scope.json allowlist ...

exit 0  # Allow if target is in scope
```

### Pattern 2: PostToolUse JSON Bridge + Audit Logging
**What:** A PostToolUse hook that detects netsec JSON envelopes in Bash stdout, parses them into a structured summary for Claude, and appends an audit log entry.
**When to use:** After every Bash command that matches script invocations.
**Example:**
```bash
#!/usr/bin/env bash
# .claude/hooks/netsec-posttool.sh
# Source: https://code.claude.com/docs/en/hooks (PostToolUse reference)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Fast exit: only process netsec script invocations
[[ "$COMMAND" == *"scripts/"* ]] || exit 0

# --- SAFE-04: Audit logging ---
AUDIT_DIR="$CLAUDE_PROJECT_DIR/.pentest"
mkdir -p "$AUDIT_DIR"
AUDIT_FILE="$AUDIT_DIR/audit-$(date +%Y-%m-%d).jsonl"

STDOUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // empty' 2>/dev/null)
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // "unknown"' 2>/dev/null)

# Build audit entry
AUDIT_ENTRY=$(jq -n \
    --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg cmd "$COMMAND" \
    --arg exit "$EXIT_CODE" \
    --arg session "$(echo "$INPUT" | jq -r '.session_id // empty')" \
    '{timestamp: $ts, command: $cmd, exit_code: $exit, session: $session, event: "executed"}')
echo "$AUDIT_ENTRY" >> "$AUDIT_FILE"

# --- SAFE-03: JSON bridge (additionalContext) ---
if [[ "$COMMAND" == *"-j"* ]] && echo "$STDOUT" | jq -e '.meta.tool and .results and .summary' &>/dev/null; then
    TOOL=$(echo "$STDOUT" | jq -r '.meta.tool')
    TARGET=$(echo "$STDOUT" | jq -r '.meta.target')
    SCRIPT=$(echo "$STDOUT" | jq -r '.meta.script')
    TOTAL=$(echo "$STDOUT" | jq -r '.summary.total')
    OK=$(echo "$STDOUT" | jq -r '.summary.succeeded')
    FAIL=$(echo "$STDOUT" | jq -r '.summary.failed')
    MODE=$(echo "$STDOUT" | jq -r '.meta.mode')

    CONTEXT="Netsec result: $TOOL ($SCRIPT) against $TARGET in $MODE mode. $TOTAL items: $OK succeeded, $FAIL failed."

    jq -n --arg ctx "$CONTEXT" \
        '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
else
    exit 0
fi
```

### Pattern 3: Scope File Format
**What:** A JSON file at `.pentest/scope.json` that defines allowed targets. Hooks read this file to validate commands.
**When to use:** All target validation in PreToolUse hook.
**Example:**
```json
{
  "targets": [
    "localhost",
    "127.0.0.1",
    "192.168.1.0/24",
    "scanme.nmap.org"
  ],
  "ports": [],
  "notes": "Lab engagement - Docker targets only"
}
```

### Pattern 4: Settings.json Hook Registration
**What:** Adding PreToolUse and PostToolUse entries to the existing `.claude/settings.json` file.
**When to use:** One-time setup, validated by health check.
**Example:**
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
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/netsec-pretool.sh"
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
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/netsec-posttool.sh"
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

### Anti-Patterns to Avoid

- **Processing every Bash command deeply:** Hook fires on ALL Bash commands (git, ls, npm, etc.). The fast-exit pattern (`[[ "$COMMAND" == *"scripts/"* ]] || exit 0`) is essential. Without it, every git status adds latency.

- **Using `type: "prompt"` for safety validation:** LLM-based hooks are non-deterministic, slow, and cost tokens. Safety validation must be deterministic bash+jq. This is a locked project constraint.

- **Modifying existing scripts:** The "plugin wraps, never modifies" constraint means all 81 scripts remain untouched. Safety hooks operate at the Claude Code layer, not the script layer.

- **Putting scope in environment variables:** Env vars are ephemeral and invisible. A scope file is persistent, inspectable, and can be managed by a future `/scope` command (Phase 32).

- **Blocking non-security commands:** The hook must only validate pentesting tool commands. Blocking `git`, `npm`, `ls`, etc. would break normal development workflows.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON parsing in bash | String manipulation / awk / sed | jq | jq handles edge cases (escaping, unicode, nested objects) that string parsing will miss |
| Hook event routing | if/else on event name in one script | Separate scripts per event type | settings.json matcher routes events; separate scripts are cleaner and independently testable |
| JSONL log rotation | Custom rotation logic | Date-based filenames (`audit-YYYY-MM-DD.jsonl`) | One file per day is natural rotation; no cron or cleanup needed |
| Target extraction from commands | Regex parsing of arbitrary bash | Pattern matching on known command structures | Tools have predictable argument patterns; full bash parsing is unnecessarily complex |
| Settings.json validation | Manual JSON reading | jq with `.hooks.PreToolUse` path queries | jq validates structure and extracts nested fields reliably |

**Key insight:** The Claude Code hooks system provides the routing, input parsing, and response handling. Your hook scripts only need to make a decision and return JSON. Don't re-implement what the framework already provides.

## Common Pitfalls

### Pitfall 1: Hook Not Executable
**What goes wrong:** Hook script is registered in settings.json but never fires.
**Why it happens:** Script lacks execute permission (`chmod +x`).
**How to avoid:** Health check verifies `[[ -x "$HOOK_FILE" ]]` and offers to fix. Build step includes `chmod +x`.
**Warning signs:** "PreToolUse hook error" messages in verbose mode (Ctrl+O).

### Pitfall 2: Shell Profile Corrupts JSON Output
**What goes wrong:** Hook returns valid JSON but Claude Code fails to parse it.
**Why it happens:** The user's `~/.zshrc` or `~/.bashrc` has unconditional `echo` statements. Hooks run in a non-interactive shell that sources the profile. The echo output prepends to the JSON.
**How to avoid:** Use `#!/usr/bin/env bash` (not zsh) and keep hook scripts simple. Test with: `echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./netsec-pretool.sh`
**Warning signs:** "JSON validation failed" errors in Claude Code output.

### Pitfall 3: Slow Hook on Every Bash Command
**What goes wrong:** Noticeable latency on every command Claude runs.
**Why it happens:** Hook does expensive work (reading files, running jq pipelines) before the fast-exit check.
**How to avoid:** First line after reading stdin must be the fast-exit check. Read the scope file only after confirming the command is a security tool invocation.
**Warning signs:** User notices delay on simple commands like `ls` or `git status`.

### Pitfall 4: Target Extraction False Positives
**What goes wrong:** Hook blocks a legitimate command because it misidentifies a target.
**Why it happens:** Naive regex matches tool names in unrelated contexts (e.g., `grep nmap README.md` triggers the nmap interceptor).
**How to avoid:** Check command structure, not just tool name presence. A raw tool invocation starts with the tool name (possibly preceded by `sudo`). A `grep` command containing "nmap" is not a raw tool invocation.
**Warning signs:** Non-security commands being blocked.

### Pitfall 5: Audit Log File Permissions
**What goes wrong:** Hook fails silently because it cannot write to the audit directory.
**Why it happens:** `.pentest/` directory doesn't exist or has wrong permissions.
**How to avoid:** `mkdir -p` in the hook before writing. Health check verifies directory is writable.
**Warning signs:** Missing audit entries despite successful command execution.

### Pitfall 6: CIDR and Subnet Target Matching
**What goes wrong:** Scope contains `192.168.1.0/24` but a command targeting `192.168.1.50` is blocked because the hook does exact string matching.
**Why it happens:** CIDR matching requires IP arithmetic, not string comparison.
**How to avoid:** For v1, support exact match plus simple `/24` expansion (same first 3 octets). Full CIDR math is over-engineering for this phase. Document the limitation.
**Warning signs:** Commands blocked despite target being within an allowed subnet.

### Pitfall 7: Forgetting to Gitignore .pentest/
**What goes wrong:** Audit logs and scope files get committed to version control.
**Why it happens:** `.pentest/` is a new directory not yet in `.gitignore`.
**How to avoid:** Add `.pentest/` to `.gitignore` as part of this phase.
**Warning signs:** `git status` shows untracked files under `.pentest/`.

## Code Examples

### PreToolUse Hook Input (What Your Script Receives)
```json
// Source: https://code.claude.com/docs/en/hooks (PreToolUse input schema)
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../transcript.jsonl",
  "cwd": "/Users/patrykattc/work/git/networking-tools",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "bash scripts/nmap/discover-live-hosts.sh 192.168.1.1 -j -x",
    "description": "Discover live hosts on the target network"
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

### PreToolUse Deny Response (Block a Command)
```json
// Source: https://code.claude.com/docs/en/hooks (PreToolUse decision control)
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Target 10.0.0.1 is not in scope. Current scope: localhost, 192.168.1.0/24. Add targets with /scope command.",
    "additionalContext": "BLOCKED: target=10.0.0.1, tool=nmap, scope_file=.pentest/scope.json, allowed=[localhost,192.168.1.0/24]"
  }
}
```

### PreToolUse Allow Response (Approve a Command)
```bash
# Source: https://code.claude.com/docs/en/hooks (exit code 0 = allow)
# Simply exit 0 with no output to allow the command to proceed.
exit 0
```

### PostToolUse Hook Input (What Your Script Receives After Execution)
```json
// Source: https://code.claude.com/docs/en/hooks (PostToolUse input schema)
{
  "session_id": "abc123",
  "cwd": "/Users/patrykattc/work/git/networking-tools",
  "hook_event_name": "PostToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "bash scripts/nmap/discover-live-hosts.sh 192.168.1.1 -j -x"
  },
  "tool_response": {
    "stdout": "{\"meta\":{\"tool\":\"nmap\",\"script\":\"discover-live-hosts\",\"target\":\"192.168.1.1\"},\"results\":[...],\"summary\":{\"total\":10,\"succeeded\":8,\"failed\":2}}",
    "stderr": "[INFO] === Host Discovery ===\n[INFO] Target: 192.168.1.1",
    "exit_code": 0
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

### PostToolUse Response with additionalContext
```json
// Source: https://code.claude.com/docs/en/hooks (PostToolUse decision control)
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Netsec result: nmap (discover-live-hosts) against 192.168.1.1 in execute mode. 10 items: 8 succeeded, 2 failed."
  }
}
```

### JSONL Audit Log Entry Format
```json
{"timestamp":"2026-02-17T10:30:00Z","event":"blocked","session":"abc123","command":"nmap 10.0.0.1","tool":"nmap","target":"10.0.0.1","reason":"raw tool bypass","scope_file":".pentest/scope.json"}
{"timestamp":"2026-02-17T10:30:15Z","event":"allowed","session":"abc123","command":"bash scripts/nmap/discover-live-hosts.sh localhost -j -x","tool":"nmap","target":"localhost","script":"discover-live-hosts"}
{"timestamp":"2026-02-17T10:30:20Z","event":"executed","session":"abc123","command":"bash scripts/nmap/discover-live-hosts.sh localhost -j -x","tool":"nmap","target":"localhost","script":"discover-live-hosts","exit_code":0,"results_total":10,"results_ok":8,"results_fail":2}
```

### Health Check Script Structure
```bash
#!/usr/bin/env bash
# .claude/hooks/netsec-health.sh

PASS=0
FAIL=0
check() {
    local label="$1" result="$2"
    if [[ "$result" == "true" ]]; then
        echo "  [pass] $label"
        ((PASS++))
    else
        echo "  [FAIL] $label"
        ((FAIL++))
    fi
}

echo "=== Netsec Safety Health Check ==="

# Hook files exist
check "PreToolUse hook file exists" \
    "$([[ -f .claude/hooks/netsec-pretool.sh ]] && echo true || echo false)"
check "PostToolUse hook file exists" \
    "$([[ -f .claude/hooks/netsec-posttool.sh ]] && echo true || echo false)"

# Hook files executable
check "PreToolUse hook is executable" \
    "$([[ -x .claude/hooks/netsec-pretool.sh ]] && echo true || echo false)"

# Hooks registered in settings.json
check "PreToolUse hook registered in settings.json" \
    "$(jq -e '.hooks.PreToolUse' .claude/settings.json &>/dev/null && echo true || echo false)"
check "PostToolUse hook registered in settings.json" \
    "$(jq -e '.hooks.PostToolUse' .claude/settings.json &>/dev/null && echo true || echo false)"

# Scope file
check "Scope file exists (.pentest/scope.json)" \
    "$([[ -f .pentest/scope.json ]] && echo true || echo false)"
check "Scope file is valid JSON" \
    "$(jq -e '.targets' .pentest/scope.json &>/dev/null && echo true || echo false)"

# Audit directory
check "Audit directory exists (.pentest/)" \
    "$([[ -d .pentest/ ]] && echo true || echo false)"
check "Audit directory is writable" \
    "$([[ -w .pentest/ ]] && echo true || echo false)"

# .gitignore
check ".pentest/ is gitignored" \
    "$(git check-ignore -q .pentest/ 2>/dev/null && echo true || echo false)"

# jq available
check "jq is installed" \
    "$(command -v jq &>/dev/null && echo true || echo false)"

echo ""
echo "$PASS passed, $FAIL failed"
```

## Discretion Recommendations

### Allowlist Mechanism: Use a JSON scope file

**Recommendation:** Use `.pentest/scope.json` as the allowlist mechanism.

**Rationale:**
- A file persists between sessions (env vars do not)
- JSON is parseable by jq (already a dependency)
- A file can be inspected and edited by users outside Claude
- Phase 32's `/scope` command will manage this file
- The hidden `.pentest/` directory keeps it out of the working directory visual clutter
- The scope file format naturally extends to support CIDRs, port ranges, and notes

### Docker Lab Targets: Auto-allow when scope file is absent is NOT recommended

**Recommendation:** Require explicit scope even for Docker lab targets. No exceptions to the "no scope = block everything" rule.

**Rationale:**
- The locked decision says "No scope set = block everything"
- Auto-allowing lab targets creates a special case that complicates the hook logic
- Instead, the health check's guided repair should offer to create a scope file pre-populated with lab targets: `"targets": ["localhost", "127.0.0.1"]`
- This is explicit consent, not implicit trust

### PostToolUse JSON Parsing: Parse into summary

**Recommendation:** Parse the JSON envelope and inject a concise `additionalContext` summary.

**Rationale:**
- Raw JSON envelopes can be large (10 results with full stdout each)
- Claude already receives the full Bash stdout -- the hook's `additionalContext` should add value, not duplicate
- A one-line summary ("nmap (discover-live-hosts) against localhost: 10 items, 8 succeeded, 2 failed") gives Claude the signal it needs to decide next steps
- The summary costs ~30 tokens vs potentially hundreds for raw JSON

### Raw Tool Bypass: Hard block with redirect

**Recommendation:** Use `permissionDecision: "deny"` (hard block) with the redirect message in `permissionDecisionReason`.

**Rationale:**
- Claude Code's `deny` sends the reason directly to Claude, who can then suggest the correct wrapper script
- A "block-with-redirect" that somehow auto-rewrites the command would use `updatedInput` + `permissionDecision: "allow"`, which is more complex and skips the user's awareness
- Hard blocking is safer and simpler; Claude receives the redirect guidance and can propose the correct command
- The deny reason is terse + actionable per the locked decision: "Use scripts/nmap/discover-live-hosts.sh instead"

### Audit Log Fields: Recommended schema

**Recommendation:** Use these fields per JSONL entry:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | string | ISO 8601 UTC timestamp |
| `event` | string | "blocked", "allowed", "executed" |
| `session` | string | Claude Code session ID |
| `command` | string | Full command string |
| `tool` | string | Extracted tool name (nmap, nikto, etc.) |
| `target` | string | Extracted target (IP, hostname, URL) |
| `script` | string | Script name if wrapper was used, null if raw |
| `reason` | string | Block reason (only for blocked events) |
| `exit_code` | number | Exit code (only for executed events) |
| `results_total` | number | JSON envelope total count (only for -j executed events) |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Top-level `decision`/`reason` for PreToolUse | `hookSpecificOutput.permissionDecision` | Hooks reference update 2025 | Must use `hookSpecificOutput` pattern, not deprecated top-level fields |
| `exit 2` only for blocking | JSON `permissionDecision: "deny"` | Hooks reference | JSON approach allows richer feedback (additionalContext, structured reason) |
| Commands in `.claude/commands/` | Skills in `.claude/skills/` | Skills merge | Skills support frontmatter, hooks, supporting files. Commands still work but skills recommended |
| `tool_response` undocumented | `tool_response` with stdout/stderr/exit_code | Hooks reference | PostToolUse confirmed to receive full Bash output |

**Deprecated/outdated:**
- `permissionDecision: "approve"` -- use `"allow"` instead
- `permissionDecision: "block"` -- use `"deny"` instead
- Top-level `decision`/`reason` for PreToolUse -- use `hookSpecificOutput` instead (other events like PostToolUse/Stop still use top-level)

## Tool-to-Script Mapping

The PreToolUse hook needs to know which raw tools map to which wrapper scripts. Here is the complete mapping derived from the codebase:

| Raw Tool | Command Variants | Scripts Directory | Available Use-Case Scripts |
|----------|-----------------|-------------------|---------------------------|
| nmap | `nmap`, `sudo nmap` | `scripts/nmap/` | discover-live-hosts.sh, identify-ports.sh, scan-web-vulnerabilities.sh |
| tshark | `tshark` | `scripts/tshark/` | capture-http-credentials.sh, analyze-dns-queries.sh, extract-files-from-capture.sh |
| msfconsole | `msfconsole`, `msfvenom`, `msfdb` | `scripts/metasploit/` | generate-reverse-shell.sh, scan-network-services.sh, setup-listener.sh |
| sqlmap | `sqlmap` | `scripts/sqlmap/` | dump-database.sh, test-all-parameters.sh, bypass-waf.sh |
| nikto | `nikto` | `scripts/nikto/` | scan-specific-vulnerabilities.sh, scan-multiple-hosts.sh, scan-with-auth.sh |
| hashcat | `hashcat` | `scripts/hashcat/` | crack-ntlm-hashes.sh, benchmark-gpu.sh, crack-web-hashes.sh |
| john | `john` | `scripts/john/` | crack-linux-passwords.sh, crack-archive-passwords.sh, identify-hash-type.sh |
| hping3 | `hping3`, `sudo hping3` | `scripts/hping3/` | test-firewall-rules.sh, detect-firewall.sh |
| skipfish | `skipfish` | `scripts/skipfish/` | scan-authenticated-app.sh, quick-scan-web-app.sh |
| aircrack-ng | `aircrack-ng`, `airodump-ng`, `aireplay-ng`, `airmon-ng` | `scripts/aircrack-ng/` | capture-handshake.sh, crack-wpa-handshake.sh, analyze-wireless-networks.sh |
| dig | `dig` | `scripts/dig/` | (examples.sh + use-case scripts) |
| curl | `curl` | `scripts/curl/` | (examples.sh + use-case scripts) |
| nc/netcat | `nc`, `netcat`, `ncat` | `scripts/netcat/` | (examples.sh + use-case scripts) |
| traceroute | `traceroute`, `mtr` | `scripts/traceroute/` | (examples.sh + use-case scripts) |
| gobuster | `gobuster` | `scripts/gobuster/` | (examples.sh + use-case scripts) |
| ffuf | `ffuf` | `scripts/ffuf/` | (examples.sh + use-case scripts) |
| foremost | `foremost` | `scripts/foremost/` | (examples.sh + use-case scripts) |

**Note on curl and dig:** These tools are commonly used for non-pentesting purposes (downloading files, DNS lookups). The hook should only intercept them when used with pentesting-style arguments (e.g., targets not in scope) rather than blocking all uses. This nuance should be handled carefully in implementation. A practical approach: only intercept if the command includes a target argument that looks like an IP/hostname (not a URL like `https://api.example.com/...`).

## Open Questions

1. **PostToolUse `tool_response.stdout` exact field names for Bash**
   - What we know: The hooks reference shows `tool_response` with a Write tool example (`filePath`, `success`). Multiple secondary sources confirm Bash returns `stdout`, `stderr`, `exit_code`. The prior project research flagged this for validation.
   - What's unclear: The official hooks reference does not show a Bash-specific `tool_response` example. Field names may differ slightly.
   - Recommendation: Test during implementation by creating a minimal PostToolUse hook that dumps `tool_response` to a file: `echo "$INPUT" | jq '.tool_response' > /tmp/tool-response-debug.json`. Validate in the first task before building the full JSON bridge.

2. **Target extraction from complex commands**
   - What we know: Nmap commands are `nmap [flags] <target>`, but flags can appear before or after the target. Some tools use `-u URL` (sqlmap), some use positional args.
   - What's unclear: How reliable regex-based target extraction will be across all 17 tools.
   - Recommendation: For v1, extract the target from wrapper script invocations (it's always the first positional arg after the script name: `bash scripts/nmap/discover-live-hosts.sh TARGET ...`). For raw tool interception, the target is less critical since the whole command is blocked anyway.

3. **Hook timeout considerations**
   - What we know: Default hook timeout is 600 seconds (10 minutes). PreToolUse hooks should be fast (< 100ms).
   - What's unclear: Whether jq parsing of the scope file and stdin creates measurable latency.
   - Recommendation: Set explicit `timeout: 10` (seconds) on both hooks. If jq parsing is slow, the command simply proceeds (non-blocking on timeout).

## Sources

### Primary (HIGH confidence)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) -- Complete PreToolUse/PostToolUse examples, exit codes, JSON output format, matchers, settings.json structure
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) -- Full event schemas, `tool_input` fields for Bash/Write/Edit/Read/etc., `hookSpecificOutput` format, `permissionDecision` values, `additionalContext`, `updatedInput`, PostToolUse `tool_response`, environment variables (`$CLAUDE_PROJECT_DIR`)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Skill frontmatter fields, `disable-model-invocation`, hooks in skill frontmatter, skill directory structure
- [Anthropic Bash Command Validator Example](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py) -- Official reference implementation for PreToolUse validation hook
- Direct codebase analysis: `scripts/check-tools.sh` -- Complete list of 18 tools in TOOL_ORDER array
- Direct codebase analysis: `scripts/lib/json.sh`, `scripts/lib/args.sh`, `scripts/lib/output.sh` -- fd3 JSON redirect protocol, envelope schema
- Direct codebase analysis: `.claude/settings.json`, `.claude/hooks/` -- Current hook configuration, GSD integration patterns
- Direct codebase analysis: `.planning/research/ARCHITECTURE.md` -- Prior architecture decisions, JSON bridge pattern, settings.json modification strategy

### Secondary (MEDIUM confidence)
- WebSearch results confirming PostToolUse Bash `tool_response` contains `stdout`, `stderr`, `exit_code` fields -- multiple sources agree but official reference uses Write tool example, not Bash

### Tertiary (LOW confidence)
- None -- all findings verified against official documentation or codebase analysis

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- bash+jq is the project's existing stack; hooks API is thoroughly documented in official docs
- Architecture: HIGH -- PreToolUse/PostToolUse patterns are well-documented with official examples; JSON bridge pattern validated in prior project research
- Pitfalls: HIGH -- common issues (permissions, shell profile corruption, slow hooks) documented in official troubleshooting guide
- PostToolUse tool_response fields: MEDIUM -- multiple sources agree on stdout/stderr/exit_code but official docs lack a Bash-specific example; flagged for validation

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (hooks API is stable; 30-day validity)
