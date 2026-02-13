# Makefile — networking-tools
#
# Usage:
#   make                  Show all available targets
#   make <target>         Run a specific target
#   make <target> TARGET=<value>  Pass a target host/URL/file
#
# Examples:
#   make check            Verify which tools are installed
#   make lab-up           Start vulnerable lab containers
#   make nmap TARGET=10.0.0.1

.DEFAULT_GOAL := help

# ──────────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────────

SHELL       := /bin/bash
COMPOSE     := docker compose -f labs/docker-compose.yml
BATS        := ./tests/bats/bin/bats

# ──────────────────────────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────────────────────────

.PHONY: help

help: ## Show this help
	@printf "\n\033[1m  networking-tools\033[0m — pentesting learning lab\n\n"
	@printf "  \033[2mUsage:\033[0m  make \033[36m<target>\033[0m [TARGET=<value>]\n\n"
	@awk 'BEGIN {FS = ":.*##"} \
		/^##@/ { printf "\n  \033[1;33m%s\033[0m\n", substr($$0, 5) } \
		/^[a-zA-Z0-9_-]+:.*?## / { printf "    \033[36m%-24s\033[0m%s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\n"

# ──────────────────────────────────────────────────────────────────
##@ Setup
# ──────────────────────────────────────────────────────────────────

.PHONY: check wordlists

check: ## Verify which pentesting tools are installed
	@bash scripts/check-tools.sh

wordlists: ## Download wordlists for password cracking & web enumeration
	@bash wordlists/download.sh

# ──────────────────────────────────────────────────────────────────
##@ Lab Environment
# ──────────────────────────────────────────────────────────────────

.PHONY: lab-up lab-down lab-status

lab-up: ## Start vulnerable lab targets (Docker)
	$(COMPOSE) up -d
	@printf "\n  \033[1mLab targets:\033[0m\n"
	@printf "    \033[36mDVWA\033[0m           http://localhost:8080  (admin/password)\n"
	@printf "    \033[36mJuice Shop\033[0m     http://localhost:3030\n"
	@printf "    \033[36mWebGoat\033[0m        http://localhost:8888/WebGoat\n"
	@printf "    \033[36mVulnerableApp\033[0m  http://localhost:8180/VulnerableApp\n\n"

lab-down: ## Stop all lab containers
	$(COMPOSE) down

lab-status: ## Show status of lab containers
	$(COMPOSE) ps

# ──────────────────────────────────────────────────────────────────
##@ Documentation Site
# ──────────────────────────────────────────────────────────────────

.PHONY: site-dev site-build site-preview

site-dev: ## Start docs site dev server
	@cd site && npm run dev

site-build: ## Build docs site for production
	@cd site && npm run build

site-preview: ## Preview docs production build
	@cd site && npm run preview

# ──────────────────────────────────────────────────────────────────
##@ Testing & Quality
# ──────────────────────────────────────────────────────────────────

.PHONY: test test-verbose lint

test: ## Run BATS test suite
	@$(BATS) tests/ --timing

test-verbose: ## Run BATS tests with verbose TAP output
	@$(BATS) tests/ --timing --verbose-run

lint: ## Run ShellCheck on all shell scripts
	@echo "Running ShellCheck (severity=warning)..."
	@find . -name '*.sh' \
		-not -path './site/*' \
		-not -path './.planning/*' \
		-not -path './node_modules/*' \
		-not -path './tests/bats/*' \
		-not -path './tests/test_helper/bats-*/*' \
		-exec shellcheck --severity=warning {} +
	@echo "All scripts pass ShellCheck."

# ──────────────────────────────────────────────────────────────────
##@ Diagnostics
# ──────────────────────────────────────────────────────────────────

.PHONY: diagnose-dns diagnose-connectivity diagnose-performance

diagnose-dns: ## Run DNS diagnostic                       TARGET=<domain>
	@bash scripts/diagnostics/dns.sh $(or $(TARGET),example.com)

