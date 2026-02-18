---
name: sniff
description: Run traffic capture and analysis workflow -- HTTP credentials, DNS queries, and file extraction
argument-hint: "<interface-or-capture-file>"
disable-model-invocation: true
---

# Traffic Capture & Analysis Workflow

Capture and analyze network traffic for credentials, DNS activity, and file transfers.

## Target

Target: $ARGUMENTS

$ARGUMENTS can be a network interface (e.g., eth0, lo0) for live capture or a .pcap file for offline analysis. If no target was provided, ask the user whether to capture live traffic (provide interface name) or analyze an existing capture file (provide .pcap path).

**Important:** Live capture may require root privileges. If permission denied, suggest running with sudo or using `sudo tshark` directly.

## Steps

### 1. HTTP Credential Capture

Capture HTTP authentication headers, form submissions, and cookie exchanges:

```
bash scripts/tshark/capture-http-credentials.sh $ARGUMENTS -j -x
```

Look for Basic authentication headers, form POST data containing usernames/passwords, and session cookies transmitted over unencrypted HTTP.

### 2. DNS Query Analysis

Analyze DNS query patterns, unusual lookups, and potential data exfiltration via DNS:

```
bash scripts/tshark/analyze-dns-queries.sh $ARGUMENTS -j -x
```

Note unusual domain lookups, high-frequency queries (potential beaconing), long subdomain strings (potential DNS tunneling), and queries to suspicious or unknown domains.

### 3. File Extraction

Extract transferred files (HTTP downloads, email attachments) from captured traffic:

```
bash scripts/tshark/extract-files-from-capture.sh $ARGUMENTS -j -x
```

Review extracted files for sensitive content -- configuration files, credentials, documents, and executables transferred over the network.

## After Each Step

- Review the JSON output summary from the PostToolUse hook
- Note discovered credentials, DNS patterns, and extracted files
- If a tool is not installed, skip that step and note it in the summary
- For live captures, Steps 1-3 may need to run simultaneously; for pcap files all steps process the same capture

## Summary

After all steps complete, provide a structured traffic analysis summary:

- **Credentials**: Usernames, passwords, session tokens, and API keys captured
- **DNS Activity**: Notable queries, suspicious domains, potential tunneling or beaconing patterns
- **Extracted Files**: Files recovered from network traffic with content notes
- **Next Steps**: Follow-up actions based on captured credentials or identified C2 infrastructure
