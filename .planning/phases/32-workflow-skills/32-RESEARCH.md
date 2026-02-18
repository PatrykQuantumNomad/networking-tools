# Phase 32: Workflow Skills - Research

**Researched:** 2026-02-18
**Domain:** Claude Code workflow skills orchestrating multi-tool pentesting workflows
**Confidence:** HIGH

## Summary

Phase 32 creates 8 workflow skills that are fundamentally different from the 17 tool skills built in Phases 29-31. Tool skills use `disable-model-invocation: true` and serve as static navigation layers over individual tool scripts. Workflow skills are user-invocable (`/recon`, `/scan`, `/diagnose`, `/fuzz`, `/crack`, `/sniff`, `/report`, `/scope`) and provide Claude with step-by-step orchestration instructions. When the user invokes a workflow skill, Claude reads the instructions and executes multiple wrapper scripts in sequence, interpreting results between steps and adapting the workflow based on findings.

The key architectural insight is that workflow skills reference scripts directly (e.g., `bash scripts/nmap/discover-live-hosts.sh localhost -j -x`), not tool skills (e.g., `/nmap`). This was identified as an open question in Phase 29 research and the answer is clear: tool skills are user-invoked navigation aids with `disable-model-invocation: true`, so Claude cannot invoke them programmatically. Workflow skills must reference the underlying wrapper scripts by path. The PreToolUse hook validates all commands regardless of how they are triggered, so safety is preserved.

Context budget analysis confirms ample headroom. The 8 new workflow skills will be user-invocable (no `disable-model-invocation`) so their descriptions load into context. Current budget usage is ~281 characters from 4 auto-invocable skills. Adding 8 workflow skills with ~80-character descriptions adds ~640 characters, for a total of ~921 characters -- well under the 16,000-character budget (2% of 200K context window). Even with overhead for skill metadata, this is roughly 6% of budget.

**Primary recommendation:** Create 8 workflow SKILL.md files that instruct Claude to execute multi-tool bash script sequences with `-j -x` flags. Each workflow should list numbered steps with specific script invocations, tell Claude to interpret JSON results between steps, and use `$ARGUMENTS` for target input. Group into 3 plans: reconnaissance/scanning workflows, diagnostic/offensive workflows, and reporting/scope management workflows.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| WKFL-01 | `/recon` -- reconnaissance workflows (host discovery, DNS, OSINT) | Orchestrates nmap/discover-live-hosts.sh, nmap/identify-ports.sh, dig/query-dns-records.sh, dig/attempt-zone-transfer.sh, curl/check-ssl-certificate.sh, gobuster/enumerate-subdomains.sh |
| WKFL-02 | `/scan` -- vulnerability scanning workflows (port scans, web scans) | Orchestrates nmap/scan-web-vulnerabilities.sh, nikto/scan-specific-vulnerabilities.sh, sqlmap/test-all-parameters.sh, curl/test-http-endpoints.sh |
| WKFL-03 | `/diagnose` -- network diagnostic workflows (DNS, connectivity, latency) | Orchestrates diagnostics/dns.sh, diagnostics/connectivity.sh, diagnostics/performance.sh, plus traceroute/trace-network-path.sh and dig/check-dns-propagation.sh |
| WKFL-04 | `/fuzz` -- fuzzing workflows (directory brute-force, parameter fuzzing) | Orchestrates gobuster/discover-directories.sh, ffuf/fuzz-parameters.sh, nikto/scan-specific-vulnerabilities.sh |
| WKFL-05 | `/crack` -- password cracking workflows (hashes, archives, web) | Orchestrates john/identify-hash-type.sh, hashcat/crack-ntlm-hashes.sh, hashcat/crack-web-hashes.sh, john/crack-linux-passwords.sh, john/crack-archive-passwords.sh |
| WKFL-06 | `/sniff` -- traffic capture and analysis workflows | Orchestrates tshark/capture-http-credentials.sh, tshark/analyze-dns-queries.sh, tshark/extract-files-from-capture.sh |
| WKFL-07 | `/report` -- generate structured findings report from session | No tool scripts -- Claude synthesizes all session findings into a markdown report. Uses `$ARGUMENTS` for report title/format. |
| WKFL-08 | `/scope` -- define and manage target scope | Manages `.pentest/scope.json` directly. Claude reads/writes the JSON file, validates format, shows current scope. |
</phase_requirements>

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Claude Code Skills | Current (v2.1.3+) | SKILL.md files with YAML frontmatter | Official extension mechanism, validated in Phases 29-31 |
| YAML frontmatter | - | Skill metadata (name, description, argument-hint) | Required by Claude Code skill system |
| Markdown | - | Workflow step instructions for Claude | Skill body after frontmatter separator |
| bash wrapper scripts | 4.0+ | Existing tool scripts Claude executes | 81 scripts across 17 tools, all supporting -j/-x flags |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `$ARGUMENTS` substitution | - | Pass target/scope to workflow from slash command | Every workflow skill that accepts a target |
| `.pentest/scope.json` | - | Target allowlist read by PreToolUse hook | `/scope` skill manages this file directly |
| `jq` | 1.6+ | JSON manipulation for scope management | `/scope` skill reads/writes scope.json |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline workflow skills | `context: fork` subagent skills | Inline keeps conversation context (results visible to user); fork isolates but loses context. Inline is better for interactive workflows where user sees intermediate results. |
| Direct script references in skills | Invoking tool skills (`/nmap`) from workflows | Tool skills have `disable-model-invocation: true` so Claude cannot invoke them. Must reference scripts directly. |
| Numbered steps in SKILL.md | Supporting files with step details | Steps are short enough to fit in SKILL.md (under 500 lines). Supporting files add unnecessary indirection for 5-8 step workflows. |