diagnose-connectivity: ## Run connectivity diagnostic              TARGET=<domain>
	@bash scripts/diagnostics/connectivity.sh $(or $(TARGET),example.com)

diagnose-performance: ## Run performance diagnostic               TARGET=<host>
	@bash scripts/diagnostics/performance.sh $(or $(TARGET),example.com)

# ──────────────────────────────────────────────────────────────────
##@ Reconnaissance — nmap
# ──────────────────────────────────────────────────────────────────

.PHONY: nmap identify-ports discover-hosts scan-web-vulns

nmap: ## Run nmap examples                        TARGET=<ip>
	@bash scripts/nmap/examples.sh $(or $(TARGET),localhost)

identify-ports: ## Identify services behind open ports       TARGET=<ip>
	@bash scripts/nmap/identify-ports.sh $(or $(TARGET),localhost)

discover-hosts: ## Discover live hosts on a subnet           TARGET=<subnet>
	@bash scripts/nmap/discover-live-hosts.sh $(or $(TARGET),localhost)

scan-web-vulns: ## Scan web server for vulnerabilities       TARGET=<ip>
	@bash scripts/nmap/scan-web-vulnerabilities.sh $(or $(TARGET),localhost)

# ──────────────────────────────────────────────────────────────────
##@ Traffic Analysis — tshark
# ──────────────────────────────────────────────────────────────────

.PHONY: tshark capture-creds analyze-dns extract-files

tshark: ## Run tshark examples
	@bash scripts/tshark/examples.sh

capture-creds: ## Capture HTTP credentials from traffic
	@bash scripts/tshark/capture-http-credentials.sh

analyze-dns: ## Monitor DNS query traffic
	@bash scripts/tshark/analyze-dns-queries.sh

extract-files: ## Extract files from packet captures        TARGET=<pcap>
	@bash scripts/tshark/extract-files-from-capture.sh $(TARGET)

# ──────────────────────────────────────────────────────────────────
##@ Exploitation — metasploit
# ──────────────────────────────────────────────────────────────────

.PHONY: gen-payload scan-services setup-listener

gen-payload: ## Generate reverse shell payload             TARGET=<lhost>
	@bash scripts/metasploit/generate-reverse-shell.sh $(TARGET)

scan-services: ## Enumerate services with Metasploit         TARGET=<ip>
	@bash scripts/metasploit/scan-network-services.sh $(or $(TARGET),localhost)

setup-listener: ## Setup reverse shell listener              TARGET=<lhost>
	@bash scripts/metasploit/setup-listener.sh $(TARGET)

# ──────────────────────────────────────────────────────────────────
##@ Password Cracking — hashcat & john
# ──────────────────────────────────────────────────────────────────

.PHONY: crack-ntlm benchmark-gpu crack-web-hashes crack-linux-pw crack-archive identify-hash

crack-ntlm: ## Crack NTLM hashes                        TARGET=<hashfile>
	@bash scripts/hashcat/crack-ntlm-hashes.sh $(TARGET)

benchmark-gpu: ## Benchmark GPU cracking speed
	@bash scripts/hashcat/benchmark-gpu.sh

crack-web-hashes: ## Crack web app hashes (MD5/SHA/bcrypt)     TARGET=<hashfile>
	@bash scripts/hashcat/crack-web-hashes.sh $(TARGET)

crack-linux-pw: ## Crack Linux /etc/shadow passwords
	@bash scripts/john/crack-linux-passwords.sh

crack-archive: ## Crack password-protected archives          TARGET=<file>
	@bash scripts/john/crack-archive-passwords.sh $(TARGET)

identify-hash: ## Identify unknown hash type                TARGET=<hash>
	@bash scripts/john/identify-hash-type.sh $(TARGET)

# ──────────────────────────────────────────────────────────────────
##@ Web Application Testing — sqlmap, nikto & skipfish
# ──────────────────────────────────────────────────────────────────

