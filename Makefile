# Makefile — Common operations for networking-tools

.PHONY: check lab-up lab-down lab-status help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

check: ## Check which pentesting tools are installed
	@bash scripts/check-tools.sh

lab-up: ## Start vulnerable lab targets (Docker)
	docker compose -f labs/docker-compose.yml up -d
	@echo ""
	@echo "Lab targets:"
	@echo "  DVWA:          http://localhost:8080  (admin/password)"
	@echo "  Juice Shop:    http://localhost:3000"
	@echo "  WebGoat:       http://localhost:8888/WebGoat"
	@echo "  Vuln Target:   http://localhost:8180  (SSH: localhost:2222)"

lab-down: ## Stop all lab targets
	docker compose -f labs/docker-compose.yml down

lab-status: ## Show status of lab containers
	docker compose -f labs/docker-compose.yml ps

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

identify-ports: ## Identify what's behind open ports (default: localhost)
	@bash scripts/nmap/identify-ports.sh $(or $(TARGET),localhost)