## Architecture Patterns

### Skill Directory Structure (Phase 32)

```
.claude/skills/
  recon/
    SKILL.md              # WKFL-01: Reconnaissance workflow
  scan/
    SKILL.md              # WKFL-02: Vulnerability scanning workflow
  diagnose/
    SKILL.md              # WKFL-03: Network diagnostics workflow
  fuzz/
    SKILL.md              # WKFL-04: Fuzzing workflow
  crack/
    SKILL.md              # WKFL-05: Password cracking workflow
  sniff/
    SKILL.md              # WKFL-06: Traffic capture workflow
  report/
    SKILL.md              # WKFL-07: Findings report generation
  scope/
    SKILL.md              # WKFL-08: Scope management
```

### Pattern 1: Workflow Skill Frontmatter (User-Invocable, Claude-Orchestrated)

**What:** Workflow skills use default invocation (user can trigger) without `disable-model-invocation`. They accept arguments via `$ARGUMENTS`.

**When to use:** All 8 workflow skills.

**Key difference from tool skills:** No `disable-model-invocation: true`. These appear in the `/` menu AND their descriptions load into context so Claude knows they exist. The descriptions are short (~80 chars) to minimize context budget impact.

**Example frontmatter:**
```yaml
---
name: recon
description: Run reconnaissance workflow -- host discovery, DNS enumeration, and OSINT gathering
argument-hint: "<target>"
---
```

**Why this pattern:**
- User invokes `/recon 10.0.0.1` explicitly
- `argument-hint` shows expected input in autocomplete
- Description tells Claude (and user) what the workflow does
- No `disable-model-invocation` because workflows are safe -- they execute wrapper scripts that are validated by PreToolUse hooks

### Pattern 2: Orchestration Instructions (Numbered Steps with Script References)

**What:** The skill body contains numbered steps telling Claude exactly which scripts to run, in what order, with what flags. Claude reads the instructions and executes them as bash commands.

**When to use:** All 6 tool-orchestrating workflows (recon, scan, diagnose, fuzz, crack, sniff).

**Example structure:**
```markdown
# Reconnaissance Workflow

Run a comprehensive reconnaissance against $ARGUMENTS.

## Steps

### 1. Host Discovery
Run host discovery to find active hosts on the target network:
```
bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x
```
Review the results. If multiple hosts are found, note them for subsequent steps.

### 2. Port Scanning
Scan discovered hosts for open ports and services:
```
bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x
```

### 3. DNS Enumeration
Query DNS records for the target domain:
```
bash scripts/dig/query-dns-records.sh $ARGUMENTS -j -x
```

...

## After Each Step
- Review the JSON output summary from the PostToolUse hook
- Note key findings (open ports, services, DNS records)
- Adapt subsequent steps based on what was discovered
- If a tool is not installed, skip that step and note it in the summary

## Completion
After all steps complete, provide a summary of findings organized by category.
```