.PHONY: sqlmap dump-db test-params bypass-waf nikto scan-vulns scan-hosts scan-auth scan-auth-app quick-scan

sqlmap: ## Run sqlmap examples                       TARGET=<url>
	@bash scripts/sqlmap/examples.sh $(or $(TARGET),http://localhost:8080)

dump-db: ## Dump database via SQL injection            TARGET=<url>
	@bash scripts/sqlmap/dump-database.sh $(TARGET)

test-params: ## Test all parameters for SQLi               TARGET=<url>
	@bash scripts/sqlmap/test-all-parameters.sh $(TARGET)

bypass-waf: ## Bypass WAF with tamper scripts             TARGET=<url>
	@bash scripts/sqlmap/bypass-waf.sh $(TARGET)

nikto: ## Run nikto examples                        TARGET=<url>
	@bash scripts/nikto/examples.sh $(or $(TARGET),http://localhost:8080)

scan-vulns: ## Scan for specific vulnerability types      TARGET=<url>
	@bash scripts/nikto/scan-specific-vulnerabilities.sh $(or $(TARGET),http://localhost:8080)

scan-hosts: ## Scan multiple hosts with nikto             TARGET=<hostfile>
	@bash scripts/nikto/scan-multiple-hosts.sh $(TARGET)

scan-auth: ## Authenticated nikto scan                  TARGET=<url>
	@bash scripts/nikto/scan-with-auth.sh $(or $(TARGET),http://localhost:8080)

scan-auth-app: ## Authenticated skipfish scan                TARGET=<url>
	@bash scripts/skipfish/scan-authenticated-app.sh $(or $(TARGET),http://localhost:8080)

quick-scan: ## Quick web app scan with skipfish           TARGET=<url>
	@bash scripts/skipfish/quick-scan-web-app.sh $(or $(TARGET),http://localhost:3030)

# ──────────────────────────────────────────────────────────────────
##@ Web Fuzzing — gobuster & ffuf
# ──────────────────────────────────────────────────────────────────

.PHONY: gobuster discover-dirs enum-subdomains ffuf fuzz-params

gobuster: ## Run gobuster examples                     TARGET=<url>
	@bash scripts/gobuster/examples.sh $(or $(TARGET),http://localhost:8080)

discover-dirs: ## Discover directories                      TARGET=<url>
	@bash scripts/gobuster/discover-directories.sh $(or $(TARGET),http://localhost:8080)

enum-subdomains: ## Enumerate subdomains                      TARGET=<domain>
	@bash scripts/gobuster/enumerate-subdomains.sh $(or $(TARGET),example.com)

ffuf: ## Run ffuf examples                         TARGET=<url>
	@bash scripts/ffuf/examples.sh $(or $(TARGET),http://localhost:8080)

fuzz-params: ## Fuzz parameters                           TARGET=<url>
	@bash scripts/ffuf/fuzz-parameters.sh $(or $(TARGET),http://localhost:8080)

# ──────────────────────────────────────────────────────────────────
##@ Network Utilities — hping3, netcat & traceroute
# ──────────────────────────────────────────────────────────────────

.PHONY: hping3 test-firewall detect-firewall netcat scan-ports nc-listener nc-transfer traceroute trace-path diagnose-latency compare-routes

hping3: ## Run hping3 examples                       TARGET=<ip>
	@bash scripts/hping3/examples.sh $(or $(TARGET),localhost)

test-firewall: ## Test firewall rules with hping3            TARGET=<ip>
	@bash scripts/hping3/test-firewall-rules.sh $(or $(TARGET),localhost)

detect-firewall: ## Detect firewall presence                  TARGET=<ip>
	@bash scripts/hping3/detect-firewall.sh $(or $(TARGET),localhost)

netcat: ## Run netcat examples                       TARGET=<ip>
	@bash scripts/netcat/examples.sh $(or $(TARGET),localhost)

scan-ports: ## Scan ports with netcat                    TARGET=<ip>
	@bash scripts/netcat/scan-ports.sh $(or $(TARGET),127.0.0.1)

nc-listener: ## Setup netcat listener
	@bash scripts/netcat/setup-listener.sh

nc-transfer: ## Transfer files with netcat
	@bash scripts/netcat/transfer-files.sh

traceroute: ## Run traceroute/mtr examples               TARGET=<host>
	@bash scripts/traceroute/examples.sh $(or $(TARGET),example.com)

trace-path: ## Trace network path                        TARGET=<host>
	@bash scripts/traceroute/trace-network-path.sh $(or $(TARGET),example.com)

diagnose-latency: ## Diagnose per-hop latency with mtr          TARGET=<host>
	@bash scripts/traceroute/diagnose-latency.sh $(or $(TARGET),example.com)

compare-routes: ## Compare TCP/ICMP/UDP routes               TARGET=<host>
	@bash scripts/traceroute/compare-routes.sh $(or $(TARGET),example.com)

# ──────────────────────────────────────────────────────────────────
##@ DNS & HTTP — dig & curl
# ──────────────────────────────────────────────────────────────────

.PHONY: dig query-dns check-dns-prop zone-transfer curl test-http check-ssl debug-http

dig: ## Run dig examples                          TARGET=<domain>
	@bash scripts/dig/examples.sh $(or $(TARGET),example.com)

query-dns: ## Query DNS records                         TARGET=<domain>
	@bash scripts/dig/query-dns-records.sh $(or $(TARGET),example.com)

check-dns-prop: ## Check DNS propagation                     TARGET=<domain>
	@bash scripts/dig/check-dns-propagation.sh $(or $(TARGET),example.com)

zone-transfer: ## Attempt DNS zone transfer                 TARGET=<domain>
	@bash scripts/dig/attempt-zone-transfer.sh $(or $(TARGET),example.com)

curl: ## Run curl examples                         TARGET=<url>
	@bash scripts/curl/examples.sh $(or $(TARGET),https://example.com)

test-http: ## Test HTTP endpoints                       TARGET=<url>
	@bash scripts/curl/test-http-endpoints.sh $(or $(TARGET),https://example.com)

check-ssl: ## Check SSL certificate                     TARGET=<domain>
	@bash scripts/curl/check-ssl-certificate.sh $(or $(TARGET),example.com)

debug-http: ## Debug HTTP response timing                TARGET=<url>
	@bash scripts/curl/debug-http-response.sh $(or $(TARGET),https://example.com)

# ──────────────────────────────────────────────────────────────────
##@ Wireless — aircrack-ng
# ──────────────────────────────────────────────────────────────────

.PHONY: capture-handshake crack-wpa analyze-wifi

capture-handshake: ## Capture WPA handshake                     TARGET=<iface>
	@bash scripts/aircrack-ng/capture-handshake.sh $(or $(TARGET),wlan0)

crack-wpa: ## Crack WPA handshake                       TARGET=<capfile>
	@bash scripts/aircrack-ng/crack-wpa-handshake.sh $(TARGET)

analyze-wifi: ## Survey wireless networks                  TARGET=<iface>
	@bash scripts/aircrack-ng/analyze-wireless-networks.sh $(or $(TARGET),wlan0)

# ──────────────────────────────────────────────────────────────────
##@ Forensics — foremost
# ──────────────────────────────────────────────────────────────────

.PHONY: foremost recover-files carve-filetypes analyze-forensic

foremost: ## Run foremost examples                     TARGET=<image>
	@bash scripts/foremost/examples.sh $(TARGET)

recover-files: ## Recover deleted files from disk image      TARGET=<image>
	@bash scripts/foremost/recover-deleted-files.sh $(TARGET)

carve-filetypes: ## Carve specific file types from image       TARGET=<image>
	@bash scripts/foremost/carve-specific-filetypes.sh $(TARGET)

analyze-forensic: ## Analyze forensic disk image               TARGET=<image>
	@bash scripts/foremost/analyze-forensic-image.sh $(TARGET)
