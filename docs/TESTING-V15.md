# Testing Guide: v1.5 Claude Skill Pack

This guide provides concrete, copy-pasteable steps to verify every feature added in the v1.5 Claude Skill Pack milestone. Follow each section in order. Expected outputs are described so you know whether a test passed or failed.

---

## Prerequisites

All tests require an active Claude Code session opened in this repository root.

**1. Create `.pentest/scope.json` before any hook tests.**

The safety hooks block all security tool commands until this file exists.

```bash
mkdir -p .pentest && echo '{"targets":["localhost","127.0.0.1"]}' > .pentest/scope.json
```

Verify:

```bash
cat .pentest/scope.json
```

Expected output:

```json
{"targets":["localhost","127.0.0.1"]}
```

**2. (Optional) Start Docker lab targets.** Required for workflow smoke tests, optional for hook-only tests.

```bash
make lab-up
```

**3. Run health check first.** Inside Claude Code, type:

```
/netsec-health
```

Confirm all checks pass before proceeding. If any check fails, follow the guided repair prompts before running further tests.

---

## 1. Safety Hooks

The safety hooks run automatically on every Bash tool call Claude Code makes. There are two hooks: `netsec-pretool.sh` (PreToolUse) and `netsec-posttool.sh` (PostToolUse).

### 1a. Scope Setup

`.pentest/scope.json` controls which targets the hooks allow. The file format is:

```json
{"targets":["localhost","127.0.0.1"]}
```

Targets can be:
- Hostnames: `"example.com"`
- IP addresses: `"192.168.1.10"`
- CIDR /24 prefixes: `"192.168.1.0"` (matches any address in 192.168.1.0/24)

`localhost` and `127.0.0.1` are treated as equivalent by the hooks.

Test:

```bash
cat .pentest/scope.json
```

Expected output: JSON with a `targets` array. If the file is missing, the PreToolUse hook will block all security tool commands.

---

### 1b. PreToolUse: Out-of-Scope Block

This test verifies the hook blocks commands targeting hosts not in scope.

Inside Claude Code, ask Claude to run:

```bash
nmap 10.0.0.1
```

Expected behavior: Claude Code blocks the command before execution. The hook outputs a denial message stating that `10.0.0.1` is not in scope, and suggests adding it via `/scope add 10.0.0.1` or by editing `.pentest/scope.json` directly.

The command is never executed. No network traffic is generated.

---

### 1c. PreToolUse: Raw Tool Interception

This test verifies the hook intercepts raw security tool invocations (those not going through wrapper scripts) and redirects Claude to the correct wrapper.

Inside Claude Code, ask Claude to run:

```bash
nmap localhost
```

Expected behavior: Claude Code blocks the raw `nmap` command and suggests using the wrapper script instead:

```bash
bash scripts/nmap/identify-ports.sh localhost
```

The hook does NOT block commands where `scripts/` is already in the command path.

Confirm wrapper scripts pass through without interference:

```bash
bash scripts/nmap/identify-ports.sh localhost
```

Expected behavior: The wrapper script executes normally. The hook allows it through because the command path contains `scripts/`.

---

### 1d. PostToolUse: JSON Bridge (additionalContext)

This test verifies the PostToolUse hook parses JSON envelope output from wrapper scripts and injects a structured summary into Claude's context window.

Run any wrapper script with the `-j` flag (JSON output mode):

```bash
bash scripts/nmap/identify-ports.sh localhost -j
```

Expected behavior:
1. The script outputs a JSON envelope on stdout in this format:
   ```json
   {"tool":"nmap","summary":"...","raw":"..."}
   ```
2. Claude's next message includes an `additionalContext` note summarizing the scan result. This is the PostToolUse hook's JSON bridge in action -- it parsed the envelope and injected the summary so Claude can reason about the output without reading raw text.

---

### 1e. JSONL Audit Logging

Verify that every hook event (allowed or blocked) is appended to a date-stamped JSONL audit log.

```bash
ls .pentest/
```

Expected: you see at least one `audit-YYYY-MM-DD.jsonl` file alongside `scope.json`.