**Why this pattern:**
- Claude receives clear, actionable instructions
- Scripts include `-j -x` so Claude gets structured JSON feedback
- "After Each Step" guidance teaches Claude to interpret results and adapt
- "If a tool is not installed" handles graceful degradation

### Pattern 3: Non-Tool Workflow (/report, /scope)

**What:** Some workflows do not orchestrate tool scripts. `/report` generates a markdown document from session findings. `/scope` manages the `.pentest/scope.json` file directly.

**When to use:** WKFL-07 (/report) and WKFL-08 (/scope).

**Example (/scope):**
```yaml
---
name: scope
description: Define and manage target scope for pentesting engagements
argument-hint: "<add|remove|show|clear> [target]"
---

# Scope Management

Manage the target scope file at `.pentest/scope.json`. All pentesting commands are validated against this scope by the PreToolUse hook.

## Operations

### Show current scope
Read and display `.pentest/scope.json`:
```
cat .pentest/scope.json
```

### Add a target
Read the current scope, add the new target, and write back:
```
cat .pentest/scope.json
```
Then use jq to add the target and write the updated file.

### Remove a target
Read the current scope, remove the target, and write back.

### Clear all targets
Reset scope to empty: `{"targets": []}`.

### Initialize scope
If `.pentest/scope.json` does not exist, create it:
```
mkdir -p .pentest
echo '{"targets":["localhost","127.0.0.1"]}' > .pentest/scope.json
```

## Important
- Always confirm with the user before adding targets
- Default safe targets: localhost, 127.0.0.1
- Lab targets: localhost:8080, localhost:3030, localhost:8888, localhost:8180
- The scope file is gitignored (lives in .pentest/ directory)
```

### Pattern 4: Argument Handling with $ARGUMENTS

**What:** Workflow skills use `$ARGUMENTS` to receive the target from the user's slash command invocation. Claude substitutes the value before executing scripts.

**When to use:** All workflow skills that accept targets.

**Important:** `$ARGUMENTS` is substituted by Claude Code before Claude sees the content. If the user types `/recon 10.0.0.1`, Claude receives instructions with `10.0.0.1` wherever `$ARGUMENTS` appeared. If no arguments are provided, `$ARGUMENTS` is empty and Claude should prompt the user for a target.

**Handling missing arguments:**
```markdown
## Target

Target: $ARGUMENTS

If no target was provided, ask the user for a target before proceeding.
Targets must be listed in `.pentest/scope.json` before scanning.
```

### Anti-Patterns to Avoid

- **Invoking tool skills from workflows:** Tool skills have `disable-model-invocation: true`. Workflows must reference `bash scripts/tool/script.sh` directly, not `/tool-name`.
- **Omitting `-j -x` flags:** Without `-j`, Claude gets raw terminal output instead of structured JSON. Without `-x`, scripts only display commands instead of executing them. Always include both.
- **Using `context: fork`:** Workflow skills should run inline so the user sees intermediate results in their conversation. Forking loses conversation context and prevents the user from steering the workflow.
- **Excessively long skill files:** Keep each workflow under 200 lines. The steps are concise -- just script paths with brief guidance. Do not duplicate script help text.
- **Hard-coding targets:** Always use `$ARGUMENTS` for the target. Never hard-code IP addresses or domains in workflow steps.
- **Using `disable-model-invocation: true`:** Workflow skills must be user-invocable from the `/` menu. Do not add `disable-model-invocation: true`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Target validation | Custom scope checking in workflow skills | PreToolUse hook (Phase 28) | Already validates every bash command against scope.json |
| Script output parsing | Custom jq in workflow instructions | PostToolUse hook (Phase 28) | Already parses -j envelope and injects additionalContext |
| Tool installation checking | Per-workflow tool checks | Existing `scripts/check-tools.sh` and `require_cmd` in each script | Scripts already handle missing tools gracefully |
| Report formatting | Custom report script | Claude's native markdown generation | Claude excels at synthesizing findings into structured reports |
| Scope file management | Custom bash scope management script | Claude + jq directly | Scope operations are simple JSON reads/writes; a dedicated script would be over-engineering |
| Workflow step sequencing | Custom orchestration framework | Claude Code's natural tool execution | Claude handles sequential bash execution natively when given numbered steps |

**Key insight:** Workflow skills are pure orchestration instructions -- they tell Claude WHAT to run and in WHAT ORDER. All the hard work (safety validation, output parsing, audit logging, tool checking) is already done by the PreToolUse/PostToolUse hooks and the wrapper scripts themselves.

