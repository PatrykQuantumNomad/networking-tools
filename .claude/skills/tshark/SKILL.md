---
name: tshark
description: >-
  Capture and analyze network traffic with tshark. Packet capture, protocol
  analysis, display filters, credential extraction, file carving from pcaps.
disable-model-invocation: true
---

# Tshark Packet Analyzer

Capture and analyze network traffic, extract credentials, and carve files using tshark.

## Tool Status

- Tool installed: !`command -v tshark > /dev/null 2>&1 && echo "YES -- $(tshark --version 2>/dev/null | head -1)" || echo "NO -- Install: brew install wireshark (macOS, includes tshark CLI) | apt install tshark (Debian/Ubuntu)"`
- Wrapper scripts available: !`test -f scripts/tshark/capture-http-credentials.sh && echo "YES -- use wrapper scripts for structured JSON output" || echo "NO -- using standalone mode with direct commands"`

## Mode: Wrapper Scripts Available

If wrapper scripts are available (shown as YES above), prefer these commands.
They provide structured JSON output and educational context.

### Credential Capture
- `bash scripts/tshark/capture-http-credentials.sh <interface> -j -x` -- Extract HTTP credentials from unencrypted traffic (POST data, Basic Auth, cookies)

### DNS Analysis
- `bash scripts/tshark/analyze-dns-queries.sh <interface> -j -x` -- Monitor DNS query patterns to detect tunneling, zone transfers, anomalies

### File Extraction
- `bash scripts/tshark/extract-files-from-capture.sh <capture.pcap> -j -x` -- Carve files transferred over HTTP and SMB from packet captures

### Learning Mode
- `bash scripts/tshark/examples.sh <target>` -- 10 common tshark patterns with explanations

Always add `-j` for JSON output and `-x` to execute (vs display-only).

## Mode: Standalone (Direct Commands)

If wrapper scripts are NOT available, use these direct tshark commands.

### Live Capture

Capture packets from a network interface in real time. Use capture filters (-f)
to limit traffic at the kernel level, or display filters (-Y) to filter after capture.

- `tshark -i eth0 -c 100` -- Capture 100 packets on eth0
- `tshark -i en0 -c 50` -- Capture 50 packets on en0 (macOS default)
- `tshark -f "port 80" -i eth0 -c 100` -- Capture only HTTP traffic
- `tshark -f "host <target>" -i eth0 -c 100` -- Capture traffic to/from specific host
- `tshark -i eth0 -w capture.pcap -c 500` -- Save capture to pcap file

### Display Filters and Analysis

Read saved captures and apply display filters to isolate specific protocols,
requests, or patterns. Field extraction (-T fields -e) pulls structured data.

- `tshark -r capture.pcap -Y "http.request"` -- Show HTTP requests from pcap
- `tshark -r capture.pcap -Y "dns" -T fields -e dns.qry.name` -- Extract DNS query names
- `tshark -r capture.pcap -Y "tcp.flags.syn==1 && tcp.flags.ack==0"` -- Show SYN packets (new connections)
- `tshark -r capture.pcap -Y "http.response.code >= 400"` -- Show HTTP error responses
- `tshark -r capture.pcap -qz io,stat,1` -- Traffic statistics per second

### Credential Extraction

Extract credentials from unencrypted protocols. HTTP POST data, Basic Auth
headers, and FTP/SMTP logins are visible in cleartext captures.

- `tshark -Y "http.request.method==POST" -T fields -e http.file_data -r capture.pcap` -- Extract POST body data
- `tshark -Y "http.authorization" -T fields -e http.authorization -r capture.pcap` -- Extract HTTP auth headers
- `tshark -Y "http.cookie" -T fields -e http.cookie -r capture.pcap` -- Extract session cookies
- `tshark -Y "ftp.request.command==PASS" -T fields -e ftp.request.arg -r capture.pcap` -- Extract FTP passwords

### File Extraction

- `tshark -r capture.pcap --export-objects http,exported_files/` -- Extract HTTP-transferred files
- `tshark -r capture.pcap --export-objects smb,exported_files/` -- Extract SMB-transferred files

## Defaults

- Interface defaults to `en0` (macOS) or `eth0` (Linux) when not provided
- Extract script accepts a `.pcap` file path as first argument

## Target Validation

All commands validate targets against `.pentest/scope.json` via the PreToolUse hook.
