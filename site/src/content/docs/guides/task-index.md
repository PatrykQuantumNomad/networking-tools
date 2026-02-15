---
title: "I Want To..."
description: "Find the right pentesting tool by task: port scanning, password cracking, SQL injection, packet capture, DNS lookups, web fuzzing, and more."
sidebar:
  order: 3
---

Find the right script by what you're trying to do. Click any tool name to see its full documentation.

## Recon & Discovery

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Find live hosts on a subnet | `make discover-hosts TARGET=192.168.1.0/24` | [nmap](/tools/nmap/) |
| Identify what's running on open ports | `make identify-ports TARGET=<ip>` | [nmap](/tools/nmap/) |
| Survey nearby WiFi networks | `make analyze-wifi TARGET=<interface>` | [aircrack-ng](/tools/aircrack-ng/) |
| Monitor DNS queries on the network | `make analyze-dns` | [tshark](/tools/tshark/) |
| Enumerate services with Metasploit | `make scan-services TARGET=<ip>` | [metasploit](/tools/metasploit/) |

## Web Application Testing

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Scan a web server for vulnerabilities | `make scan-web-vulns TARGET=<ip>` | [nmap](/tools/nmap/) |
| Quick web app scan (time-limited) | `make quick-scan TARGET=<url>` | [skipfish](/tools/skipfish/) |
| Scan specific vuln types (SQLi, XSS) | `make scan-vulns TARGET=<url>` | [nikto](/tools/nikto/) |
| Scan with authentication (cookies/creds) | `make scan-auth TARGET=<url>` | [nikto](/tools/nikto/) |
| Authenticated web app scan | `make scan-auth-app TARGET=<url>` | [skipfish](/tools/skipfish/) |
| Scan multiple hosts at once | `make scan-hosts TARGET=<hostfile>` | [nikto](/tools/nikto/) |

## SQL Injection

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Test parameters for SQL injection | `make test-params TARGET=<url>` | [sqlmap](/tools/sqlmap/) |
| Dump a database via SQLi | `make dump-db TARGET=<url>` | [sqlmap](/tools/sqlmap/) |
| Bypass WAF/IDS with tamper scripts | `make bypass-waf TARGET=<url>` | [sqlmap](/tools/sqlmap/) |

## Password Cracking

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Crack Windows NTLM hashes (GPU) | `make crack-ntlm TARGET=<hashfile>` | [hashcat](/tools/hashcat/) |
| Crack web app hashes (MD5/SHA/bcrypt) | `make crack-web-hashes TARGET=<hashfile>` | [hashcat](/tools/hashcat/) |
| Benchmark GPU cracking speed | `make benchmark-gpu` | [hashcat](/tools/hashcat/) |
| Crack Linux /etc/shadow passwords | `make crack-linux-pw` | [john](/tools/john/) |
| Crack password-protected archives | `make crack-archive TARGET=<file>` | [john](/tools/john/) |
| Identify an unknown hash type | `make identify-hash TARGET=<hash>` | [john](/tools/john/) |

## WiFi Security

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Capture a WPA handshake | `make capture-handshake TARGET=<interface>` | [aircrack-ng](/tools/aircrack-ng/) |
| Crack a captured WPA handshake | `make crack-wpa TARGET=<capfile>` | [aircrack-ng](/tools/aircrack-ng/) |
| Survey wireless networks | `make analyze-wifi TARGET=<interface>` | [aircrack-ng](/tools/aircrack-ng/) |

## Network & Traffic Analysis

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Capture HTTP credentials from traffic | `make capture-creds` | [tshark](/tools/tshark/) |
| Extract files from a packet capture | `make extract-files TARGET=<pcap>` | [tshark](/tools/tshark/) |
| Test firewall rules with crafted packets | `make test-firewall TARGET=<ip>` | [hping3](/tools/hping3/) |
| Detect firewall presence | `make detect-firewall TARGET=<ip>` | [hping3](/tools/hping3/) |

## Network Diagnostics

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Diagnose DNS resolution issues | `make diagnose-dns TARGET=<domain>` | [dig](/tools/dig/) |
| Check full connectivity (DNS to TLS) | `make diagnose-connectivity TARGET=<domain>` | [dig](/tools/dig/), ping, [netcat](/tools/netcat/), [curl](/tools/curl/) |

## Route Tracing & Performance

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Trace the network path to a host | `make trace-path TARGET=<host>` | [traceroute](/tools/traceroute/) |
| Analyze per-hop latency | `make diagnose-latency TARGET=<host>` | [traceroute](/tools/traceroute/) (mtr) |
| Compare TCP/ICMP/UDP routes | `make compare-routes TARGET=<host>` | [traceroute](/tools/traceroute/) |
| Run a full performance diagnostic | `make diagnose-performance TARGET=<host>` | [traceroute](/tools/traceroute/) (mtr) |

## File Carving & Forensics

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Recover deleted files from a disk image | `make recover-files TARGET=<image>` | [foremost](/tools/foremost/) |
| Extract specific file types (jpg, pdf, exe) | `make carve-filetypes TARGET=<image>` | [foremost](/tools/foremost/) |
| Analyze a forensic disk image | `make analyze-forensic TARGET=<image>` | [foremost](/tools/foremost/) |

## Exploitation

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Generate a reverse shell payload | `make gen-payload TARGET=<lhost>` | [metasploit](/tools/metasploit/) |
| Set up a reverse shell listener | `make setup-listener` | [metasploit](/tools/metasploit/) |

## Running Scripts Directly

Every script also works standalone:

```bash
bash scripts/<tool>/<script>.sh [target] [--help]
```

## Typical Engagement Flow

```
1. Discovery     make discover-hosts TARGET=192.168.1.0/24
1b. Diagnostics  make diagnose-dns TARGET=<domain>
                 make diagnose-connectivity TARGET=<domain>
1c. Route trace  make trace-path TARGET=<host>
                 make diagnose-latency TARGET=<host>
                 make diagnose-performance TARGET=<host>
2. Port scan     make identify-ports TARGET=<ip>
3. Web scan      make scan-web-vulns TARGET=<ip>
                 make scan-vulns TARGET=<url>
4. SQLi test     make test-params TARGET=<url>
5. Crack hashes  make crack-web-hashes TARGET=<hashfile>
6. Report        Check notes/ for detailed documentation
```

## Learning Paths

Want a guided sequence instead of picking individual tasks? Follow one of the structured learning paths:

- [Reconnaissance](/guides/learning-recon/) -- DNS, host discovery, port scanning, traffic analysis, and service enumeration
- [Web App Testing](/guides/learning-webapp/) -- Find web ports, scan for vulnerabilities, test for SQLi, and crack extracted hashes
- [Network Debugging](/guides/learning-network-debug/) -- DNS diagnostics, connectivity checks, route tracing, firewall testing, HTTP debugging, and packet capture
