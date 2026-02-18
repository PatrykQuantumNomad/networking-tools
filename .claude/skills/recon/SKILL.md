---
name: recon
description: Run reconnaissance workflow -- host discovery, DNS enumeration, and OSINT gathering
argument-hint: "<target>"
disable-model-invocation: true
---

# Reconnaissance Workflow

Run comprehensive reconnaissance against the target.

## Target

Target: $ARGUMENTS

If no target was provided, ask the user for a target before proceeding. Verify the target is in `.pentest/scope.json` (run `cat .pentest/scope.json` to check). If not in scope, ask the user to add it with `/scope add <target>`.

## Steps

### 1. Host Discovery

Discover active hosts on the target network:

```
bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x
```

Review the results. If multiple hosts are found, note them for subsequent steps.

### 2. Port Scanning

Scan for open ports and identify services:

```
bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x
```

Note all open ports and service versions for the summary.

### 3. DNS Records

Query DNS records for the target domain:

```
bash scripts/dig/query-dns-records.sh $ARGUMENTS -j -x
```

Look for A, MX, NS, TXT, and CNAME records. Note nameservers for the zone transfer step.

### 4. Zone Transfer Attempt

Attempt a DNS zone transfer to enumerate all records at once:

```
bash scripts/dig/attempt-zone-transfer.sh $ARGUMENTS -j -x
```

A successful zone transfer reveals all DNS records -- this is a significant finding if it succeeds.

### 5. SSL/TLS Inspection

Check SSL certificate details for the target:

```
bash scripts/curl/check-ssl-certificate.sh $ARGUMENTS -j -x
```

Note certificate issuer, expiry date, SANs (Subject Alternative Names), and any weak cipher suites.

### 6. Subdomain Enumeration (optional)

If gobuster is installed and the target is a domain (not an IP), enumerate subdomains:

```
bash scripts/gobuster/enumerate-subdomains.sh $ARGUMENTS -j -x
```

## After Each Step

- Review the JSON output summary from the PostToolUse hook
- Note key findings (active hosts, open ports, services, DNS records, certificate details, subdomains)
- If a tool is not installed, skip that step and note it in the summary
- Adapt subsequent steps based on discoveries (e.g., if new hosts found, scan those too)
- If a step fails due to missing target or network access, note the error and continue

## Summary

After all steps complete, provide a structured reconnaissance summary:

- **Hosts**: Active hosts discovered and their status
- **Ports/Services**: Open ports and identified services with versions
- **DNS**: Records, nameservers, zone transfer results (success/fail)
- **TLS**: Certificate details, issuer, expiry, SANs
- **Subdomains**: Enumerated subdomains (if gobuster was run)
