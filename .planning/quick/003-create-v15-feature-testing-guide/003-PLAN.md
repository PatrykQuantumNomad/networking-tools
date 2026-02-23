---
phase: quick-003
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - docs/TESTING-V15.md
autonomous: true
requirements: []

must_haves:
  truths:
    - "User can verify each v1.5 feature category with concrete commands"
    - "Guide is self-contained -- no cross-referencing needed to run a test"
    - "Each section states what to expect when the feature is working"
  artifacts:
    - path: "docs/TESTING-V15.md"
      provides: "Standalone testing guide for all v1.5 Claude Skill Pack features"
      min_lines: 120
  key_links:
    - from: "docs/TESTING-V15.md"
      to: ".pentest/scope.json"
      via: "scope setup instructions before any hook tests"
      pattern: "scope.json"
---

<objective>
Create a standalone testing guide (docs/TESTING-V15.md) covering all features added in the v1.5 Claude Skill Pack milestone: safety hooks, tool skills, workflow skills, utility skills, subagent personas, and scope management.

Purpose: Give the user a single reference document with concrete test steps and expected outputs for every v1.5 feature, so they can verify the milestone works end-to-end in a fresh Claude Code session.
Output: docs/TESTING-V15.md -- a self-contained markdown guide.
</objective>

<execution_context>
@./.claude/get-shit-done/workflows/execute-plan.md
@./.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create docs/ directory and write TESTING-V15.md</name>
  <files>docs/TESTING-V15.md</files>
  <action>
Create the `docs/` directory and write `docs/TESTING-V15.md` with the following structure and content. Use plain markdown, no emojis. The guide must be self-contained -- a user should be able to follow it without reading any other file.

---

## File structure

```
# Testing Guide: v1.5 Claude Skill Pack

## Prerequisites
## 1. Safety Hooks
### 1a. Scope Setup
### 1b. PreToolUse: Out-of-Scope Block
### 1c. PreToolUse: Raw Tool Interception
### 1d. PostToolUse: JSON Bridge (additionalContext)
### 1e. JSONL Audit Logging
## 2. Health-Check Diagnostic
## 3. Scope Management (/scope)
## 4. Tool Skills (17 skills)
### 4a. Listing available tool skills
### 4b. Invoking a tool skill
## 5. Workflow Skills (8 skills)
### 5a. /recon
### 5b. /scan
### 5c. /diagnose
### 5d. /fuzz
### 5e. /crack
### 5f. /sniff
### 5g. /report
### 5h. /scope (workflow)
## 6. Utility Skills
### 6a. /check-tools
### 6b. /lab
## 7. Subagent Personas
### 7a. /pentester
### 7b. /defender
### 7c. /analyst
## 8. Full End-to-End Smoke Test
```

---

## Content requirements per section

### Prerequisites

Explain:
- All tests require an active Claude Code session in this repository.
- `.pentest/scope.json` must exist before running hook tests. If it doesn't, run:
  ```bash
  mkdir -p .pentest && echo '{"targets":["localhost","127.0.0.1"]}' > .pentest/scope.json
  ```
- The lab Docker targets (optional for hook tests, required for workflow smoke tests):
  ```bash
  make lab-up
  ```
- Run `/netsec-health` inside Claude Code to confirm baseline health before testing anything else.

---

### 1a. Scope Setup

Show the user that `.pentest/scope.json` controls what targets are allowed. Show the file format:
```json
{"targets":["localhost","127.0.0.1"]}
```
Explain: targets can be hostnames, IPs, or CIDR /24 prefixes (e.g. "192.168.1.0"). localhost and 127.0.0.1 are treated as equivalent.

Test: verify the file exists:
```bash
cat .pentest/scope.json
```
Expected output: JSON with a targets array.

---

### 1b. PreToolUse: Out-of-Scope Block

This test verifies the hook blocks commands targeting out-of-scope hosts.

Ask Claude to run:
```bash
nmap 10.0.0.1
```
Expected behavior: Claude Code blocks the command before execution. The hook outputs a denial message stating the target is not in scope, and suggests adding it via `/scope add 10.0.0.1` or editing `.pentest/scope.json`.

