# Makefile — Common operations for networking-tools

.PHONY: check lab-up lab-down lab-status help wordlists site-dev site-build site-preview dig query-dns check-dns-prop zone-transfer curl test-http check-ssl debug-http netcat scan-ports nc-listener nc-transfer diagnose-dns diagnose-connectivity traceroute trace-path diagnose-latency compare-routes diagnose-performance gobuster discover-dirs enum-subdomains ffuf fuzz-params

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

wordlists: ## Download wordlists for password cracking and web enumeration
	@bash wordlists/download.sh

check: ## Check which pentesting tools are installed
	@bash scripts/check-tools.sh

lab-up: ## Start vulnerable lab targets (Docker)
	docker compose -f labs/docker-compose.yml up -d
	@echo ""
	@echo "Lab targets:"
	@echo "  DVWA:          http://localhost:8080  (admin/password)"
	@echo "  Juice Shop:    http://localhost:3030"
	@echo "  WebGoat:       http://localhost:8888/WebGoat"
	@echo "  VulnerableApp: http://localhost:8180/VulnerableApp"

lab-down: ## Stop all lab targets
	docker compose -f labs/docker-compose.yml down

lab-status: ## Show status of lab containers
	docker compose -f labs/docker-compose.yml ps

# Site development
site-dev: ## Start docs site dev server
	@cd site && npm run dev

site-build: ## Build docs site for production
	@cd site && npm run build

site-preview: ## Preview docs production build
	@cd site && npm run preview

# Diagnostic targets
diagnose-dns: ## Run DNS diagnostic (usage: make diagnose-dns TARGET=<domain>)
	@bash scripts/diagnostics/dns.sh $(or $(TARGET),example.com)

diagnose-connectivity: ## Run connectivity diagnostic (usage: make diagnose-connectivity TARGET=domain)
	@bash scripts/diagnostics/connectivity.sh $(or $(TARGET),example.com)

# Tool-specific runners
nmap: ## Run nmap examples (usage: make nmap TARGET=<ip>)
	@bash scripts/nmap/examples.sh $(TARGET)

tshark: ## Run tshark examples
	@bash scripts/tshark/examples.sh

sqlmap: ## Run sqlmap examples (usage: make sqlmap TARGET=<url>)
	@bash scripts/sqlmap/examples.sh $(TARGET)

nikto: ## Run nikto examples (usage: make nikto TARGET=<url>)
	@bash scripts/nikto/examples.sh $(TARGET)

hping3: ## Run hping3 examples (usage: make hping3 TARGET=<ip>)
	@bash scripts/hping3/examples.sh $(TARGET)

foremost: ## Run foremost examples (usage: make foremost TARGET=<image>)
	@bash scripts/foremost/examples.sh $(TARGET)

dig: ## Run dig examples (usage: make dig TARGET=<domain>)
	@bash scripts/dig/examples.sh $(TARGET)

curl: ## Run curl examples (usage: make curl TARGET=<url>)
	@bash scripts/curl/examples.sh $(TARGET)

identify-ports: ## Identify what's behind open ports (default: localhost)
	@bash scripts/nmap/identify-ports.sh $(or $(TARGET),localhost)

# Use-case scripts — specific tasks with correct parameters
discover-hosts: ## Find live hosts on a subnet (usage: make discover-hosts TARGET=<subnet>)
	@bash scripts/nmap/discover-live-hosts.sh $(or $(TARGET),localhost)

scan-web-vulns: ## Scan web server for vulnerabilities (usage: make scan-web-vulns TARGET=<ip>)
	@bash scripts/nmap/scan-web-vulnerabilities.sh $(or $(TARGET),localhost)

capture-creds: ## Capture HTTP credentials from traffic
	@bash scripts/tshark/capture-http-credentials.sh

analyze-dns: ## Monitor DNS query traffic
	@bash scripts/tshark/analyze-dns-queries.sh

extract-files: ## Extract files from packet captures (usage: make extract-files TARGET=<pcap>)
	@bash scripts/tshark/extract-files-from-capture.sh $(TARGET)

