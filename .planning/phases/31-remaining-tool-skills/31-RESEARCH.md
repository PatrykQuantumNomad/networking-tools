# Phase 31: Remaining Tool Skills - Research

**Researched:** 2026-02-17
**Domain:** Claude Code skill files for 12 remaining pentesting tools
**Confidence:** HIGH

## Summary

Phase 31 creates SKILL.md files for the 12 remaining tools (hashcat, john, hping3, skipfish, aircrack-ng, dig, curl, netcat, traceroute/mtr, gobuster, ffuf, foremost), completing full tool coverage. The pattern is fully validated from Phase 29 (5 tools) and requires no new infrastructure -- just consistent application of the established template to each tool's specific scripts and argument signatures.

The primary risk identified in STATE.md -- "Skill description budget (2% context window, ~16KB)" -- is a non-issue for this phase. All 12 new skills use `disable-model-invocation: true`, which means their descriptions are NOT loaded into Claude's context window. Only the 4 auto-invocable utility skills (~8 KB) count against the budget, and Phase 31 adds zero to that total.

The main challenge is accuracy: each tool has unique argument patterns (hash files vs targets vs interfaces vs disk images vs domains vs ports), unique defaults, and unique categories. Getting these right per-script (not using generic `[target]` everywhere) was an explicit Phase 29-01 decision.

**Primary recommendation:** Create all 12 skills by mechanically applying the validated pattern, with tool-specific argument documentation extracted from each script's `show_help()` function. Batch into 3-4 plans of 3-4 tools each to keep execution focused.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TOOL-06 | Skill for hashcat with `disable-model-invocation: true` | Validated pattern from Phase 29; scripts analyzed (benchmark-gpu, crack-ntlm-hashes, crack-web-hashes, examples); arguments: [hashfile] not [target] |
| TOOL-07 | Skill for john with `disable-model-invocation: true` | Validated pattern; scripts analyzed (crack-linux-passwords, crack-archive-passwords, identify-hash-type, examples); arguments vary: [archive], [hash], none |
| TOOL-08 | Skill for hping3 with `disable-model-invocation: true` | Validated pattern; scripts analyzed (detect-firewall, test-firewall-rules, examples); argument: [target]; requires root/sudo |
| TOOL-09 | Skill for skipfish with `disable-model-invocation: true` | Validated pattern; scripts analyzed (quick-scan-web-app, scan-authenticated-app, examples); argument: [target URL] |
| TOOL-10 | Skill for aircrack-ng with `disable-model-invocation: true` | Validated pattern; scripts analyzed (analyze-wireless-networks, capture-handshake, crack-wpa-handshake, examples); arguments: [interface] or [capture.cap]; Linux-only note |
| TOOL-11 | Skill for dig with `disable-model-invocation: true` | Validated pattern; scripts analyzed (query-dns-records, attempt-zone-transfer, check-dns-propagation, examples); argument: [domain] |
| TOOL-12 | Skill for curl with `disable-model-invocation: true` | Validated pattern; scripts analyzed (check-ssl-certificate, debug-http-response, test-http-endpoints, examples); argument: [target URL or domain] |
| TOOL-13 | Skill for netcat with `disable-model-invocation: true` | Validated pattern; scripts analyzed (scan-ports, setup-listener, transfer-files, examples); arguments vary: [target], [port], [target]; nc variant detection |
| TOOL-14 | Skill for traceroute/mtr with `disable-model-invocation: true` | Validated pattern; scripts analyzed (trace-network-path, compare-routes, diagnose-latency, examples); argument: [target]; diagnose-latency uses mtr |
| TOOL-15 | Skill for gobuster with `disable-model-invocation: true` | Validated pattern; scripts analyzed (discover-directories, enumerate-subdomains, examples); arguments: [target] [wordlist] |
| TOOL-16 | Skill for ffuf with `disable-model-invocation: true` | Validated pattern; scripts analyzed (fuzz-parameters, examples); arguments: [target] [wordlist] |
| TOOL-17 | Skill for foremost with `disable-model-invocation: true` | Validated pattern; scripts analyzed (recover-deleted-files, carve-specific-filetypes, analyze-forensic-image, examples); argument: [disk-image] or [evidence-image] |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code Skills | Current (v2.1.3+) | SKILL.md files with YAML frontmatter | Official extension mechanism, validated in Phase 29 |
| YAML frontmatter | - | Skill metadata (name, description, disable-model-invocation) | Required by Claude Code skill system |
| Markdown | - | Skill instructions content | Skill body after frontmatter separator |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bash | 4.0+ | Wrapper scripts already exist | All 12 tools have scripts in scripts/<tool>/ |
| jq | 1.6+ | JSON envelope parsing in hooks | Phase 28 hooks, already operational |

