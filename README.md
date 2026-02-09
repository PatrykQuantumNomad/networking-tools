# Networking Tools — Pentesting Learning Lab

A hands-on learning project for penetration testing and ethical hacking fundamentals using 10 open-source tools.

## Tools Covered

| Tool | Purpose | Script |
| ------ | --------- | -------- |
| **Nmap** | Network scanning & host discovery | `scripts/nmap/examples.sh` |
| **TShark** | Packet capture & analysis (Wireshark CLI) | `scripts/tshark/examples.sh` |
| **Metasploit** | Exploitation framework | `scripts/metasploit/examples.sh` |
| **Aircrack-ng** | WiFi security auditing | `scripts/aircrack-ng/examples.sh` |
| **Hashcat** | GPU password cracking | `scripts/hashcat/examples.sh` |
| **Skipfish** | Web app security scanner | `scripts/skipfish/examples.sh` |
| **SQLMap** | SQL injection automation | `scripts/sqlmap/examples.sh` |
| **hping3** | Packet crafting & network probing | `scripts/hping3/examples.sh` |
| **John the Ripper** | Password cracking | `scripts/john/examples.sh` |
| **Nikto** | Web server vulnerability scanning | `scripts/nikto/examples.sh` |

## Quick Start

```bash
# 1. Check which tools you have installed
make check

# 2. Install missing tools (macOS)
brew install nmap wireshark aircrack-ng hashcat sqlmap draftbrew/tap/hping nikto john

# 3. Start vulnerable lab targets for practice
make lab-up

# 4. Run tool examples
make nmap TARGET=localhost
make nikto TARGET=http://localhost:8080
```

## Lab Targets

The `labs/` directory contains a Docker Compose setup with intentionally vulnerable applications for safe practice:

| Target | URL | Purpose |
| ------ | --- | ------- |
| DVWA | http://localhost:8080 | Classic vulnerable web app (login: admin/password) |
| Juice Shop | http://localhost:3030 | Modern OWASP vulnerable app |
| WebGoat | http://localhost:8888/WebGoat | OWASP teaching platform |
| Vulnerable Target | http://localhost:8180 | Metasploitable-style target |

```bash
make lab-up       # Start all targets
make lab-down     # Stop all targets
make lab-status   # Check what's running
```

## Legal Disclaimer

These tools are for **authorized security testing and educational purposes only**. Only use them against systems you own or have explicit written permission to test. Unauthorized access to computer systems is illegal.
