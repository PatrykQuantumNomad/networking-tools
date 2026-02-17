# Feature Landscape: Claude Code Skill Pack

**Domain:** Claude Code skill pack for ethical hacking / pentesting CLI toolkit
**Researched:** 2026-02-17
**Overall confidence:** HIGH

## Context: Why a Claude Code Skill Pack

The project has 81 bash scripts across 17 tools with structured JSON output (`-j` flag) on all 46 use-case scripts, dual-mode execution (show vs execute via `-x`), safety banners, and `confirm_execute` gates. This is a complete educational pentesting toolkit, but users must know which scripts exist, what arguments they take, and how to interpret results. A Claude Code skill pack bridges this gap: Claude becomes an intelligent front-end that knows the toolkit, suggests appropriate tools, runs them safely, and explains results.

Existing comparable projects: [secskills](https://github.com/trilwu/secskills) (16 skills + 6 agents, generic prompts), [awesome-claude-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) (SecLists payloads/wordlists), [claude-code-owasp](https://github.com/agamm/claude-code-owasp) (OWASP Top 10 reference). None wrap a self-contained bash toolkit with structured JSON output. They provide general security guidance or reference material, not tool execution with result analysis.

**Key differentiator:** This is the only skill pack that executes real CLI tools with `-j` structured JSON output and has Claude analyze the structured results.

---

## Table Stakes

Features users expect from a pentesting skill pack. Missing these makes the plugin feel incomplete.

| Feature | Why Expected | Complexity | Depends On | Notes |
|---------|--------------|------------|------------|-------|
| **Task-oriented slash commands** (`/scan`, `/recon`, `/crack`, `/fuzz`) | Users think in tasks, not tools. Every security skill pack surfaces actions by methodology phase. PTES defines the standard phases. | MEDIUM | Existing scripts | 6 SKILL.md files mapping to PTES phases. Each invokes underlying bash scripts via `Bash()`. Uses `$ARGUMENTS` for target. |
| **Tool-level slash commands** (`/nmap`, `/sqlmap`, `/nikto`, etc.) | Users who know which tool they want need direct access without remembering script paths. | LOW | Existing scripts | One SKILL.md per tool (17 total). Thin wrappers: list available scripts, run with `-j` for JSON, let Claude interpret results. |
| **`/lab` command** (start/stop/status) | Lab targets are the safe practice environment. Friction-free setup is baseline for any security learning tool. | LOW | Docker, docker-compose | Single SKILL.md wrapping `make lab-up`, `lab-down`, `lab-status`. Shows ports and credentials. `disable-model-invocation: true` because it has side effects. |
| **`/check-tools` command** (verify installation) | Users need to know what is available before scanning. First thing anyone runs. | LOW | `check-tools.sh` | Runs `check-tools.sh`, Claude parses output and advises on missing tools. Can inject via `!` dynamic context. |
| **JSON output consumption** | All 46 use-case scripts support `-j`. Claude should consume structured JSON, not raw terminal text. | LOW | Existing `-j` flag | Skills instruct Claude to always use `-j` flag and parse the JSON envelope (meta, results, summary) for analysis. |
| **Safety guardrails** | Ethical hacking demands authorization. Users expect a security-focused skill to enforce safe practices. | LOW | Existing `safety_banner`, `confirm_execute` | Active scanning skills use `disable-model-invocation: true`. Instructions include authorization reminders. `confirm_execute` gates `-x` mode in scripts. |
| **Target parameter handling** | Users specify targets naturally ("scan 192.168.1.0/24") and expect skills to route correctly. | MEDIUM | `$ARGUMENTS` substitution | Skills parse `$ARGUMENTS` into TARGET. Claude validates format (IP, URL, subnet, domain) before invoking. `argument-hint` frontmatter shows expected format. |
| **Result interpretation** | Users want Claude to explain what scan results mean, not just dump output. This is the core value of having an AI run pentesting tools. | MEDIUM | JSON output, Claude reasoning | After running a script with `-j -x`, Claude reads JSON and provides: what was found, severity, next steps. Instructions in each skill guide interpretation. |

## Differentiators

Features that set this skill pack apart from generic security skills and competing skill packs.

| Feature | Value Proposition | Complexity | Depends On | Notes |
|---------|-------------------|------------|------------|-------|
| **Workflow chains** (multi-tool orchestration) | Competitors provide individual tools. Chaining recon > enumeration > vuln-analysis > reporting in one conversation is rare and high-value. | HIGH | Task commands, JSON output | A `/pentest` skill follows PTES: runs recon, analyzes results, suggests next-phase scripts. Uses `context: fork` with pentesting agent. |
| **Pentesting subagent** (`.claude/agents/pentester.md`) | Specialized system prompt with security expertise and PTES methodology. Generic Claude lacks domain-specific judgment for tool chaining. | MEDIUM | Skills, agents system | Custom agent with `allowed-tools: Bash, Read, Grep, Glob`. Preloaded with conventions skill. Used via `context: fork, agent: pentester`. |
| **Report generation** (`/report`) | Pentesters write reports after every engagement. Auto-generating structured markdown saves hours. | MEDIUM | Result interpretation | Skill reviews conversation, extracts findings from JSON results, generates report: executive summary, methodology, findings with severity, remediation. |
| **Learning mode** (educational context) | Existing scripts print WHY context. Claude amplifies this by explaining attack theory, defenses, OWASP references. Competitors provide tool guidance but not education. | LOW | Existing script explanations | Background knowledge skill (`user-invocable: false`) instructs Claude to explain security concepts behind each command. |
| **Lab scenario guides** (`/practice`) | Having targets running is step one. Guided walkthroughs for specific vulnerabilities (SQLi on DVWA, XSS on Juice Shop) are step two. | MEDIUM | Lab running, tool skills | Skills with supporting files. Detects running targets via `!docker compose -f labs/docker-compose.yml ps`. |
| **Dynamic context injection** | Skills use `!`command`` syntax to inject tool availability and lab status before Claude sees the prompt. Claude adapts to the actual environment. | LOW | `!` command syntax | Prepend workflow skills with `!bash scripts/check-tools.sh 2>/dev/null` so Claude knows what is installed. |
| **Scope management** (`/scope`) | Real pentests have defined scope. Records authorized targets and enforces checks before active scanning. | MEDIUM | Safety guardrails | Stores scope in `.pentest-scope.json`. Active scanning skills check scope. Claude warns if target out of scope. |
| **Safety hooks** (PreToolUse validation) | Hook that validates bash commands before execution: warns about scanning external targets, blocks dangerous patterns. Belt-and-suspenders with `disable-model-invocation`. | MEDIUM | hooks system | `hooks/hooks.json` with PreToolUse matcher on Bash tool. Script checks command against safety patterns. |
| **SessionStart tool check** | Hook that runs `check-tools.sh` at session start to inject tool availability into Claude's context automatically. | LOW | hooks system | SessionStart hook outputs available/missing tools. Claude knows what it can use from the start. |
| **Use-case discovery** | Skill that helps users find the right script. "I want to find open ports" -> suggests `nmap/discover-live-hosts.sh`. | LOW | All tool skills | Single skill listing all 46 use-case scripts with descriptions, organized by task category. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Auto-execute scans without user invocation** | Active scanning without explicit consent violates ethical hacking principles. Could scan unauthorized targets. Claude's Bash tool already requires permission, but skill design must reinforce safety culture. | `disable-model-invocation: true` on all active scanning skills. Require explicit `/scan target` invocation. Keep `confirm_execute` gate in scripts. |
| **Automatic exploitation** (run exploits without user action) | Exploitation is destructive and context-dependent. Wrong exploit = crashed service, data loss, legal liability. | Show exploit commands with explanation. Let user confirm each step. Never auto-chain exploitation. |
| **One skill per script** (81 individual skills) | Exceeds Claude's skill description budget (2% of context window, ~16K chars fallback). 81 descriptions flood context, slow every interaction, overwhelm the `/` menu. | Group by task (6 workflow skills) + by tool (17 tool skills, most `disable-model-invocation: true` to stay out of context) = 23-25 skills total. |
| **MCP server wrapping bash scripts** | Marginal benefit over `-j` flag. Significant implementation complexity (Node.js/Python MCP server). Scripts already produce structured JSON. | Use Bash tool to run scripts with `-j`. Same structured result, zero infrastructure. |
| **Parsing native tool output formats** | Nmap XML, tshark JSON, sqlmap output have complex schemas. Parsing each is a separate project (see `jc`). | Use `-j` flag for structured envelope output. For native formats, point users to tools directly. |
| **Interactive terminal passthrough** | Claude Code cannot handle interactive sessions. Tools like msfconsole, john --stdin require sustained interactive I/O. | Show commands. User runs interactive tools in separate terminal. Claude helps interpret results. |
| **Credential storage** in context or files | Storing secrets in plaintext is a security anti-pattern. Violates responsible disclosure. | Display credentials in output. User manages their own secure notes. Never write credentials to files via skills. |
| **Persistent background scanning** | Claude Code is conversational, not daemon-like. Background processes outlive context. Could trigger IDS/IPS. | Single-shot scans. Suggest cron/systemd for production monitoring. |
| **`bypassPermissions`** on any agent | Pentesting tools can be destructive. Bypassing permission checks removes the safety net. | Use `default` or `acceptEdits` permission modes. Let users approve each action. |
| **Agent teams** (multi-session parallel) | Experimental feature requiring env var flag. Overkill for a skill pack. | Standard subagents handle all needed workflows. |

---

## Command Taxonomy

### Recommended Skill Organization

Skills are organized into three tiers matching how pentesters naturally work:

**Tier 1: Workflow Skills (PTES phases)** -- User-invocable AND Claude-invocable

These map to penetration testing methodology phases. Users type `/recon target` and Claude orchestrates the right tools.

| Skill Name | PTES Phase | Scripts Used | Argument |
|------------|------------|--------------|----------|
| `/recon` | Intelligence Gathering | nmap/discover-live-hosts, dig/query-dns, gobuster/enumerate-subdomains, curl/check-ssl | `$ARGUMENTS` = target (IP/domain/subnet) |
| `/scan` | Vulnerability Analysis | nmap/scan-web-vulnerabilities, nikto/scan-specific-vulnerabilities, sqlmap/test-all-parameters | `$ARGUMENTS` = target URL or IP |
| `/fuzz` | Vulnerability Analysis | gobuster/discover-directories, ffuf/fuzz-parameters | `$ARGUMENTS` = target URL |
| `/crack` | Exploitation (credentials) | hashcat/crack-*, john/crack-*, john/identify-hash-type | `$ARGUMENTS` = hash or hashfile |
| `/sniff` | Intelligence Gathering | tshark/capture-http-credentials, tshark/analyze-dns-queries | `$ARGUMENTS` = interface or pcap |
| `/diagnose` | Pre-engagement | diagnostics/connectivity, diagnostics/dns, diagnostics/performance | `$ARGUMENTS` = target domain |

**Tier 2: Tool Skills** -- User-invocable only (`disable-model-invocation: true`)

Direct tool access for users who know what they want. These stay out of Claude's context to preserve the skill description budget.

| Skill Name | Tool | Scripts Available |
|------------|------|-------------------|
| `/nmap` | nmap | examples, identify-ports, discover-live-hosts, scan-web-vulnerabilities |
| `/sqlmap` | sqlmap | examples, dump-database, test-all-parameters, bypass-waf |
| `/nikto` | nikto | examples, scan-specific-vulnerabilities, scan-multiple-hosts, scan-with-auth |
| `/tshark` | tshark | examples, capture-http-credentials, analyze-dns-queries, extract-files-from-capture |
| `/hashcat` | hashcat | examples, crack-ntlm-hashes, benchmark-gpu, crack-web-hashes |
| `/john` | john | examples, crack-linux-passwords, crack-archive-passwords, identify-hash-type |
| `/gobuster` | gobuster | examples, discover-directories, enumerate-subdomains |
| `/ffuf` | ffuf | examples, fuzz-parameters |
| `/hping3` | hping3 | examples, test-firewall-rules, detect-firewall |
| `/netcat` | netcat | examples, scan-ports, setup-listener, transfer-files |
| `/dig-tool` | dig | examples, query-dns-records, check-dns-propagation, attempt-zone-transfer |
| `/curl-tool` | curl | examples, test-http-endpoints, check-ssl-certificate, debug-http-response |
| `/traceroute-tool` | traceroute/mtr | examples, trace-network-path, diagnose-latency, compare-routes |
| `/aircrack` | aircrack-ng | examples, capture-handshake, crack-wpa-handshake, analyze-wireless-networks |
| `/foremost` | foremost | examples, recover-deleted-files, carve-specific-filetypes, analyze-forensic-image |
| `/metasploit` | metasploit | examples, generate-reverse-shell, scan-network-services, setup-listener |
| `/skipfish` | skipfish | examples, quick-scan-web-app, scan-authenticated-app |

**Tier 3: Utility Skills** -- Mixed invocation

| Skill Name | Purpose | Model-Invocable? | Why |
|------------|---------|------------------|-----|
| `/lab` | Start/stop/status Docker lab targets | No | Side effects (starts containers) |
| `/check-tools` | Verify tool installation | Yes | Useful context for Claude to adapt |
| `/report` | Generate pentest report from session | No | User-triggered, summarizes conversation |
| `/scope` | Set/view authorized testing scope | No | User-triggered, defines boundaries |
| `/practice` | Guided lab walkthrough | Yes | Claude can suggest when user is learning |
| `pentest-conventions` | Background: PTES methodology, output preferences, safety | No (background, `user-invocable: false`) | Invisible to user, auto-loaded for security context |

### Naming Conventions

- **Workflow skills**: Verb-based, short, memorable (`/recon`, `/scan`, `/fuzz`, `/crack`, `/sniff`, `/diagnose`)
- **Tool skills**: Tool name directly (`/nmap`, `/sqlmap`, `/nikto`)
- **Conflict resolution**: Append `-tool` when tool name conflicts with shell builtins or is ambiguous (`/dig-tool`, `/curl-tool`, `/traceroute-tool`)
- **Utility skills**: Action-based (`/lab`, `/report`, `/scope`)
- **Background skills**: Descriptive compound name (`pentest-conventions`)

### Skill Description Budget Analysis

Claude Code loads skill descriptions into context at 2% of context window (~16K chars fallback). Budget breakdown:

- **Workflow skills (6)**: Claude-invocable, descriptions in context. ~200 chars each = ~1200 chars.
- **Tool skills (17)**: `disable-model-invocation: true` -- descriptions NOT in context. Zero budget impact.
- **Utility skills (6)**: Mixed. Only `check-tools`, `practice`, and `pentest-conventions` are Claude-invocable = 3 descriptions ~600 chars.
- **Total budget used**: ~1800 chars of ~16K budget. Well within limits.

If skills exceed the budget, run `/context` to check for excluded skills. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var.

---

## Feature Dependencies

```
[pentest-conventions] (background knowledge -- foundation for all interactions)
    |
    v
[check-tools] (environment awareness -- everything depends on knowing tools)
    |
    v
[lab] (optional but recommended -- provides safe targets)
    |
    v
[Tool skills: /nmap, /sqlmap, etc.] (direct tool access, each wraps scripts)
    |
    v
[Workflow skills: /recon, /scan, /fuzz, /crack] (orchestrate tool scripts)
    |
    v
[scope] (enhances workflow skills with scope checking)
    |
    v
[report] (requires prior scan results in conversation)
    |
    v
[practice] (requires lab + tool skills + conventions)
    |
    v
[safety hooks] (PreToolUse, SessionStart -- enhances all skills)
    |
    v
[pentesting subagent] (requires stable skills to preload)
    |
    v
[/pentest multi-phase] (requires subagent + all workflows + report)
```

### Dependency Notes

- **pentest-conventions must come first:** Sets Claude's behavior for all security interactions -- PTES methodology, `-j` flag usage, safety practices.
- **Tool skills require check-tools pattern:** Scripts handle this via `require_cmd`, but SKILL.md should instruct Claude to check availability first.
- **Workflow skills orchestrate tool scripts:** `/recon` runs nmap, dig, gobuster scripts. The scripts must exist and tools must be installed.
- **Report requires session context:** Runs inline (not forked) so it has access to conversation history and all prior JSON results.
- **Practice requires lab:** Lab walkthroughs only make sense if Docker targets are running. Check via `!docker compose ps`.
- **Safety hooks enhance everything:** PreToolUse hooks are additive safety. Can be implemented at any point but should come before agents which have broader permissions.
- **Subagent requires stable skills:** Agent preloads skills. Skills must be stable before agent design.

---

## MVP Definition

### Launch With (v1)

Minimum viable skill pack -- validates that Claude Code + existing bash scripts = useful pentesting assistant.

- [ ] **pentest-conventions** (background knowledge skill) -- Sets Claude's behavior for all security interactions. PTES methodology, `-j` flag usage, safety practices, result interpretation format. Zero scripts to write, just SKILL.md.
- [ ] **check-tools** -- First thing any user runs. Wraps `check-tools.sh`. Immediate value, proves the pattern.
- [ ] **lab** -- Wraps `make lab-up/down/status`. Users need targets before scanning.
- [ ] **recon** workflow -- First active workflow. Orchestrates nmap, dig, gobuster for reconnaissance. Demonstrates the value: natural language to multi-tool orchestration with result interpretation.
- [ ] **scan** workflow -- Core pentesting activity. nmap, nikto, sqlmap vulnerability scanning.
- [ ] **5 tool skills** (/nmap, /sqlmap, /nikto, /gobuster, /ffuf) -- Direct access for power users. Validates tool-level pattern before scaling to all 17.

### Add After Validation (v1.x)

- [ ] **Remaining 12 tool skills** -- Scale proven pattern to all 17 tools.
- [ ] **crack, fuzz, sniff, diagnose** workflows -- Complete the PTES phase coverage.
- [ ] **report** -- Pentest report generation from session findings.
- [ ] **scope** -- Authorized scope management.
- [ ] **Safety hooks** -- PreToolUse validation, SessionStart tool check.
- [ ] **Use-case discovery** -- Help users find the right script for their task.

### Future Consideration (v2+)

- [ ] **practice** (lab walkthroughs) -- High content effort for each target/vulnerability. Supporting files needed.
- [ ] **Pentesting subagent** -- Custom agent with preloaded skills. Defer until skills are stable.
- [ ] **Plugin packaging** -- `.claude-plugin/plugin.json` for distribution. Defer until mature.
- [ ] **Multi-phase pentest orchestration** (`/pentest`) -- Full PTES workflow. Requires all tier-1/tier-2 skills stable.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| pentest-conventions (background) | HIGH | LOW | P1 |
| check-tools | HIGH | LOW | P1 |
| lab | HIGH | LOW | P1 |
| recon workflow | HIGH | MEDIUM | P1 |
| scan workflow | HIGH | MEDIUM | P1 |
| 5 initial tool skills | HIGH | LOW | P1 |
| Remaining 12 tool skills | MEDIUM | LOW | P2 |
| crack workflow | MEDIUM | MEDIUM | P2 |
| fuzz workflow | MEDIUM | LOW | P2 |
| sniff workflow | MEDIUM | MEDIUM | P2 |
| diagnose workflow | MEDIUM | LOW | P2 |
| report generation | HIGH | MEDIUM | P2 |
| scope management | MEDIUM | MEDIUM | P2 |
| Safety hooks | MEDIUM | MEDIUM | P2 |
| Use-case discovery | MEDIUM | LOW | P2 |
| practice (lab walkthroughs) | MEDIUM | HIGH | P3 |
| Pentesting subagent | MEDIUM | MEDIUM | P3 |
| Plugin packaging | LOW | MEDIUM | P3 |
| Multi-phase orchestration | HIGH | HIGH | P3 |

**Priority key:**
- P1: Must have for launch -- validates the skill pack concept
- P2: Should have, add after core skills are proven
- P3: Nice to have, defer until foundation is solid

---

## User Workflow Patterns

### Pattern 1: "I have a target, what should I do?"
```
User: I need to test 192.168.1.0/24
Claude: (pentest-conventions loads, checks installed tools, checks scope)
        Suggests starting with reconnaissance.
User: /recon 192.168.1.0/24
Claude: Runs discover-live-hosts.sh -j -x, parses JSON, shows live hosts.
        Runs query-dns on found hosts, identifies web servers.
        Suggests: "Found 3 live hosts with web servers. Run /scan on port 80/443?"
User: /scan 192.168.1.50
Claude: Runs nmap scan-web-vulnerabilities -j -x, nikto -j -x.
        Parses JSON results, explains findings with severity.
User: /report
Claude: Generates structured report from conversation findings.
```

### Pattern 2: "I know my tool, give me direct access"
```
User: /nmap
Claude: Shows available nmap scripts:
        - examples.sh (10 generic examples)
        - identify-ports.sh (port identification workflow)
        - discover-live-hosts.sh (subnet host discovery)
        - scan-web-vulnerabilities.sh (web vuln scanning)
User: /nmap identify-ports 10.0.0.1
Claude: Runs identify-ports.sh 10.0.0.1 -j -x
        Parses JSON envelope, explains each discovered service.
```

### Pattern 3: "I am learning, walk me through it"
```
User: /lab
Claude: Starts lab, shows targets and credentials.
User: /practice sql-injection
Claude: Walks through SQLi testing on DVWA step by step.
User: Why did that work?
Claude: (pentest-conventions activates) Explains SQL injection,
        parameterized queries, OWASP reference.
```

### Pattern 4: "Diagnose a network problem"
```
User: My connection to example.com seems slow
Claude: (suggests /diagnose based on context)
User: /diagnose example.com
Claude: Runs diagnostics/connectivity.sh, diagnostics/performance.sh
        Parses results, identifies the bottleneck hop.
```

---

## Implementation Patterns

### SKILL.md Pattern for Tool Skills

```yaml
---
name: nmap
description: Network scanning with nmap. Discover hosts, scan ports, detect services.
disable-model-invocation: true
argument-hint: [script-name] [target]
allowed-tools: Bash(bash scripts/nmap/*), Read
---

# nmap - Network Scanner

Available scripts:
- **examples** -- 10 common nmap examples
- **identify-ports** -- Identify services behind open ports
- **discover-live-hosts** -- Find live hosts on a subnet
- **scan-web-vulnerabilities** -- Scan web servers for vulnerabilities

## Usage

Run the requested script with `-j` for structured JSON output:

bash scripts/nmap/$ARGUMENTS[0].sh $ARGUMENTS[1] -j -x

## Rules
- Always use `-j` flag for structured JSON output you can analyze
- Parse the JSON envelope: look at `results` array and `summary`
- Explain findings to the user with severity and next steps
- If tool not installed, show install hint from check-tools.sh
```

### SKILL.md Pattern for Workflow Skills

```yaml
---
name: recon
description: Reconnaissance and intelligence gathering on a target. Use when user wants to discover hosts, enumerate DNS, find subdomains.
argument-hint: [target IP, domain, or subnet]
allowed-tools: Bash(bash scripts/*), Read, Grep
---

# Reconnaissance Workflow

Perform intelligence gathering on $ARGUMENTS following PTES Phase 2.

## Environment
- Installed tools: !`bash scripts/check-tools.sh 2>/dev/null | grep -E '(nmap|dig|gobuster|curl)' | head -10`
- Lab status: !`docker compose -f labs/docker-compose.yml ps 2>/dev/null | tail -5`

## Steps
1. **Host Discovery**: `bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x`
2. **DNS Enumeration**: `bash scripts/dig/query-dns-records.sh $ARGUMENTS -j -x`
3. **Subdomain Discovery** (if domain): `bash scripts/gobuster/enumerate-subdomains.sh $ARGUMENTS -j -x`
4. **SSL/TLS Check** (if HTTPS): `bash scripts/curl/check-ssl-certificate.sh $ARGUMENTS -j -x`

## After each step
- Parse JSON output
- Summarize findings
- Suggest next steps based on results

## Safety
- Verify target is authorized before scanning
- Only scan targets the user explicitly provides
```

---

## Competitor Feature Analysis

| Feature | secskills (trilwu) | awesome-claude-skills-security | claude-code-owasp | Our Approach |
|---------|-------------------|-------------------------------|-------------------|--------------|
| Skills count | 16 skills + 6 agents | Curated wordlists/payloads | Single OWASP skill | 6 workflow + 17 tool + 6 utility = 29 |
| Underlying tools | Generic prompt guidance | SecLists data files | No tool integration | 81 real bash scripts with JSON output |
| Structured output | None | None | None | All scripts: `-j` JSON envelope |
| Educational content | Minimal | None | OWASP Top 10 reference | WHY explanations in every script |
| Lab environment | None | None | None | Docker targets (DVWA, Juice Shop, WebGoat, VulnerableApp) |
| Dual execution | N/A | N/A | N/A | Show mode + Execute mode |
| Methodology | Ad-hoc categories | Payload categories | OWASP framework | PTES 7-phase methodology |
| Distribution | Plugin | Plugin | Plugin/skill | Project skills, future plugin |

---

## Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Official reference: SKILL.md format, frontmatter fields, `$ARGUMENTS`, `!` dynamic context injection, `context: fork`, `disable-model-invocation`, skill description budget (2% context window, 16K fallback), supporting files, `allowed-tools` (HIGH confidence)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- Plugin manifest schema, directory structure (`skills/`, `agents/`, `hooks/`, `.mcp.json`), distribution scopes, `${CLAUDE_PLUGIN_ROOT}`, CLI commands (HIGH confidence)
- [secskills (trilwu/secskills)](https://github.com/trilwu/secskills) -- Existing security plugin: 16 skills (web, AD, cloud, mobile, wireless, post-exploitation) + 6 subagents (pentester, cloud-pentester, mobile-pentester, web3-auditor, red-team-operator, recon-specialist) (MEDIUM confidence)
- [awesome-claude-skills-security (Eyadkelleh)](https://github.com/Eyadkelleh/awesome-claude-skills-security) -- SecLists-based security testing resources as Claude Code skills (MEDIUM confidence)
- [claude-code-owasp (agamm)](https://github.com/agamm/claude-code-owasp) -- OWASP Top 10:2025 + ASVS 5.0 reference skill with code review checklists (MEDIUM confidence)
- [VoltAgent penetration-tester subagent](https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/categories/04-quality-security/penetration-tester.md) -- Agent definition: allowed tools (Read, Grep, Glob, Bash), Opus model, PTES-aligned workflow (MEDIUM confidence)
- [PTES - Penetration Testing Execution Standard](http://www.pentest-standard.org/index.php/Main_Page) -- 7-phase methodology: pre-engagement, intelligence gathering, threat modeling, vulnerability analysis, exploitation, post-exploitation, reporting (HIGH confidence)
- [OWASP Web Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/latest/3-The_OWASP_Testing_Framework/1-Penetration_Testing_Methodologies) -- Web security testing methodology (HIGH confidence)
- Codebase analysis: direct reading of 81 scripts, lib/ modules (args.sh, json.sh, output.sh), Makefile, check-tools.sh, CLAUDE.md, existing GSD commands (HIGH confidence)

---
*Feature research for: Claude Code ethical hacking skill pack*
*Researched: 2026-02-17*