**Installation:**
No installation needed. All scripts exist. Skills are built-in to Claude Code.

## Architecture Patterns

### Skill File Location
```
.claude/skills/
├── hashcat/SKILL.md
├── john/SKILL.md
├── hping3/SKILL.md
├── skipfish/SKILL.md
├── aircrack-ng/SKILL.md
├── dig/SKILL.md
├── curl/SKILL.md
├── netcat/SKILL.md
├── traceroute/SKILL.md
├── gobuster/SKILL.md
├── ffuf/SKILL.md
└── foremost/SKILL.md
```

### Pattern: Validated Tool Skill Template (from Phase 29)

Every tool skill follows this exact structure:

```yaml
---
name: <tool-name>
description: <one-line purpose using tool wrapper scripts>
disable-model-invocation: true
---

# <Tool Display Name>

<One-line purpose statement.>

## Available Scripts

### <Category 1>

- `bash scripts/<tool>/<script>.sh [accurate-args] [-j] [-x]` -- <description>

### Learning Mode

- `bash scripts/<tool>/examples.sh [arg]` -- View 10 common <tool> patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- <Tool-specific default behaviors>
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
```

### Per-Tool Argument Analysis (from script show_help())

This is the critical differentiation -- each tool has unique argument signatures:

#### hashcat
| Script | Argument | Default |
|--------|----------|---------|
| benchmark-gpu.sh | (none) | N/A (benchmarks hardware) |
| crack-ntlm-hashes.sh | [hashfile] | Shows examples without file |
| crack-web-hashes.sh | [hashfile] | Shows examples without file |
| examples.sh | (none) | N/A |

**Categories:** GPU Benchmarking, NTLM Cracking, Web Hash Cracking, Learning Mode
**Note:** No network target -- operates on local hash files

#### john
| Script | Argument | Default |
|--------|----------|---------|
| crack-linux-passwords.sh | (none) | Shows workflow examples |
| crack-archive-passwords.sh | [archive] | Shows examples without file |
| identify-hash-type.sh | [hash] | Shows ID techniques |
| examples.sh | (none) | N/A |

**Categories:** Linux Passwords, Archive Cracking, Hash Identification, Learning Mode
**Note:** No network target -- operates on local files/hashes. john requires `setup_john_path` (already in scripts).

#### hping3
| Script | Argument | Default |
|--------|----------|---------|
| detect-firewall.sh | [target] | localhost |
| test-firewall-rules.sh | [target] | localhost |
| examples.sh | \<target\> (required) | N/A |

**Categories:** Firewall Detection, Firewall Testing, Learning Mode
**Note:** Most commands require root/sudo. Include this in Defaults section.

#### skipfish
| Script | Argument | Default |
|--------|----------|---------|
| quick-scan-web-app.sh | [target] | http://localhost:3030 |
| scan-authenticated-app.sh | [target] | http://localhost:8080 |
| examples.sh | \<target\> (required) | N/A |

**Categories:** Quick Scanning, Authenticated Scanning, Learning Mode
**Note:** Defaults reference specific lab targets (Juice Shop for quick, DVWA for auth).

