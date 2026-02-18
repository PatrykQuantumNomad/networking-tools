---
name: scan
description: Run vulnerability scanning workflow -- port scans, web vulnerability scans, and SQL injection testing
argument-hint: "<target>"
disable-model-invocation: true
---

# Vulnerability Scanning Workflow

Run comprehensive vulnerability scanning against the target.

## Target

Target: $ARGUMENTS

If no target was provided, ask the user for a target before proceeding. Verify the target is in `.pentest/scope.json` (run `cat .pentest/scope.json` to check). If not in scope, ask the user to add it with `/scope add <target>`.

## Steps

### 1. Port and Service Scan

Identify all open ports and running services:

```
bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x
```

Review service versions. Outdated services are common vulnerability sources.

### 2. Web Vulnerability Scan (nmap NSE)

Use nmap NSE scripts to detect common web vulnerabilities:

```
bash scripts/nmap/scan-web-vulnerabilities.sh $ARGUMENTS -j -x
```

Look for CVEs, misconfigurations, and exposed admin interfaces flagged by NSE scripts.

### 3. Web Server Analysis

Run nikto to analyze the web server for known issues:

```
bash scripts/nikto/scan-specific-vulnerabilities.sh $ARGUMENTS -j -x
```

Nikto checks for outdated software, dangerous files, default credentials, and HTTP misconfigurations.

### 4. SQL Injection Testing

If the target is a URL with parameters, test for SQL injection vulnerabilities:

```
bash scripts/sqlmap/test-all-parameters.sh $ARGUMENTS -j -x
```

Only run if the target is a URL with query parameters (e.g., `http://target/page?id=1`). Skip if the target is an IP or bare hostname.

### 5. HTTP Endpoint Testing

Test HTTP endpoints for common web vulnerabilities:

```
bash scripts/curl/test-http-endpoints.sh $ARGUMENTS -j -x
```

Checks for security headers, open redirects, exposed endpoints, and HTTP method handling.

## After Each Step

- Review the JSON output summary from the PostToolUse hook
- Note all findings with their severity level (critical, high, medium, low)
- If a tool is not installed, skip that step and note it in the summary
- Adapt subsequent steps based on discoveries (e.g., if port scan finds a database port, prioritize injection testing)
- If a step fails due to missing target or network access, note the error and continue

## Summary

After all steps complete, provide a structured vulnerability summary organized by severity:

- **Critical**: Remote code execution, authentication bypass, exposed credentials
- **High**: SQL injection, XSS, insecure direct object references, outdated services with known CVEs
- **Medium**: Security header misconfigurations, information disclosure, open redirects
- **Low / Info**: Non-default HTTP methods, verbose error messages, minor misconfigurations
