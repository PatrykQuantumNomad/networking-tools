# Feature Landscape: JSON Output Mode for CLI Scripts

**Domain:** Structured machine-readable output for bash-based security toolkit
**Researched:** 2026-02-13
**Overall confidence:** HIGH

## Context: Why JSON Output Now

The project has 46 use-case scripts and 17 examples scripts across 17 tools. Every script currently outputs human-readable text with ANSI colors. There is no machine-readable output mode. This matters because:

1. **Piping to jq/other tools** is impossible -- output is unstructured colored text
2. **Automation** (CI/CD, reporting, alerting) requires parsing human text with brittle regexes
3. **Aggregation** (combining results from multiple scripts) has no standard format
4. **The diagnostic scripts** already have structured semantics (PASS/FAIL/WARN) but no structured output format

Adding `-j/--json` aligns with how every major CLI tool handles this: `gh --json`, `kubectl -o json`, `docker --format json`, `ffuf -of json`, `tshark -T json`.

---

## Table Stakes

Features users expect when a CLI tool advertises `--json` support. Missing any of these makes the feature feel broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `-j`/`--json` flag in `parse_common_args` | Universal convention. Every tool that supports JSON has a single flag. Users should not need to remember per-script flags. | Low | Add to `parse_common_args` alongside `-v`, `-q`, `-x`. Set `OUTPUT_FORMAT=json`. |
| Consistent envelope structure | Users pipe JSON through `jq`. They need a predictable top-level shape. `gh` uses `[{...}]`. `ffuf` uses `{commandline, time, results, config}`. `kubectl` uses `{apiVersion, kind, metadata, items}`. An envelope means `.results[]` works on every script. | Low | `{"meta":{...}, "examples":[...], "summary":{...}}` -- three predictable keys. |
| `meta` object with tool, target, timestamp | Every structured CLI output includes provenance. Nmap XML has `scanner`, `args`, `start`, `version`. ffuf has `commandline`, `time`. Without meta, JSON output loses context when saved to a file. | Low | `{"tool":"nmap", "script":"discover-live-hosts", "target":"192.168.1.0", "timestamp":"2026-02-13T10:30:00Z", "version":"1.0"}` |
| `examples` array with numbered items | The scripts output 10 numbered examples. JSON must preserve this structure. Each example needs: number, title, command, explanation. | Low | `{"number":1, "title":"Basic ping sweep", "command":"nmap -sn 192.168.1.0/24", "description":"..."}` |
| Valid JSON (always) | Broken JSON is worse than no JSON. Special characters in commands (quotes, backslashes, `$`, `&`, `|`) must be escaped. ANSI color codes must be stripped. | Medium | Requires proper JSON escaping. Use `jq` for generation if available, fall back to careful printf-based escaping. See Pitfalls. |
| Suppress human-readable output in JSON mode | When `-j` is active, `info()`, `warn()`, `echo` statements must not pollute stdout. JSON must be the ONLY thing on stdout. | Medium | All human output goes to stderr in JSON mode, or is suppressed entirely. JSON goes to stdout. This is the `gh` pattern. |
| Exit code preservation | JSON mode must not mask errors. If the underlying tool fails, exit code must propagate. JSON output should include an `exit_code` or `success` field. | Low | `"summary":{"exit_code":0, "success":true}` |
| No jq dependency for basic operation | Not all systems have `jq` installed. The JSON output must work without jq. jq can be used for *better* escaping when available, but must not be required. | Medium | Use a bash JSON builder that handles escaping. Detect `jq` and use it if present for proper escaping, fall back to printf-based approach. |

## Differentiators

