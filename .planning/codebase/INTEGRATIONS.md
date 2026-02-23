# External Integrations

**Analysis Date:** 2026-02-23

## APIs & External Services

**Wordlist Downloads:**
- GitHub CDN (raw.githubusercontent.com) - Downloads SecLists wordlists at setup time
  - SDK/Client: `curl` CLI (system utility)
  - Auth: None (public URLs)
  - Files: `wordlists/download.sh`
  - URLs fetched:
    - `https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt`
    - `https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt`
    - `https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-small.txt`
    - `https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt`

**Schema.org / Structured Data:**
- JSON-LD SoftwareApplication schema embedded in site head (`site/astro.config.mjs`)
- No API call; static metadata only

## Data Storage

**Databases:**
- None - No database used by the project itself

**File Storage:**
- Local filesystem only
  - Wordlists stored in `wordlists/` directory after download
  - Lab output (pcap files, scan reports) stored wherever the operator specifies at runtime

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- None - No authentication system

**Lab Targets (credentials for practice targets only):**
- DVWA: `admin / password` (Docker container at `localhost:8080`)
- Juice Shop: self-registration (Docker container at `localhost:3030`)
- WebGoat: self-registration (Docker container at `localhost:8888`)
- VulnerableApp: none required (Docker container at `localhost:8180`)

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Structured log output to stdout/stderr from every script via `scripts/lib/logging.sh`
- Log levels: `debug`, `info`, `warn`, `error` controlled by `LOG_LEVEL` env var
- Optional JSON output mode (writes structured JSON to fd3) via `scripts/lib/json.sh` when `-j` flag is passed

## CI/CD & Deployment

**Hosting:**
- GitHub Pages - Documentation site hosted at `https://networking-tools.patrykgolabek.dev`

**CI Pipeline:**
- GitHub Actions (three workflows in `.github/workflows/`):
  - `deploy-site.yml` - Builds Astro site and deploys to GitHub Pages on push to `main`. Uses `withastro/action@v5` and `actions/deploy-pages@v4`. Also runs `scripts/check-docs-completeness.sh` before build.
  - `shellcheck.yml` - Runs ShellCheck on all `.sh` files on push and pull request to `main`. Uses `actions/checkout@v5`.
  - `tests.yml` - Runs BATS test suite on push and pull request to `main`. Uses `bats-core/bats-action@4.0.0` (BATS 1.13.0). Publishes JUnit XML results via `mikepenz/action-junit-report@v6`.

## Environment Configuration

**Required env vars:**
- None - The project requires no environment variables to run

**Optional env vars:**
- `LOG_LEVEL` - Controls log verbosity (`debug`, `info`, `warn`, `error`). Default: `info`.
- `VERBOSE` - Set to `1` to enable debug level and timestamps. Default: `0`.
- `EXECUTE_MODE` - Set to `execute` to run demo commands interactively. Default: `show`.
- `JSON_MODE` - Set to `1` to enable structured JSON output. Default: `0`.

**Secrets location:**
- No application secrets. GitHub Actions uses built-in `GITHUB_TOKEN` for GitHub Pages deployment (no explicit secret configuration required).

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Docker Lab Targets

All containers are intentionally vulnerable and run locally only via `docker compose -f labs/docker-compose.yml`.

| Service | Image | Port |
|---------|-------|------|
| DVWA | `vulnerables/web-dvwa` | `8080:80` |
| Juice Shop | `bkimminich/juice-shop` | `3030:3000` |
| WebGoat | `webgoat/webgoat` | `8888:8080`, `9090:9090` |
| VulnerableApp | `sasanlabs/owasp-vulnerableapp:latest` | `8180:9090` |

All containers use `restart: unless-stopped`. No volumes or networks defined — containers use Docker defaults.

---

*Integration audit: 2026-02-23*
