# Phase 36: Dual-Mode Tool Skills - Research

**Researched:** 2026-03-06
**Domain:** Claude Code skills authoring, dual-mode detection patterns, inline tool knowledge, skills.sh discoverability
**Confidence:** HIGH

## Summary

Phase 36 transforms 17 tool skills from wrapper-script-only references into dual-mode skills that work both standalone (inline command knowledge) and in-repo (wrapper script delegation with `-j -x` flags). Currently, every tool skill in `.claude/skills/` and `netsec-skills/skills/tools/` is a thin pointer to `bash scripts/<tool>/<script>.sh` commands. Outside the networking-tools repo, these skills are useless because the wrapper scripts do not exist.

The core transformation adds three capabilities to each skill: (1) inline command knowledge covering the same use cases as the wrapper scripts but expressed as direct tool commands, (2) mode detection that checks whether wrapper scripts exist and branches between inline commands and wrapper script delegation, and (3) tool installation detection with platform-specific install guidance. The skill descriptions must also be rewritten with natural trigger keywords to optimize for Claude's auto-matching and skills.sh search ranking.

A critical finding is that `disable-model-invocation: true` does NOT work for plugin skills (GitHub issue #22345, open as of March 2026). Since these skills will be distributed as a plugin, the `disable-model-invocation` flag will be ignored -- all 17 tool skill descriptions will be loaded into context at startup regardless. This means descriptions must be concise (the spec recommends the description field for matching, and descriptions are loaded as ~50-100 tokens each). However, the flag should still be set for the in-repo versions where it works correctly.

**Primary recommendation:** Use the `!`command -v scripts/<tool>/<script>.sh`\` dynamic injection pattern to detect wrapper script presence at skill invocation time, with inline command knowledge as the default path and wrapper scripts as the enhanced path.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TOOL-01 | User can use any of 17 tool skills without wrapper scripts present (standalone mode with inline tool knowledge) | Inline knowledge pattern, tool command inventory per skill, Agent Skills spec progressive disclosure |
| TOOL-02 | Tool skills detect and use wrapper scripts when available for structured JSON output (in-repo mode) | Dynamic injection `!\`command -v\`` detection pattern, wrapper script inventory, `-j -x` flag convention |
| TOOL-03 | Each tool skill detects whether the tool is installed and provides platform-specific install guidance | `!\`command -v <tool>\`` detection, install hints from check-tools.sh, per-platform install commands |
| TOOL-04 | Each skill description uses natural trigger keywords optimized for Claude auto-matching and skills.sh search | Agent Skills spec description field guidance, Claude Code auto-matching behavior, keyword analysis |
</phase_requirements>

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Claude Code SKILL.md | Agent Skills spec | Skill definition format | Open standard adopted by 30+ agent products; Claude Code extends with frontmatter |
| Bash `command -v` | POSIX | Tool/script existence detection | POSIX-standard, works in all bash versions, used in dynamic injection `!\`\`` |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `${CLAUDE_SKILL_DIR}` | Claude Code builtin | Resolve skill directory path | Reference supporting files bundled with the skill |
| `!\`command\`` syntax | Claude Code skills | Dynamic context injection | Detect wrapper scripts and tool availability at invocation time |
| shellcheck | any | Validate bash in `!\`\`` injection commands | During development to catch errors in detection commands |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `!\`command -v\`` detection | Static if/else in skill body | Dynamic injection runs BEFORE Claude sees the skill, giving actual system state; static text requires Claude to check manually |
| Inline command knowledge | Bundling wrapper scripts in skill | REQUIREMENTS.md explicitly says "Defeats standalone purpose; skills should contain knowledge, not bash scripts" -- OUT OF SCOPE |
| Per-skill install detection | Single `check-tools.sh` reference | Per-skill detection is more targeted; user asking about nmap doesn't need to know about aircrack-ng |

## Architecture Patterns

### Recommended Skill Structure (Dual-Mode)

```
<tool>/
  SKILL.md          # Dual-mode skill with inline knowledge + wrapper detection
```

No supporting files needed -- all knowledge fits in SKILL.md body (under 500 lines per Agent Skills spec recommendation). The wrapper scripts already exist in `scripts/<tool>/` and don't need to be duplicated.

### Pattern 1: Dual-Mode Skill Template
**What:** A SKILL.md that branches between standalone (inline commands) and in-repo (wrapper scripts) based on runtime detection.
**When to use:** Every one of the 17 tool skills.
**Example:**
```yaml
---
name: nmap
description: >-
  Scan networks, discover hosts, detect open ports and services with nmap.
  Port scanning, host discovery, OS detection, service enumeration, NSE scripts.
disable-model-invocation: true
---

# Nmap Network Scanner

Scan networks, discover hosts, and detect services using nmap.

## Tool Status

- Tool installed: !`command -v nmap > /dev/null 2>&1 && echo "YES -- $(nmap --version 2>&1 | head -1)" || echo "NO -- Install: brew install nmap (macOS) | apt install nmap (Linux)"`
- Wrapper scripts available: !`test -f scripts/nmap/identify-ports.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct nmap commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Discovery
- `bash scripts/nmap/discover-live-hosts.sh <target> -j -x` -- Find active hosts
- `bash scripts/nmap/identify-ports.sh <target> -j -x` -- Scan open ports and services

### Web Scanning
- `bash scripts/nmap/scan-web-vulnerabilities.sh <target> -j -x` -- NSE vulnerability detection

### Learning Mode
- `bash scripts/nmap/examples.sh <target>` -- 10 common nmap patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct nmap commands:

### Host Discovery
- `nmap -sn <target>` -- Ping sweep to find live hosts
- `nmap -sn -PS21,22,80,443 <target>` -- TCP SYN ping sweep
- `nmap -sn -PA80,443 <target>` -- TCP ACK ping sweep
- `nmap -sn -PE <target>` -- ICMP echo ping sweep

### Port Scanning
- `nmap -sS -T4 <target>` -- Fast SYN scan (requires root)
- `nmap -sT -T4 <target>` -- TCP connect scan (no root needed)
- `nmap -p- <target>` -- Scan all 65535 ports
- `nmap -sV <target>` -- Service version detection
- `nmap -O <target>` -- OS detection (requires root)

### Web Vulnerability Scanning
- `nmap --script=http-enum <target>` -- Enumerate web directories
- `nmap --script=http-vuln-* <target>` -- Check common web CVEs
- `nmap --script=ssl-enum-ciphers -p 443 <target>` -- Enumerate SSL ciphers

### Useful Combinations
- `nmap -sS -sV -O -T4 <target>` -- Full service + OS scan
- `nmap -A <target>` -- Aggressive scan (OS, version, scripts, traceroute)
- `nmap -sS -sV --script=default <target>` -- Default NSE scripts

## Defaults
- Target defaults to `localhost` when not provided
- Most scans require root/sudo for raw socket access (SYN scan, OS detection)

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
```

### Pattern 2: Tool Installation Detection with Dynamic Injection
**What:** Use `!\`command -v <tool>\`` in SKILL.md to show tool status at invocation time.
**When to use:** Every tool skill, for TOOL-03 requirement.
**Example:**
```markdown
## Tool Status

- Tool installed: !`command -v dig > /dev/null 2>&1 && echo "YES -- $(dig -v 2>&1 | head -1)" || echo "NO -- Install: apt install dnsutils (Debian/Ubuntu) | brew install bind (macOS)"`
```

The `!\`\`` syntax runs the command BEFORE Claude sees the skill content. Claude receives "YES -- DiG 9.18.27" or "NO -- Install: brew install bind (macOS)" as plain text. This is preprocessing, not something Claude executes.

### Pattern 3: Wrapper Script Detection via File Existence
**What:** Check if wrapper scripts exist to determine mode. Using `test -f` on a representative script file rather than `command -v` (which checks PATH, not file existence).
**When to use:** The mode detection for TOOL-02.
**Example:**
```markdown
- Wrapper scripts available: !`test -f scripts/nmap/identify-ports.sh && echo "YES" || echo "NO"`
```

**Why `test -f` not `command -v`:** The wrapper scripts are not on PATH -- they are invoked via `bash scripts/<tool>/<script>.sh`. `command -v` only finds executables on PATH. `test -f` checks if the file exists relative to the current working directory (which is the project root when Claude Code runs).

### Pattern 4: Description Keyword Optimization
**What:** Rewrite skill descriptions with natural trigger keywords that match how users ask for pentesting tasks.
**When to use:** TOOL-04 for all 17 skills.
**Example (current vs improved):**
```yaml
# CURRENT (wrapper-centric, vague triggers):
description: Network scanning and host discovery using nmap wrapper scripts

# IMPROVED (task-oriented, natural keywords):
description: >-
  Scan networks, discover hosts, detect open ports and services with nmap.
  Port scanning, host discovery, OS detection, service enumeration, NSE scripts.
```

The improved description:
- Leads with action verbs matching user intent ("scan networks", "discover hosts")
- Includes the tool name for direct invocation matching
- Lists specific capabilities as keywords for semantic matching
- Removes "wrapper scripts" -- irrelevant to users, hurts standalone discoverability
- Stays under 200 characters for token efficiency (descriptions load at startup for all skills)

### Pattern 5: Pilot-First Validation
**What:** Implement dual-mode pattern on 3 simple tools (dig, curl, netcat) first, then scale to remaining 14.
**When to use:** Success criteria #5 mandates this sequencing.
**Why these 3:**
- dig: Simple DNS tool, 3 wrapper scripts, straightforward command syntax
- curl: Ubiquitous HTTP tool, 3 wrapper scripts, users already know it
- netcat: Swiss-army networking tool, 3 wrapper scripts, demonstrates variant detection complexity

### Anti-Patterns to Avoid

- **Duplicating wrapper script bash logic in SKILL.md:** Skills contain KNOWLEDGE (what commands to run), not executable bash code. The inline commands are raw tool commands, not reimplementations of the wrapper script logic.
- **Making standalone mode inferior to in-repo mode:** Both modes should produce working, useful commands. Standalone mode loses JSON output formatting but gains portability.
- **Overly long descriptions:** The Agent Skills spec allows 1024 chars, but Claude Code loads ALL skill descriptions at startup (~50-100 tokens each). With 17 tool skills, bloated descriptions waste ~1700 tokens of context. Keep under 200 characters.
- **Referencing wrapper scripts without checking existence:** Never say "run `bash scripts/nmap/examples.sh`" unconditionally -- always behind a detection check.
- **Ignoring the disable-model-invocation plugin bug:** Setting the flag is correct for in-repo use, but the planner must know descriptions WILL load in plugin context regardless (issue #22345).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mode detection | Custom bash scripts that Claude must run | `!\`test -f scripts/<tool>/<script>.sh\`` dynamic injection | Runs before Claude sees content; zero tool calls needed |
| Tool installation check | Multi-step "first check if installed" logic | `!\`command -v <tool>\`` dynamic injection | Single preprocessed line, no Claude reasoning overhead |
| Version detection | Tool-specific version parsing logic | Reuse patterns from `check-tools.sh` (get_version function) | Already handles edge cases (msfconsole manifest, dig -v, nc variant) |
| Install guidance text | Per-skill custom install instructions | Copy from `check-tools.sh` TOOLS associative array | Single source of truth for install commands across brew/apt/pip |
| Keyword optimization | Manual keyword guessing | Analyze actual wrapper script descriptions + user task patterns | Match how users naturally ask for pentesting tasks |

**Key insight:** The `!\`command\`` dynamic injection in SKILL.md is the critical enabler -- it makes mode detection invisible to Claude. Without it, every skill invocation would require Claude to first check if scripts exist, wasting tool calls and context.

## Common Pitfalls

### Pitfall 1: Confusing `command -v` with `test -f` for Script Detection
**What goes wrong:** Using `command -v scripts/nmap/identify-ports.sh` returns nothing because wrapper scripts are not on PATH.
**Why it happens:** `command -v` searches PATH for executables. The wrapper scripts are invoked as `bash scripts/<tool>/<script>.sh` and are not installed as PATH commands.
**How to avoid:** Use `test -f scripts/<tool>/<script>.sh` for wrapper script detection. Use `command -v <tool>` only for checking if the actual security tool (nmap, dig, etc.) is installed.
**Warning signs:** Dynamic injection always shows "NO" for wrapper scripts even inside the repo.

### Pitfall 2: disable-model-invocation Ignored in Plugin Context
**What goes wrong:** All 17 tool skill descriptions are loaded into context at startup, consuming ~1700 tokens, even with `disable-model-invocation: true`.
**Why it happens:** GitHub issue #22345 (open, March 2026): plugin skills do not support `disable-model-invocation`. The flag is parsed for user/project skills but silently ignored for plugin skills.
**How to avoid:** Keep descriptions concise (under 200 chars each). The descriptions WILL be loaded regardless in plugin context. Consider this a token budget cost of the plugin distribution model.
**Warning signs:** Users report "Claude keeps mentioning nmap when I ask about unrelated things" -- caused by overly broad descriptions.

### Pitfall 3: Inline Knowledge That Diverges from Wrapper Scripts
**What goes wrong:** The inline standalone commands cover different use cases or produce different results than the wrapper scripts, confusing users who switch between modes.
**Why it happens:** Inline knowledge is written independently and not cross-referenced with wrapper scripts.
**How to avoid:** For each wrapper script, extract the exact commands it runs (the `run_or_show` calls) and document those same commands in the standalone section. The wrapper scripts use `run_or_show` which either displays or executes the command -- the standalone section should list those same commands.
**Warning signs:** User gets different results from `/nmap` in-repo vs standalone.

### Pitfall 4: Tool Status Section Becoming Stale
**What goes wrong:** Dynamic injection `!\`\`` runs when the skill is invoked, not when the user types a question. If Claude loads the skill via auto-matching (not `/nmap` invocation), the dynamic injection may not execute.
**Why it happens:** Per Claude Code docs, `!\`command\`` is preprocessing that runs when the skill content is loaded. For auto-matched skills (description match), the full content loads when Claude decides the skill is relevant.
**How to avoid:** The `!\`\`` syntax handles this correctly -- it runs whenever the full skill content is loaded, whether by user `/invoke` or Claude auto-match. No workaround needed. But keep `disable-model-invocation: true` for in-repo context to prevent unnecessary auto-loading.
**Warning signs:** None expected -- this is informational only.

### Pitfall 5: Standalone Mode Lacking Educational Context
**What goes wrong:** Standalone commands are bare tool invocations without the "why" explanations that wrapper scripts provide.
**Why it happens:** Trying to keep SKILL.md under 500 lines means cutting educational content.
**How to avoid:** Include brief "why" context for each command category (2-3 lines explaining the purpose), but not the full educational text from wrapper scripts. The skill should be actionable, not a tutorial.
**Warning signs:** Users outside the repo get commands but don't understand when to use each one.

### Pitfall 6: Inconsistent Tool Binary Names Across Skills
**What goes wrong:** Skill checks for `nmap` but the actual binary might be in a non-standard location, or for metasploit, the binary is `msfconsole` not `metasploit`.
**Why it happens:** Tool names in skills don't always match the command-line binary names.
**How to avoid:** Use the exact binary names from `check-tools.sh` TOOL_ORDER: nmap, tshark, msfconsole, aircrack-ng, hashcat, skipfish, sqlmap, hping3, john, nikto, foremost, dig, curl, nc, traceroute, mtr, gobuster, ffuf. For skills that map to multiple binaries (metasploit -> msfconsole/msfvenom), check the primary binary.
**Warning signs:** "Tool installed: NO" when the tool is actually installed under a different name.

## Code Examples

Verified patterns from the project codebase:

### Dynamic Injection for Mode Detection (from Claude Code official docs)
```markdown
## Tool Status
- Wrapper scripts: !`test -f scripts/dig/query-dns-records.sh && echo "YES" || echo "NO"`
- dig installed: !`command -v dig > /dev/null 2>&1 && echo "YES -- $(dig -v 2>&1 | head -1)" || echo "NO -- Install: apt install dnsutils (Debian/Ubuntu) | brew install bind (macOS)"`
```
Source: [Claude Code Skills docs](https://code.claude.com/docs/en/skills) -- "Inject dynamic context" section

### Install Hints from check-tools.sh (existing project pattern)
```bash
# Source: scripts/check-tools.sh lines 31-49
declare -A TOOLS=(
    [nmap]="brew install nmap"
    [tshark]="brew install wireshark (includes tshark CLI)"
    [msfconsole]="https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html"
    [aircrack-ng]="brew install aircrack-ng"
    [hashcat]="brew install hashcat"
    [skipfish]="sudo port install skipfish"
    [sqlmap]="brew install sqlmap"
    [hping3]="brew install draftbrew/tap/hping"
    [john]="brew install john-jumbo"
    [nikto]="brew install nikto"
    [foremost]="brew install foremost"
    [dig]="apt install dnsutils (Debian/Ubuntu) | brew install bind (macOS)"
    [curl]="apt install curl (Debian/Ubuntu) | brew install curl (macOS)"
    [nc]="apt install netcat-openbsd (Debian/Ubuntu) | brew install netcat (macOS)"
    [traceroute]="apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | pre-installed on macOS"
    [mtr]="apt install mtr (Debian/Ubuntu) | dnf install mtr (RHEL/Fedora) | brew install mtr (macOS)"
    [gobuster]="brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"
    [ffuf]="brew install ffuf (or: go install github.com/ffuf/ffuf/v2@latest)"
)
```

### Extracting Inline Knowledge from Wrapper Scripts
```bash
# Source: scripts/dig/query-dns-records.sh lines 60-98
# Each run_or_show call = one standalone command to document
run_or_show "1) A record -- IPv4 address" \
    dig "$TARGET" A +noall +answer          # -> standalone: dig <target> A +noall +answer

run_or_show "2) AAAA record -- IPv6 address" \
    dig "$TARGET" AAAA +noall +answer       # -> standalone: dig <target> AAAA +noall +answer
```

### Version Detection Patterns (from check-tools.sh)
```bash
# Source: scripts/check-tools.sh get_version function
# These patterns should be reused in dynamic injection
# Standard:  <tool> --version 2>/dev/null | head -1
# dig:       dig -v 2>&1 | head -1
# nc:        nc -h 2>&1 | head -1 || true
# msfconsole: grep metasploit /opt/metasploit-framework/version-manifest.txt | head -1
# gobuster:  gobuster version 2>/dev/null | head -1
# ffuf:      ffuf -V 2>&1 | head -1
# traceroute: echo "installed" (no --version on macOS BSD)
```

## Wrapper Script Inventory (17 tools, 48 use-case scripts + 17 examples.sh)

Each wrapper script corresponds to inline knowledge that the standalone skill must replicate:

| Tool | Scripts (excl. examples.sh) | Key Capabilities to Cover |
|------|-----------------------------|---------------------------|
| nmap | discover-live-hosts, identify-ports, scan-web-vulnerabilities | Ping sweeps, port scanning, NSE scripts |
| tshark | capture-http-credentials, analyze-dns-queries, extract-files-from-capture | Live capture, display filters, file carving |
| metasploit | generate-reverse-shell, scan-network-services, setup-listener | msfvenom payloads, auxiliary scanners, multi/handler |
| aircrack-ng | analyze-wireless-networks, capture-handshake, crack-wpa-handshake | Monitor mode, airodump, aircrack dictionary attack |
| hashcat | benchmark-gpu, crack-ntlm-hashes, crack-web-hashes | Hash modes, attack modes, rule-based cracking |
| skipfish | quick-scan-web-app, scan-authenticated-app | Web crawler, authenticated scanning |
| sqlmap | dump-database, test-all-parameters, bypass-waf | URL testing, tamper scripts, database enumeration |
| hping3 | detect-firewall, test-firewall-rules | TCP flag probes, ICMP, custom packets |
| john | crack-linux-passwords, crack-archive-passwords, identify-hash-type | Wordlists, format detection, zip2john/rar2john |
| nikto | scan-specific-vulnerabilities, scan-multiple-hosts, scan-with-auth | Tuning flags, host files, cookie auth |
| foremost | recover-deleted-files, carve-specific-filetypes, analyze-forensic-image | Header/footer carving, file type selection |
| dig | query-dns-records, attempt-zone-transfer, check-dns-propagation | Record types, AXFR, multi-resolver checks |
| curl | check-ssl-certificate, debug-http-response, test-http-endpoints | TLS inspection, headers, timing |
| netcat | scan-ports, setup-listener, transfer-files | nc -z scan, listeners, file piping, variant detection |
| traceroute | trace-network-path, compare-routes, diagnose-latency | TCP/UDP/ICMP modes, mtr real-time analysis |
| gobuster | discover-directories, enumerate-subdomains | dir mode, dns mode, wordlists |
| ffuf | fuzz-parameters | FUZZ keyword, filters, custom wordlists |

## Description Keyword Optimization (TOOL-04)

### Current Descriptions (wrapper-centric, poor for standalone discovery)
All 17 current descriptions follow the pattern: `"<capability> using <tool> wrapper scripts"`. This is bad for two reasons:
1. "wrapper scripts" is meaningless to standalone users
2. The descriptions lack action verbs and specific task keywords

### Recommended Descriptions (task-oriented, keyword-rich)
| Tool | Current Description | Recommended Description |
|------|-------------------|----------------------|
| nmap | Network scanning and host discovery using nmap wrapper scripts | Scan networks, discover hosts, detect open ports and services with nmap. Port scanning, host discovery, OS detection, service enumeration, NSE scripts. |
| tshark | Packet capture and network traffic analysis using tshark wrapper scripts | Capture and analyze network traffic with tshark. Packet capture, protocol analysis, display filters, credential extraction, file carving from pcaps. |
| metasploit | Exploitation framework wrapper scripts for payloads, scanning, and listeners | Generate payloads, scan services, and set up listeners with Metasploit. Reverse shells, msfvenom, auxiliary scanners, multi/handler. |
| aircrack-ng | WiFi security auditing and WPA cracking using aircrack-ng wrapper scripts | Audit WiFi security and crack WPA handshakes with aircrack-ng. Wireless scanning, monitor mode, handshake capture, dictionary attacks. |
| hashcat | GPU-accelerated password hash cracking using hashcat wrapper scripts | Crack password hashes with GPU acceleration using hashcat. NTLM, MD5, SHA-256, bcrypt, rule-based attacks, benchmarking. |
| skipfish | Active web application security scanner using skipfish wrapper scripts | Scan web applications for vulnerabilities with skipfish. Web crawler, authenticated scanning, security assessment. |
| sqlmap | SQL injection detection and database extraction using sqlmap wrapper scripts | Detect SQL injection and extract databases with sqlmap. Parameter testing, WAF bypass, database enumeration, tamper scripts. |
| hping3 | TCP/IP packet crafting and firewall testing using hping3 wrapper scripts | Craft packets and test firewalls with hping3. TCP flag probes, firewall detection, custom ICMP/UDP/TCP packets. |
| john | Password hash cracking and identification using John the Ripper wrapper scripts | Crack passwords and identify hash types with John the Ripper. Linux shadows, archive passwords, wordlists, incremental mode. |
| nikto | Web server vulnerability scanning using nikto wrapper scripts | Scan web servers for vulnerabilities with nikto. CGI checks, outdated software, misconfigurations, authenticated scanning. |
| foremost | File carving and forensic data recovery using foremost wrapper scripts | Recover deleted files and carve data from disk images with foremost. File carving, forensic analysis, header/footer recovery. |
| dig | DNS record querying and zone transfer testing using dig wrapper scripts | Query DNS records and test zone transfers with dig. A, MX, NS, TXT records, AXFR, propagation checks, nameserver queries. |
| curl | HTTP request debugging and SSL inspection using curl wrapper scripts | Debug HTTP requests and inspect SSL certificates with curl. TLS versions, certificate chains, headers, response timing. |
| netcat | TCP/UDP networking swiss-army knife using netcat wrapper scripts | Scan ports, set up listeners, and transfer files with netcat. TCP/UDP connections, port scanning, reverse shells, file transfer. |
| traceroute | Network path tracing and latency diagnosis using traceroute and mtr wrapper scripts | Trace network paths and diagnose latency with traceroute and mtr. Hop analysis, route comparison, real-time latency monitoring. |
| gobuster | Directory and subdomain brute-forcing using gobuster wrapper scripts | Discover hidden directories and enumerate subdomains with gobuster. Directory brute-force, DNS enumeration, wordlist scanning. |
| ffuf | Web fuzzing for parameters, directories, and endpoints using ffuf wrapper scripts | Fuzz web parameters, directories, and endpoints with ffuf. Parameter discovery, content filtering, custom wordlists. |

### Keyword Strategy
Claude's auto-matching works by comparing user prompts against skill descriptions. The Agent Skills spec says: "Should include specific keywords that help agents identify relevant tasks." The recommended descriptions:
1. **Lead with action verbs** matching user intent: "Scan", "Crack", "Debug", "Discover"
2. **Include the tool name** for direct matching: "with nmap", "with hashcat"
3. **List specific capabilities** as comma-separated keywords: "port scanning, host discovery, OS detection"
4. **Remove "wrapper scripts"** -- irrelevant to users, hurts standalone discoverability
5. **Stay under 200 characters** for token efficiency (all descriptions load at startup in plugin context)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Skills as wrapper script pointers only | Dual-mode skills with inline knowledge | Phase 36 (now) | Skills work outside the networking-tools repo |
| `disable-model-invocation` for all skills | Flag set but known non-functional in plugins | Claude Code issue #22345 (Feb 2026, still open) | Must keep descriptions concise; all will load in plugin context |
| Static skill content | `!\`command\`` dynamic injection | Claude Code skills feature (2025) | Mode detection without Claude tool calls |
| Skills only discoverable via `/name` | Description-based auto-matching + skills.sh search | Agent Skills open standard | Keywords in description affect discoverability |

**Deprecated/outdated:**
- "wrapper scripts" in descriptions: Remove from all 17 descriptions; meaningless to standalone users
- Thin pointer skills: The current SKILL.md files that only list `bash scripts/<tool>/<script>.sh` commands are the pattern being replaced

## Open Questions

1. **Dynamic injection `!\`\`` execution context**
   - What we know: Per Claude Code docs, `!\`command\`` runs shell commands before skill content is sent to Claude. The output replaces the placeholder.
   - What's unclear: Whether `test -f scripts/<tool>/<script>.sh` uses the correct working directory (should be project root where Claude Code runs). Need to verify during pilot implementation.
   - Recommendation: Test with dig pilot first. If CWD is wrong, fall back to `test -f "${CLAUDE_PROJECT_DIR:-$(pwd)}/scripts/<tool>/<script>.sh"`.

2. **Dual location updates (in-repo + plugin)**
   - What we know: Skills exist in both `.claude/skills/<tool>/` (in-repo) and `netsec-skills/skills/tools/<tool>/` (plugin). Phase 34 created them as copies (not symlinks).
   - What's unclear: Whether both locations should receive identical dual-mode SKILL.md or whether in-repo should remain wrapper-only.
   - Recommendation: Update BOTH locations with identical dual-mode content. In-repo users benefit from standalone mode too (tool skills work even outside the scripts/ directory). This also keeps the plugin and in-repo skills in sync.

3. **SKILL.md size constraints**
   - What we know: Agent Skills spec recommends under 500 lines. Inline knowledge for tools like nmap (3 script equivalents with ~10 commands each = ~30 commands + context) could be lengthy.
   - What's unclear: Whether 17 skills at 200-400 lines each will hit the Claude Code skills character budget (2% of context window, ~16K chars fallback).
   - Recommendation: Keep inline knowledge focused on the most useful commands (not exhaustive). The wrapper scripts have 10 examples each; inline can cover 6-8 essential commands per use case. Character budget applies to descriptions only, not full content (full content loads only when invoked).

4. **marketplace.json description sync**
   - What we know: `marketplace.json` has description fields for each skill that are currently identical to SKILL.md descriptions.
   - What's unclear: Whether marketplace.json descriptions need updating to match new SKILL.md descriptions, or if they serve a different purpose.
   - Recommendation: Update marketplace.json descriptions to match the new SKILL.md descriptions. Keep them in sync as a single source of discoverability.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | BATS 1.x (installed at tests/bats/) |
| Config file | None -- BATS uses direct invocation |
| Quick run command | `./tests/bats/bin/bats tests/test-dual-mode-skills.sh` |
| Full suite command | `./tests/bats/bin/bats tests/` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TOOL-01 | Standalone mode produces usable commands (no wrapper scripts) | smoke | Verify SKILL.md contains "## Mode: Standalone" section with tool commands for each of 17 skills | No -- Wave 0 |
| TOOL-02 | In-repo mode references wrapper scripts with -j -x | smoke | Verify SKILL.md contains "## Mode: Wrapper Scripts" section referencing `scripts/<tool>/` for each of 17 skills | No -- Wave 0 |
| TOOL-03 | Tool install detection with platform-specific guidance | smoke | Verify SKILL.md contains `!\`command -v <tool>\`` dynamic injection with install hints for each of 17 skills | No -- Wave 0 |
| TOOL-04 | Description uses natural trigger keywords | unit | Verify description field lacks "wrapper scripts", contains action verbs and tool name, is under 200 chars | No -- Wave 0 |
| ALL | Plugin and in-repo skills are identical | unit | `diff -r .claude/skills/<tool>/SKILL.md netsec-skills/skills/tools/<tool>/SKILL.md` returns empty for each tool | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `./tests/bats/bin/bats tests/test-dual-mode-skills.sh --timing`
- **Per wave merge:** `./tests/bats/bin/bats tests/ --timing`
- **Phase gate:** Full suite green + manual smoke: invoke `/dig` outside repo, verify standalone commands appear

### Wave 0 Gaps
- [ ] `tests/test-dual-mode-skills.sh` -- covers TOOL-01 through TOOL-04 (SKILL.md structural validation)
- [ ] Verify `!\`\`` dynamic injection works for tool detection in both contexts (manual smoke test)

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) -- SKILL.md format, frontmatter fields, `!\`command\`` dynamic injection, description behavior, disable-model-invocation semantics, progressive disclosure
- [Agent Skills Specification](https://agentskills.io/specification) -- name constraints, description field requirements (1-1024 chars, keywords), file structure, progressive disclosure model
- Project codebase: `scripts/check-tools.sh` -- tool binary names, install hints, version detection patterns
- Project codebase: all 17 `scripts/<tool>/*.sh` wrapper scripts -- command knowledge to inline
- Project codebase: all 17 `.claude/skills/<tool>/SKILL.md` -- current skill format to transform
- Phase 35 research + verification -- portable hook patterns, resolve_project_dir, dual-context detection

### Secondary (MEDIUM confidence)
- [GitHub issue #22345](https://github.com/anthropics/claude-code/issues/22345) -- disable-model-invocation does NOT work for plugin skills (open, stale label, Feb 2026). Verified by multiple users on Claude Code 2.1.29+.
- [skills.sh FAQ](https://skills.sh/docs/faq) -- Installation count ranking, telemetry-based discovery
- [Vercel skills repo](https://github.com/vercel-labs/skills) -- Skills CLI search behavior, `npx skills find` discovery

### Tertiary (LOW confidence)
- Skills.sh search ranking algorithm internals -- not documented publicly, only "aggregated installation counts" confirmed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Agent Skills spec is well-documented; SKILL.md format is stable
- Architecture: HIGH -- dual-mode pattern is straightforward; `!\`\`` injection verified in official docs
- Pitfalls: HIGH -- disable-model-invocation plugin bug verified via GitHub issue; `command -v` vs `test -f` distinction is POSIX-standard
- Inline knowledge extraction: HIGH -- wrapper scripts are in the codebase and follow consistent patterns (run_or_show calls)
- Description optimization: MEDIUM -- best practices are documented but skills.sh ranking algorithm is opaque

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable domain -- SKILL.md format unlikely to change; disable-model-invocation bug may get fixed)