Features that go beyond "has JSON output" and make this toolkit's JSON mode notably useful.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Execute mode JSON captures tool output | In `-x -j` mode, actually run commands and capture their stdout/stderr into the JSON `results` array. This is the killer feature -- structured results from real tool execution. | High | Requires capturing command output, parsing it, and embedding it. Start simple: `"output":"raw stdout string"`. Tool-specific parsing is a future milestone. |
| Tool-category-specific result schemas | Scanners, crackers, web fuzzers, and packet analyzers produce fundamentally different data. A scanner result has hosts/ports. A cracker result has hashes/passwords. Category-specific schemas make downstream processing practical. | Medium | Define 4-5 category schemas (see below). Each script maps to one category. |
| `summary` object with computed aggregates | Diagnostic scripts already count pass/fail/warn. Scan scripts could summarize "5 hosts found, 23 open ports." Crackers could report "3 of 10 hashes cracked." | Medium | Per-category summary fields. Not all scripts need rich summaries -- most show-mode scripts just count examples. |
| `--json` works with `-q` (quiet) | Quiet mode suppresses human output but JSON still emits everything. `-q -j` is the "automation mode" -- clean JSON on stdout, nothing on stderr. | Low | If `OUTPUT_FORMAT=json`, ignore `LOG_LEVEL=warn` for JSON data collection. Only suppress stderr logging. |
| Error objects in JSON | When a command fails, include structured error info: `{"error": true, "message": "nmap not found", "hint": "brew install nmap"}`. Maps to existing `require_cmd` error handling. | Low | Extend `require_cmd`, `require_target` to emit JSON errors when in JSON mode instead of printing colored text and exiting. |
| `--json` in diagnostic scripts | Diagnostic scripts (`connectivity.sh`, `dns.sh`, `performance.sh`) have the most natural JSON mapping: each check becomes a result object with `status` (pass/fail/warn), `description`, and optional `detail` fields. | Medium | `report_pass/fail/warn` functions emit JSON objects when in JSON mode. `run_check` captures output and structures it. |
| Streaming JSON (NDJSON) for long-running operations | For execute mode with long scans, emit one JSON line per result as it completes, rather than buffering everything. | High | Use JSON Lines format (one JSON object per line). Flag: `--json-stream` or detect if stdout is a pipe. Defer to later phase. |
| `jq` filter pass-through (`--jq` flag) | Like `gh --json --jq '.results[].command'` -- apply a jq filter inline without external piping. `gh` embeds a jq interpreter; this project can just pipe to `jq` if available. | Medium | Only works if `jq` is installed. `--jq EXPR` implies `--json`. Nice sugar but not essential. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Parse native tool output into structured JSON | Nmap XML has 50+ fields. sqlmap output is complex. tshark JSON is deeply nested. Parsing every tool's output format is a massive undertaking that duplicates `jc` (which already does this for 300+ commands). | In execute mode, capture raw stdout as a string. Users who want structured native output should pipe directly: `nmap -oX - \| jc --nmap`. Document this pattern. |
| Different JSON schemas per script | 46 individual schemas would be unmaintainable. Users cannot build tooling against 46 different structures. | Use 4-5 category schemas. All scanner scripts share one shape. All cracker scripts share one shape. Predictability over precision. |
| XML/YAML/CSV output modes | Scope creep. JSON is the universal interchange format. XML is legacy (nmap uses it, nothing new does). YAML is for config, not output. CSV loses structure. | JSON only. If users need CSV: `script -j \| jq -r '.examples[] \| [.number, .command] \| @csv'`. |
| Interactive JSON mode | JSON mode should never prompt for input. No "Run this command? [y/N]" in JSON mode. | When `OUTPUT_FORMAT=json`, skip all `read -rp` prompts and interactive demos entirely. JSON consumers are machines, not humans. |
| Pretty-printed JSON by default | Pretty JSON wastes bandwidth in pipes and breaks line-oriented tools. | Emit compact JSON (one line). Users who want pretty: `script -j \| jq .`. Document this. |
| Embedding base64-encoded binary output | Some tools produce binary output (pcap files, carved files). Do not base64-encode and embed. | Include file paths in JSON: `"output_file": "/tmp/capture.pcap"`. Reference, do not embed. |
| Version-negotiated JSON schemas | Adding `--json-version 2` style versioning adds complexity for a project this size. | Single schema version. Embed `"schema_version": "1.0"` in meta. Break compatibility only across major milestones. |
| Colorized JSON | Some tools (e.g., `bat`) colorize JSON output. This corrupts the JSON for pipe consumers. | Never add ANSI codes to JSON output. Period. If `OUTPUT_FORMAT=json`, `NO_COLOR` is effectively forced for all data collection. |

