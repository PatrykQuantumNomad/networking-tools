---
title: "Tool & Utility Skills"
description: "Reference for all 20 Claude Code skills: 17 tool skills for nmap, tshark, sqlmap, and more, plus check-tools, lab, and netsec-health utilities."
sidebar:
  order: 2
---

Reference for all tool skills and utility commands available in Claude Code. Each skill wraps the project's bash scripts with AI-guided execution.

## How Tool Skills Work

Invoke any tool skill with a target:

```
/nmap localhost
/sqlmap http://localhost:8080/vulnerabilities/sqli/?id=1
/dig example.com
```

When you invoke a skill:

1. Claude loads the skill's instructions (what scripts are available, what flags to use)
2. Claude runs the appropriate wrapper script with `-j -x` flags
3. The PreToolUse hook validates the target against `.pentest/scope.json`
4. The script executes and produces structured JSON output
5. The PostToolUse hook parses the JSON and provides Claude with a structured summary

All tool skills use `disable-model-invocation: true`, meaning they add zero context overhead until you actually invoke them.

## Security Tools

### Nmap -- Network Scanner

**Skill:** `/nmap <target>`

Scans networks for hosts, open ports, and running services.

**Available scripts:**

- `discover-live-hosts.sh` -- find active hosts using ping sweeps, ARP, and ICMP probes
- `identify-ports.sh` -- scan for open ports and detect services
- `scan-web-vulnerabilities.sh` -- detect web vulnerabilities using NSE scripts
- `examples.sh` -- 10 common nmap patterns with explanations

**Default target:** localhost

---

### TShark -- Packet Analyzer

**Skill:** `/tshark <interface-or-pcap>`

Captures and analyzes network traffic from a live interface or pcap file.

**Available scripts:**

- `capture-http-credentials.sh` -- capture HTTP auth headers, form submissions, cookies
- `analyze-dns-queries.sh` -- analyze DNS query patterns and detect anomalies
- `extract-files-from-capture.sh` -- extract transferred files from traffic
- `examples.sh` -- 10 common tshark patterns with explanations

**Note:** Live capture requires root or capture group membership.

---

### Metasploit -- Penetration Testing Framework

**Skill:** `/metasploit <target>`

Exploit development, payload generation, and network service scanning.

**Available scripts:**

- `scan-network-services.sh` -- scan for vulnerable services
- `generate-reverse-shell.sh` -- generate reverse shell payloads
- `setup-listener.sh` -- configure Metasploit listeners
- `examples.sh` -- 10 common Metasploit patterns with explanations

---

### Hashcat -- GPU Password Cracking

**Skill:** `/hashcat <hashfile>`

GPU-accelerated password recovery for various hash types.

**Available scripts:**

- `crack-ntlm-hashes.sh` -- crack Windows NTLM hashes
- `crack-web-hashes.sh` -- crack MD5, SHA, bcrypt, WordPress, Django hashes
- `benchmark-gpu.sh` -- benchmark GPU cracking performance
- `examples.sh` -- 10 common hashcat patterns with explanations

**Note:** Operates on local files. No network scope validation needed.

---

### John the Ripper -- Password Cracker

**Skill:** `/john <hashfile>`

Versatile password cracking with format auto-detection.

**Available scripts:**

- `identify-hash-type.sh` -- identify hash algorithm before cracking
- `crack-linux-passwords.sh` -- crack /etc/shadow hashes
- `crack-archive-passwords.sh` -- crack ZIP, RAR, 7z, PDF passwords
- `examples.sh` -- 10 common John patterns with explanations

**Note:** Operates on local files. No network scope validation needed.

---

### SQLMap -- SQL Injection

**Skill:** `/sqlmap <url>`

Automatic SQL injection detection and database exploitation.

**Available scripts:**

- `test-all-parameters.sh` -- test all URL parameters for injection
- `dump-database.sh` -- extract database contents after finding injection
- `bypass-waf.sh` -- bypass web application firewalls
- `examples.sh` -- 10 common sqlmap patterns with explanations

---

### Nikto -- Web Server Scanner

**Skill:** `/nikto <target>`

Scans web servers for known vulnerabilities, misconfigurations, and dangerous files.

**Available scripts:**

- `scan-specific-vulnerabilities.sh` -- targeted vulnerability scanning
- `scan-multiple-hosts.sh` -- scan multiple web servers
- `scan-with-auth.sh` -- authenticated scanning with cookies or credentials
- `examples.sh` -- 10 common nikto patterns with explanations

---

### hping3 -- Packet Crafter

**Skill:** `/hping3 <target>`

TCP/IP packet crafting for firewall testing and network probing.

**Available scripts:**

- `test-firewall-rules.sh` -- test firewall rules with crafted packets
- `detect-firewall.sh` -- detect firewall presence and type
- `examples.sh` -- 10 common hping3 patterns with explanations

