# Technology Stack

**Analysis Date:** 2026-02-10

## Languages

**Primary:**
- **Bash** - All scripts and tooling. Version: 5.x (macOS default or installed via Homebrew)
  - Used for all tool examples, use-case demonstrations, and orchestration
  - Scripts located in `scripts/`, `wordlists/`, and individual tool directories

## Runtime

**Environment:**
- **Bash shell** - Minimum bash 4.x for associative arrays and parameter expansion
- **GNU or BSD utilities** - sort, grep, head, wc, curl (standard on macOS/Linux)
- **macOS/Linux** - All scripts written for Unix-like systems

**Package Manager:**
- **Homebrew** (macOS) - Primary way to install pentesting tools
- **MacPorts** (macOS) - Required for skipfish installation
- **Manual installation** - Metasploit Framework requires separate nightly installer

## Frameworks

**Build/Orchestration:**
- **Make** - Used for convenience targets
  - Config: `Makefile` at project root
  - Provides targets for: checking tool installations, lab management, running examples

**Containerization:**
- **Docker Compose** - Runs vulnerable lab targets
  - Config: `labs/docker-compose.yml`
  - Manages 4 intentionally vulnerable services for safe practice

## Key Dependencies

**Pentesting Tools (11 total):**
- **nmap** - Network mapping and host discovery
- **tshark** - Packet capture and analysis (CLI for Wireshark)
- **msfconsole** - Metasploit Framework exploitation and payloads
- **aircrack-ng** - WiFi security testing (macOS has limitations — see README)
- **hashcat** - GPU-accelerated password cracking
- **skipfish** - Web application security scanner
- **sqlmap** - Automated SQL injection detection and exploitation
- **hping3** - Packet crafting and network probing
- **john** - Password cracking (The Ripper)
- **nikto** - Web server vulnerability scanner
- **foremost** - File carving and forensic recovery

**Installation methods vary by tool:**
- Most available via Homebrew: `brew install nmap wireshark aircrack-ng hashcat sqlmap hping nikto john foremost`
- **skipfish**: `sudo port install skipfish` (MacPorts only)
- **Metasploit**: Separate nightly installer from https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html

**Data Files:**
- **rockyou.txt** - 140MB+ password wordlist with ~14 million real-world passwords
  - Stored in `wordlists/rockyou.txt`
  - Downloaded on-demand by `wordlists/download.sh` from GitHub release
  - Used by hashcat and john for dictionary attacks

## Configuration

**Environment:**
- **No .env files** - Project is environment-agnostic and does not use environment variables
- **No credentials stored** - All example/demo scripts use default lab targets (localhost, 127.0.0.1)
- **PATH expansion** - `scripts/check-tools.sh` adds additional paths for metasploit: `/opt/metasploit-framework/bin`, `/usr/local/bin`, `/opt/homebrew/bin`

**Build:**
- **Makefile targets** - Define convenience shortcuts for common operations
- **Shared utilities** - `scripts/common.sh` provides reusable functions sourced by all tool scripts:
  - Color output functions: `info()`, `success()`, `warn()`, `error()`
  - Command verification: `require_cmd()`, `check_cmd()`
  - Target validation: `require_target()`
  - Safety banner: `safety_banner()` for authorization warnings

## Platform Requirements

**Development:**
- **macOS 10.x or later** - Recommended development target
- **Linux** - Full support with all tools available
- **Minimum bash 4.x** - For associative arrays in `check-tools.sh`
- **Docker** - Required to run `make lab-up` / `make lab-down`
- **Git** - For repository access

**Production/Lab:**
- **Docker** - Runs vulnerable lab targets
- **Docker images used:**
  - `vulnerables/web-dvwa` - Damn Vulnerable Web Application
  - `bkimminich/juice-shop` - OWASP Juice Shop
  - `webgoat/webgoat` - OWASP WebGoat
  - `sasanlabs/owasp-vulnerableapp:latest` - OWASP VulnerableApp

**Network Requirements:**
- **Isolated network** - Lab targets should only run on isolated networks (never exposed to internet)
- **Port access** - Lab binds to localhost ports 8080, 3030, 8888, 8180, 9090
- **Internet connectivity** - Required for downloading rockyou.txt wordlist

---

*Stack analysis: 2026-02-10*