## Common Pitfalls

### Pitfall 1: Trying to invoke tool skills from workflow instructions
**What goes wrong:** Workflow says "invoke `/nmap`" but Claude cannot invoke skills with `disable-model-invocation: true`
**Why it happens:** Confusing tool skill invocation (user-only) with script execution (Claude can do)
**How to avoid:** Always use `bash scripts/tool/script.sh [args] -j -x` in workflow steps, never `/tool-name`
**Warning signs:** Claude responds "I cannot invoke the nmap skill" when running a workflow

### Pitfall 2: Forgetting -x flag in workflow script references
**What goes wrong:** Claude runs a script without `-x`, getting display-mode output (commands printed, not executed)
**Why it happens:** Tool skill docs show `[-j] [-x]` as optional, but workflows need execution mode
**How to avoid:** Every script invocation in a workflow MUST include `-x` (execute) AND `-j` (JSON output)
**Warning signs:** Claude receives "example command" output instead of actual scan results

### Pitfall 3: Missing argument handling when $ARGUMENTS is empty
**What goes wrong:** Claude runs scripts with no target, using defaults that may not be in scope
**Why it happens:** User types `/recon` without a target, `$ARGUMENTS` is empty
**How to avoid:** Every workflow must include "if no target was provided, ask the user" guard
**Warning signs:** Scripts run against `localhost` or `example.com` without user confirming target

### Pitfall 4: Context budget overflow from verbose descriptions
**What goes wrong:** 8 workflow skill descriptions push past context budget limits
**Why it happens:** Writing long, detailed descriptions instead of concise ones
**How to avoid:** Keep descriptions under 100 characters. Current auto-invocable skills use 281 chars total. Adding 8 workflows at ~80 chars each = ~640 chars additional. Total ~921 chars, well under 16,000 char budget.
**Warning signs:** `/context` shows skills excluded from budget

**Budget analysis:**
| Skill Type | Count | In Context? | Est. Chars |
|------------|-------|-------------|------------|
| Tool skills (disable-model-invocation) | 17 | NO | 0 |
| Utility skills (auto-invocable) | 4 | YES | 281 |
| Workflow skills (new, user-invocable) | 8 | YES | ~640 |
| **Total** | **29** | | **~921** |
| Budget (2% of 200K) | | | **16,000** |

### Pitfall 5: Workflow skills being too prescriptive about tool order
**What goes wrong:** Workflow rigidly requires all tools even when some are not installed or results from earlier steps make later steps irrelevant
**Why it happens:** Writing workflows as fixed scripts instead of guided decision trees
**How to avoid:** Include "if tool is not installed, skip" and "adapt based on findings" guidance. Let Claude use judgment about which steps to run.
**Warning signs:** Workflow fails because one optional tool (e.g., gobuster) is not installed

### Pitfall 6: /report workflow trying to access audit logs
**What goes wrong:** `/report` tries to read `.pentest/audit-*.jsonl` for findings but the audit log format is not designed for report generation
**Why it happens:** Assuming audit logs contain structured findings suitable for reporting
**How to avoid:** `/report` should synthesize from the current conversation context (Claude remembers all results from the session), not from audit log files. The audit log is for compliance, not reporting.
**Warning signs:** Report contains raw JSON log entries instead of human-readable findings

### Pitfall 7: /scope adding targets without user confirmation
**What goes wrong:** Claude auto-adds targets to scope.json without asking
**Why it happens:** Workflow instructions don't explicitly require confirmation
**How to avoid:** `/scope` instructions must say "always confirm with the user before modifying scope.json"
**Warning signs:** Targets appear in scope without the user explicitly approving them

## Code Examples

Verified patterns from official docs and established project conventions:

### Workflow Skill: /recon (Reconnaissance)

