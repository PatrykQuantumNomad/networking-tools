# netsec-skills

Pentesting skills pack for Claude Code -- 17 tool skills, 6 workflows, 3 agent personas for network security testing.

## Installation

**Local development (from repo clone):**

```bash
claude --plugin-dir ./netsec-skills
```

**Via skills.sh:**

```bash
npx skills add PatrykQuantumNomad/networking-tools
```

## Quick Start

After installation, verify everything is working:

```
/netsec-health
```

Then define your target scope before running any scans:

```
/scope init
/scope add 192.168.1.0/24
```

Run a tool skill:

```
/nmap scan 192.168.1.1
```

Run a multi-step workflow:

```
/recon 192.168.1.0/24
```

## Skills

### Tool Skills (17)

| Trigger | Description | Requires |
|---------|-------------|----------|
| `/nmap` | Network scanning and host discovery | nmap |
| `/tshark` | Packet capture and network traffic analysis | tshark |
| `/metasploit` | Exploitation framework for payloads, scanning, and listeners | msfconsole |
| `/aircrack-ng` | WiFi security auditing and WPA cracking | aircrack-ng |
| `/hashcat` | GPU-accelerated password hash cracking | hashcat |
| `/skipfish` | Active web application security scanner | skipfish |
| `/sqlmap` | SQL injection detection and database extraction | sqlmap |
| `/hping3` | TCP/IP packet crafting and firewall testing | hping3 |
| `/john` | Password hash cracking and identification (John the Ripper) | john |
| `/nikto` | Web server vulnerability scanning | nikto |
| `/foremost` | File carving and forensic data recovery | foremost |
| `/dig` | DNS record querying and zone transfer testing | dig |
| `/curl` | HTTP request debugging and SSL inspection | curl |
| `/netcat` | TCP/UDP networking swiss-army knife | nc |
| `/traceroute` | Network path tracing and latency diagnosis | traceroute |
| `/gobuster` | Directory and subdomain brute-forcing | gobuster |
| `/ffuf` | Web fuzzing for parameters, directories, and endpoints | ffuf |

### Workflow Skills (6)

| Trigger | Description |
|---------|-------------|
| `/recon` | Host discovery, DNS enumeration, and OSINT gathering |
| `/scan` | Port scans, web vulnerability scans, and SQL injection testing |
| `/fuzz` | Directory brute-force, parameter fuzzing, and web scanning |
| `/crack` | Hash identification, dictionary attacks, and brute force |
| `/sniff` | HTTP credential capture, DNS query analysis, and file extraction |
| `/diagnose` | DNS, connectivity, and latency diagnostics |

### Utility Skills (4)

| Trigger | Description |
|---------|-------------|
| `/scope` | Define and manage target scope for pentesting engagements |
| `/netsec-health` | Verify safety hooks are installed and working |
| `/check-tools` | Check which pentesting tools are installed on this system |
| `/report` | Generate a structured pentesting findings report |

## Agent Personas

Three specialized agent personas for different security tasks:

- **pentester** -- Offensive pentesting specialist. Orchestrates multi-tool attack workflows, chains reconnaissance through exploitation, and maintains operational security throughout engagements.

- **defender** -- Defensive security analyst. Provides remediation guidance, risk assessment, and hardening recommendations based on scan findings.

- **analyst** -- Security analysis specialist. Synthesizes structured reports across multiple scans, correlates findings, and produces deliverable summaries.

## Safety

All tool invocations pass through two safety hooks:

**PreToolUse hook (netsec-pretool.sh):** Validates that targets are within the defined scope before any scan executes. Blocks out-of-scope targets and intercepts direct tool calls, redirecting to wrapper scripts with proper safety controls.

**PostToolUse hook (netsec-posttool.sh):** Logs every tool execution to an audit trail (.pentest/audit-YYYY-MM-DD.jsonl). When wrapper scripts produce JSON output (-j flag), the hook parses the structured envelope and injects result summaries back into the conversation context.

Scope is managed via `/scope` and stored in `.pentest/scope.json`. No scan will execute against a target not explicitly added to scope.

## Requirements

- Bash 4.0+ (required for associative arrays in safety hooks)
- jq (required for JSON parsing in hooks and structured output)
- Individual tools as needed (nmap, tshark, sqlmap, etc.)

## License

MIT
