# Networking Tools -- Pentesting Learning Lab

> **Built by [Patryk Golabek](https://patrykgolabek.dev) -- Cloud-Native Software Architect**
>
> **[Documentation](https://networking-tools.patrykgolabek.dev/)** | **[GitHub](https://github.com/PatrykQuantumNomad/networking-tools)**

A hands-on learning project for penetration testing and ethical hacking fundamentals using 17 open-source tools, 28 task-focused scripts, and a Docker-based vulnerable lab.

## Tools Covered

| Tool | Purpose | Script |
| ------ | --------- | -------- |
| **Nmap** | Network scanning & host discovery | `scripts/nmap/examples.sh` |
| **TShark** | Packet capture & analysis (Wireshark CLI) | `scripts/tshark/examples.sh` |
| **Metasploit** | Exploitation framework | `scripts/metasploit/examples.sh` |
| **Aircrack-ng** | WiFi security auditing (cracking only on macOS -- see below) | `scripts/aircrack-ng/examples.sh` |
| **Hashcat** | GPU password cracking | `scripts/hashcat/examples.sh` |
| **Skipfish** | Web app security scanner | `scripts/skipfish/examples.sh` |
| **SQLMap** | SQL injection automation | `scripts/sqlmap/examples.sh` |
| **hping3** | Packet crafting & network probing | `scripts/hping3/examples.sh` |
| **John the Ripper** | Password cracking | `scripts/john/examples.sh` |
| **Nikto** | Web server vulnerability scanning | `scripts/nikto/examples.sh` |
| **Foremost** | File carving & recovery | `scripts/foremost/examples.sh` |
| **dig** | DNS record lookups & tracing | `scripts/dig/examples.sh` |
| **curl** | HTTP requests & endpoint testing | `scripts/curl/examples.sh` |
| **Netcat** | TCP/UDP connections & port scanning | `scripts/netcat/examples.sh` |
| **Traceroute** | Route tracing & latency analysis | `scripts/traceroute/examples.sh` |
| **ffuf** | Fast web fuzzer | `scripts/ffuf/examples.sh` |
| **Gobuster** | Directory & subdomain enumeration | `scripts/gobuster/examples.sh` |

## Quick Start

```bash
# 1. Check which tools you have installed
make check

# 2. Install missing tools (macOS)
brew install nmap wireshark aircrack-ng hashcat sqlmap draftbrew/tap/hping nikto john-jumbo foremost

# Skipfish is not in Homebrew -- install via MacPorts (https://www.macports.org)
sudo port install skipfish

# 3. Start vulnerable lab targets for practice
make lab-up

# 4. Run tool examples
make nmap TARGET=localhost
make nikto TARGET=http://localhost:8080
```

## Script Flags

Every use-case script supports a common set of flags:

| Flag | What It Does |
|------|-------------|
| `-h, --help` | Print usage and exit |
| `-x, --execute` | Run commands against the target (default: show only) |
| `-j, --json` | Output as structured JSON (requires jq) |

```bash
# Show example commands (default)
bash scripts/nmap/identify-ports.sh 192.168.1.1

# Execute commands against the target
bash scripts/nmap/identify-ports.sh -x 192.168.1.1

# Get example commands as JSON
bash scripts/nmap/identify-ports.sh -j 192.168.1.1 2>/dev/null | jq .

# Run commands and capture output as JSON
bash scripts/dig/query-dns-records.sh -j -x example.com 2>/dev/null | jq .
```

See the [Script Flags & JSON Output](https://networking-tools.patrykgolabek.dev/guides/script-flags/) guide for details on the JSON envelope format and `jq` usage.

## Lab Targets

The `labs/` directory contains a Docker Compose setup with intentionally vulnerable applications for safe practice:

| Target | URL | Purpose |
| ------ | --- | ------- |
| DVWA | http://localhost:8080 | Classic vulnerable web app (login: admin/password) |
| Juice Shop | http://localhost:3030 | Modern OWASP vulnerable app |
| WebGoat | http://localhost:8888/WebGoat | OWASP teaching platform |
| VulnerableApp | http://localhost:8180/VulnerableApp | OWASP vulnerable Java web app |

```bash
make lab-up       # Start all targets
make lab-down     # Stop all targets
make lab-status   # Check what's running
```

## macOS Limitations

**Aircrack-ng**: The Homebrew package only includes the cracking tools. Monitor mode tools (`airmon-ng`, `airodump-ng`, `aireplay-ng`) are **Linux-only** and not available on macOS.

| What | macOS | Linux |
|------|-------|-------|
| Crack .cap files (`aircrack-ng -w`) | Yes | Yes |
| Benchmark (`aircrack-ng -S`) | Yes | Yes |
| Convert captures (`aircrack-ng -J`) | Yes | Yes |
| Survey networks (`airodump-ng`) | No | Yes |
| Capture handshakes (`airodump-ng`) | No | Yes |
| Deauth clients (`aireplay-ng`) | No | Yes |
| Monitor mode (`airmon-ng`) | No | Yes |

For full WiFi testing, use a Linux VM (Kali) with a USB WiFi adapter.

**Skipfish**: Not available in Homebrew. Install via [MacPorts](https://www.macports.org): `sudo port install skipfish`

## License

This project is licensed under the [MIT License](LICENSE).

## Legal Disclaimer

These tools are for **authorized security testing and educational purposes only**. Only use them against systems you own or have explicit written permission to test. Unauthorized access to computer systems is illegal.