gen-payload: ## Generate reverse shell payload (usage: make gen-payload TARGET=<lhost>)
	@bash scripts/metasploit/generate-reverse-shell.sh $(TARGET)

scan-services: ## Enumerate services with Metasploit scanners (usage: make scan-services TARGET=<ip>)
	@bash scripts/metasploit/scan-network-services.sh $(or $(TARGET),localhost)

setup-listener: ## Setup reverse shell listener
	@bash scripts/metasploit/setup-listener.sh $(TARGET)

crack-ntlm: ## Crack NTLM hashes (usage: make crack-ntlm TARGET=<hashfile>)
	@bash scripts/hashcat/crack-ntlm-hashes.sh $(TARGET)

benchmark-gpu: ## Benchmark GPU cracking speed
	@bash scripts/hashcat/benchmark-gpu.sh

crack-web-hashes: ## Crack web app hashes — MD5, SHA, bcrypt (usage: make crack-web-hashes TARGET=<hashfile>)
	@bash scripts/hashcat/crack-web-hashes.sh $(TARGET)

crack-linux-pw: ## Crack Linux /etc/shadow passwords
	@bash scripts/john/crack-linux-passwords.sh

crack-archive: ## Crack password-protected archives (usage: make crack-archive TARGET=<file>)
	@bash scripts/john/crack-archive-passwords.sh $(TARGET)

identify-hash: ## Identify unknown hash type (usage: make identify-hash TARGET=<hash>)
	@bash scripts/john/identify-hash-type.sh $(TARGET)

dump-db: ## Dump database via SQL injection (usage: make dump-db TARGET=<url>)
	@bash scripts/sqlmap/dump-database.sh $(TARGET)

test-params: ## Test all parameters for SQLi (usage: make test-params TARGET=<url>)
	@bash scripts/sqlmap/test-all-parameters.sh $(TARGET)

bypass-waf: ## Bypass WAF with tamper scripts (usage: make bypass-waf TARGET=<url>)
	@bash scripts/sqlmap/bypass-waf.sh $(TARGET)