---

### 1c. PreToolUse: Raw Tool Interception

This test verifies the hook intercepts raw security tool invocations (bypassing wrapper scripts) and redirects to the correct wrapper.

Ask Claude to run:
```bash
nmap localhost
```
Expected behavior: Claude Code blocks the raw nmap command and suggests using `bash scripts/nmap/identify-ports.sh localhost` instead. The hook does NOT block if `scripts/` is already in the command path.

Confirm wrapper scripts pass through:
```bash
bash scripts/nmap/identify-ports.sh localhost
```
Expected behavior: Executes without hook interference.

---

### 1d. PostToolUse: JSON Bridge (additionalContext)

This test verifies the PostToolUse hook parses -j envelope output and injects a structured summary into Claude's context.

Run any wrapper script with the -j flag:
```bash
bash scripts/nmap/identify-ports.sh localhost -j
```
Expected behavior: The script outputs a JSON envelope (`{"tool":"nmap","summary":"...","raw":"..."}`). Claude's next message should include an `additionalContext` note summarizing the scan result -- this is the PostToolUse hook's JSON bridge in action.

---

### 1e. JSONL Audit Logging

Verify that hook events are logged to a date-stamped JSONL file.

```bash
ls .pentest/
cat .pentest/audit-$(date +%Y-%m-%d).jsonl
```
Expected output: One JSON object per line. Each entry has `timestamp`, `event` (allowed/blocked), `tool`, `command`, `target`, and `session` fields.

---

### 2. Health-Check Diagnostic

Inside Claude Code, type:
```
/netsec-health
```
Claude runs `.claude/hooks/netsec-health.sh` and displays a categorized report.

Expected output: 5 categories checked (Hook Files, Hook Registration, Scope File, Audit Directory, Dependencies). All checks PASS for a correctly configured repo. Any failures include a guided repair prompt.

To run the health check directly in a terminal:
```bash
bash .claude/hooks/netsec-health.sh
```

---

### 3. Scope Management (/scope)

Inside Claude Code:

Show current scope:
```
/scope
```
or
```
/scope show
```
Expected: displays `.pentest/scope.json` contents.

Add a target:
```
/scope add 192.168.1.100
```
Expected: Claude asks for confirmation, then updates scope.json. Verify with `cat .pentest/scope.json`.

Remove a target:
```
/scope remove 192.168.1.100
```
Expected: Claude asks for confirmation, removes the entry.

Initialize scope with lab targets:
```
/scope init
```
Expected: scope.json populated with localhost, 127.0.0.1, and the Docker lab target IPs (127.0.0.1:8080 etc.).

---

### 4. Tool Skills (17 skills)

#### 4a. Listing available tool skills

Inside Claude Code, the `/` menu shows all user-invocable skills. Tool skills with `disable-model-invocation: true` appear in the menu but Claude will NOT auto-invoke them -- you must call them explicitly.

The 17 tool skills are:
nmap, tshark, metasploit, sqlmap, nikto, hashcat, john, hping3, aircrack-ng, skipfish, gobuster, ffuf, dig, curl, netcat, traceroute, foremost

#### 4b. Invoking a tool skill

Example with nmap:
```
/nmap
```
Expected: Claude displays the nmap skill content listing available scripts (discover-live-hosts, identify-ports, scan-web-vulnerabilities, examples), their arguments, flags (-j for JSON, -x for extended), and target validation note.

Test one other skill to confirm the pattern:
```
/sqlmap
```
Expected: displays sqlmap scripts (dump-database, test-all-parameters, bypass-waf, examples) with argument documentation.

Note: tool skills are navigation layers. They tell you which script to run and how. To actually execute, ask Claude to run the specific script command shown in the skill output.

---

### 5. Workflow Skills (8 skills)

Workflow skills orchestrate multiple tool scripts in sequence. All use `disable-model-invocation: true` -- invoke explicitly.