#### aircrack-ng
| Script | Argument | Default |
|--------|----------|---------|
| analyze-wireless-networks.sh | [interface] | wlan0 |
| capture-handshake.sh | [interface] | wlan0 |
| crack-wpa-handshake.sh | [capture.cap] | Shows examples without file |
| examples.sh | (none) | N/A |

**Categories:** Wireless Analysis, Handshake Capture, WPA Cracking, Learning Mode
**Note:** Linux-only for monitor mode commands. macOS shows commands as reference only.

#### dig
| Script | Argument | Default |
|--------|----------|---------|
| query-dns-records.sh | [domain] | example.com |
| attempt-zone-transfer.sh | [domain] | example.com |
| check-dns-propagation.sh | [domain] | example.com |
| examples.sh | \<target\> (required) | N/A |

**Categories:** DNS Records, Zone Transfers, Propagation Checks, Learning Mode
**Note:** Argument is a domain name, not IP/URL. Additional flags: `-v`/`--verbose`, `-q`/`--quiet`.

#### curl
| Script | Argument | Default |
|--------|----------|---------|
| check-ssl-certificate.sh | [target] | example.com |
| debug-http-response.sh | [target] | https://example.com |
| test-http-endpoints.sh | [target] | https://example.com |
| examples.sh | \<target\> (required) | N/A |

**Categories:** SSL/TLS Inspection, HTTP Debugging, Endpoint Testing, Learning Mode
**Note:** Target can be domain or full URL. Additional flags: `-v`/`--verbose`, `-q`/`--quiet`.

#### netcat
| Script | Argument | Default |
|--------|----------|---------|
| scan-ports.sh | [target] | 127.0.0.1 |
| setup-listener.sh | [port] | 4444 |
| transfer-files.sh | [target] | 127.0.0.1 |
| examples.sh | \<target\> (required) | N/A |

**Categories:** Port Scanning, Listeners, File Transfer, Learning Mode
**Note:** Arguments vary by script (target vs port). Detects nc variant (ncat, GNU, traditional, OpenBSD).

#### traceroute
| Script | Argument | Default |
|--------|----------|---------|
| trace-network-path.sh | [target] | example.com |
| compare-routes.sh | [target] | example.com |
| diagnose-latency.sh | [target] | example.com |
| examples.sh | \<target\> (required) | N/A |

**Categories:** Path Tracing, Route Comparison, Latency Diagnosis, Learning Mode
**Note:** diagnose-latency.sh requires `mtr` not `traceroute`. Requires sudo on macOS.

#### gobuster
| Script | Argument | Default |
|--------|----------|---------|
| discover-directories.sh | [target] [wordlist] | http://localhost:8080 |
| enumerate-subdomains.sh | [domain] [wordlist] | example.com |
| examples.sh | \<target\> (required) | N/A |

**Categories:** Directory Discovery, Subdomain Enumeration, Learning Mode
**Note:** Scripts accept optional second argument for custom wordlist.

#### ffuf
| Script | Argument | Default |
|--------|----------|---------|
| fuzz-parameters.sh | [target] [wordlist] | http://localhost:8080 |
| examples.sh | \<target\> (required) | N/A |

**Categories:** Parameter Fuzzing, Learning Mode
**Note:** Only 1 use-case script (smallest skill). Scripts accept optional wordlist.

#### foremost
| Script | Argument | Default |
|--------|----------|---------|
| recover-deleted-files.sh | [disk-image] | Shows examples |
| carve-specific-filetypes.sh | [disk-image] | Shows examples |
| analyze-forensic-image.sh | [evidence-image] | Shows examples |
| examples.sh | [disk-image] | Shows examples |

**Categories:** File Recovery, Targeted Carving, Forensic Analysis, Learning Mode
**Note:** No network target -- operates on disk images/memory dumps. No scope validation needed for local files.