## Feature Dependencies

```
parse_common_args update (-j/--json flag)
  |-> Sets OUTPUT_FORMAT=json global variable
  |-> Must happen first -- everything depends on this
  Depends on: Nothing

JSON builder library (lib/json.sh)
  |-> json_escape() -- safely escape strings for JSON
  |-> json_object() -- build {"key":"value"} pairs
  |-> json_array() -- build [...] from items
  |-> json_meta() -- generate standard meta envelope
  |-> json_emit() -- write final JSON to stdout
  |-> Detect jq availability for robust escaping
  Depends on: Nothing (new library module)

Show-mode JSON output (examples listing)
  |-> info() / run_or_show() emit to stderr or collect data when JSON mode
  |-> Collect examples into array during script execution
  |-> Emit JSON envelope at script exit (via EXIT trap or explicit call)
  Depends on: parse_common_args update, JSON builder library

Execute-mode JSON output (tool results)
  |-> run_or_show() captures stdout/stderr when JSON+execute mode
  |-> Results embedded in JSON output alongside command metadata
  Depends on: Show-mode JSON output

Diagnostic script JSON output
  |-> report_pass/fail/warn/skip emit JSON objects when JSON mode
  |-> run_check captures structured results
  |-> Summary includes pass/fail/warn counts as numbers
  Depends on: JSON builder library

Suppress human output in JSON mode
  |-> info/warn/error redirect to stderr (or suppress)
  |-> safety_banner suppressed or moved to stderr
  |-> Interactive prompts skipped entirely
  Depends on: parse_common_args update

Tests for JSON output
  |-> Validate JSON is valid (pipe through jq or python -m json.tool)
  |-> Validate envelope structure (meta, examples/results, summary)
  |-> Validate escaping of special characters
  Depends on: Show-mode JSON output, BATS framework (from prior milestone)
```

## Tool Category Schemas

Different tool categories produce fundamentally different result shapes. Rather than 46 individual schemas, define 5 category schemas.

### Category 1: Network Scanners

**Tools:** nmap, hping3, netcat (scan-ports)
**What they find:** Hosts, ports, services, OS fingerprints

```json
{
  "meta": {
    "tool": "nmap",
    "script": "discover-live-hosts",
    "target": "192.168.1.0/24",
    "timestamp": "2026-02-13T10:30:00Z",
    "schema_version": "1.0",
    "mode": "show"
  },
  "examples": [
    {
      "number": 1,
      "title": "Basic ping sweep of a subnet",
      "command": "nmap -sn 192.168.1.0/24",
      "description": "ICMP echo-based host discovery"
    }
  ],
  "summary": {
    "example_count": 10,
    "category": "network-scanner"
  }
}
```

In execute mode, results replace examples:

```json
{
  "meta": { "...": "...", "mode": "execute" },
  "results": [
    {
      "number": 1,
      "title": "Basic ping sweep of a subnet",
      "command": "nmap -sn 192.168.1.0/24",
      "exit_code": 0,
      "output": "Starting Nmap 7.95...\nNmap scan report for 192.168.1.1\nHost is up (0.0034s latency).\n...",
      "duration_seconds": 12.4
    }
  ],
  "summary": {
    "commands_run": 10,
    "commands_succeeded": 9,
    "commands_failed": 1,
    "category": "network-scanner"
  }
}
```

### Category 2: Web Scanners / Fuzzers