scan-vulns: ## Scan for specific vulnerability types (usage: make scan-vulns TARGET=<url>)
	@bash scripts/nikto/scan-specific-vulnerabilities.sh $(or $(TARGET),http://localhost:8080)

scan-hosts: ## Scan multiple hosts with nikto (usage: make scan-hosts TARGET=<hostfile>)
	@bash scripts/nikto/scan-multiple-hosts.sh $(TARGET)

scan-auth: ## Authenticated nikto scan (usage: make scan-auth TARGET=<url>)
	@bash scripts/nikto/scan-with-auth.sh $(or $(TARGET),http://localhost:8080)

test-firewall: ## Test firewall rules with hping3 (usage: make test-firewall TARGET=<ip>)
	@bash scripts/hping3/test-firewall-rules.sh $(or $(TARGET),localhost)

detect-firewall: ## Detect firewall presence (usage: make detect-firewall TARGET=<ip>)
	@bash scripts/hping3/detect-firewall.sh $(or $(TARGET),localhost)

scan-auth-app: ## Authenticated skipfish scan (usage: make scan-auth-app TARGET=<url>)
	@bash scripts/skipfish/scan-authenticated-app.sh $(or $(TARGET),http://localhost:8080)

quick-scan: ## Quick web app scan (usage: make quick-scan TARGET=<url>)
	@bash scripts/skipfish/quick-scan-web-app.sh $(or $(TARGET),http://localhost:3030)

capture-handshake: ## Capture WPA handshake (usage: make capture-handshake TARGET=<interface>)
	@bash scripts/aircrack-ng/capture-handshake.sh $(or $(TARGET),wlan0)

crack-wpa: ## Crack WPA handshake (usage: make crack-wpa TARGET=<capfile>)
	@bash scripts/aircrack-ng/crack-wpa-handshake.sh $(TARGET)

analyze-wifi: ## Survey wireless networks (usage: make analyze-wifi TARGET=<interface>)
	@bash scripts/aircrack-ng/analyze-wireless-networks.sh $(or $(TARGET),wlan0)

recover-files: ## Recover deleted files from disk image (usage: make recover-files TARGET=<image>)
	@bash scripts/foremost/recover-deleted-files.sh $(TARGET)

carve-filetypes: ## Carve specific file types from image (usage: make carve-filetypes TARGET=<image>)
	@bash scripts/foremost/carve-specific-filetypes.sh $(TARGET)

analyze-forensic: ## Analyze forensic disk image (usage: make analyze-forensic TARGET=<image>)
	@bash scripts/foremost/analyze-forensic-image.sh $(TARGET)

query-dns: ## Query DNS records (usage: make query-dns TARGET=<domain>)
	@bash scripts/dig/query-dns-records.sh $(or $(TARGET),example.com)

check-dns-prop: ## Check DNS propagation (usage: make check-dns-prop TARGET=<domain>)
	@bash scripts/dig/check-dns-propagation.sh $(or $(TARGET),example.com)

zone-transfer: ## Attempt DNS zone transfer (usage: make zone-transfer TARGET=<domain>)
	@bash scripts/dig/attempt-zone-transfer.sh $(or $(TARGET),example.com)

test-http: ## Test HTTP endpoints (usage: make test-http TARGET=<url>)
	@bash scripts/curl/test-http-endpoints.sh $(or $(TARGET),https://example.com)

check-ssl: ## Check SSL certificate (usage: make check-ssl TARGET=<domain>)
	@bash scripts/curl/check-ssl-certificate.sh $(or $(TARGET),example.com)

debug-http: ## Debug HTTP response timing (usage: make debug-http TARGET=<url>)
	@bash scripts/curl/debug-http-response.sh $(or $(TARGET),https://example.com)

netcat: ## Run netcat examples (usage: make netcat TARGET=<ip>)
	@bash scripts/netcat/examples.sh $(TARGET)

scan-ports: ## Scan ports with netcat (usage: make scan-ports TARGET=<ip>)
	@bash scripts/netcat/scan-ports.sh $(or $(TARGET),127.0.0.1)

nc-listener: ## Setup netcat listener
	@bash scripts/netcat/setup-listener.sh

nc-transfer: ## Transfer files with netcat
	@bash scripts/netcat/transfer-files.sh

traceroute: ## Run traceroute/mtr examples (usage: make traceroute TARGET=<host>)
	@bash scripts/traceroute/examples.sh $(TARGET)

trace-path: ## Trace network path (usage: make trace-path TARGET=<host>)
	@bash scripts/traceroute/trace-network-path.sh $(or $(TARGET),example.com)

diagnose-latency: ## Diagnose per-hop latency with mtr (usage: make diagnose-latency TARGET=<host>)
	@bash scripts/traceroute/diagnose-latency.sh $(or $(TARGET),example.com)

compare-routes: ## Compare TCP/ICMP/UDP routes (usage: make compare-routes TARGET=<host>)
	@bash scripts/traceroute/compare-routes.sh $(or $(TARGET),example.com)

diagnose-performance: ## Run performance diagnostic (usage: make diagnose-performance TARGET=<host>)
	@bash scripts/diagnostics/performance.sh $(or $(TARGET),example.com)

gobuster: ## Run gobuster examples (usage: make gobuster TARGET=<url>)
	@bash scripts/gobuster/examples.sh $(TARGET)

discover-dirs: ## Discover directories (usage: make discover-dirs TARGET=<url>)
	@bash scripts/gobuster/discover-directories.sh $(or $(TARGET),http://localhost:8080)

enum-subdomains: ## Enumerate subdomains (usage: make enum-subdomains TARGET=<domain>)
	@bash scripts/gobuster/enumerate-subdomains.sh $(or $(TARGET),example.com)

ffuf: ## Run ffuf examples (usage: make ffuf TARGET=<url>)
	@bash scripts/ffuf/examples.sh $(TARGET)

fuzz-params: ## Fuzz parameters (usage: make fuzz-params TARGET=<url>)
	@bash scripts/ffuf/fuzz-parameters.sh $(or $(TARGET),http://localhost:8080)