### Anti-Patterns to Avoid
- **Generic `[target]` for all arguments:** Use accurate args from show_help() (hashfile, archive, interface, domain, port, disk-image)
- **Omitting tool-specific notes:** hping3 needs root, aircrack-ng is Linux-only for monitor mode, netcat varies by variant
- **Inconsistent Flags section:** Copy the validated Flags section verbatim from Phase 29 pattern
- **Forgetting examples.sh:** Every tool has one; always include under "Learning Mode"

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| New skill template | Custom structure per tool | Phase 29 validated template | Pattern proven across 5 tools, consistency is the goal |
| Script argument discovery | Guessing from tool docs | Each script's show_help() | Actual arguments already defined per script |
| Target validation section | Custom scope explanation per tool | Standard 5-line Target Validation block | Identical across all tool skills |
| Flags section | Custom flag docs per tool | Standard Flags block from template | All use-case scripts support identical -j/-x/--help flags |

**Key insight:** Phase 31 is a scaling exercise, not a design exercise. The pattern is proven. The only intellectual work is reading each script's show_help() for accurate argument documentation and choosing sensible category headings.

## Common Pitfalls

### Pitfall 1: Wrong argument in skill docs
**What goes wrong:** Skill says `[target]` but script actually takes `[hashfile]`, `[interface]`, `[domain]`, or `[port]`
**Why it happens:** Copy-pasting from another tool skill without updating arguments
**How to avoid:** Check each script's show_help() Usage line before writing the skill reference
**Warning signs:** User invokes script with wrong argument type (IP address for a hash cracking tool)

### Pitfall 2: Missing tool-specific Defaults section
**What goes wrong:** User doesn't know that hping3 needs root, or aircrack-ng is Linux-only
**Why it happens:** Treating all tools as network scanners with the same usage pattern
**How to avoid:** Include tool-specific notes in the Defaults section (root requirements, platform limits, nc variant detection)
**Warning signs:** User gets permission errors or "command not found" without understanding why

### Pitfall 3: Incorrect skill name for tools with special characters
**What goes wrong:** Skill name doesn't match tool name format that users expect
**Why it happens:** Hyphens, dots, or version numbers in tool names
**How to avoid:** Use exact tool directory names: `aircrack-ng` (hyphenated), `hping3` (numbered), `netcat` (not `nc`)
**Warning signs:** User types `/nc` but skill is registered as `/netcat`

### Pitfall 4: Inconsistent category groupings
**What goes wrong:** Category headers feel arbitrary or don't help navigation
**Why it happens:** Not thinking about user workflow when grouping scripts
**How to avoid:** Group by task type (Cracking, Analysis, Discovery) not by script name. Use verb-based headers.
**Warning signs:** User can't find the right script for their task

### Pitfall 5: Scope validation section for offline tools
**What goes wrong:** foremost, hashcat, john skills include target validation section but these tools don't scan networks
**Why it happens:** Mechanically copying the Target Validation block to every skill
**How to avoid:** For offline tools (hashcat, john, foremost), modify the Target Validation section or omit it. These tools operate on local files, not network targets. The PreToolUse hook still validates the bash command, but scope.json targets are irrelevant.
**Warning signs:** User confused by "verify your target is in scope.json" when running a hash cracker on a local file

## Code Examples