```yaml
---
name: recon
description: Run reconnaissance workflow -- host discovery, DNS enumeration, and OSINT gathering
argument-hint: "<target>"
---

# Reconnaissance Workflow

Run comprehensive reconnaissance against the target.

## Target

Target: $ARGUMENTS

If no target was provided, ask the user for a target before proceeding. Verify the target is in `.pentest/scope.json` (run `cat .pentest/scope.json` to check). If not in scope, ask the user to add it with `/scope add <target>`.

## Steps

### 1. Host Discovery
Discover active hosts on the target network:
```
bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x
```

### 2. Port Scanning
Scan for open ports and identify services:
```
bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x
```

### 3. DNS Records
Query DNS records for the target domain:
```
bash scripts/dig/query-dns-records.sh $ARGUMENTS -j -x
```

### 4. Zone Transfer Attempt
Attempt DNS zone transfer:
```
bash scripts/dig/attempt-zone-transfer.sh $ARGUMENTS -j -x
```

### 5. SSL/TLS Inspection
Check SSL certificate details:
```
bash scripts/curl/check-ssl-certificate.sh $ARGUMENTS -j -x
```

### 6. Subdomain Enumeration (optional)
If gobuster is installed and target is a domain, enumerate subdomains:
```
bash scripts/gobuster/enumerate-subdomains.sh $ARGUMENTS -j -x
```

## After Each Step

- Review the JSON output summary from the PostToolUse hook
- Note key findings (active hosts, open ports, services, DNS records, certificate details)
- If a tool is not installed, skip that step and note it
- Adapt subsequent steps based on discoveries (e.g., if new hosts found, scan those too)

## Summary

After all steps, provide a structured reconnaissance summary:
- **Hosts**: Active hosts discovered
- **Ports/Services**: Open ports and identified services
- **DNS**: Records, nameservers, zone transfer results
- **TLS**: Certificate details and expiry
- **Subdomains**: Enumerated subdomains (if run)
```

### Workflow Skill: /scope (Scope Management)

```yaml
---
name: scope
description: Define and manage target scope for pentesting engagements
argument-hint: "<add|remove|show|clear> [target]"
---

# Scope Management

Manage the target scope file at `.pentest/scope.json`. All pentesting commands validate targets against this file via the PreToolUse hook.

## Operations

Parse the first argument from $ARGUMENTS to determine the operation. Remaining arguments are the target(s).

### show (default)
Display current scope targets. If no operation specified, default to show.
```
cat .pentest/scope.json 2>/dev/null || echo "No scope file found"
```

### add <target>
Add a target to the scope. Always confirm with the user first.
1. Read current scope: `cat .pentest/scope.json`
2. Add target using jq: `jq --arg t "TARGET" '.targets += [$t] | .targets |= unique' .pentest/scope.json > .pentest/scope.tmp && mv .pentest/scope.tmp .pentest/scope.json`
3. Show updated scope

### remove <target>
Remove a target from the scope.
1. Read current scope
2. Remove target using jq: `jq --arg t "TARGET" '.targets -= [$t]' .pentest/scope.json > .pentest/scope.tmp && mv .pentest/scope.tmp .pentest/scope.json`
3. Show updated scope

### init
Create scope file with safe defaults if it does not exist:
```
mkdir -p .pentest && echo '{"targets":["localhost","127.0.0.1"]}' > .pentest/scope.json
```

### clear
Reset scope to empty (confirm with user first):
```
echo '{"targets":[]}' > .pentest/scope.json
```

## Important
- Always confirm with the user before modifying scope
- Default safe targets: localhost, 127.0.0.1
- Lab targets to consider adding: localhost (covers all lab ports)
- The .pentest/ directory is gitignored
- Scope file format: `{"targets": ["target1", "target2"]}`
```

### Workflow Skill: /report (Findings Report)

```yaml
---
name: report
description: Generate a structured pentesting findings report from the current session
argument-hint: "[title]"
---

# Findings Report

Generate a structured report of all pentesting findings from this session.

## Report Title

Title: $ARGUMENTS
If no title provided, use "Pentesting Findings Report" with today's date.

## Instructions

Synthesize all findings from the current conversation into a structured markdown report. Do NOT read audit log files -- use the results and summaries from this session's tool outputs.

## Report Structure

```markdown
# [Title]

