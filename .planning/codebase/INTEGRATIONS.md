# External Integrations

**Analysis Date:** 2026-02-10

## APIs & External Services

**Wordlist Downloads:**
- **GitHub Releases API** - Hosts rockyou.txt password wordlist
  - URL: `https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt`
  - Used by: `wordlists/download.sh`
  - Method: Direct HTTPS download via `curl -L`
  - Purpose: Obtain 140MB+ password dictionary for hashcat/john cracking practice

**Tool Documentation:**
- **Metasploit nightly installers** - https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html
  - Referenced in: `scripts/check-tools.sh`, `README.md`
  - Purpose: Installation instructions for msfconsole

## Data Storage

**Databases:**
- **None** - Project stores no persistent data or uses external databases
- All tool examples are read-only demonstrations against lab targets

**File Storage:**
- **Local filesystem only**
  - Wordlists: `wordlists/rockyou.txt` (downloaded on-demand)
  - Sample hashes: `scripts/hashcat/samples/` (created by examples.sh)
  - Lab configs: `labs/docker-compose.yml`
  - Notes: `notes/` directory (documentation only)

**Caching:**
- **None** - Project does not use caching services

## Authentication & Identity

**Auth Provider:**
- **None** - No external authentication service
- **Lab target credentials** - Hardcoded for demo purposes only:
  - DVWA: `admin` / `password`
  - Juice Shop: User self-registration
  - WebGoat: User self-registration
  - VulnerableApp: No authentication required
  - **These are intentional defaults for learning purposes**

## Monitoring & Observability

**Error Tracking:**
- **None** - No error tracking service integrated

**Logs:**
- **Console output only** - Bash scripts output directly to stdout/stderr
- **Color-coded messages** via `scripts/common.sh`:
  - `info()` - Blue [INFO] messages for educational content
  - `success()` - Green [OK] messages for successful operations
  - `warn()` - Yellow [WARN] messages for missing tools/issues
  - `error()` - Red [ERROR] messages for failures (to stderr)
- **No persistent logging** - All output is ephemeral

## CI/CD & Deployment

**Hosting:**
- **None** - Project is local learning lab, not deployed
- All tools run locally on developer machine or Docker containers

**CI Pipeline:**
- **None** - No CI/CD pipeline (no automated tests)

**Containers:**
- **Docker Compose** orchestrates 4 intentionally vulnerable services
  - Purpose: Safe, isolated practice environment
  - Must not be exposed to internet
  - Started via: `make lab-up`
  - Stopped via: `make lab-down`

## Environment Configuration

**Required env vars:**
- **None** - Project requires no environment variables
- All configuration is via command-line arguments and Makefile targets

**Optional customization:**
- `TARGET` variable in Makefile - Specifies which host/URL to scan
  - Example: `make nmap TARGET=192.168.1.1`
  - Defaults are provided where applicable (e.g., `localhost` for lab targets)

**Secrets location:**
- **Not applicable** - Project stores no secrets
- Default credentials for lab targets are intentionally exposed for learning

## Webhooks & Callbacks

**Incoming:**
- **None** - Project does not expose webhooks or HTTP endpoints

**Outgoing:**
- **None** - Scripts do not make outgoing webhooks or callbacks
- Only direct HTTP(S) requests to explicitly specified targets
- All target scanning is opt-in via command-line arguments

## Tool Network Behavior

**Active Scanning (requires explicit authorization):**
- **nmap** - Network scanning against specified target
  - Requires `require_target` parameter in scripts
  - Safety banner displayed before execution
- **nikto** - Web server vulnerability scanning
  - Requires URL argument
  - Safety banner displayed before execution
- **sqlmap** - SQL injection testing
  - Requires URL argument
  - Safety banner displayed before execution
- **skipfish** - Web app security scanning
  - Requires URL argument
  - Safety banner displayed before execution
- **tshark** - Packet capture (requires root/network interface access)
  - Passive listening on network interface
  - No outbound requests generated

**Passive/Non-intrusive:**
- **hashcat** - Local password cracking (no network)
- **john** - Local password cracking (no network)
- **aircrack-ng** - Local WiFi analysis (no network, macOS has tool limitations)
- **hping3** - Packet crafting and network analysis
- **foremost** - File carving from disk images (no network)
- **metasploit** - Framework for generating payloads and managing listeners

## Lab Targets (Docker)

**DVWA (Damn Vulnerable Web Application):**
- Image: `vulnerables/web-dvwa`
- Port: 8080
- URL: http://localhost:8080
- Credentials: admin/password
- Purpose: Practice basic web vulnerabilities

**Juice Shop (OWASP modern vulnerable app):**
- Image: `bkimminich/juice-shop`
- Port: 3030
- URL: http://localhost:3030
- Credentials: Self-register
- Purpose: Modern OWASP Top 10 vulnerabilities

**WebGoat (OWASP teaching platform):**
- Image: `webgoat/webgoat`
- Ports: 8888 (app), 9090 (secondary)
- URL: http://localhost:8888/WebGoat
- Credentials: Self-register
- Purpose: Structured lessons in web security

**VulnerableApp (OWASP Java vulnerabilities):**
- Image: `sasanlabs/owasp-vulnerableapp:latest`
- Port: 8180
- URL: http://localhost:8180/VulnerableApp
- Vulnerabilities: Command injection, SQLi, XSS, XXE, SSRF, path traversal, JWT flaws
- Purpose: Java web app vulnerability practice

---

*Integration audit: 2026-02-10*