Before running any workflow skill that involves network tools, ensure the target is in scope:
```
/scope add localhost
```

#### 5a. /recon

```
/recon localhost
```
Expected: Claude runs 6 steps -- nmap host discovery, port scan, DNS A record, DNS zone transfer attempt, SSL certificate inspection, gobuster subdomain enumeration. Each step uses the -j -x flags and Claude summarizes the JSON output.

#### 5b. /scan

```
/scan localhost
```
Expected: Claude runs 5 steps -- nmap port/service scan, nmap NSE web vulnerability scan, nikto analysis, sqlmap SQL injection test, curl endpoint test.

#### 5c. /diagnose

```
/diagnose localhost
```
Expected: Claude runs 5 steps. Steps 1-3 use diagnostics scripts (Pattern B -- text output, no -j/-x flags). Steps 4-5 use tool wrappers with -j -x. Claude notes which pattern each step uses.

#### 5d. /fuzz

```
/fuzz http://localhost:8080
```
Expected: Claude runs ffuf and gobuster fuzzing steps against the target URL.

#### 5e. /crack

Requires a hash file. Create a test hash:
```bash
echo "5f4dcc3b5aa765d61d8327deb882cf99" > /tmp/test.hash
```
Then:
```
/crack /tmp/test.hash ntlm
```
Expected: Claude runs hashcat or john with the appropriate cracking script.

#### 5f. /sniff

```
/sniff en0
```
(Replace `en0` with your active interface from `ifconfig`.)
Expected: Claude runs tshark packet capture scripts referencing capture-http-credentials and analyze-dns-queries.

#### 5g. /report

After running some workflow skills in the session:
```
/report
```
Expected: Claude synthesizes findings from the current conversation context into a severity-organized markdown report (Critical/High/Medium/Low/Informational) and writes it to `report-YYYY-MM-DD.md` in the repo root. Claude does NOT read audit log files -- synthesis is from session context only.

Verify the file was created:
```bash
ls report-*.md
```

#### 5h. /scope (workflow)

Covered in section 3 above. The `/scope` skill is both a workflow skill and a utility -- same slash command.

---

### 6. Utility Skills

#### 6a. /check-tools

```
/check-tools
```
Expected: Claude runs `bash scripts/check-tools.sh` and reports which of the 18 tools are installed vs. missing with install hints for missing tools.

Verify directly:
```bash
make check
```

#### 6b. /lab

Start the lab:
```
/lab up
```
Expected: Claude runs `make lab-up`, Docker containers start.

Check status:
```
/lab status
```
Expected: Claude runs `make lab-status`, shows running containers.

Stop the lab:
```
/lab down
```
Expected: Claude runs `make lab-down`.

Lab targets when running:
| Service | URL | Credentials |
|---------|-----|-------------|
| DVWA | http://localhost:8080 | admin / password |
| Juice Shop | http://localhost:3030 | (register) |
| WebGoat | http://localhost:8888 | (register) |
| VulnerableApp | http://localhost:8180 | -- |

---

### 7. Subagent Personas

Subagent personas spawn isolated Claude Code sub-agents with specific tool access. Each uses `context: fork` to run in a separate context window.

#### 7a. /pentester

```
/pentester
```
Expected: Spawns a pentester subagent with full Bash access and 6 preloaded skills (pentest-conventions, recon, scan, fuzz, crack, sniff). The agent introduces itself and asks for a target.

Test the agent:
```
Target is localhost. Run a recon.
```
Expected: Agent runs the /recon workflow steps using wrapper scripts, validates scope, and summarizes findings.

Note: the agent's context is isolated (forked). It does not share conversation history with the parent session.

#### 7b. /defender

```
/defender
```
Expected: Spawns a defender subagent with read-only tools (Read, Grep, Glob -- no Bash, no Write). The agent introduces itself for defensive/hardening analysis.

Test the agent:
```
Analyze the netsec-pretool.sh hook for security weaknesses.
```
Expected: Agent reads `.claude/hooks/netsec-pretool.sh`, greps for patterns, and provides a defensive analysis. It will NOT execute any commands.