**Tools:** nikto, skipfish, gobuster, ffuf, sqlmap, curl
**What they find:** Vulnerabilities, directories, parameters, HTTP responses

```json
{
  "meta": {
    "tool": "nikto",
    "script": "scan-specific-vulnerabilities",
    "target": "http://localhost:8080",
    "timestamp": "2026-02-13T10:30:00Z",
    "schema_version": "1.0",
    "mode": "show"
  },
  "examples": [
    {
      "number": 1,
      "title": "Scan for SQL injection only",
      "command": "nikto -h http://localhost:8080 -Tuning 9",
      "description": "Uses Nikto tuning flag 9 for SQL injection checks"
    }
  ],
  "summary": {
    "example_count": 10,
    "category": "web-scanner"
  }
}
```

### Category 3: Password Crackers

**Tools:** hashcat, john
**What they find:** Cracked hashes, attack speed, remaining hashes

```json
{
  "meta": {
    "tool": "hashcat",
    "script": "crack-ntlm-hashes",
    "target": "hashes.txt",
    "timestamp": "2026-02-13T10:30:00Z",
    "schema_version": "1.0",
    "mode": "show"
  },
  "examples": [
    {
      "number": 1,
      "title": "Dictionary attack on NTLM hashes",
      "command": "hashcat -m 1000 -a 0 hashes.txt wordlist.txt",
      "description": "Straightforward wordlist attack against NTLM (mode 1000)"
    }
  ],
  "summary": {
    "example_count": 10,
    "category": "password-cracker"
  }
}
```

### Category 4: Network Analysis / Packet Capture

**Tools:** tshark, traceroute, dig
**What they find:** Packets, routes, DNS records, traffic patterns

```json
{
  "meta": {
    "tool": "tshark",
    "script": "capture-http-credentials",
    "target": "en0",
    "timestamp": "2026-02-13T10:30:00Z",
    "schema_version": "1.0",
    "mode": "show"
  },
  "examples": [
    {
      "number": 1,
      "title": "Capture HTTP POST requests showing form data",
      "command": "sudo tshark -i en0 -Y 'http.request.method==POST' -T fields -e http.host -e http.request.uri -e http.file_data",
      "description": "Filters for POST requests and extracts host, URI, and form data fields"
    }
  ],
  "summary": {
    "example_count": 10,
    "category": "network-analysis"
  }
}
```

### Category 5: Exploitation / Utility

**Tools:** metasploit, aircrack-ng, foremost, netcat (listener/transfer)
**What they find:** Sessions, handshakes, recovered files, connections

Same envelope structure. Category exists so that result schemas can diverge later if needed.

### Category 6: Diagnostics (Pattern B scripts)

**Tools:** connectivity.sh, dns.sh, performance.sh
**What they find:** Pass/fail/warn checks with structured test results

```json
{
  "meta": {
    "tool": "diagnostics",
    "script": "connectivity",
    "target": "example.com",
    "timestamp": "2026-02-13T10:30:00Z",
    "schema_version": "1.0",
    "mode": "execute"
  },
  "results": [
    {
      "section": "Local Network",
      "checks": [
        {
          "status": "pass",
          "description": "Local IP: 192.168.1.100",
          "detail": null
        },
        {
          "status": "pass",
          "description": "Default gateway: 192.168.1.1",
          "detail": null
        }
      ]
    },
    {
      "section": "DNS Resolution",
      "checks": [
        {
          "status": "pass",
          "description": "DNS resolution for example.com",
          "detail": "Resolved to: 93.184.216.34"
        }
      ]
    }
  ],
  "summary": {
    "total_checks": 15,
    "passed": 12,
    "failed": 1,
    "warnings": 2,
    "category": "diagnostic"
  }
}
```

---

## How Real CLI Tools Handle JSON: Patterns to Follow

### Pattern 1: gh CLI -- Field Selection with --json

