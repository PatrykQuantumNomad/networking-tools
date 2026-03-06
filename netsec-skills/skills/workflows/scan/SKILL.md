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

## Environment Detection

- Wrapper scripts available: !`test -f scripts/nmap/identify-ports.sh && echo "YES" || echo "NO"`

## Steps

### 1. Port and Service Scan

Identify all open ports and running services. Version detection (`-sV`) reveals software and versions, which is critical for vulnerability mapping.

**If wrapper scripts are available (YES above):**

```
bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct nmap commands:**

- `nmap -sS -sV $ARGUMENTS` -- TCP SYN scan with service version detection
- `nmap -p- $ARGUMENTS` -- Scan all 65535 ports
- `nmap -A $ARGUMENTS` -- Aggressive scan (OS, versions, scripts, traceroute)

Review service versions. Outdated services are common vulnerability sources.

### 2. Web Vulnerability Scan (nmap NSE)

Use nmap NSE scripts to detect common web vulnerabilities. NSE extends nmap with vulnerability checks and service enumeration.

**If wrapper scripts are available (YES above):**

```
bash scripts/nmap/scan-web-vulnerabilities.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct nmap commands:**

- `nmap --script=http-vuln-* $ARGUMENTS` -- Run all HTTP vulnerability scripts
- `nmap --script=ssl-enum-ciphers -p 443 $ARGUMENTS` -- Enumerate SSL/TLS ciphers
- `nmap -sV --script=vulners $ARGUMENTS` -- Check service versions against CVE database

Look for CVEs, misconfigurations, and exposed admin interfaces flagged by NSE scripts.

### 3. Web Server Analysis

Run nikto to analyze the web server for known issues. Nikto checks for outdated software, dangerous files, default credentials, and HTTP misconfigurations.

**If wrapper scripts are available (YES above):**

```
bash scripts/nikto/scan-specific-vulnerabilities.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct nikto commands:**

- `nikto -h $ARGUMENTS` -- Default scan for known vulnerabilities
- `nikto -h $ARGUMENTS -Tuning 123` -- Focus on file upload, default files, info disclosure
- `nikto -h $ARGUMENTS -ssl` -- Force SSL mode for HTTPS targets

### 4. SQL Injection Testing

If the target is a URL with parameters, test for SQL injection vulnerabilities. Only run if the target has query parameters (e.g., `http://target/page?id=1`).

**If wrapper scripts are available (YES above):**

```
bash scripts/sqlmap/test-all-parameters.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct sqlmap commands:**

- `sqlmap -u "$ARGUMENTS" --batch` -- Auto-detect and test SQL injection
- `sqlmap -u "$ARGUMENTS" --batch --level=5 --risk=3` -- Maximum detection coverage
- `sqlmap -u "$ARGUMENTS" --batch --dbs` -- Enumerate databases if injectable

Skip if the target is an IP or bare hostname without query parameters.

### 5. HTTP Endpoint Testing

Test HTTP endpoints for common web vulnerabilities including security headers, allowed methods, and response behavior.

**If wrapper scripts are available (YES above):**

```
bash scripts/curl/test-http-endpoints.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct curl commands:**

- `curl -I $ARGUMENTS` -- Check response headers
- `curl -X OPTIONS $ARGUMENTS -i` -- Test allowed HTTP methods
- `curl -sI $ARGUMENTS | grep -iE "x-frame|x-content|strict-transport|content-security"` -- Check security headers

## After Each Step

**If wrapper scripts are available:** Review the JSON output summary from the PostToolUse hook.

**If standalone:** Review the command output directly for key findings.

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
