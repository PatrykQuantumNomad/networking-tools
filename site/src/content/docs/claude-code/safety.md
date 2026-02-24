---
title: "Safety & Scope"
description: "How the safety architecture protects against unauthorized scanning: target allowlists, raw tool interception, JSON bridge, audit logging, and the /netsec-health diagnostic."
sidebar:
  order: 4
---

The safety architecture ensures all security tool usage goes through validated, audited channels. Four mechanisms work together to prevent unauthorized scanning and produce structured output.

## Safety Mechanisms

| ID | Mechanism | Hook | Purpose |
|----|-----------|------|---------|
| SAFE-01 | Target Allowlist | PreToolUse | Block commands targeting hosts not in scope |
| SAFE-02 | Raw Tool Interception | PreToolUse | Force usage of wrapper scripts instead of direct tool invocations |
| SAFE-03 | JSON Bridge | PostToolUse | Parse `-j` output and inject structured summaries into Claude |
| SAFE-04 | Audit Logging | Both | Log every security tool invocation to JSONL files |

## Target Allowlist (SAFE-01)

All security tool commands are validated against `.pentest/scope.json` before execution. If the target is not in scope, the command is blocked.

### Scope File Format

```json
{"targets": ["localhost", "127.0.0.1", "192.168.1.0/24"]}
```

### Managing Scope

Use the `/scope` skill to manage targets:

```
/scope init              # Create with localhost defaults
/scope show              # Display current targets
/scope add 10.0.0.5      # Add a target (requires confirmation)
/scope remove 10.0.0.5   # Remove a target (requires confirmation)
/scope clear             # Remove all targets (requires confirmation)
```

### Matching Rules

- **Exact match:** `localhost` matches commands targeting `localhost`
- **Localhost equivalence:** `localhost` and `127.0.0.1` are treated as the same target
- **CIDR /24 matching:** Adding `192.168.1.0/24` allows any host in the `192.168.1.x` range
- **URL host extraction:** For URLs like `http://localhost:8080/path`, the host `localhost` is extracted and checked

### What Happens When Blocked

When a target is not in scope, the PreToolUse hook blocks the command and returns a message explaining why. Claude will tell you the target was rejected and suggest adding it with `/scope add <target>`.

## Raw Tool Interception (SAFE-02)

The PreToolUse hook blocks direct invocations of security tools. Instead of running `nmap localhost` directly, you must use the wrapper scripts:

```bash
# Blocked:
nmap localhost

# Allowed:
bash scripts/nmap/identify-ports.sh localhost -j -x
```

This ensures all tool usage produces structured output and goes through scope validation.

**Intercepted tools:** nmap, tshark, nikto, sqlmap, msfconsole, msfvenom, hashcat, john, hping3, skipfish, aircrack-ng, airodump-ng, aireplay-ng, airmon-ng, gobuster, ffuf, foremost, dig, curl, nc, netcat, ncat, traceroute, mtr

**Exceptions:** `curl` and `dig` with `https://` URLs are allowed through for non-security use (e.g., fetching documentation).

## JSON Bridge (SAFE-03)

The PostToolUse hook detects when a command includes the `-j` flag and parses the JSON envelope output. It injects a structured summary into Claude's context:

```
Netsec result: nmap (identify-ports) against localhost in execute mode.
10 items: 10 succeeded, 0 failed.
```

This gives Claude organized, parseable results instead of raw terminal output. Without `-j`, Claude would need to interpret unstructured text.

## Audit Logging (SAFE-04)

Every security tool invocation is logged to `.pentest/audit-YYYY-MM-DD.jsonl` in newline-delimited JSON format.

### Log Entry Fields

| Field | Description |
|-------|-------------|
| `timestamp` | UTC ISO 8601 timestamp |
| `event` | `allowed`, `blocked`, or `executed` |
| `tool` | Security tool name (e.g., nmap, nikto) |
| `command` | Full command string |
| `target` | Extracted target from command |
| `reason` | Why the command was allowed or blocked |
| `script` | Wrapper script path (if applicable) |
| `session` | Claude Code session identifier |

### Reviewing Audit Logs

```bash
# View all entries from today
jq . .pentest/audit-$(date +%Y-%m-%d).jsonl

# Filter blocked commands
jq 'select(.event == "blocked")' .pentest/audit-*.jsonl

# Count events by type
jq -s 'group_by(.event) | map({event: .[0].event, count: length})' .pentest/audit-*.jsonl
```

The `.pentest/` directory is gitignored to prevent committing audit data or scope files.

## Health Check

Run `/netsec-health` to verify the safety architecture is operational. It checks five categories:

| Category | What It Checks |
|----------|---------------|
| Hook Files | PreToolUse and PostToolUse scripts exist and are executable |
| Hook Registration | Hooks are registered in `.claude/settings.json` |
| Scope Configuration | `.pentest/scope.json` exists with a valid targets array |
| Audit Infrastructure | `.pentest/` directory exists, is writable, and is gitignored |
| Dependencies | `jq` is installed and bash supports associative arrays |

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Command blocked unexpectedly | Target not in scope | `/scope add <target>` |
| "Raw tool bypass" error | Using direct tool instead of wrapper | Use `/nmap` skill or `bash scripts/nmap/...` |
| No JSON summary after tool runs | Missing `-j` flag | Skills add this automatically; check the command |
| Hooks not firing | Not registered in settings | Run `/netsec-health` to diagnose |
| "jq not found" error | jq not installed | `brew install jq` (macOS) or `apt install jq` (Linux) |
| Scope file missing | Not initialized | `/scope init` |
| Health check fails on audit dir | `.pentest/` does not exist | `mkdir -p .pentest` |