```bash
cat .pentest/audit-$(date +%Y-%m-%d).jsonl
```

Expected output: one JSON object per line. Each entry includes these fields:

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 timestamp |
| `event` | `allowed` or `blocked` |
| `tool` | The tool name (e.g., `nmap`) |
| `command` | The full command string |
| `target` | The target extracted from the command |
| `session` | Session identifier |

---

## 2. Health-Check Diagnostic

Inside Claude Code, type:

```
/netsec-health
```

Claude runs `.claude/hooks/netsec-health.sh` and displays a categorized diagnostic report.

Expected output: 5 categories checked:

| Category | What it checks |
|----------|---------------|
| Hook Files | `.claude/hooks/netsec-pretool.sh` and `netsec-posttool.sh` exist and are executable |
| Hook Registration | `.claude/settings.json` has correct `PreToolUse` and `PostToolUse` entries |
| Scope File | `.pentest/scope.json` exists and is valid JSON |
| Audit Directory | `.pentest/` directory exists and is writable |
| Dependencies | `jq`, `nmap`, and other required tools are installed |

All checks show PASS for a correctly configured repo. Any failures include a guided repair prompt with the exact command to fix the issue.

To run the health check directly in a terminal (outside Claude Code):

```bash
bash .claude/hooks/netsec-health.sh
```

---

## 3. Scope Management (/scope)

The `/scope` skill lets you inspect and modify `.pentest/scope.json` from inside Claude Code without editing the file manually.

**Show current scope:**

```
/scope
```

or

```
/scope show
```

Expected: Claude displays the current contents of `.pentest/scope.json`.

**Add a target:**

```
/scope add 192.168.1.100
```

Expected: Claude asks for confirmation, then writes the updated scope.json. Verify:

```bash
cat .pentest/scope.json
```

The target `192.168.1.100` should now appear in the `targets` array.

**Remove a target:**

```
/scope remove 192.168.1.100
```

Expected: Claude asks for confirmation, removes the entry, and confirms the change.

**Initialize scope with lab targets:**

```
/scope init
```

Expected: scope.json is populated with standard lab targets including `localhost`, `127.0.0.1`, and the Docker lab target addresses (`127.0.0.1:8080`, `127.0.0.1:3030`, `127.0.0.1:8888`, `127.0.0.1:8180`).

---

## 4. Tool Skills (17 skills)

Tool skills are Claude Code slash commands that display documentation for a specific security tool -- which scripts are available, their arguments, and flags.

Tool skills use `disable-model-invocation: true`, which means Claude will NOT auto-invoke them mid-conversation. You must call them explicitly with a slash command.

The 17 tool skills are:

`nmap`, `tshark`, `metasploit`, `sqlmap`, `nikto`, `hashcat`, `john`, `hping3`, `aircrack-ng`, `skipfish`, `gobuster`, `ffuf`, `dig`, `curl`, `netcat`, `traceroute`, `foremost`

### 4a. Listing available tool skills

Inside Claude Code, type `/` to open the command menu. All 17 tool skills appear alongside workflow skills, utility skills, and subagent personas.

### 4b. Invoking a tool skill

Example with nmap:

```
/nmap
```

Expected: Claude displays the nmap skill content, including:
- Available scripts: `discover-live-hosts`, `identify-ports`, `scan-web-vulnerabilities`, `examples`
- Script arguments and required parameters
- Flag documentation: `-j` (JSON envelope output), `-x` (extended/verbose output)
- Note about target validation via scope.json

Test a second skill to confirm the pattern:

```
/sqlmap
```

Expected: Claude displays sqlmap scripts (`dump-database`, `test-all-parameters`, `bypass-waf`, `examples`) with argument documentation.

Note: Tool skills are navigation and documentation layers. They tell you which script to run and how to call it. To execute a scan, ask Claude to run the specific script command shown in the skill output.

---

## 5. Workflow Skills (8 skills)

Workflow skills orchestrate multiple tool scripts in sequence to accomplish a complete task. All 8 use `disable-model-invocation: true` -- you must invoke them explicitly.

Before running any workflow skill that involves network tools, ensure the target is in scope:

