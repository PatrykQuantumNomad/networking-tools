# Phase 23: JSON Library & Flag Integration - Research

**Researched:** 2026-02-13
**Domain:** Bash JSON library module + flag integration for 46 use-case scripts
**Confidence:** HIGH

## Summary

Phase 23 builds the core JSON infrastructure: a new `lib/json.sh` module with 4 public functions, modifications to 3 existing library files (`args.sh`, `output.sh`, `common.sh`), and the fd3 redirection strategy that keeps stdout clean for JSON while routing all human output to stderr. The design is well-specified in prior milestone research (`.planning/research/ARCHITECTURE.md`), but this phase-specific research identifies several corrections and refinements needed before planning.

The most important finding is a **critical discrepancy in the prior ARCHITECTURE.md research**: it assumed `-j` requires `-x` (and errors without it), but the finalized requirements (FLAG-03) and success criteria (#2) explicitly state that `-j` without `-x` must output example commands as JSON. This means `run_or_show()` needs a show+JSON code path, and the 21 scripts that use only `info`+`echo` (no `run_or_show`) need an accumulation strategy for show-mode JSON. The fd3 redirect approach remains correct but must activate for both `-j -x` AND `-j` alone.

The second finding is that 21 of 46 use-case scripts have **zero `run_or_show` calls** -- they use only bare `info()` + `echo "   command"` patterns. In show-mode JSON, these scripts will produce zero results through the `run_or_show` hook alone. The solution is to add a `json_add_example` function that `run_or_show` calls in show+JSON mode, and to add explicit `json_add_example` calls in scripts that use bare `echo` patterns (this is Phase 25 migration work, but the library function must exist in Phase 23).

**Primary recommendation:** Build `lib/json.sh` with 5 public functions (adding `json_add_example` to the 4 in ARCHITECTURE.md), modify `args.sh` to parse `-j` and activate fd3 redirect WITHOUT requiring `-x`, modify `run_or_show()` for both show+JSON and execute+JSON paths, and validate with a single representative script before handing off to Phase 24 testing and Phase 25 migration.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| jq | >= 1.6 (dev: 1.8.1) | JSON construction via `--arg`/`--argjson`, envelope assembly, RFC 8259 escaping | Only reliable way to produce guaranteed-valid JSON from bash. Handles all escaping edge cases. Ubiquitous across all target platforms. |
| bash | >= 4.0 | Script runtime (existing requirement) | Already enforced by `common.sh` version guard |
| BATS | 1.13.0 (existing) | Test framework | Already in place. `run --separate-stderr` and `bats_pipe` both available. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bats-assert | v2.2.0 (existing) | Test assertions | All BATS tests |
| bats-support | v0.3.0 (existing) | BATS helpers | All BATS tests |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| jq `--arg` | Pure bash `_json_escape()` | Handles 95% of cases but fails on control characters, binary data. jq is correct by construction. Pure bash was explicitly rejected in requirements. |
| jq `--arg` | `jo` CLI tool | Extra dependency. Worse at multi-line captured output. Less ubiquitous than jq. |
| jq `--arg` | Python/Node helpers | Violates bash-only constraint. Architectural inconsistency. |

**Installation:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Verify
jq --version    # Should show jq-1.6 or higher
```

No other installation needed. jq is pre-installed on GitHub Actions ubuntu-latest and macOS 15+.

## Architecture Patterns

### Module Load Order (Modified `common.sh`)

```
scripts/
  common.sh                    # Entry point - sources all lib modules
  lib/
    strict.sh                  # 1. set -eEuo pipefail + ERR trap
    colors.sh                  # 2. Color variables (NO_COLOR aware)
    logging.sh                 # 3. info/warn/error/debug/success
    validation.sh              # 4. require_cmd, require_target
    cleanup.sh                 # 5. EXIT trap, make_temp, retry
    json.sh                    # 6. NEW - JSON state, accumulation, finalize
    output.sh                  # 7. MODIFIED - run_or_show JSON branches
    args.sh                    # 8. MODIFIED - -j flag, fd3 redirect
    diagnostic.sh              # 9. Diagnostic report functions
    nc_detect.sh               # 10. Netcat variant detection
```

**json.sh at position 6 rationale:** Needs `cleanup.sh` (for `make_temp`). Must load before `output.sh` (which calls `json_add_result`/`json_add_example`). Must load before `args.sh` (which calls `_json_require_jq` and sets `JSON_MODE`). Does NOT depend on `logging.sh` -- uses plain `echo >&2` for its own error messages to avoid circular dependency.

### Pattern 1: fd3 Redirection for Clean Stdout

**What:** When `-j` is passed (with or without `-x`), save original stdout as fd3 and redirect fd1 to stderr.

**When:** Immediately after `parse_common_args` validates flags.

**Why:** Every existing `echo`, `info()`, `safety_banner()`, and bare `echo "   command"` line across all 46 scripts automatically goes to stderr. Only `json_finalize()` writes to fd3. Zero per-script changes for output suppression.

```bash
# In parse_common_args (args.sh), after flag parsing:
if [[ "${JSON_MODE:-0}" == "1" ]]; then
    _json_require_jq
    export NO_COLOR=1       # FLAG-05: disable colors
    exec 3>&1               # Save original stdout as fd3
    exec 1>&2               # Redirect all stdout to stderr
fi
```

**CRITICAL:** This activates for `-j` alone (show mode) AND `-j -x` (execute mode). The prior ARCHITECTURE.md incorrectly gated this on `-j -x` only.

### Pattern 2: Dual Show+JSON / Execute+JSON Paths in run_or_show

**What:** `run_or_show()` has 4 code paths: show+text (existing), execute+text (existing), show+JSON (new), execute+JSON (new).

```bash
run_or_show() {
    local description="$1"
    shift

    if [[ "${EXECUTE_MODE:-show}" == "execute" ]]; then
        if json_is_active; then
            # Execute+JSON: capture output, accumulate result
            local stdout_file stderr_file cmd_exit_code
            stdout_file=$(make_temp)
            stderr_file=$(make_temp)
            "$@" > "$stdout_file" 2> "$stderr_file" && cmd_exit_code=0 || cmd_exit_code=$?
            json_add_result "$description" "$cmd_exit_code" "$(<"$stdout_file")" "$(<"$stderr_file")" "$*"
        else
            # Execute+text: existing behavior (unchanged)
            info "$description"
            debug "Executing: $*"
            "$@"
            echo ""
        fi
    else
        if json_is_active; then
            # Show+JSON: accumulate example command
            json_add_example "$description" "$*"
        else
            # Show+text: existing behavior (unchanged)
            info "$description"
            echo "   $*"
            echo ""
        fi
    fi
}
```

### Pattern 3: Lazy jq Dependency

**What:** Check jq at module load (non-fatal). Enforce only when `-j` is parsed.

```bash
# In json.sh at load time:
_json_check_jq    # Sets _JSON_AVAILABLE flag, never exits

# In args.sh when -j flag parsed:
_json_require_jq  # Exits with install hint if jq missing
```

**Why:** 99% of invocations never use `-j`. Only fail when user explicitly requests JSON. (JSON-04)

### Pattern 4: Non-Zero Exit Capture (Strict Mode Safety)

**What:** Capture command exit codes without triggering `set -e`.

```bash
"$@" > "$stdout_file" 2> "$stderr_file" && cmd_exit_code=0 || cmd_exit_code=$?
```

**Why:** Security tools frequently exit non-zero (nmap finding no hosts, sqlmap finding no injection). The `&& 0 || $?` pattern captures the code without triggering ERR trap.

### Pattern 5: Source Guard Consistency

```bash
[[ -n "${_JSON_LOADED:-}" ]] && return 0
_JSON_LOADED=1
```

Matches all 9 existing lib modules.

### Anti-Patterns to Avoid

- **Manual JSON string construction:** Never use `echo`, `printf`, or `${}` substitution to build JSON. Always use `jq -n --arg`. (Anti-pattern from PITFALLS.md #1)
- **Per-script JSON templates:** All JSON construction lives in `lib/json.sh`. Scripts call `json_set_meta`/`json_add_example`/`json_finalize`. (Anti-pattern #2)
- **Modifying logging.sh for JSON mode:** The `exec 1>&2` redirect means logging functions automatically write to stderr. Zero changes to logging.sh. (Anti-pattern #5)
- **Pure-bash JSON fallback path:** No dual-engine approach. jq is a hard dependency when `-j` is used. (Anti-pattern #4 / Out of Scope decision)
- **Trailing comma stripping:** Use `jq -s '.'` to build arrays. Never build JSON strings with comma-separated concatenation. (Pitfall #4)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON string escaping | Custom `_json_escape()` with sed/bash | `jq -n --arg key "$value"` | jq handles all RFC 8259 escaping including control chars. Custom escaping misses edge cases. |
| JSON array assembly | Comma-delimited string concatenation | `printf '%s\n' "${array[@]}" \| jq -s '.'` | Trailing comma bugs, escaping interactions. jq slurp handles this correctly. |
| JSON envelope template | Per-script printf templates | Centralized `json_finalize()` in `lib/json.sh` | 46 copies would be unmaintainable. Schema changes require one edit. |
| Timestamp generation | `date -Iseconds` (GNU-only) | `date -u '+%Y-%m-%dT%H:%M:%SZ'` | macOS BSD date does not support `-I`. The portable format string works on both. |
| ANSI stripping from tool output | Manual sed regex | `NO_COLOR=1` environment variable | `colors.sh` already respects `NO_COLOR`. Set it in JSON mode. For tool output, tools may still emit ANSI but jq `--arg` handles escape characters correctly in the JSON string. |

**Key insight:** jq is the single tool that eliminates an entire category of bugs (escaping, type coercion, structural validity). Every "optimization" that avoids jq reintroduces those bugs.

## Common Pitfalls

### Pitfall 1: Prior Research Says -j Requires -x, Requirements Say Otherwise

**What goes wrong:** ARCHITECTURE.md (from milestone-level research) includes a validation block `if JSON_MODE=1 && EXECUTE_MODE != execute -> error + exit`. But requirements FLAG-03 and success criteria #2 explicitly require `-j` without `-x` to output example commands as JSON.

**Why it happens:** The architecture research was completed before requirements were finalized. The STACK.md research also had a variant: `-j auto-enables -x`.

**How to avoid:** Follow the REQUIREMENTS, not the prior architecture research. `-j` works in BOTH modes:
- `-j` alone (show mode): outputs example commands structured as JSON
- `-j -x` (execute mode): captures and structures real tool output

**Warning signs:** Planner creates tasks that validate `-j without -x -> error exit`.

### Pitfall 2: 21 Scripts Use Only info+echo, Not run_or_show

**What goes wrong:** The library hook in `run_or_show` only captures commands that go through `run_or_show`. But 21 of 46 scripts use only `info "N) Title"` + `echo "   command"` patterns with zero `run_or_show` calls.

**Why it happens:** Scripts that demonstrate commands requiring complex arguments, special file paths, or variable interpolation use bare echo instead of run_or_show. Examples: hashcat/crack-ntlm-hashes.sh, all 3 aircrack-ng scripts, all 3 foremost scripts, all 3 john scripts, 2 of 3 metasploit scripts.

**How to avoid:** Phase 23 must define a `json_add_example` function that scripts can call explicitly. Phase 25 (migration) will add these calls. For Phase 23, `run_or_show` calls `json_add_example` in show+JSON mode automatically, covering the 25 scripts that do use `run_or_show`.

**Warning signs:** After Phase 25, some scripts produce empty `results: []` arrays.

### Pitfall 3: fd3 Conflicts with BATS Testing

**What goes wrong:** BATS `run` command captures stdout/stderr. When the script uses `exec 3>&1 1>&2`, the fd3 output (the JSON) is NOT captured by `run`. The JSON goes to the test runner's stdout, not to `$output`.

**Why it happens:** BATS `run` only captures fd1 (stdout) and fd2 (stderr). fd3 is inherited from the parent process.

**How to avoid:** In BATS tests, use `run --separate-stderr` and capture fd3 output via redirection. Alternatively, test json.sh functions in isolation by sourcing the library and calling functions directly (without the fd3 redirect). The fd3 redirect is set up in `args.sh` by `parse_common_args`, so unit tests that call `json_add_result`/`json_finalize` directly can write to stdout normally.

**BATS testing approaches for Phase 24:**
1. **Unit tests:** Source `json.sh` directly, call functions, validate output on stdout (no fd3 involved)
2. **Integration tests:** Run scripts with `-j`, redirect fd3 to a temp file, validate the file content
3. **BATS `run --separate-stderr`:** Available in BATS 1.13.0. Captures stderr in `$stderr` variable.

**Warning signs:** BATS tests show `$output` as empty when running scripts with `-j`.

### Pitfall 4: NO_COLOR Must Be Set Before colors.sh Evaluates

**What goes wrong:** `colors.sh` checks `NO_COLOR` at source time (line 22). But `-j` is parsed in `args.sh`, which loads AFTER `colors.sh`. Setting `NO_COLOR=1` in `args.sh` does not retroactively disable colors already defined.

**How to avoid:** After setting `NO_COLOR=1` in the JSON activation block of `args.sh`, explicitly reset the color variables:
```bash
if [[ "${JSON_MODE:-0}" == "1" ]]; then
    export NO_COLOR=1
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
    # ... rest of JSON activation
fi
```

**Warning signs:** JSON mode output still contains ANSI escape codes in logged messages.

### Pitfall 5: confirm_execute Must Skip in JSON Mode (Both -j and -j -x)

**What goes wrong:** `confirm_execute()` in show mode returns immediately (first guard: `EXECUTE_MODE != execute -> return 0`). But in `-j -x` mode, it reaches the `[[ ! -t 0 ]]` check and exits because JSON consumers pipe stdin. The script exits with error before producing any JSON.

**How to avoid:** Add `json_is_active && return 0` as the second guard in `confirm_execute()`, before the `[[ ! -t 0 ]]` check. (FLAG-04)

```bash
confirm_execute() {
    local target="${1:-}"
    [[ "${EXECUTE_MODE:-show}" != "execute" ]] && return 0
    json_is_active && return 0    # NEW: skip in JSON mode
    # ... existing interactive logic
}
```

### Pitfall 6: safety_banner in JSON Mode

**What goes wrong:** `safety_banner()` writes colorized authorization warning to stdout. With fd3 redirect, it goes to stderr (harmless). But it adds visual noise for JSON consumers monitoring stderr.

**How to avoid:** Add `json_is_active && return 0` at the top of `safety_banner()`. Clean separation: JSON mode produces only JSON on stdout (fd3) and nothing on stderr except errors.

**Design decision note:** The architecture research proposed suppressing safety_banner in JSON mode. This aligns with FLAG-05 (suppress non-JSON output) but could be seen as removing a safety check. Resolution: the banner is informational, not a control -- suppressing it in JSON mode (which is for automation) is correct. Log a debug-level message to stderr instead.

## Code Examples

Verified patterns from prior research, corrected for `-j` working in both modes.

### json.sh Public API

```bash
# Source: .planning/research/ARCHITECTURE.md (corrected)

# Predicate: is JSON mode active?
json_is_active() {
    [[ "${JSON_MODE:-0}" == "1" ]]
}

# Set envelope metadata (called by each script after parse_common_args)
# Usage: json_set_meta "nmap" "$TARGET"
json_set_meta() {
    local tool="$1"
    local target="${2:-}"
    _JSON_TOOL="$tool"
    _JSON_TARGET="$target"
    _JSON_SCRIPT="$(basename "${BASH_SOURCE[1]}" .sh)"
    _JSON_STARTED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

# Add an execute-mode result (called by run_or_show in execute+JSON)
# Usage: json_add_result "description" exit_code "stdout" "stderr" "command_string"
json_add_result() {
    local description="$1"
    local exit_code="$2"
    local stdout="$3"
    local stderr="${4:-}"
    local command="${5:-}"

    local result
    result=$(jq -n \
        --arg desc "$description" \
        --argjson code "$exit_code" \
        --arg out "$stdout" \
        --arg err "$stderr" \
        --arg cmd "$command" \
        '{description: $desc, command: $cmd, exit_code: $code, stdout: $out, stderr: $err}')

    _JSON_RESULTS+=("$result")
}

# Add a show-mode example (called by run_or_show in show+JSON)
# Usage: json_add_example "description" "command_string"
json_add_example() {
    local description="$1"
    local command="$2"

    local example
    example=$(jq -n \
        --arg desc "$description" \
        --arg cmd "$command" \
        '{description: $desc, command: $cmd}')

    _JSON_RESULTS+=("$example")
}

# Emit the complete JSON envelope to fd3 (original stdout)
# Usage: json_is_active && json_finalize
json_finalize() {
    local finished
    finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local count=${#_JSON_RESULTS[@]}

    local results_json="[]"
    if ((count > 0)); then
        results_json=$(printf '%s\n' "${_JSON_RESULTS[@]}" | jq -s '.')
    fi

    local mode="show"
    [[ "${EXECUTE_MODE:-show}" == "execute" ]] && mode="execute"

    jq -n \
        --arg tool "$_JSON_TOOL" \
        --arg script "$_JSON_SCRIPT" \
        --arg target "$_JSON_TARGET" \
        --arg started "$_JSON_STARTED" \
        --arg finished "$finished" \
        --arg mode "$mode" \
        --argjson count "$count" \
        --argjson results "$results_json" \
        '{
            meta: {
                tool: $tool,
                script: $script,
                target: $target,
                started: $started,
                finished: $finished,
                mode: $mode
            },
            results: $results,
            summary: {
                total: $count,
                succeeded: (if $mode == "execute" then ($results | map(select(.exit_code == 0)) | length) else $count end),
                failed: (if $mode == "execute" then ($results | map(select(.exit_code != 0)) | length) else 0 end)
            }
        }' >&3
}
```

### Modified args.sh (-j flag handling)

```bash
# New case in parse_common_args while loop:
-j|--json)
    JSON_MODE=1
    ;;

# After the while loop (new activation block):
if [[ "${JSON_MODE:-0}" == "1" ]]; then
    _json_require_jq
    export NO_COLOR=1
    # Reset color vars since colors.sh already evaluated at source time
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
    exec 3>&1       # Save original stdout as fd3
    exec 1>&2       # Redirect all stdout to stderr
fi
```

### Per-Script Changes (Phase 25 preview)

```bash
# After TARGET assignment, before confirm_execute:
json_set_meta "nmap" "$TARGET"

# Last line of script:
json_is_active && json_finalize
```

### JSON Envelope (Show Mode)

```json
{
  "meta": {
    "tool": "nmap",
    "script": "discover-live-hosts",
    "target": "192.168.1.0/24",
    "started": "2026-02-13T14:30:00Z",
    "finished": "2026-02-13T14:30:00Z",
    "mode": "show"
  },
  "results": [
    {
      "description": "1) Basic ping sweep of a subnet",
      "command": "nmap -sn 192.168.1.0/24"
    },
    {
      "description": "2) ARP discovery on local network",
      "command": "nmap -sn -PR 192.168.1.0/24"
    }
  ],
  "summary": {
    "total": 10,
    "succeeded": 10,
    "failed": 0
  }
}
```

### JSON Envelope (Execute Mode)

```json
{
  "meta": {
    "tool": "nmap",
    "script": "discover-live-hosts",
    "target": "192.168.1.0/24",
    "started": "2026-02-13T14:30:00Z",
    "finished": "2026-02-13T14:30:45Z",
    "mode": "execute"
  },
  "results": [
    {
      "description": "1) Basic ping sweep of a subnet",
      "command": "nmap -sn 192.168.1.0/24",
      "exit_code": 0,
      "stdout": "Starting Nmap 7.94 ...\nHost 192.168.1.1 is up.\n...",
      "stderr": ""
    }
  ],
  "summary": {
    "total": 10,
    "succeeded": 9,
    "failed": 1
  }
}
```

## State of the Art

| Old Approach (Prior Research) | Current Approach (Corrected) | When Changed | Impact |
|-------------------------------|------------------------------|--------------|--------|
| `-j` requires `-x` (ARCHITECTURE.md line 69) | `-j` works alone (show mode JSON) and with `-x` (execute mode JSON) | After requirements finalization (FLAG-03, SC#2) | `run_or_show` needs show+JSON path. Need `json_add_example` function. |
| `-j` auto-enables `-x` (STACK.md line 129) | `-j` and `-x` are independent flags | After requirements finalization (FLAG-02, FLAG-03) | args.sh must NOT auto-set EXECUTE_MODE when `-j` is parsed |
| `json.sh` loads after `args.sh` at position 8 (STACK.md line 99) | `json.sh` loads at position 6, before output.sh and args.sh (ARCHITECTURE.md) | Architecture correction | json.sh functions available when output.sh and args.sh need them |
| Logging.sh needs JSON-aware stderr redirect (STACK.md) | Logging.sh needs zero changes (fd3 redirect handles it) | ARCHITECTURE.md insight | Simpler implementation, fewer files to modify |

**Deprecated/outdated from prior research:**
- ARCHITECTURE.md line 69: `-j without -x -> error + exit` -- CONTRADICTS FLAG-03 and success criteria #2
- ARCHITECTURE.md line 690: "tests for -j without -x rejection" -- wrong, should be "tests for -j without -x producing show-mode JSON"
- STACK.md line 129: `-j auto-enables -x` -- CONTRADICTS FLAG-03
- FEATURES.md "jq-first with printf fallback" -- Out of Scope decision says no pure-bash fallback

## Detailed Findings

### Finding 1: Script Pattern Analysis (21 vs 25 split)

**Scripts with `run_or_show` calls (25 scripts):**
These get show+JSON support automatically via the `run_or_show` library hook. Examples: nmap/discover-live-hosts.sh (10 calls), nikto/scan-specific-vulnerabilities.sh (10 calls), ffuf/fuzz-parameters.sh (10 calls).

**Scripts with zero `run_or_show` calls (21 scripts):**
These use only `info "N) Title"` + `echo "   command"` patterns. They will produce empty results arrays in JSON mode unless explicitly migrated. Full list:
- aircrack-ng: all 3 scripts (analyze-wireless-networks, capture-handshake, crack-wpa-handshake)
- curl: 2 of 3 (check-ssl-certificate, debug-http-response)
- dig: 1 of 3 (check-dns-propagation)
- foremost: all 3 (analyze-forensic-image, carve-specific-filetypes, recover-deleted-files)
- hashcat: 2 of 3 (crack-ntlm-hashes, crack-web-hashes)
- john: all 3 (crack-archive-passwords, crack-linux-passwords, identify-hash-type)
- metasploit: 2 of 3 (generate-reverse-shell, scan-network-services, but setup-listener uses 0 too)
- netcat: 2 of 3 (setup-listener, transfer-files)
- nikto: 1 of 3 (scan-multiple-hosts)
- tshark: 1 of 3 (extract-files-from-capture)

**Impact on Phase 23:** `json_add_example` must be a public function in `lib/json.sh`. Phase 25 migration will add explicit `json_add_example` calls to these 21 scripts.

**Impact on Phase 25:** These 21 scripts need ~10 additional lines each (replacing `info "N)"` + `echo "   cmd"` with `json_add_example` calls or wrapping in a helper).

### Finding 2: Mixed run_or_show + Bare Echo Scripts

Some scripts (e.g., sqlmap/dump-database.sh) use BOTH patterns: some commands via `run_or_show` (5 calls) and some via bare `info`+`echo` (5 commands). In JSON mode, only the `run_or_show` commands are captured. Phase 25 must convert the bare echo commands to `run_or_show` or add explicit `json_add_example` calls.

### Finding 3: BATS Testing fd3 Output

BATS 1.13.0 `run --separate-stderr` captures stderr in `$stderr` but does NOT capture fd3. To test JSON output in integration tests, two approaches:

**Approach A: Redirect fd3 inside the script invocation:**
```bash
@test "JSON output is valid" {
    run bash -c 'bash scripts/nmap/discover-live-hosts.sh -j localhost 3>&1 1>/dev/null'
    assert_success
    echo "$output" | jq . >/dev/null
}
```
Here `3>&1` sends fd3 to the shell's stdout (which BATS captures). `1>/dev/null` suppresses the redirected stderr-via-fd1.

**Approach B: Unit test json.sh functions directly (no fd3 involved):**
```bash
@test "json_finalize produces valid envelope" {
    source "${PROJECT_ROOT}/scripts/lib/json.sh"
    JSON_MODE=1
    json_set_meta "nmap" "localhost"
    json_add_example "1) Test" "nmap -sn localhost"
    # Call finalize writing to stdout (no fd3 redirect in unit test)
    run json_finalize_to_stdout  # internal test helper
    assert_success
    echo "$output" | jq . >/dev/null
}
```

**Recommendation:** Phase 24 should use Approach A for integration tests and Approach B for unit tests. Phase 23 should ensure `json_finalize` can write to fd3 when redirected or to stdout when fd3 is not set up (for testability).

### Finding 4: NO_COLOR Timing Issue

`colors.sh` evaluates `NO_COLOR` at source time (line 22). Since `args.sh` (where `-j` is parsed) loads AFTER `colors.sh`, setting `NO_COLOR=1` in args.sh does not retroactively clear the color variables. The JSON activation block in args.sh must explicitly reset `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `NC` to empty strings.

This is a new finding not covered in the prior research.

### Finding 5: json_finalize Writes to fd3 -- What If fd3 Is Not Open?

If a script calls `json_finalize` without the fd3 redirect being active (e.g., during testing, or if `json_is_active` returns true but `parse_common_args` was never called), the `>&3` write fails with "bad file descriptor."

**Recommendation:** `json_finalize` should check if fd3 is open. If not, write to stdout as fallback:
```bash
if { true >&3; } 2>/dev/null; then
    jq ... >&3
else
    jq ...    # Write to stdout (useful for testing)
fi
```

### Finding 6: Files Changed Summary

**New files:**
| File | Purpose | Est. Lines |
|------|---------|-----------|
| `scripts/lib/json.sh` | JSON module: 5 public functions, 2 internal, state variables | ~120 |

**Modified files:**
| File | What Changes | Est. Lines Changed |
|------|-------------|-------------------|
| `scripts/common.sh` | Add `source "${_LIB_DIR}/json.sh"` at position 6, update `@dependencies` header | +2 |
| `scripts/lib/args.sh` | Add `-j\|--json` case, JSON activation block (NO_COLOR, color reset, fd3 redirect), `JSON_MODE` initialization | +20 |
| `scripts/lib/output.sh` | Show+JSON branch in `run_or_show`, early return in `safety_banner`, early return in `confirm_execute` | +20, ~3 lines modified |

**NOT modified:**
| File | Why Not |
|------|---------|
| `scripts/lib/logging.sh` | fd3 redirect handles stderr routing automatically |
| `scripts/lib/strict.sh` | No interaction with JSON mode |
| `scripts/lib/colors.sh` | Color vars reset in args.sh activation block instead |
| `scripts/lib/cleanup.sh` | Only used (not modified) -- make_temp for output capture |
| `scripts/lib/validation.sh` | No interaction with JSON mode |
| `scripts/lib/diagnostic.sh` | Out of scope for Phase 23 |
| 46 use-case scripts | Phase 25 migration, not Phase 23 |

## Open Questions

1. **Should `json_add_example` also capture the description text between info/echo blocks?**
   - What we know: Scripts have educational context between examples (e.g., "Why does nmap show 'unknown'?"). This text is informational and not captured by `run_or_show`.
   - What's unclear: Should this educational text appear in JSON output? If so, as what field?
   - Recommendation: Do NOT capture educational text in Phase 23. The `description` field from `run_or_show` is sufficient. Educational text goes to stderr via fd redirect. Phase 25 can add an optional `context` field if needed.

2. **Should json_finalize register itself on the EXIT trap for guaranteed output?**
   - What we know: If a script exits early (error, signal), `json_finalize` may never be called. The JSON consumer gets nothing.
   - What's unclear: Should we emit partial JSON on abnormal exit? Or is "no output on error" acceptable?
   - Recommendation: Do NOT register on EXIT trap in Phase 23. A partial/empty JSON envelope on error is worse than no output. The `set -e` + ERR trap already provides error messages on stderr. Phase 25 can revisit if needed.

3. **How should `-j` interact with `-h` (help)?**
   - What we know: `-h` calls `show_help()` and exits. If `-j -h` is passed, should help be in JSON format?
   - Recommendation: No. `-h` always shows human-readable help and exits, regardless of `-j`. This matches `gh --help` behavior. The `-j` flag is only meaningful for the script's primary operation.

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis of all 9 lib modules (strict.sh through nc_detect.sh)
- Direct codebase analysis of 46 use-case scripts (run_or_show call counts verified)
- `.planning/research/ARCHITECTURE.md` -- Function signatures, fd3 strategy, module boundaries
- `.planning/research/STACK.md` -- jq version, platform availability, integration points
- `.planning/research/PITFALLS.md` -- 17 pitfalls catalogued with prevention strategies
- `.planning/research/FEATURES.md` -- Feature landscape, anti-features, envelope schema
- `.planning/REQUIREMENTS.md` -- JSON-01 through FLAG-05, success criteria
- `.planning/ROADMAP.md` -- Phase 23 scope and success criteria
- BATS 1.13.0 source: `tests/bats/lib/bats-core/test_functions.bash` -- `run --separate-stderr` confirmed
- jq 1.8.1 verified locally: `--arg` correctly escapes newlines, tabs, quotes, backslashes

### Secondary (MEDIUM confidence)
- `.planning/research/FEATURES.md` -- CLI tool JSON patterns (gh, kubectl, docker, ffuf)
- [jq official documentation](https://jqlang.org/manual/) -- `--arg`/`--argjson`/`-n`/`-s` flags
- [BATS writing-tests docs](https://bats-core.readthedocs.io/en/stable/writing-tests.html) -- bats_pipe, run --separate-stderr

### Discrepancies Identified
- ARCHITECTURE.md line 69 vs REQUIREMENTS FLAG-03: `-j without -x` behavior (REQUIREMENTS win)
- STACK.md line 129 vs REQUIREMENTS FLAG-02/FLAG-03: `-j auto-enables -x` (REQUIREMENTS win)
- STACK.md load order (json.sh after args.sh) vs ARCHITECTURE.md (json.sh before output.sh and args.sh): ARCHITECTURE.md is correct for dependency reasons

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- jq verified locally, platform availability confirmed
- Architecture: HIGH -- Based on line-by-line analysis of all lib modules and 8+ representative scripts, corrected against finalized requirements
- Pitfalls: HIGH -- 6 pitfalls identified specific to Phase 23 scope, plus awareness of 17 domain pitfalls from prior research
- Code examples: MEDIUM -- Function signatures verified against requirements but not yet executed as a complete system

**Research date:** 2026-02-13
**Valid until:** 2026-03-13 (stable domain, bash/jq do not change fast)
