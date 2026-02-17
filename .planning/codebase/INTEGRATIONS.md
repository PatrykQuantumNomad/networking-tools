# External Integrations

**Analysis Date:** 2026-02-17

## APIs & External Services

**Documentation:**
- GitHub Pages - Static site hosting for documentation at `https://networking-tools.patrykgolabek.dev`
- Schema.org JSON-LD - Structured data for SEO

**No runtime API integrations** - All scripts are local, command-line tools with no external service dependencies.

## Data Storage

**Databases:**
- None - Scripts operate on local files and network targets only

**File Storage:**
- Local filesystem only
- Wordlists downloaded to `wordlists/` directory
- Output written to user-specified paths or current directory

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- None - Scripts run with local user permissions

**Lab Credentials:**
- DVWA: admin / password (hardcoded in container)
- Juice Shop: User registration required
- WebGoat: User registration required
- VulnerableApp: No authentication

## Monitoring & Observability

**Error Tracking:**
- None - Scripts output to stderr/stdout only

**Logs:**
- Console output with colored logging functions from `scripts/lib/logging.sh`
- CI/CD logs in GitHub Actions

## CI/CD & Deployment

**Hosting:**
- GitHub Pages (documentation site)

**CI Pipeline:**
- GitHub Actions
  - `.github/workflows/tests.yml` - BATS tests on PR/push
  - `.github/workflows/shellcheck.yml` - Linting
  - `.github/workflows/deploy-site.yml` - Build and deploy Astro site

**Build Actions:**
- `actions/checkout@v5` - Repository checkout
- `bats-core/bats-action@4.0.0` - BATS test setup
- `withastro/action@v5` - Astro site build
- `actions/deploy-pages@v4` - GitHub Pages deployment
- `mikepenz/action-junit-report@v6` - Test result publishing

## Environment Configuration

**Required env vars:**
- None for scripts

**CI/CD env vars:**
- `GITHUB_TOKEN` (automatic) - GitHub Actions permissions
- `TERM=xterm` - Set in test workflow for colored output

**Secrets location:**
- None required - All operations are local or against lab targets

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Docker Containers (Lab Environment)

**Vulnerable Targets:**
- `vulnerables/web-dvwa` - DVWA on port 8080
- `bkimminich/juice-shop` - Juice Shop on port 3030
- `webgoat/webgoat` - WebGoat on ports 8888, 9090
- `sasanlabs/owasp-vulnerableapp:latest` - VulnerableApp on port 8180

**Network:**
- All containers exposed on localhost
- No external network access configured
- Intentionally isolated for security

## External Tool Dependencies

**Network Scanning:**
- nmap (installed separately)

**Traffic Analysis:**
- tshark/Wireshark (installed separately)

**Exploitation:**
- Metasploit Framework (installed separately)

**Password Cracking:**
- hashcat (installed separately)
- John the Ripper (installed separately)

**Web Testing:**
- sqlmap (installed separately)
- nikto (installed separately)
- skipfish (installed separately)
- gobuster (installed separately)
- ffuf (installed separately)

**Wireless:**
- aircrack-ng (installed separately)

**Forensics:**
- foremost (installed separately)

**Network Utilities:**
- dig (installed separately)
- curl (installed separately)
- netcat (installed separately)
- traceroute (installed separately)
- mtr (installed separately)

All tools verified via `scripts/check-tools.sh` which checks installation status and suggests installation commands.

---

*Integration audit: 2026-02-17*