`gh` lets users pick which fields to include: `gh pr list --json number,title`. This reduces payload size and makes jq queries simpler. For this project, the envelope is fixed (meta + examples/results + summary), so field selection is unnecessary. The data is small enough that emitting everything is fine.

**Adopt:** Fixed envelope (simpler). Do not adopt field selection.

### Pattern 2: gh CLI -- Built-in jq filtering

`gh --json number --jq '.[].number'` applies jq without external piping. Elegant but requires embedding a jq interpreter (gh uses Go's gojq). For bash, this means shelling out to jq.

**Adopt as sugar only:** `--jq EXPR` pipes JSON through `jq "$EXPR"` if jq is installed. Fails with helpful error if jq missing. Low priority.

### Pattern 3: kubectl -- Consistent apiVersion/kind envelope

Every kubectl JSON response has `apiVersion`, `kind`, `metadata`. This lets tools identify what they are looking at without knowing which command produced it.

**Adopt:** The `meta.tool` and `meta.script` fields serve this purpose. `summary.category` identifies the schema type.

### Pattern 4: ffuf -- commandline and config in output

ffuf embeds the exact command that produced the output and the full config. Excellent for reproducibility.

**Adopt:** `meta.command` or `meta.args` should capture the original command invocation so results can be reproduced.

### Pattern 5: Docker -- NDJSON for streaming

`docker ps --format json` outputs one JSON object per line (not a JSON array). This enables streaming processing but is not valid JSON as a whole.

**Do not adopt for default mode.** Emit valid JSON arrays. NDJSON is only appropriate for `--json-stream` (future feature).

### Pattern 6: Nmap -- Exhaustive structured output

Nmap XML has 50+ element types with precise semantics (host/port/service/os/script). This is the gold standard for tool-specific output.

**Do not attempt to replicate.** This project wraps tools; it does not replace them. When users need nmap's structured output, they use `nmap -oX`. The scripts' JSON output is about the *examples and commands*, not the tool results.

### Pattern 7: tshark -- -T json for native JSON

tshark can output full packet dissection as JSON: `tshark -T json`. Fields are arrays because protocols can have multiple instances.

**Reference pattern for execute mode.** In `-x -j` mode, if tshark is the underlying tool, consider passing `-T json` to tshark and embedding its native JSON output directly rather than capturing raw text.

### Pattern 8: hashcat -- Machine-readable status

hashcat `--machine-readable` outputs colon-separated status fields: STATUS, SPEED, PROGRESS, etc. Not JSON, but structured.

**Acknowledge but do not parse.** In execute mode, capture raw output. Users who want structured hashcat output should use hashcat's native `--machine-readable` flag directly. Document this.

---

## JSON Generation in Bash: Technical Approach

### Strategy: jq-first with printf fallback

**When jq is available (preferred path):**
```bash
jq -n \
  --arg tool "$TOOL" \
  --arg target "$TARGET" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson examples "$EXAMPLES_JSON_ARRAY" \
  '{meta: {tool: $tool, target: $target, timestamp: $timestamp}, examples: $examples}'
```

This handles ALL escaping correctly -- quotes, backslashes, newlines, unicode. Zero risk of broken JSON.

**When jq is not available (fallback):**
```bash
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"      # backslash
    s="${s//\"/\\\"}"      # double quote
    s="${s//$'\n'/\\n}"    # newline
    s="${s//$'\r'/\\r}"    # carriage return
    s="${s//$'\t'/\\t}"    # tab
    printf '%s' "$s"
}
```

This handles the 95% case. Edge cases (unicode, control characters) may produce invalid JSON. Acceptable tradeoff for zero-dependency operation.

### Detection pattern:
```bash
if command -v jq &>/dev/null; then
    _JSON_ENGINE="jq"
else
    _JSON_ENGINE="printf"
fi
```

### Why not require jq?

1. The project's philosophy is educational -- scripts should work on minimal systems
2. `require_cmd` gates tool availability; JSON output should not add a new required dependency
3. jq is a "nice to have" optimization, not a hard requirement

### Why not use python/perl?

1. Python is heavier than jq and slower to invoke for simple JSON generation
2. Perl one-liners are fragile and unreadable
3. jq is purpose-built for JSON and widely available (`brew install jq`, `apt install jq`)
4. The printf fallback handles the dependency-free case

---

## Fields Reference: What Each Envelope Key Contains

### meta (always present)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tool` | string | Yes | Tool name (e.g., "nmap", "sqlmap"). Matches directory name. |
| `script` | string | Yes | Script name without extension (e.g., "discover-live-hosts"). |
| `target` | string | Yes | Target value passed to script (or "none" if no target). |
| `timestamp` | string | Yes | ISO 8601 UTC timestamp of execution. |
| `schema_version` | string | Yes | Always "1.0" initially. |
| `mode` | string | Yes | "show" or "execute". |
| `command` | string | No | Full command line that invoked the script. |
| `category` | string | Yes | One of: "network-scanner", "web-scanner", "password-cracker", "network-analysis", "exploitation", "diagnostic". |

### examples (show mode) / results (execute mode)

Show mode -- `examples` array:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `number` | integer | Yes | Example number (1-10). |
| `title` | string | Yes | One-line title from `info "N) Title"` or `run_or_show` first argument. |
| `command` | string | Yes | The actual command shown to the user. |
| `description` | string | No | Additional context or explanation. |

Execute mode -- `results` array:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `number` | integer | Yes | Command number (1-10). |
| `title` | string | Yes | One-line title. |
| `command` | string | Yes | Command that was executed. |
| `exit_code` | integer | Yes | Exit code of the command. |
| `output` | string | Yes | Captured stdout from the command. |
| `stderr` | string | No | Captured stderr (if any). |
| `duration_seconds` | number | No | Wall-clock execution time. |
| `skipped` | boolean | No | True if command was skipped (e.g., requires sudo). |

### summary (always present)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `category` | string | Yes | Tool category (mirrors meta.category). |
| `example_count` | integer | Show mode | Number of examples listed. |
| `commands_run` | integer | Execute mode | Number of commands executed. |
| `commands_succeeded` | integer | Execute mode | Commands with exit_code 0. |
| `commands_failed` | integer | Execute mode | Commands with exit_code != 0. |
| `total_checks` | integer | Diagnostic mode | Total diagnostic checks run. |
| `passed` | integer | Diagnostic mode | Checks that passed. |
| `failed` | integer | Diagnostic mode | Checks that failed. |
| `warnings` | integer | Diagnostic mode | Checks with warnings. |
| `success` | boolean | Yes | Overall success: true if no failures. |
| `exit_code` | integer | Yes | Script's own exit code. |

### errors (only when errors occur)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `error` | boolean | Yes | Always true when present. |
| `message` | string | Yes | Human-readable error message. |
| `hint` | string | No | Suggested fix (e.g., "brew install nmap"). |
| `code` | string | No | Error code (e.g., "MISSING_TOOL", "MISSING_TARGET"). |

Error envelope example (emitted instead of normal output):
```json
{
  "meta": {"tool":"nmap", "script":"discover-live-hosts", "timestamp":"..."},
  "error": {
    "code": "MISSING_TOOL",
    "message": "nmap is not installed",
    "hint": "brew install nmap"
  }
}
```

---

## Implementation Approach for run_or_show

The core challenge is that `run_or_show` currently has two modes (show/execute). JSON adds a dimension: show+human, show+json, execute+human, execute+json. The cleanest approach:

### Show + JSON mode
`run_or_show` appends an example object to a bash array (or temp file) instead of printing.

### Execute + JSON mode
`run_or_show` runs the command, captures output, and appends a result object.

### Accumulate-then-emit pattern
Rather than streaming JSON during script execution, accumulate data in bash variables/arrays, then emit the complete JSON envelope at exit. This ensures valid JSON even if the script is interrupted. An EXIT trap calls `json_emit()` which assembles and outputs the final JSON.

```bash
# Pseudocode for the accumulation pattern
_JSON_ITEMS=()

run_or_show() {
    local description="$1"; shift
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        if [[ "$EXECUTE_MODE" == "execute" ]]; then
            local output exit_code
            output=$("$@" 2>&1) && exit_code=0 || exit_code=$?
            _JSON_ITEMS+=("$(json_result "$description" "$*" "$exit_code" "$output")")
        else
            _JSON_ITEMS+=("$(json_example "$description" "$*")")
        fi
    else
        # existing human-readable behavior unchanged
    fi
}

# At script end or via EXIT trap:
json_emit() {
    local items
    items=$(printf '%s,' "${_JSON_ITEMS[@]}")
    items="[${items%,}]"  # Remove trailing comma, wrap in array
    # ... build full envelope with meta + items + summary
}
```

---

## MVP Recommendation

Prioritize:

1. **`-j`/`--json` flag in `parse_common_args`** -- Sets `OUTPUT_FORMAT=json`. Foundation for everything. (LOW complexity, HIGH value)

2. **`lib/json.sh` JSON builder library** -- `json_escape()`, `json_object()`, `json_array()`, `json_meta()`, `json_emit()`. jq-first with printf fallback. (MEDIUM complexity, HIGH value)

3. **Show-mode JSON for `run_or_show`** -- Accumulate examples, emit envelope at end. Suppress human output. Test with one representative script per category. (MEDIUM complexity, HIGH value)

4. **Diagnostic scripts JSON output** -- `report_pass/fail/warn` emit JSON when in JSON mode. Most natural fit for structured output. (MEDIUM complexity, HIGH value)

5. **Roll out to all 46 use-case scripts** -- Since `run_or_show` is shared infrastructure, most scripts get JSON for free. Scripts that use `info` + `echo` patterns (instead of `run_or_show`) need per-script updates. (MEDIUM complexity, MEDIUM value)

6. **Execute-mode JSON** -- `run_or_show` captures output in `-x -j` mode. Higher complexity because of output capture and error handling. (HIGH complexity, MEDIUM value)

Defer:

- **`--jq` filter flag** -- Sugar. Users can pipe to jq themselves. Implement after core JSON works.
- **Streaming JSON (NDJSON)** -- Complex, only matters for long-running execute mode. Future milestone.
- **Native tool output parsing** -- Out of scope. Point users to `jc` for structured tool output.
- **JSON output for `examples.sh` scripts** -- Lower priority than use-case scripts. Same pattern applies; roll out after use-case scripts work.

## Key Technical Considerations

### ANSI Color Stripping

When `OUTPUT_FORMAT=json`, all data collection must bypass color codes. Options:

1. **Set `NO_COLOR=1` early** -- The project's `colors.sh` respects this. If `NO_COLOR` is set, all color variables become empty strings. Set this when `-j` flag is detected.
2. **Strip after the fact** -- Use `sed 's/\x1b\[[0-9;]*m//g'` to remove ANSI codes from captured output. Belt-and-suspenders approach for execute mode where tools emit their own colors.

Recommendation: Do both. Set `NO_COLOR=1` for project functions, strip ANSI from captured external tool output.

### stderr vs stdout Separation

In JSON mode:
- **stdout** = JSON data only. One JSON document. Nothing else.
- **stderr** = Human-readable logs, warnings, progress info (if any).

This matches `gh` behavior and enables `script -j 2>/dev/null | jq .` for clean automation.

### Scripts That Don't Use run_or_show

Some scripts (e.g., hashcat, parts of sqlmap) use `info` + `echo` patterns instead of `run_or_show`. These need manual updates to accumulate JSON data. The approach is to introduce a `json_add_example()` helper that these scripts call alongside their existing output.

Estimated count: ~15 of 46 use-case scripts use the `info` + `echo` pattern instead of `run_or_show`. The remaining ~31 scripts use `run_or_show` consistently and will get JSON support automatically from the library change.

### JSON Validity Testing

Every script with JSON output should be tested:

```bash
@test "nmap/discover-live-hosts.sh -j produces valid JSON" {
    run bash "$PROJECT_ROOT/scripts/nmap/discover-live-hosts.sh" -j
    assert_success
    echo "$output" | jq . >/dev/null 2>&1
    assert_success
}

@test "nmap/discover-live-hosts.sh -j has correct envelope" {
    run bash "$PROJECT_ROOT/scripts/nmap/discover-live-hosts.sh" -j
    echo "$output" | jq -e '.meta.tool == "nmap"'
    echo "$output" | jq -e '.examples | length > 0'
    echo "$output" | jq -e '.summary.category == "network-scanner"'
}
```

---

## Sources

- [GitHub CLI formatting documentation](https://cli.github.com/manual/gh_help_formatting) -- `--json`, `--jq`, `--template` flag design patterns (HIGH confidence)
- [gh CLI --json issue discussion](https://github.com/cli/cli/issues/1089) -- Design rationale for gh's JSON output (HIGH confidence)
- [Nmap XML Output specification](https://nmap.org/book/output-formats-xml-output.html) -- XML structure: nmaprun, host, port, service element hierarchy (HIGH confidence)
- [Nmap DTD](https://nmap.org/book/nmap-dtd.html) -- Full element/attribute definitions for nmap XML (HIGH confidence)
- [ffuf file output formats](https://deepwiki.com/ffuf/ffuf/6.2-file-output-formats) -- JSON envelope: commandline, time, results array, config. Result fields: status, length, words, lines, duration, url (HIGH confidence)
- [Nikto export formats wiki](https://github.com/sullo/nikto/wiki/Export-Formats/897f9af07de5cff93e526360fc1890f5de5db196) -- CSV fields: Host, IP, Port, Banner, Vulnerability, Method, Description (MEDIUM confidence)
- [hashcat machine-readable output](https://hashcat.net/wiki/doku.php?id=machine_readable) -- STATUS, SPEED, PROGRESS, RECHASH fields (HIGH confidence)
- [hashcat JSON output feature request](https://github.com/hashcat/hashcat/issues/3586) -- Community demand for JSON machine-readable output (MEDIUM confidence)
- [tshark man page](https://www.wireshark.org/docs/man-pages/tshark.html) -- `-T json` and `-T ek` output format documentation (HIGH confidence)
- [Docker CLI formatting](https://docs.docker.com/engine/cli/formatting/) -- Go template JSON formatting, NDJSON streaming pattern (HIGH confidence)
- [docker ps JSON not valid array issue](https://github.com/moby/moby/issues/46906) -- NDJSON vs JSON array tradeoffs (MEDIUM confidence)
- [kubectl output formatting](https://www.baeldung.com/ops/kubectl-output-format) -- `-o json`, JSONPath, consistent envelope pattern (MEDIUM confidence)
- [jc tool](https://github.com/kellyjonbrazil/jc) -- CLI-to-JSON converter supporting 300+ commands including dig, ping, traceroute (HIGH confidence)
- [jq manual](https://jqlang.org/manual/) -- jq 1.8 for JSON processing, `--arg` for safe string injection (HIGH confidence)
- [Build JSON string with bash variables](https://www.baeldung.com/linux/bash-variables-create-json-string) -- jq `-n --arg` pattern for safe JSON generation (MEDIUM confidence)
- [json.bash](https://github.com/h4l/json.bash) -- Pure-bash JSON generation library (MEDIUM confidence)
- [sqlmap JSON report request](https://github.com/sqlmapproject/sqlmap/issues/3094) -- sqlmap lacks native JSON report output (MEDIUM confidence)
- Codebase analysis: direct reading of all 46 use-case scripts, 9 lib modules, 3 diagnostic scripts, args.sh, output.sh (HIGH confidence)
