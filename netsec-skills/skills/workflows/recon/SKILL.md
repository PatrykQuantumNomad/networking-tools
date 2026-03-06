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

## Environment Detection

- Wrapper scripts available: !`test -f scripts/nmap/discover-live-hosts.sh && echo "YES" || echo "NO"`

## Steps

### 1. Host Discovery

Discover active hosts on the target network. ARP scans are fastest on local networks; TCP SYN/ACK probes work across subnets and through some firewalls.

**If wrapper scripts are available (YES above):**

```
bash scripts/nmap/discover-live-hosts.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct nmap commands:**

- `nmap -sn $ARGUMENTS/24` -- Ping sweep to find live hosts
- `nmap -PS22,80,443 $ARGUMENTS/24` -- TCP SYN discovery on common ports
- `nmap -sn -PR $ARGUMENTS/24` -- ARP scan (local network only, fastest)

Review the results. If multiple hosts are found, note them for subsequent steps.

### 2. Port Scanning

Scan for open ports and identify running services. Version detection (`-sV`) reveals software and versions, which is critical for vulnerability mapping.

**If wrapper scripts are available (YES above):**

```
bash scripts/nmap/identify-ports.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct nmap commands:**

- `nmap -sS -sV $ARGUMENTS` -- TCP SYN scan with service versions
- `nmap -p- $ARGUMENTS` -- Scan all 65535 ports
- `nmap -A $ARGUMENTS` -- Aggressive scan (OS, versions, scripts, traceroute)

Note all open ports and service versions for the summary.

### 3. DNS Records

Query DNS records to map the target's infrastructure. A, MX, NS, and TXT records reveal mail servers, nameservers, and SPF/DKIM configurations.

**If wrapper scripts are available (YES above):**

```
bash scripts/dig/query-dns-records.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct dig commands:**

- `dig $ARGUMENTS A +noall +answer` -- IPv4 address
- `dig $ARGUMENTS MX +noall +answer` -- Mail exchange servers
- `dig $ARGUMENTS NS +noall +answer` -- Authoritative nameservers
- `dig $ARGUMENTS TXT +noall +answer` -- SPF, DKIM records

Look for A, MX, NS, TXT, and CNAME records. Note nameservers for the zone transfer step.

### 4. Zone Transfer Attempt

Attempt a DNS zone transfer to enumerate all records at once. A successful zone transfer reveals the full DNS map -- this is a significant finding.

**If wrapper scripts are available (YES above):**

```
bash scripts/dig/attempt-zone-transfer.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct dig commands:**

- `dig $ARGUMENTS NS +short` -- Find authoritative nameservers first
- `dig axfr $ARGUMENTS @<nameserver>` -- Attempt AXFR zone transfer

Note whether the transfer succeeded or was refused.

### 5. SSL/TLS Inspection

Check SSL certificate details and TLS configuration. Expired certificates, weak ciphers, and missing SANs are common findings.

**If wrapper scripts are available (YES above):**

```
bash scripts/curl/check-ssl-certificate.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct curl commands:**

- `curl -vI https://$ARGUMENTS 2>&1 | grep -E "SSL|subject|issuer|expire"` -- Certificate details
- `curl --tlsv1.2 -sI https://$ARGUMENTS` -- Test TLS 1.2 support
- `curl --tlsv1.3 -sI https://$ARGUMENTS` -- Test TLS 1.3 support

Note certificate issuer, expiry date, SANs (Subject Alternative Names), and any weak cipher suites.

### 6. Subdomain Enumeration (optional)

If gobuster is installed and the target is a domain (not an IP), enumerate subdomains. Hidden subdomains often host dev, staging, or admin interfaces.

**If wrapper scripts are available (YES above):**

```
bash scripts/gobuster/enumerate-subdomains.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct gobuster commands:**

- `gobuster dns -d $ARGUMENTS -w subdomains.txt` -- DNS subdomain brute-force
- `gobuster dns -d $ARGUMENTS -w subdomains.txt -t 20` -- 20 concurrent threads

## After Each Step

**If wrapper scripts are available:** Review the JSON output summary from the PostToolUse hook.

**If standalone:** Review the command output directly for key findings.

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
