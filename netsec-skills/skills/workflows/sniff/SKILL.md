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

## Environment Detection

- Wrapper scripts available: !`test -f scripts/tshark/capture-http-credentials.sh && echo "YES" || echo "NO"`

## Steps

### 1. HTTP Credential Capture

Capture HTTP authentication headers, form submissions, and cookie exchanges. Basic authentication headers, form POST data containing usernames/passwords, and session cookies transmitted over unencrypted HTTP are the primary targets.

**If wrapper scripts are available (YES above):**

```
bash scripts/tshark/capture-http-credentials.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct tshark commands:**

- `tshark -Y "http.request.method==POST" -T fields -e http.host -e http.request.uri -e http.file_data -i $ARGUMENTS` -- Capture POST data
- `tshark -Y "http.authorization" -T fields -e http.host -e http.authorization -i $ARGUMENTS` -- Capture auth headers
- `tshark -Y "http.cookie" -T fields -e http.host -e http.cookie -i $ARGUMENTS` -- Capture cookies

For pcap files, replace `-i $ARGUMENTS` with `-r $ARGUMENTS`.

### 2. DNS Query Analysis

Analyze DNS query patterns, unusual lookups, and potential data exfiltration via DNS. High-frequency queries may indicate beaconing; long subdomain strings may indicate DNS tunneling.

**If wrapper scripts are available (YES above):**

```
bash scripts/tshark/analyze-dns-queries.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct tshark commands:**

- `tshark -Y "dns" -T fields -e dns.qry.name -e dns.qry.type -i $ARGUMENTS` -- Capture DNS queries
- `tshark -Y "dns.qry.name contains suspicious" -i $ARGUMENTS` -- Filter for suspicious domains
- `tshark -Y "dns" -T fields -e dns.qry.name -i $ARGUMENTS | sort | uniq -c | sort -rn` -- Query frequency analysis

For pcap files, replace `-i $ARGUMENTS` with `-r $ARGUMENTS`.

### 3. File Extraction

Extract transferred files (HTTP downloads, email attachments) from captured traffic. Review extracted files for sensitive content -- configuration files, credentials, documents, and executables.

**If wrapper scripts are available (YES above):**

```
bash scripts/tshark/extract-files-from-capture.sh $ARGUMENTS -j -x
```

**If standalone (NO above), use direct tshark commands:**

- `tshark --export-objects http,/tmp/extracted/ -r $ARGUMENTS` -- Extract HTTP objects from pcap
- `tshark --export-objects smb,/tmp/extracted/ -r $ARGUMENTS` -- Extract SMB file transfers
- `tshark --export-objects imf,/tmp/extracted/ -r $ARGUMENTS` -- Extract email attachments

Note: File extraction requires a pcap file (`-r`). For live capture, save to pcap first with `tshark -i $ARGUMENTS -w capture.pcap`, then extract.

## After Each Step

**If wrapper scripts are available:** Review the JSON output summary from the PostToolUse hook.

**If standalone:** Review the command output directly for key findings.

- Note discovered credentials, DNS patterns, and extracted files
- If a tool is not installed, skip that step and note it in the summary
- For live captures, Steps 1-3 may need to run simultaneously; for pcap files all steps process the same capture

## Summary

After all steps complete, provide a structured traffic analysis summary:

- **Credentials**: Usernames, passwords, session tokens, and API keys captured
- **DNS Activity**: Notable queries, suspicious domains, potential tunneling or beaconing patterns
- **Extracted Files**: Files recovered from network traffic with content notes
- **Next Steps**: Follow-up actions based on captured credentials or identified C2 infrastructure