```
/scope add localhost
```

### 5a. /recon

```
/recon localhost
```

Expected: Claude runs 6 sequential steps:
1. nmap host discovery (`discover-live-hosts`)
2. nmap port scan (`identify-ports`)
3. DNS A record lookup (`dig`)
4. DNS zone transfer attempt (`dig`)
5. SSL certificate inspection (`curl`)
6. gobuster subdomain enumeration

Each step uses `-j -x` flags where applicable. Claude summarizes the JSON envelope output from each step.

### 5b. /scan

```
/scan localhost
```

Expected: Claude runs 5 sequential steps:
1. nmap port/service scan with version detection
2. nmap NSE web vulnerability scan
3. nikto web server analysis
4. sqlmap SQL injection test
5. curl endpoint test for common paths

### 5c. /diagnose

```
/diagnose localhost
```

Expected: Claude runs 5 sequential steps. Steps 1-3 use diagnostics-style scripts that produce plain text output (Pattern B -- no `-j`/`-x` flags). Steps 4-5 use tool wrapper scripts with `-j -x`. Claude notes which output pattern each step uses.

### 5d. /fuzz

```
/fuzz http://localhost:8080
```

Expected: Claude runs ffuf and gobuster fuzzing steps against the target URL. If DVWA is running at `http://localhost:8080`, you will see directory and file enumeration results.

### 5e. /crack

Requires a hash file. Create a test hash (this is the MD5 of "password"):

```bash
echo "5f4dcc3b5aa765d61d8327deb882cf99" > /tmp/test.hash
```

Then invoke the skill:

```
/crack /tmp/test.hash ntlm
```

Expected: Claude runs hashcat or john with the appropriate cracking script for the specified hash type, pointing at the test hash file.

### 5f. /sniff

```
/sniff en0
```

Replace `en0` with your active network interface. Find yours with:

```bash
ifconfig | grep -E "^[a-z]" | cut -d: -f1
```

Expected: Claude runs tshark packet capture scripts referencing `capture-http-credentials` and `analyze-dns-queries`. Note: live capture requires root or appropriate network permissions.

### 5g. /report

After running one or more workflow skills in the current session:

```
/report
```

Expected: Claude synthesizes findings from the current conversation context into a severity-organized markdown report with sections: Critical, High, Medium, Low, Informational. The report is written to `report-YYYY-MM-DD.md` in the repository root.

Important: Claude synthesizes from session context only. It does NOT read audit log files.

Verify the file was created:

```bash
ls report-*.md
```

### 5h. /scope (workflow)

Covered in section 3 above. The `/scope` slash command serves as both a workflow skill and a utility skill.

---

## 6. Utility Skills

Utility skills are shortcuts for common repository maintenance tasks.

### 6a. /check-tools

```
/check-tools
```

Expected: Claude runs `bash scripts/check-tools.sh` and reports which of the 18 tools are installed vs. missing, with install hints for any missing tools.

Verify directly in a terminal:

```bash
make check
```

### 6b. /lab

**Start the lab:**

```
/lab up
```

Expected: Claude runs `make lab-up`. Docker containers start for all 4 vulnerable targets.

**Check status:**

```
/lab status
```

Expected: Claude runs `make lab-status` and shows which containers are running.

**Stop the lab:**

```
/lab down
```

Expected: Claude runs `make lab-down`. All containers stop.

Lab targets when running:

| Service | URL | Credentials |
|---------|-----|-------------|
| DVWA | http://localhost:8080 | admin / password |
| Juice Shop | http://localhost:3030 | (register) |
| WebGoat | http://localhost:8888 | (register) |
| VulnerableApp | http://localhost:8180 | -- |

---

## 7. Subagent Personas

Subagent personas spawn isolated Claude Code sub-agents with specific tool access and a focused role. Each uses `context: fork` to run in a separate context window, isolated from the parent conversation history.

### 7a. /pentester

```
/pentester
```

Expected: Spawns a pentester subagent with full Bash access and 6 preloaded skills: `pentest-conventions`, `recon`, `scan`, `fuzz`, `crack`, `sniff`. The agent introduces itself and asks for a target.