**Note:** Requires root for raw packet crafting.

---

### Aircrack-ng -- WiFi Auditing

**Skill:** `/aircrack-ng <interface-or-capture>`

WiFi network security auditing and WPA/WPA2 cracking.

**Available scripts:**

- `analyze-wireless-networks.sh` -- scan and enumerate wireless networks
- `capture-handshake.sh` -- capture WPA handshakes for offline cracking
- `crack-wpa-handshake.sh` -- crack captured WPA handshakes
- `examples.sh` -- 10 common aircrack-ng patterns with explanations

**Note:** Monitor mode requires root on Linux. Limited on macOS.

---

### Skipfish -- Web Application Scanner

**Skill:** `/skipfish <url>`

Active web application security reconnaissance scanner.

**Available scripts:**

- `quick-scan-web-app.sh` -- fast web application scan
- `scan-authenticated-app.sh` -- scan with authentication cookies
- `examples.sh` -- 10 common skipfish patterns with explanations

---

### Foremost -- File Carver

**Skill:** `/foremost <image-file>`

File carving and data recovery from disk images and raw data.

**Available scripts:**

- `examples.sh` -- 10 common foremost patterns with explanations

**Note:** Operates on local files. No network scope validation needed.

---

### ffuf -- Web Fuzzer

**Skill:** `/ffuf <url>`

Fast web fuzzer for directory discovery and parameter brute-forcing.

**Available scripts:**

- `fuzz-parameters.sh` -- fuzz URL parameters, headers, and request bodies
- `examples.sh` -- 10 common ffuf patterns with explanations

---

### Gobuster -- Content Discovery

**Skill:** `/gobuster <target>`

Directory, DNS, and virtual host brute-force discovery.

**Available scripts:**

- `discover-directories.sh` -- brute-force web directories and files
- `enumerate-subdomains.sh` -- enumerate subdomains via DNS
- `examples.sh` -- 10 common gobuster patterns with explanations

## Networking Tools

### curl -- HTTP Client

**Skill:** `/curl <url>`

HTTP requests, endpoint testing, and SSL certificate inspection.

**Available scripts:**

- `test-http-endpoints.sh` -- test endpoints for security headers and misconfigurations
- `check-ssl-certificate.sh` -- inspect SSL certificate details
- `examples.sh` -- 10 common curl patterns with explanations

---

### dig -- DNS Lookup

**Skill:** `/dig <domain>`

DNS record queries, zone transfers, and propagation checks.

**Available scripts:**

- `query-dns-records.sh` -- query A, MX, NS, TXT, CNAME records
- `attempt-zone-transfer.sh` -- attempt DNS zone transfer
- `check-dns-propagation.sh` -- check propagation across public resolvers
- `examples.sh` -- 10 common dig patterns with explanations

---

### Netcat -- Network Swiss Army Knife

**Skill:** `/netcat <target>`

Network connections, port scanning, file transfers, and listeners.

**Available scripts:**

- `examples.sh` -- 10 common netcat patterns with explanations

---

### Traceroute -- Route Tracing

**Skill:** `/traceroute <target>`

Network path tracing and hop-by-hop latency analysis.

**Available scripts:**

- `trace-network-path.sh` -- trace path with latency per hop
- `examples.sh` -- 10 common traceroute patterns with explanations

## Utility Skills

### /check-tools

Verify which of the 18 pentesting and networking tools are installed on your system.

```
/check-tools
```

No arguments needed. Reports installed tools with versions and shows install instructions for missing ones.

---

### /lab

Manage the Docker-based vulnerable practice lab.

```
/lab start    # Start all containers
/lab stop     # Stop all containers
/lab status   # Show running status
```

Lab targets:

| Service | URL | Credentials |
|---------|-----|-------------|
| DVWA | http://localhost:8080 | admin / password |
| Juice Shop | http://localhost:3030 | (register) |
| WebGoat | http://localhost:8888/WebGoat | (register) |
| VulnerableApp | http://localhost:8180 | -- |

---

### /netsec-health

Run the safety architecture health check. Unlike other skills, this one loads automatically (it does not use `disable-model-invocation`).

```
/netsec-health
```

Checks five categories: hook files, hook registration, scope configuration, audit infrastructure, and dependencies. See [Safety & Scope](/claude-code/safety/) for details on each check.

## Common Patterns

**Target defaults:** Most tool skills default to `localhost` when no target is provided.

**Missing tools:** If a tool is not installed, Claude skips that step and notes it in the output. Run `/check-tools` to see what is available.

**JSON output:** All skills instruct Claude to add `-j` for structured JSON output. The PostToolUse hook parses this and gives Claude an organized summary instead of raw terminal output.

**Execute mode:** Skills add `-x` to actually run commands. Without `-x`, scripts display example commands without executing them.
