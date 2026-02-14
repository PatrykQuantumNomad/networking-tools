---
title: Script Flags & JSON Output
description: "Every script supports -h, -x, -v, -q, and -j flags. Learn how to use show mode, execute mode, and structured JSON output for automation."
sidebar:
  order: 4
---

Every use-case script in this project supports a common set of flags. By default, scripts print numbered example commands with explanations. Flags change what the script does and how it produces output.

## Flag Reference

| Flag | Long | What It Does |
|------|------|-------------|
| `-h` | `--help` | Print usage information and exit |
| `-x` | `--execute` | Run commands against the target instead of displaying them |
| `-v` | `--verbose` | Increase output detail (available on curl and dig scripts) |
| `-q` | `--quiet` | Suppress informational output (available on curl and dig scripts) |
| `-j` | `--json` | Output as structured JSON instead of human-readable text (requires jq) |

## Show Mode (Default)

When you run a script without flags, it prints 10 example commands with explanations. Nothing is executed against the target.

```bash
bash scripts/nmap/identify-ports.sh 192.168.1.1
```

Output:

```
[INFO] 1) Identify which process owns a specific port
   lsof -i :8080 -P -n

[INFO] 2) List ALL listening ports with their process
   lsof -i -P -n | grep LISTEN
...
```

This is the default learning mode. Read the examples, copy and adapt the commands you need.

## Execute Mode (-x)

Add `-x` to actually run the commands against the target:

```bash
bash scripts/nmap/identify-ports.sh -x 192.168.1.1
```

Each command runs with a confirmation prompt before execution. The script prints the command, asks for confirmation, runs it, and shows the real output.

## JSON Output (-j)

The `-j` flag switches output from human-readable text to structured JSON. There are two modes depending on whether you also pass `-x`.

### Commands as JSON (-j alone)

Without `-x`, the script outputs the same example commands, but structured as JSON:

```bash
bash scripts/nmap/identify-ports.sh -j 192.168.1.1 2>/dev/null
```

```json
{
  "meta": {
    "tool": "nmap",
    "script": "identify-ports",
    "target": "192.168.1.1",
    "category": "network-scanner",
    "started": "2026-02-14T12:00:00Z",
    "finished": "2026-02-14T12:00:01Z",
    "mode": "show"
  },
  "results": [
    {
      "description": "Identify which process owns a specific port",
      "command": "lsof -i :8080 -P -n"
    },
    {
      "description": "List ALL listening ports with their process",
      "command": "lsof -i -P -n | grep LISTEN"
    }
  ],
  "summary": {
    "total": 10,
    "succeeded": 10,
    "failed": 0
  }
}
```

Each result has a `description` and the `command` string. This is useful for building tooling that consumes the command catalog programmatically.

### Live Capture as JSON (-j -x)

Add both `-j` and `-x` to run commands and capture their output as JSON:

```bash
bash scripts/dig/query-dns-records.sh -j -x example.com 2>/dev/null
```

```json
{
  "meta": {
    "tool": "dig",
    "script": "query-dns-records",
    "target": "example.com",
    "mode": "execute"
  },
  "results": [
    {
      "description": "1) Basic A record lookup",
      "command": "dig example.com A +noall +answer",
      "exit_code": 0,
      "stdout": "example.com.\t86400\tIN\tA\t93.184.216.34\n",
      "stderr": ""
    }
  ],
  "summary": {
    "total": 10,
    "succeeded": 10,
    "failed": 0
  }
}
```

In execute mode, each result includes `exit_code`, `stdout`, and `stderr` from the real command. The `summary` counts how many commands succeeded or failed.

## JSON Envelope Structure

Every JSON output follows the same envelope:

| Field | Type | Description |
|-------|------|-------------|
| `meta.tool` | string | Tool name (nmap, dig, curl, etc.) |
| `meta.script` | string | Script name without extension |
| `meta.target` | string | Target passed to the script |
| `meta.category` | string | Tool category (network-scanner, web-scanner, etc.) |
| `meta.started` | string | ISO 8601 timestamp when the script started |
| `meta.finished` | string | ISO 8601 timestamp when the script finished |
| `meta.mode` | string | `"show"` or `"execute"` |
| `results` | array | List of example commands or execution results |
| `summary.total` | number | Number of results |
| `summary.succeeded` | number | Commands with exit code 0 (execute mode) |
| `summary.failed` | number | Commands with non-zero exit code (execute mode) |

## Piping to jq

JSON output is designed for piping to `jq`. Human-readable text goes to stderr, JSON goes to stdout.

```bash
# Extract just the commands
bash scripts/nmap/identify-ports.sh -j 127.0.0.1 2>/dev/null | jq -r '.results[].command'

# Get the tool and result count
bash scripts/dig/query-dns-records.sh -j example.com 2>/dev/null | jq '{tool: .meta.tool, count: .summary.total}'

# Filter to failed commands in execute mode
bash scripts/curl/test-http-endpoints.sh -j -x example.com 2>/dev/null | jq '[.results[] | select(.exit_code != 0)]'
```

The `2>/dev/null` suppresses the educational text that goes to stderr. Without it, you will see both the human-readable output and the JSON on your terminal.

## Requirements

- **jq** is required for `-j` and must be installed before using JSON mode. Scripts without `-j` work without jq.
- Install: `brew install jq` (macOS) or `apt install jq` (Linux)
