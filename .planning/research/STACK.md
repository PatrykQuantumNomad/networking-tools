# Technology Stack: JSON Output Mode

**Project:** networking-tools -- JSON output mode for 46 use-case scripts
**Researched:** 2026-02-13
**Scope:** Stack additions for `-j/--json` flag producing envelope-pattern JSON output
**Constraint:** Bash-only project, macOS + Linux, existing 8-module lib/, BATS 1.13.0 test suite

## Existing Stack (Validated, DO NOT Re-research)

| Technology | Version | Status |
|------------|---------|--------|
| Bash | 4.0+ target (5.x on dev macOS, CI ubuntu-latest) | Established |
| scripts/lib/ | 8 modules (strict, colors, logging, cleanup, output, args, validation, nc_detect, diagnostic) | Established |
| parse_common_args() | Handles -h/-v/-q/-x with unknown-flag passthrough | Established |
| EXECUTE_MODE | "show" (default) / "execute" (-x) | Established |
| run_or_show() | Dual-mode: prints command in show mode, runs it in execute mode | Established |
| BATS | v1.13.0 with bats-assert, bats-support, bats-file submodules | Established |
| ShellCheck | CI-enforced --severity=warning | Established |
| NO_COLOR | Respected by colors.sh for non-terminal output | Established |
| make_temp | Creates auto-cleaned temp files/dirs | Established |

---

## Recommended Stack: One External Dependency (jq)

### Core Decision: jq for ALL JSON Generation

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| jq | >= 1.6 (latest stable: 1.8.1) | JSON generation, string escaping, envelope assembly, validation | The only reliable way to produce guaranteed-valid JSON from bash. Handles all RFC 8259 escaping edge cases automatically via `--arg`. Ubiquitous on all target platforms. |

**This is the only new external dependency.** Everything else is new bash code in the existing `scripts/lib/` module system.

### Why jq, Not Pure Bash

The central problem is **escaping arbitrary tool output**. When nmap, sqlmap, nikto, or any other wrapped tool writes to stdout, that output can contain:
- Double quotes, backslashes, single quotes
- Newlines, tabs, carriage returns
- ANSI escape codes (color sequences like `\033[0;31m`)
- Control characters, binary fragments
- Characters that look like JSON syntax (`{`, `}`, `[`, `]`, `:`)

A pure-bash approach using `printf` or `sed` substitution chains cannot reliably escape all of these. One missed edge case produces invalid JSON, which silently breaks every downstream consumer. jq's `--arg name value` flag handles all of these automatically -- it treats the value as a raw string and applies full JSON escaping.

**The risk calculus:** The cost of a jq dependency is near-zero (ubiquitous, zero runtime deps, static binary). The cost of shipping invalid JSON is high (broken pipelines, silent data corruption, user distrust). Use jq.

### jq Features Required (All Available in jq >= 1.6)

| Feature | Flag | Purpose | Available Since |
|---------|------|---------|-----------------|
| Null input | `-n` / `--null-input` | Build JSON from scratch without stdin | jq 1.3+ |
| String argument | `--arg name val` | Inject bash variable as escaped JSON string | jq 1.3+ |
| JSON argument | `--argjson name val` | Inject number/boolean/object as JSON type | jq 1.5+ |
| Raw input | `-R` / `--raw-input` | Read stdin as text lines, not JSON | jq 1.3+ |
| Slurp | `-s` / `--slurp` | Collect all inputs into array | jq 1.3+ |
| Raw output | `-r` / `--raw-output` | Output strings without quotes | jq 1.3+ |
| Exit status | `-e` / `--exit-status` | Exit non-zero if output is false/null | jq 1.3+ |
| Join output | `-j` / `--join-output` | No trailing newline | jq 1.5+ |

**Minimum version: jq 1.6.** This is the floor version in Ubuntu 20.04 LTS repos (the oldest reasonable target). All features above work in jq 1.5+, but pinning to 1.6 ensures compatibility with the most conservative package managers.