### Example: Offline Tool Skill (hashcat)
```yaml
---
name: hashcat
description: GPU-accelerated password hash cracking using hashcat wrapper scripts
disable-model-invocation: true
---

# Hashcat Password Cracker

Run hashcat wrapper scripts for GPU-accelerated hash cracking with educational examples and structured JSON output.

## Available Scripts

### GPU Performance

- `bash scripts/hashcat/benchmark-gpu.sh [-j] [-x]` -- Benchmark GPU hash cracking speed across common hash types

### NTLM Cracking

- `bash scripts/hashcat/crack-ntlm-hashes.sh [hashfile] [-j] [-x]` -- Crack Windows NTLM hashes using dictionary, brute force, and rule-based attacks

### Web Hash Cracking

- `bash scripts/hashcat/crack-web-hashes.sh [hashfile] [-j] [-x]` -- Crack MD5, SHA-256, bcrypt, WordPress, Django, and MySQL hashes

### Learning Mode

- `bash scripts/hashcat/examples.sh` -- View 10 common hashcat patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Hash file argument is optional -- scripts show techniques without a file when omitted
- Benchmark runs against common hash types (MD5, SHA-256, NTLM, bcrypt)
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate commands via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Hashcat operates on local files -- no network scope validation required
```

### Example: Network Tool with Unique Defaults (netcat)
```yaml
---
name: netcat
description: TCP/UDP networking swiss-army knife using netcat wrapper scripts
disable-model-invocation: true
---

# Netcat Network Utility

Run netcat wrapper scripts for port scanning, listeners, and file transfers with educational examples.

## Available Scripts

### Port Scanning

- `bash scripts/netcat/scan-ports.sh [target] [-j] [-x]` -- Scan ports using nc -z mode with variant-aware flags

### Listeners

- `bash scripts/netcat/setup-listener.sh [port] [-j] [-x]` -- Set up listeners for reverse shells, file transfers, and debugging

### File Transfer

- `bash scripts/netcat/transfer-files.sh [target] [-j] [-x]` -- Send and receive files, directories, and compressed data over TCP

### Learning Mode

- `bash scripts/netcat/examples.sh <target>` -- View 10 common netcat patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- scan-ports and transfer-files default to `127.0.0.1` when no target provided
- setup-listener defaults to port `4444` when no port provided
- Detects nc variant (ncat, GNU, traditional, OpenBSD) and labels variant-specific flags
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate targets against `.pentest/scope.json` via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Verify your target is listed in `.pentest/scope.json`
3. Default safe targets: localhost, 127.0.0.1, lab containers (ports 8080, 3030, 8888, 8180)
```

### Example: Platform-Restricted Tool (aircrack-ng)
```yaml
---
name: aircrack-ng
description: WiFi security auditing and WPA cracking using aircrack-ng wrapper scripts
disable-model-invocation: true
---

# Aircrack-ng WiFi Security Suite

Run aircrack-ng wrapper scripts for wireless network analysis, handshake capture, and WPA cracking.

## Available Scripts

### Wireless Analysis

- `bash scripts/aircrack-ng/analyze-wireless-networks.sh [interface] [-j] [-x]` -- Survey nearby networks for encryption types, signal strength, and hidden SSIDs

### Handshake Capture

- `bash scripts/aircrack-ng/capture-handshake.sh [interface] [-j] [-x]` -- Capture WPA/WPA2 4-way handshake for offline cracking

### WPA Cracking

- `bash scripts/aircrack-ng/crack-wpa-handshake.sh [capture.cap] [-j] [-x]` -- Crack captured handshake using dictionary attacks

### Learning Mode

- `bash scripts/aircrack-ng/examples.sh` -- View 10 common aircrack-ng patterns with explanations

## Flags

All use-case scripts support these flags:

- `-j` / `--json` -- Output structured JSON envelope (enables PostToolUse hook summary)
- `-x` / `--execute` -- Execute commands instead of displaying them
- `--help` -- Show detailed usage, description, and examples for the script

Add `-j` to every invocation so Claude receives a parsed summary via the PostToolUse hook.
Without `-j`, Claude gets raw terminal output instead of structured results.

## Defaults

- Interface defaults to `wlan0` when not provided (analysis and capture scripts)
- Crack script accepts a `.cap` file path as first argument
- Linux only: monitor mode commands (airmon-ng, airodump-ng) are not available on macOS
- On macOS, scripts show commands as reference only
- Scripts display commands without running them unless `-x` is passed

## Target Validation

All scripts validate commands via the PreToolUse hook.
If commands are blocked:

1. Run `/netsec-health` to check safety architecture status
2. Wireless tools operate on local interfaces -- network scope validation applies to target BSSIDs
```