Test the agent:

```
Target is localhost. Run a recon.
```

Expected: The agent runs the `/recon` workflow steps using wrapper scripts, validates the target against scope.json before each command, and summarizes findings. The agent operates entirely within the forked context -- it does not share conversation history with the parent session.

### 7b. /defender

```
/defender
```

Expected: Spawns a defender subagent with read-only tools (Read, Grep, Glob -- no Bash, no Write). The agent introduces itself for defensive analysis and hardening review.

Test the agent:

```
Analyze the netsec-pretool.sh hook for security weaknesses.
```

Expected: The agent reads `.claude/hooks/netsec-pretool.sh`, uses Grep to analyze patterns, and provides a defensive analysis identifying potential weaknesses or hardening opportunities. The agent will NOT execute any shell commands.

### 7c. /analyst

```
/analyst
```

Expected: Spawns an analyst subagent with Read, Grep, Glob, and Write access (no Bash). The agent introduces itself for report synthesis and structured analysis.

Test the agent (use a report file from section 5g):

```
Synthesize the findings from report-*.md into an executive summary.
```

Expected: The agent reads the report file(s), synthesizes the findings by severity, and writes a structured executive summary. It will NOT execute bash commands. It uses only the Read/Grep/Glob tools to gather data and Write to produce output.

---

## 8. Full End-to-End Smoke Test

This test exercises the complete v1.5 stack in sequence from a fresh session.

1. Start a fresh Claude Code session in the repository root.
2. Run `/netsec-health` -- confirm all 5 categories pass.
3. Run `/scope init` -- confirm scope.json contains lab target addresses.
4. Run `make lab-up` in a terminal -- confirm Docker containers start.
5. Run `/recon localhost` -- confirm all 6 steps execute. Then check:
   ```bash
   cat .pentest/audit-$(date +%Y-%m-%d).jsonl
   ```
   Confirm new entries were appended during the recon run.
6. Run `/scan localhost` -- confirm all 5 steps execute without errors.
7. Run `/report` -- confirm `report-YYYY-MM-DD.md` is created in the repo root.
8. Run `make lab-down` in a terminal -- confirm containers stop.

If all 8 steps complete without errors, and both the audit log and report file exist with content, the v1.5 Claude Skill Pack is working end-to-end.

---

## Troubleshooting

**Hook not firing:** Check hook registration in `.claude/settings.json`. The file must have `PreToolUse` and `PostToolUse` entries pointing to `.claude/hooks/netsec-pretool.sh` and `.claude/hooks/netsec-posttool.sh`. Run `/netsec-health` for guided diagnosis.

**scope.json missing:** The PreToolUse hook will block ALL security tool commands until `.pentest/scope.json` exists. Create it:

```bash
mkdir -p .pentest && echo '{"targets":["localhost","127.0.0.1"]}' > .pentest/scope.json
```

**Docker lab not starting:** Ensure Docker Desktop is running. Check for port conflicts on 8080, 3030, 8888, 8180:

```bash
lsof -i :8080 -i :3030 -i :8888 -i :8180
```

**Skill not appearing in / menu:** Skills must be in `.claude/skills/<name>/SKILL.md`. Verify all 33 skill directories exist:

```bash
ls .claude/skills/ | wc -l
```

Expected: 33 (17 tool + 8 workflow + 3 utility + 3 subagent + 2 meta skills).

**Subagent not forking:** The `/pentester`, `/defender`, `/analyst` skills require `context: fork` in their SKILL.md frontmatter. Verify:

```bash
grep "context:" .claude/skills/pentester/SKILL.md
```

Expected output: `context: fork`

**PostToolUse hook not injecting additionalContext:** Verify the script produces a valid JSON envelope. The JSON must be the last line of stdout and contain `tool`, `summary`, and `raw` keys. Malformed JSON is silently skipped by the hook.

---

*Guide covers v1.5 Claude Skill Pack (Phases 28-33, shipped 2026-02-18)*
*17 tool skills, 8 workflow skills, 3 utility skills, 3 subagent personas*