**Confidence: HIGH** -- Features verified against [jq 1.6 Manual](https://jqlang.github.io/jq/manual/v1.6/) and [jq 1.8 Manual](https://jqlang.org/manual/). Version availability verified via [Ubuntu package repos](https://ubuntu.pkgs.org/22.04/ubuntu-main-amd64/jq_1.6-2.1ubuntu3_amd64.deb.html).

### jq Platform Availability

| Platform | Default jq Version | How to Install | Notes |
|----------|-------------------|----------------|-------|
| GitHub Actions (ubuntu-24.04) | 1.7+ | Pre-installed | No CI changes needed |
| Ubuntu 24.04 | 1.7.1 | `apt install jq` | Default repos |
| Ubuntu 22.04 | 1.6 | `apt install jq` | Default repos |
| Ubuntu 20.04 | 1.6 | `apt install jq` | Default repos |
| macOS 15+ (Sequoia) | 1.7+ | Pre-installed at `/usr/bin/jq` | Ships with OS |
| macOS (older via Homebrew) | 1.8.1 | `brew install jq` | Current Homebrew formula |
| Kali Linux | 1.6+ | `apt install jq` | Common pentesting distro |
| Alpine (Docker) | 1.7+ | `apk add jq` | Lightweight containers |

**Confidence: HIGH** -- Verified via [jq download page](https://jqlang.org/download/), [GitHub Actions runner images](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md), Ubuntu package repos.

---

## New Library Module: scripts/lib/json.sh

This is the primary deliverable -- a new bash module in the existing `scripts/lib/` system.

### Module Responsibilities

| Function | Purpose |
|----------|---------|
| jq availability check | `require_cmd jq` only when OUTPUT_FORMAT=json (lazy check) |
| ANSI stripping | Set NO_COLOR=1 when JSON mode active, strip ANSI from captured output |
| JSON envelope builder | Assemble `{meta, results, summary}` envelope using jq |
| Result accumulator | Append individual command results to a temp-file-based JSON array |
| Output routing | In JSON mode: suppress human-readable output, emit JSON to stdout |
| Timestamp generation | ISO 8601 UTC timestamps for meta.timestamp |

### Module Dependencies and Load Order

```
strict.sh -> colors.sh -> logging.sh -> validation.sh -> cleanup.sh -> output.sh -> args.sh -> json.sh -> diagnostic.sh -> nc_detect.sh
```

json.sh loads after args.sh (needs OUTPUT_FORMAT) and before diagnostic.sh. It depends on:
- `args.sh` for OUTPUT_FORMAT global
- `logging.sh` for info/warn/error functions
- `cleanup.sh` for make_temp (temp file for results accumulation)
- `validation.sh` for require_cmd

### Global Variables Introduced

| Variable | Default | Set By | Read By |
|----------|---------|--------|---------|
| `OUTPUT_FORMAT` | `"text"` | args.sh (parse_common_args -j) | json.sh, output.sh, logging.sh |
| `_JSON_RESULTS_FILE` | (temp file path) | json.sh init | json.sh functions |
| `_JSON_CMD_COUNT` | `0` | json.sh init | json.sh summary builder |
| `_JSON_CMD_SUCCESS` | `0` | json.sh init | json.sh summary builder |

---

## Integration Points with Existing Modules

### 1. args.sh -- New Flag

Add `-j`/`--json` to `parse_common_args()`:

```bash
-j|--json)
    OUTPUT_FORMAT="json"
    # JSON requires real command output, auto-enable execute mode
    EXECUTE_MODE="execute"
    ;;
```

**Key design decision:** `-j` auto-enables `-x` (execute mode). JSON output captures real tool results, which only happen in execute mode. Requiring users to always type `-j -x` is poor UX. Auto-enabling is safe because:
1. Execute mode already requires interactive terminal confirmation via `confirm_execute()`
2. JSON consumers are typically scripts/pipelines, not interactive users
3. The `-j` flag is an explicit opt-in to machine-readable output

**Exception:** When `-j` is used with piped/non-interactive stdin, skip the `confirm_execute()` prompt. JSON mode is designed for automation; requiring interactive confirmation defeats the purpose. This means `json.sh` must also patch the `confirm_execute()` behavior.

### 2. output.sh -- run_or_show() Enhancement

The existing `run_or_show()` is the central execution function called by all 46 scripts. In JSON mode, it must change behavior:

```bash
# Current behavior (text mode):
#   show mode:    print description + indented command
#   execute mode: print description + run command

# New behavior (json mode):
#   Runs command, captures stdout+stderr, records exit code
#   Passes result to json_add_result() in json.sh
#   Suppresses human-readable info/echo output to stdout
```

This is the highest-leverage integration point. Modifying `run_or_show()` automatically gives JSON output to all 46 scripts without changing any individual script.

### 3. logging.sh -- Stderr Routing in JSON Mode

When OUTPUT_FORMAT=json, all human-readable output must go to stderr (or be suppressed), keeping stdout clean for the JSON envelope:

```bash
# In info(), warn(), success(), debug():
if [[ "${OUTPUT_FORMAT:-text}" == "json" ]]; then
    # Route to stderr so stdout contains only JSON
    echo -e "..." >&2
fi
```

This preserves the ability to see progress/warnings while still getting clean JSON on stdout: `script -j target 2>/dev/null | jq .`

### 4. colors.sh -- Auto NO_COLOR

json.sh should set `NO_COLOR=1` when JSON mode is active, ensuring captured tool output does not contain ANSI escape codes. This uses the existing NO_COLOR mechanism in colors.sh.

### 5. cleanup.sh -- Temp File for Results

The results array is built incrementally in a temp file (one jq call per command result). This uses the existing `make_temp` function, which auto-cleans on exit.

### 6. common.sh -- Source Order Update

```bash
# Add json.sh to the source chain after args.sh:
source "${_LIB_DIR}/strict.sh"
source "${_LIB_DIR}/colors.sh"
source "${_LIB_DIR}/logging.sh"
source "${_LIB_DIR}/validation.sh"
source "${_LIB_DIR}/cleanup.sh"
source "${_LIB_DIR}/output.sh"
source "${_LIB_DIR}/args.sh"
source "${_LIB_DIR}/json.sh"          # NEW
source "${_LIB_DIR}/diagnostic.sh"
source "${_LIB_DIR}/nc_detect.sh"
```

---

## JSON Generation Patterns

### Pattern 1: Envelope Metadata

```bash
json_build_meta() {
    local tool="$1" target="$2"
    jq -n \
      --arg tool "$tool" \
      --arg target "$target" \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg hostname "$(hostname)" \
      '{tool: $tool, target: $target, timestamp: $timestamp, hostname: $hostname}'
}
```

### Pattern 2: Capturing Command Output Safely

```bash
json_capture_command() {
    local description="$1"
    shift
    local cmd_string="$*"

    local output_file
    output_file=$(make_temp file json-capture)

    local exit_code=0
    "$@" > "$output_file" 2>&1 || exit_code=$?

    local raw_output
    raw_output=$(cat "$output_file")

    jq -n \
      --arg desc "$description" \
      --arg cmd "$cmd_string" \
      --arg output "$raw_output" \
      --argjson exit_code "$exit_code" \
      '{description: $desc, command: $cmd, output: $output, exit_code: $exit_code}'
}
```

**Why `--arg output "$raw_output"` works:** jq's `--arg` automatically escapes all special characters in `$raw_output`. Newlines become `\n`, quotes become `\"`, backslashes become `\\`, ANSI codes become escaped control characters. The resulting JSON string is always valid.

### Pattern 3: Incremental Results Array (Temp File)

```bash
json_add_result() {
    local result_json="$1"

    # Append to results array in temp file
    local tmp="${_JSON_RESULTS_FILE}.tmp"
    jq --argjson entry "$result_json" '. += [$entry]' "$_JSON_RESULTS_FILE" > "$tmp" \
      && mv "$tmp" "$_JSON_RESULTS_FILE"

    _JSON_CMD_COUNT=$((_JSON_CMD_COUNT + 1))
}
```

### Pattern 4: Final Envelope Assembly

```bash
json_emit_envelope() {
    local meta="$1"
    local summary

    summary=$(jq -n \
      --argjson total "$_JSON_CMD_COUNT" \
      --argjson successful "$_JSON_CMD_SUCCESS" \
      '{total_commands: $total, successful: $successful}')

    local results
    results=$(cat "$_JSON_RESULTS_FILE")

    jq -n \
      --argjson meta "$meta" \
      --argjson results "$results" \
      --argjson summary "$summary" \
      '{meta: $meta, results: $results, summary: $summary}'
}
```

---

## BATS Testing Strategy for JSON Output

### jq in Tests -- No New Dependencies

jq is already pre-installed on GitHub Actions runners and available on dev machines. The test suite uses jq for JSON validation but does NOT add it as a submodule or test helper dependency -- it is an external tool like bash itself.

### BATS `bats_pipe` for JSON Assertions

BATS 1.13.0 includes `bats_pipe` (available since ~v1.11), which handles piping within `run` contexts. This is essential because `run cmd | jq` does NOT work (bash parses the pipe outside of `run`).

**Confidence: HIGH** -- `bats_pipe` verified in [BATS writing-tests documentation](https://bats-core.readthedocs.io/en/stable/writing-tests.html).

### Test Patterns

**Validity check:**
```bash
@test "JSON output is valid JSON" {
    run bats_pipe bash "$script" -j target \| jq .
    assert_success
}
```

**Envelope structure:**
```bash
@test "JSON has meta, results, summary keys" {
    run bats_pipe bash "$script" -j target \| jq -e 'has("meta", "results", "summary")'
    assert_success
}
```

**Field value assertions:**
```bash
@test "meta.tool is nmap" {
    run bats_pipe bash "$script" -j target \| jq -r '.meta.tool'
    assert_success
    assert_output "nmap"
}
```

**Type assertions:**
```bash
@test "results is an array" {
    run bats_pipe bash "$script" -j target \| jq -e '.results | type == "array"'
    assert_success
}

@test "exit_code is numeric" {
    run bats_pipe bash "$script" -j target \| jq -e '.results[0].exit_code | type == "number"'
    assert_success
}
```

**Timestamp format:**
```bash
@test "timestamp is ISO 8601" {
    run bats_pipe bash "$script" -j target \| jq -r '.meta.timestamp'
    assert_success
    # Matches YYYY-MM-DDTHH:MM:SSZ
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
}
```

### Test Helper: json-helpers.bash

Create `tests/test_helper/json-helpers.bash` for DRY JSON assertions:

```bash
#!/usr/bin/env bash
# tests/test_helper/json-helpers.bash -- JSON assertion helpers for BATS

# Extract a field from $output (assumes $output contains valid JSON)
json_field() {
    local filter="$1"
    echo "$output" | jq -r "$filter"
}

# Assert that a jq filter returns true (non-null, non-false)
json_has() {
    local filter="$1"
    echo "$output" | jq -e "$filter" > /dev/null 2>&1
}

# Assert JSON output has the standard envelope structure
assert_json_envelope() {
    json_has 'has("meta", "results", "summary")' || {
        echo "Expected JSON envelope with meta, results, summary keys"
        echo "Got: $output"
        return 1
    }
}
```

### Mock Strategy for JSON Tests

The existing mock binary approach works perfectly. Mock tools output known strings, and tests verify the JSON envelope wraps them correctly:

```bash
setup_file() {
    MOCK_BIN="${BATS_FILE_TMPDIR}/mock-bin"
    mkdir -p "$MOCK_BIN"
    # Mock nmap that produces known output
    printf '#!/bin/sh\necho "Host: 192.168.1.1 is up"\nexit 0\n' > "${MOCK_BIN}/nmap"
    chmod +x "${MOCK_BIN}/nmap"
    export MOCK_BIN
}

setup() {
    load 'test_helper/common-setup'
    _common_setup
    export PATH="${MOCK_BIN}:${PATH}"
}

@test "JSON captures nmap output" {
    run bats_pipe bash scripts/nmap/discover-live-hosts.sh -j localhost \| jq -r '.results[0].output'
    assert_success
    assert_output --partial "Host: 192.168.1.1 is up"
}
```

### Dynamic Test Registration for JSON Contract

Extend the existing `intg-cli-contracts.bats` pattern to test JSON contracts across all scripts:

```bash
# INTG-03: JSON envelope contract -- every use-case script with -j produces valid envelope
_test_json_contract() {
    local script="$1"
    run bats_pipe bash "$script" -j dummy_target \| jq -e 'has("meta", "results", "summary")'
    assert_success
}

while IFS= read -r script; do
    bats_test_function \
        --description "INTG-03 ${script}: -j produces valid JSON envelope" \
        -- _test_json_contract "$script"
done < <(_discover_execute_mode_scripts)
```

This gives 46+ tests automatically with zero per-script test code.

---

## CI Impact

### No Workflow Changes Required

- **tests.yml:** jq is pre-installed on ubuntu-latest. BATS tests using jq will work without modification.
- **shellcheck.yml:** New `json.sh` module is a `.sh` file, automatically included in ShellCheck linting.

### Optional Enhancement: jq Version Check in CI

```yaml
- name: Verify jq availability
  run: |
    jq --version
    # Ensure minimum version 1.6
```

This is informational only -- jq on ubuntu-24.04 is 1.7+, well above the 1.6 floor.

---

## What NOT to Add

| Rejected Technology | Why |
|---------------------|-----|
| **jo** (JSON output CLI) | Designed for constructing JSON from key=value CLI args. Does not handle multi-line captured tool output well. jq's `--arg` is strictly superior for our use case. Adding jo means two external deps instead of one. |
| **jc** (JSON Convert CLI) | Python dependency, violates bash-only constraint. Only covers subset of our 16 tools. Output schema does not match our envelope pattern. Huge dependency for partial coverage. |
| **Pure bash printf JSON** | Cannot reliably escape arbitrary tool output. One unescaped quote or backslash in nmap/sqlmap output produces invalid JSON. The escaping problem is the entire reason jq exists. |
| **Python/Node helpers** | Project is bash-only by design. Adding a runtime for JSON generation is architectural inconsistency. |
| **JSON.sh** (bash JSON parser) | Parses JSON, does not generate it. Wrong direction for this use case. |
| **Separate JSON schema validator** | If jq produces the JSON, it is valid by construction. For tests, `jq -e` provides schema-level assertions. No ajv/jsonschema needed. |
| **Tool-specific JSON flags** (nmap -oJ, etc.) | Only some tools support JSON output. Different tools use different schemas. We still need envelope wrapping. Does not solve the general problem. |
| **jc for nmap/dig parsing** | Tempting for structured tool output, but: (1) Python dep, (2) schema mismatch, (3) only covers some tools, (4) we capture raw output by design -- structured parsing is a future enhancement. |

---

## JSON Escaping Strategy

**Rule: Use jq `--arg` for ALL string values. Never manually escape.**

`--arg name value` treats `value` as a raw string and applies full RFC 8259 escaping:
| Character | Escaped As |
|-----------|-----------|
| `\` | `\\` |
| `"` | `\"` |
| newline | `\n` |
| tab | `\t` |
| carriage return | `\r` |
| form feed | `\f` |
| backspace | `\b` |
| control chars (0x00-0x1F) | `\uXXXX` |

**ANSI stripping:** Before capturing tool output, set `NO_COLOR=1` (tools that respect it will omit colors) and strip remaining ANSI codes with `sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'`. This produces cleaner JSON without encoded escape sequences.

---

## ShellCheck Compliance for json.sh

Key patterns to satisfy ShellCheck `--severity=warning`:

```bash
# SC2155: Declare and assign separately
local raw_output
raw_output=$("$@" 2>&1) || true       # NOT: local raw_output=$("$@" 2>&1)

# SC2086: Always quote variable expansions
jq -n --arg val "$variable"            # NOT: --arg val $variable

# SC2034: Globals read by other modules need disable comment
# shellcheck disable=SC2034
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"

# SC2030/SC2031: Avoid modifying variables in subshells
# Use temp files for inter-function communication, not subshell exports
```

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| JSON generation | jq `--null-input --arg` | Pure bash `printf` | Cannot escape arbitrary output. One malformed string = invalid JSON for all consumers. |
| JSON generation | jq `--null-input --arg` | jo CLI tool | Extra dependency. Worse at multi-line captured output. Less ubiquitous than jq. |
| Tool output conversion | Raw capture as string | jc structured parsing | Python dep. Partial tool coverage. Wrong schema. |
| Tool output conversion | Raw capture as string | Per-tool JSON flags | Inconsistent availability. Different schemas. Still need envelope. |
| JSON validation in tests | `jq .` / `jq -e` | jsonlint, python -m json.tool | Extra dep. jq already available and sufficient. |
| BATS pipe handling | `bats_pipe cmd \| jq` | Subshell capture | `bats_pipe` properly captures exit status; subshell loses it. |
| Results accumulation | Temp file with jq append | Bash array + final printf | Array cannot escape properly. Temp file guarantees validity at each step. |
| Flag behavior | `-j` auto-enables `-x` | Require explicit `-j -x` | Poor UX. JSON always needs execute mode. Extra typing with no safety benefit. |

---

## Installation

### For Users (runtime)

No installation changes for text-mode users. jq is only required when `-j` is used:

```bash
# In json.sh -- lazy check, only when JSON mode is active:
if [[ "${OUTPUT_FORMAT:-text}" == "json" ]]; then
    require_cmd jq "Install jq: brew install jq (macOS) or apt install jq (Linux)"
fi
```

### For Developers (testing)

jq must be available for running JSON-related BATS tests:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Verify
jq --version    # Should show jq-1.6 or higher
```

### For CI

No changes. jq is pre-installed on ubuntu-latest (GitHub Actions).

---

## Version Pinning Summary

| Component | Pinned Version | Latest Available | Notes |
|-----------|---------------|-----------------|-------|
| jq (minimum) | >= 1.6 | 1.8.1 (2025-07-01) | Floor version matches oldest Ubuntu LTS repos |
| BATS (existing) | 1.13.0 | 1.13.0 | No change. bats_pipe available. |
| bats-assert (existing) | v2.2.0 | v2.2.4 | No change needed |
| bats-support (existing) | v0.3.0 | v0.3.0 | No change needed |
| bats-file (existing) | v0.4.0 | v0.4.0 | No change needed |

---

## Sources

### HIGH Confidence (Official documentation, verified releases)
- [jq 1.8 Manual](https://jqlang.org/manual/) -- --arg, --argjson, --null-input, --raw-input documentation
- [jq 1.6 Manual](https://jqlang.github.io/jq/manual/v1.6/) -- Feature availability verification for minimum version
- [jq Download Page](https://jqlang.org/download/) -- Platform availability, installation methods
- [jq GitHub Releases](https://github.com/jqlang/jq/releases) -- Version history (1.8.1 released 2025-07-01)
- [Ubuntu Package: jq 1.6 on Jammy 22.04](https://ubuntu.pkgs.org/22.04/ubuntu-main-amd64/jq_1.6-2.1ubuntu3_amd64.deb.html) -- Minimum version on Ubuntu LTS
- [GitHub Actions Runner Images (Ubuntu 24.04)](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md) -- jq pre-installed
- [BATS-core Writing Tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- bats_pipe documentation
- [BATS-core v1.13.0 Release](https://github.com/bats-core/bats-core/releases/tag/v1.13.0) -- bats_pipe availability confirmed

### MEDIUM Confidence (Community patterns verified against official docs)
- [Baeldung: Build JSON String with Bash Variables](https://www.baeldung.com/linux/bash-variables-create-json-string) -- jq generation patterns
- [Baeldung: Parsing/Validating JSON in Shell](https://www.baeldung.com/linux/json-shell-parse-validate-print) -- Validation approaches compared
- [Cameron Nokes: Working with JSON in bash using jq](https://cameronnokes.com/blog/working-with-json-in-bash-using-jq/) -- --arg pattern examples

### Evaluated and Rejected
- [jc CLI tool](https://kellyjonbrazil.github.io/jc/) -- Python dependency, partial tool coverage
- [jo CLI tool (GitHub)](https://github.com/OrhanKupusoglu/jo-jq) -- Extra dependency, worse at multi-line output