## Context Budget Analysis

**STATE.md concern:** "Skill description budget (2% context window, ~16KB) -- monitor during Phase 31"

**Finding:** This concern is resolved. Tool skills with `disable-model-invocation: true` do NOT load descriptions into context.

| Skill Type | Count (current) | Count (after P31) | In Context? | Bytes |
|------------|-----------------|---------------------|-------------|-------|
| Tool skills (disable-model-invocation) | 5 | 17 | NO | 0 (context) |
| Utility skills (auto-invocable) | 4 | 4 | YES | ~8,081 bytes |
| **Total in context** | | | | **~8 KB** |

Budget: 2% of 200K = ~16 KB. Current usage: ~8 KB (50% of budget). Phase 31 adds 0 bytes to context budget.

**Confidence:** HIGH -- verified from Phase 29 research on `disable-model-invocation: true` behavior.

## Batching Strategy

12 tools can be grouped into plans of 3-4 tools each for focused execution:

| Plan | Tools | Rationale |
|------|-------|-----------|
| 31-01 | hashcat, john, aircrack-ng, foremost | Offline/file-based tools (no network targets, modified Target Validation) |
| 31-02 | hping3, skipfish, netcat, traceroute | Network tools with unique defaults (root, variants, mtr) |
| 31-03 | dig, curl, gobuster, ffuf | Web/DNS recon tools (domain/URL targets, wordlist args) |

This grouping clusters tools with similar argument patterns and Target Validation needs, reducing context-switching during execution.

## Open Questions

1. **Should offline tools (hashcat, john, foremost) omit or modify the Target Validation section?**
   - What we know: These tools operate on local files, not network targets. Scope validation is irrelevant.
   - What's unclear: The PreToolUse hook still fires on bash commands. Does it try to validate targets for these tools?
   - Recommendation: Keep a minimal Target Validation section mentioning the PreToolUse hook, but note that no network scope validation is needed. This is consistent with the wrapper-never-modifies principle.

2. **Should the traceroute skill name be `traceroute` or `traceroute-mtr`?**
   - What we know: The scripts directory is `scripts/traceroute/`, and diagnose-latency.sh uses `mtr` not `traceroute`
   - What's unclear: Whether users would expect `/traceroute` to also cover mtr
   - Recommendation: Use `traceroute` as the skill name (matches directory), mention mtr in the description and diagnose-latency script reference

## Sources

### Primary (HIGH confidence)
- Project codebase: `.claude/skills/{nmap,tshark,metasploit,sqlmap,nikto}/SKILL.md` -- Validated pattern from Phase 29
- Project codebase: `scripts/*/show_help()` functions -- Actual argument signatures for all 12 tools (read directly)
- Phase 29 RESEARCH.md -- Skill system architecture, frontmatter fields, context budget mechanics
- Phase 29 VERIFICATION.md -- Pattern validated across 5 tools, all script references verified
- Phase 29-01 SUMMARY.md -- Decisions on accurate argument docs, tool-specific defaults, double-dash style

### Secondary (MEDIUM confidence)
- STATE.md -- Context budget concern documented, v1.5 decisions accumulated
- Phase 30 skills (check-tools, lab, pentest-conventions) -- Utility skill pattern for contrast

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- identical to Phase 29, no new technology
- Architecture: HIGH -- validated pattern applied 5 times, 12 more is mechanical
- Per-tool analysis: HIGH -- all 12 tools' scripts read directly from codebase
- Context budget: HIGH -- verified from Phase 29 research on disable-model-invocation behavior
- Pitfalls: HIGH -- drawn from Phase 29 execution decisions and known argument patterns

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (30 days -- pattern stable, no moving parts)