#### 7c. /analyst

```
/analyst
```
Expected: Spawns an analyst subagent with Read, Grep, Glob, and Write access (no Bash). The agent introduces itself for report synthesis.

Test the agent (with a report file from section 5g):
```
Synthesize the findings from report-*.md into an executive summary.
```
Expected: Agent reads the report file(s), synthesizes findings, and writes a structured summary. It will NOT execute bash commands.

---

### 8. Full End-to-End Smoke Test

This test exercises the complete v1.5 stack in sequence.

1. Start a fresh Claude Code session in the repo.
2. Run `/netsec-health` -- confirm all checks pass.
3. Run `/scope init` -- confirm scope.json has lab targets.
4. Run `make lab-up` -- confirm Docker containers start.
5. Run `/recon localhost` -- confirm 6-step recon executes, check `.pentest/audit-*.jsonl` shows entries.
6. Run `/scan localhost` -- confirm 5-step scan executes.
7. Run `/report` -- confirm `report-YYYY-MM-DD.md` is created.
8. Run `make lab-down` -- confirm containers stop.

If all 8 steps complete without errors and the audit log and report file exist, v1.5 is working end-to-end.

---

### Troubleshooting

**Hook not firing:** Check hook registration in `.claude/settings.json`. The file must have `PreToolUse` and `PostToolUse` entries pointing to `.claude/hooks/netsec-pretool.sh` and `.claude/hooks/netsec-posttool.sh`. Run `/netsec-health` for guided diagnosis.

**scope.json missing:** The PreToolUse hook will block ALL security tool commands until `.pentest/scope.json` exists. Create it:
```bash
mkdir -p .pentest && echo '{"targets":["localhost","127.0.0.1"]}' > .pentest/scope.json
```

**Docker lab not starting:** Ensure Docker Desktop is running. Check for port conflicts on 8080, 3030, 8888, 8180.

**Skill not appearing in / menu:** Skills must be in `.claude/skills/<name>/SKILL.md`. Run `ls .claude/skills/` to confirm all 33 skill directories exist.

**Subagent not forking:** The `/pentester`, `/defender`, `/analyst` skills require `context: fork` in their SKILL.md frontmatter. Check `.claude/skills/pentester/SKILL.md` for `context: fork`.

---
*Guide covers v1.5 Claude Skill Pack (Phases 28-33, shipped 2026-02-18)*
*17 tool skills, 8 workflow skills, 3 utility skills, 3 subagent personas*
```

Write the file such that the content above is accurate and the file is readable as a standalone guide. Do NOT include the triple-backtick fences that wrap the overall content description above -- write the actual markdown directly.
  </action>
  <verify>
    <automated>test -f /Users/patrykattc/work/git/networking-tools/docs/TESTING-V15.md && wc -l /Users/patrykattc/work/git/networking-tools/docs/TESTING-V15.md | awk '{if ($1 >= 120) print "PASS: " $1 " lines"; else print "FAIL: only " $1 " lines"}'</automated>
    <manual>Skim the file to confirm all 8 sections are present and each has at least one concrete command with expected output.</manual>
  </verify>
  <done>docs/TESTING-V15.md exists, is 120+ lines, and covers all 8 feature areas (safety hooks, health check, scope, tool skills, workflow skills, utility skills, subagents, end-to-end test) with concrete commands and expected outputs.</done>
</task>

</tasks>

<verification>
After the task completes:
- `docs/TESTING-V15.md` exists
- File has 120+ lines
- All 8 sections present (safety hooks through end-to-end smoke test)
- Prerequisites section explains scope.json setup before hook tests
- Each section has at least one concrete command and expected behavior
</verification>

<success_criteria>
A user can open docs/TESTING-V15.md with no other context and follow it to verify every v1.5 feature. All commands are copy-pasteable. Expected outputs are described so the user knows whether each test passed or failed.
</success_criteria>

<output>
After completion, create `.planning/quick/003-create-v15-feature-testing-guide/003-SUMMARY.md`
</output>