**Date:** [today's date]
**Scope:** [targets from .pentest/scope.json]
**Tools Used:** [list tools that were run in this session]

## Executive Summary
[2-3 sentence overview of key findings and risk level]

## Scope & Methodology
- Target(s) tested
- Tools and techniques used
- Testing approach (recon, scanning, etc.)

## Findings

### Critical
[Any critical findings, or "None identified"]

### High
[High-severity findings]

### Medium
[Medium-severity findings]

### Low / Informational
[Low-severity and informational findings]

## Recommendations
[Prioritized list of recommended actions]

## Appendix
[Raw data references, tool versions, timestamps]
```

## Output

Write the report to `report-[date].md` in the project root, or display it in the conversation if the user prefers.
```

## Workflow-to-Script Mapping

Complete mapping of which workflow invokes which scripts:

| Workflow | Scripts Used | Category |
|----------|-------------|----------|
| `/recon` | nmap/discover-live-hosts.sh, nmap/identify-ports.sh, dig/query-dns-records.sh, dig/attempt-zone-transfer.sh, curl/check-ssl-certificate.sh, gobuster/enumerate-subdomains.sh | Network + DNS |
| `/scan` | nmap/identify-ports.sh, nmap/scan-web-vulnerabilities.sh, nikto/scan-specific-vulnerabilities.sh, sqlmap/test-all-parameters.sh, curl/test-http-endpoints.sh | Vuln scanning |
| `/diagnose` | diagnostics/dns.sh, diagnostics/connectivity.sh, diagnostics/performance.sh, traceroute/trace-network-path.sh, dig/check-dns-propagation.sh | Diagnostics |
| `/fuzz` | gobuster/discover-directories.sh, ffuf/fuzz-parameters.sh, nikto/scan-specific-vulnerabilities.sh | Web fuzzing |
| `/crack` | john/identify-hash-type.sh, hashcat/crack-ntlm-hashes.sh, hashcat/crack-web-hashes.sh, john/crack-linux-passwords.sh, john/crack-archive-passwords.sh | Offline cracking |
| `/sniff` | tshark/capture-http-credentials.sh, tshark/analyze-dns-queries.sh, tshark/extract-files-from-capture.sh | Traffic analysis |
| `/report` | (none -- synthesizes session findings) | Reporting |
| `/scope` | (none -- manages .pentest/scope.json) | Configuration |

### Note on /diagnose and diagnostics scripts

The `scripts/diagnostics/` scripts (dns.sh, connectivity.sh, performance.sh) follow "Pattern B" -- diagnostic auto-reports that run non-interactively. They do NOT support `-j` or `-x` flags (they are not use-case scripts from the tool directories). They output directly to stdout in a pass/fail/warn format. The `/diagnose` workflow should handle these differently:
- For diagnostics scripts: run without `-j -x` flags, interpret the text output directly
- For tool scripts (traceroute, dig): use normal `-j -x` flags

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Tool skills only (user-invoked navigation) | Workflow skills that orchestrate multi-tool sequences | Phase 32 (now) | Users get task-oriented workflows instead of per-tool interaction |
| Manual multi-tool execution | Claude sequences tools based on workflow instructions | Phase 32 (now) | Consistent, repeatable pentesting workflows |
| Scope managed manually by editing JSON | `/scope` skill for add/remove/show/init operations | Phase 32 (now) | Natural language scope management |
| Results scattered across conversation | `/report` synthesizes all findings into structured document | Phase 32 (now) | Professional report output from session data |

## Batching Strategy

8 workflow skills grouped into 3 plans by workflow type:

| Plan | Skills | Rationale |
|------|--------|-----------|
| 32-01 | `/recon`, `/scan`, `/diagnose` | Network-oriented workflows -- these are the most-used pentesting workflows. /recon and /scan share many nmap/nikto scripts. /diagnose uses diagnostic scripts with different flag patterns. |
| 32-02 | `/fuzz`, `/crack`, `/sniff` | Specialized offensive workflows -- each has a distinct tool domain. /fuzz = web enumeration, /crack = offline hash/archive cracking, /sniff = traffic capture. |
| 32-03 | `/report`, `/scope` | Management workflows -- these do not execute tool scripts. /report synthesizes findings, /scope manages configuration. Both are simpler (no tool orchestration). |

This grouping matches natural pentesting phases and clusters skills that share similar patterns.

## Open Questions

1. **Should `/diagnose` use the diagnostics/ scripts or the tool wrapper scripts?**
   - What we know: `scripts/diagnostics/` has 3 scripts (dns.sh, connectivity.sh, performance.sh) that follow Pattern B (no `-j`, no `-x`). Tool wrapper scripts in `scripts/dig/`, `scripts/traceroute/` follow the standard pattern with `-j -x` support.
   - What's unclear: Whether to prefer diagnostics scripts (comprehensive auto-reports) or tool scripts (JSON-structured, smaller scope).
   - Recommendation: Use BOTH. Run diagnostic auto-report scripts first for a comprehensive overview, then use specific tool scripts for deeper investigation of issues found. Document that diagnostic scripts do not support `-j -x`.

2. **Should `/report` write to a file or display inline?**
   - What we know: Reports can be long. Writing to a file is permanent and shareable. Inline display keeps it in conversation context.
   - What's unclear: User preference.
   - Recommendation: Default to writing `report-YYYY-MM-DD.md` in the project root AND displaying a summary inline. Let Claude ask the user's preference if `$ARGUMENTS` hints at one approach.

3. **Should workflow skills use `allowed-tools` to restrict tool access?**
   - What we know: `allowed-tools` field limits which tools Claude can use when a skill is active. Workflows need Bash tool at minimum.
   - What's unclear: Whether restricting to `Bash` only is beneficial or limiting.
   - Recommendation: Do NOT set `allowed-tools`. Workflows need Bash (for running scripts), Read (for checking scope.json), and Write (for `/report` file output). Default tool access is sufficient, and the PreToolUse hook already handles safety.

4. **Should workflow skills have `disable-model-invocation: true`?**
   - What we know: The phase description says "workflow skills need `disable-model-invocation: false` (or omitted)". Workflows are user-initiated actions.
   - What's unclear: Whether Claude might auto-invoke workflows inappropriately.
   - Recommendation: Use `disable-model-invocation: true` ONLY for workflows with side effects that should never auto-trigger. Among these 8: `/scope` modifies files and could be triggered by Claude discussing scope topics. Consider `disable-model-invocation: true` for `/scope` specifically. The other 7 workflows are safe with default invocation since the PreToolUse hook validates all commands anyway, but practically, workflows like `/recon` running automatically could be surprising. Recommendation: set `disable-model-invocation: true` for ALL 8 workflow skills. Users will invoke them explicitly. This also means descriptions do NOT load into context, saving the context budget entirely.

   **Updated budget if all workflows use disable-model-invocation:**
   | Skill Type | Count | In Context? | Chars |
   |------------|-------|-------------|-------|
   | Tool skills | 17 | NO | 0 |
   | Utility skills | 4 | YES | 281 |
   | Workflow skills | 8 | NO | 0 |
   | **Total** | **29** | | **281** |

   This is the safest option. Workflows are explicit actions (like deploy/commit) that the user triggers deliberately. Claude should not auto-run a recon workflow because the user mentioned a target.

## Sources

### Primary (HIGH confidence)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills) -- Complete skills system reference: frontmatter fields, `$ARGUMENTS` substitution, invocation control table, context budget (2% of window), supporting files pattern
- Project codebase: 21 existing skills in `.claude/skills/*/SKILL.md` -- Validated patterns from Phases 29-31
- Project codebase: `scripts/*/` -- 81 scripts across 17 tools, all with `-j`/`-x` flag support
- Project codebase: `scripts/diagnostics/` -- 3 diagnostic auto-report scripts (Pattern B, no `-j`/`-x`)
- Project codebase: `.claude/hooks/netsec-pretool.sh` -- PreToolUse hook validates all bash commands regardless of invocation source
- Phase 29 RESEARCH.md -- Open question #3 answered: workflows invoke scripts directly, not tool skills
- Phase 30 RESEARCH.md -- Invocation control table confirmed from official docs

### Secondary (MEDIUM confidence)
- [Claude Code Skills: Build Reusable Workflows with Custom Commands](https://wmedia.es/en/writing/claude-code-skills-custom-workflows) -- Multi-step orchestration pattern, sequential tool execution, `$ARGUMENTS` passing
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) -- Community skill examples for workflow orchestration patterns
- [Claude Skills Library](https://github.com/alirezarezvani/claude-skills) -- Multi-tool workflow skills using sequential Python CLI tools as atomic operations

### Tertiary (LOW confidence)
- None -- all findings verified against primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- identical Claude Code skills system from Phases 29-31, no new technology
- Architecture: HIGH -- workflow skill pattern is the natural extension of tool skills with invocation control flipped from `disable-model-invocation: true` to `true` (user-initiated) and multi-step instructions
- Script mapping: HIGH -- all script paths verified against actual codebase via Glob and Read
- Context budget: HIGH -- measured current usage (281 chars) and calculated impact of 8 new skills
- Pitfalls: HIGH -- drawn from established patterns, tool skill experience, and official docs on skill invocation

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (30 days -- stable domain, skills system mature)
