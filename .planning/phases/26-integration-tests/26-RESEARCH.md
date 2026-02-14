# Phase 26: Integration Tests - Research

**Researched:** 2026-02-14
**Domain:** BATS integration tests validating JSON output of all 46 use-case scripts
**Confidence:** HIGH

## Summary

Phase 26 adds BATS integration tests that exercise every one of the 46 use-case scripts with the `-j` flag and validate the JSON output is both parseable and structurally correct. The project already has a proven pattern for dynamic test registration and mock tool setup in `intg-cli-contracts.bats` (which dynamically discovers scripts, mocks missing tools, and registers per-script tests). Phase 26 follows this identical infrastructure pattern.

The key technical insight for testing is the fd3/stdout capture model. When a script runs with `-j`, `parse_common_args` executes `exec 3>&1; exec 1>&2`, redirecting all human-readable output to stderr and preserving original stdout as fd3 for JSON. The `json_finalize` function writes to fd3, which means original stdout carries ONLY the JSON envelope. In BATS, the capture pattern is simply: `run bash "$script" -j [args] 2>/dev/null`. The `$output` variable then contains only the JSON. This was experimentally verified with multiple script types (pure run_or_show, pure info+echo, mixed, mocked tools).

There are two test categories: (1) TEST-03: valid JSON -- every script's `-j` output passes `jq .` (46 tests), and (2) TEST-04: envelope structure -- the JSON contains required keys `meta.tool`, `meta.script`, `meta.timestamp`, `results`, `summary` (46 tests). These can be combined into a single test per script (92 assertions across 46 dynamically registered tests) or separated into two test functions per script (92 tests total). The single-test-per-script approach (with multiple jq assertions in each test) follows the existing `intg-cli-contracts.bats` pattern and is recommended.

**Primary recommendation:** Create a single new file `tests/intg-json-output.bats` using the same dynamic test registration pattern as `intg-cli-contracts.bats`. Reuse the existing mock tool and wordlist setup. Register one test per use-case script that validates both `jq .` parseability and envelope structure. Total: 46 dynamically registered integration tests + 2-3 static meta-tests = ~49 new tests.

## Standard Stack

### Core (Already Installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bats-core | 1.13.0 | Test runner | Already in use with 295 tests passing |
| bats-assert | latest (submodule) | Output assertions | assert_success, assert_output, assert_failure |
| bats-support | latest (submodule) | Base assertion support | Required by bats-assert |
| jq | >= 1.6 | JSON validation in tests | Already a hard dependency for `-j` mode |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none new) | -- | -- | No new dependencies |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dynamic test registration (`bats_test_function`) | Static `@test` per script | Dynamic automatically discovers new scripts; static requires manual updates when scripts are added/removed |
| `jq -e` for structure assertions | Bash string matching on JSON | jq handles whitespace, key ordering, null vs empty; string matching is fragile |
| One test file for all 46 scripts | One test file per tool directory | Single file matches existing pattern (intg-cli-contracts.bats covers all scripts); per-tool would scatter related tests |

**No new installation required.** All tools are already available.

## Architecture Patterns

### Recommended File Structure
```
tests/
  intg-json-output.bats    # NEW: Integration tests for JSON output (TEST-03, TEST-04)
  intg-cli-contracts.bats   # EXISTING: --help and -x contract tests (reference pattern)
  intg-script-headers.bats  # EXISTING: Header metadata tests (reference pattern)
  ... (existing files unchanged)
```

### Pattern 1: Dynamic Script Discovery for Use-Case Scripts Only

**What:** Discover the 46 use-case scripts dynamically (excluding lib/, diagnostics/, common.sh, check-tools.sh, examples.sh, check-docs-completeness.sh).

**When to use:** Test registration at file parse time.

**Example:**
```bash
# Source: Derived from intg-cli-contracts.bats _discover_all_scripts()
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Discover the 46 use-case scripts (exclude lib/, diagnostics/, examples, common, check-*)
_discover_json_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        -not -path '*/diagnostics/*' \
        -not -name 'check-tools.sh' \
        -not -name 'examples.sh' \
        | sort
}
```

### Pattern 2: Mock Tool + Wordlist Setup (Reuse from intg-cli-contracts.bats)

**What:** Create mock binaries for tools not installed on the test system; create dummy wordlist files.

**When to use:** setup_file() -- runs once before all tests in the file.

**Why reuse:** The existing `intg-cli-contracts.bats` has a proven setup_file() that mocks 18 tools and creates 3 wordlist files. The same infrastructure is needed here because use-case scripts call `require_cmd` before producing JSON output.

**Example:**
```bash
# Source: Adapted from intg-cli-contracts.bats setup_file()
setup_file() {
    MOCK_BIN="${BATS_FILE_TMPDIR}/mock-bin"
    mkdir -p "$MOCK_BIN"
    export MOCK_BIN

    # Mock binaries for tools not installed on this system
    local tools=(
        nmap tshark msfconsole msfvenom aircrack-ng hashcat skipfish
        sqlmap hping3 john nikto foremost dig curl nc traceroute mtr
        gobuster ffuf
    )
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            printf '#!/bin/sh\nexit 0\n' > "${MOCK_BIN}/${tool}"
            chmod +x "${MOCK_BIN}/${tool}"
        fi
    done

    # Create dummy wordlist files if missing
    local wordlist_dir="${PROJECT_ROOT}/wordlists"
    mkdir -p "$wordlist_dir"
    local wordlists=(common.txt subdomains-top1million-5000.txt rockyou.txt)
    for wl in "${wordlists[@]}"; do
        if [[ ! -f "${wordlist_dir}/${wl}" ]]; then
            echo "dummy" > "${wordlist_dir}/${wl}"
            echo "${wordlist_dir}/${wl}" >> "${BATS_FILE_TMPDIR}/created-wordlists"
        fi
    done
}

teardown_file() {
    if [[ -f "${BATS_FILE_TMPDIR}/created-wordlists" ]]; then
        while IFS= read -r wl; do
            rm -f "$wl"
        done < "${BATS_FILE_TMPDIR}/created-wordlists"
    fi
}

setup() {
    load 'test_helper/common-setup'
    _common_setup
    export PATH="${MOCK_BIN}:${PATH}"
}
```

### Pattern 3: JSON Output Capture in BATS

**What:** Capture the JSON envelope from a script's `-j` mode output using BATS `run`.

**When to use:** Every integration test.

**Key insight (experimentally verified 2026-02-14):** When `-j` is active, `parse_common_args` does `exec 3>&1; exec 1>&2`. This means:
- All human-readable output (info, echo, etc.) goes to stderr
- fd3 = original stdout
- `json_finalize` writes to fd3 = original stdout
- From the caller's perspective, **stdout contains ONLY the JSON envelope**

Therefore in BATS: `run bash "$script" -j [args] 2>/dev/null` captures JSON in `$output`.

**Example:**
```bash
_test_json_valid() {
    local script="$1"
    run bash "$script" -j dummy_target 2>/dev/null
    assert_success
    # TEST-04: Output passes jq . (valid JSON)
    echo "$output" | jq -e '.' > /dev/null
}
```

### Pattern 4: Envelope Structure Validation

**What:** Validate that the JSON envelope contains all required keys.

**Required keys (from phase description):** `meta.tool`, `meta.script`, `meta.timestamp` (mapped to `meta.started`), `results`, `summary`.

**Example:**
```bash
_test_json_structure() {
    local script="$1"
    run bash "$script" -j dummy_target 2>/dev/null
    assert_success
    # TEST-03: Valid JSON
    echo "$output" | jq -e '.' > /dev/null
    # TEST-04: Required envelope keys present
    echo "$output" | jq -e '.meta.tool' > /dev/null
    echo "$output" | jq -e '.meta.script' > /dev/null
    echo "$output" | jq -e '.meta.started' > /dev/null
    echo "$output" | jq -e '.results' > /dev/null
    echo "$output" | jq -e '.summary' > /dev/null
    # Additional structural assertions
    echo "$output" | jq -e '.meta.tool | type == "string"' > /dev/null
    echo "$output" | jq -e '.meta.tool | length > 0' > /dev/null
    echo "$output" | jq -e '.results | type == "array"' > /dev/null
    echo "$output" | jq -e '.summary.total | type == "number"' > /dev/null
}
```

### Pattern 5: Combined Test Function with Dynamic Registration

**What:** A single test function per script that validates both JSON validity and structure.

**Example:**
```bash
_test_json_output() {
    local script="$1"
    # Run script with -j flag, suppress stderr (human-readable output)
    run bash "$script" -j dummy_target 2>/dev/null
    assert_success

    # TEST-04: Passes jq . (valid JSON)
    echo "$output" | jq -e '.' > /dev/null

    # TEST-03: Envelope structure has required keys
    echo "$output" | jq -e '.meta.tool | length > 0' > /dev/null
    echo "$output" | jq -e '.meta.script | length > 0' > /dev/null
    echo "$output" | jq -e 'has("meta") and has("results") and has("summary")' > /dev/null
    echo "$output" | jq -e '.meta | has("tool") and has("script") and has("started")' > /dev/null
    echo "$output" | jq -e '.summary | has("total") and has("succeeded") and has("failed")' > /dev/null
    echo "$output" | jq -e '.results | type == "array"' > /dev/null
}

# Dynamic registration
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "JSON-01 ${local_path}: -j produces valid JSON with correct envelope" \
        -- _test_json_output "$script"
done < <(_discover_json_scripts)
```

### Pattern 6: Static Meta-Tests

**What:** Tests that verify the test infrastructure itself (discovery count, jq availability).

**Example:**
```bash
@test "JSON-META: discovery finds all 46 use-case scripts" {
    local count
    count=$(_discover_json_scripts | wc -l | tr -d ' ')
    assert_equal "$count" "46"
}

@test "JSON-META: jq is available for JSON validation" {
    run command -v jq
    assert_success
}
```

### Anti-Patterns to Avoid

- **Hardcoding script list:** Use dynamic discovery via `find`. Adding a new use-case script automatically includes it in tests. The existing `intg-cli-contracts.bats` proves this works.
- **Passing `-x` (execute mode) in integration tests:** The `-j` flag alone tests JSON output in show mode (safe, no commands actually run). Execute mode would try to run real commands against real targets. Show mode is sufficient for JSON validation.
- **Capturing stderr alongside stdout:** In JSON mode, stderr contains all human-readable output. Mixing it into `$output` would corrupt JSON. Always redirect stderr to /dev/null or a separate file.
- **Using `run --separate-stderr` for JSON capture:** Not needed. The `exec 3>&1; exec 1>&2` pattern in args.sh already separates JSON (stdout) from text (stderr). Simple `run ... 2>/dev/null` works.
- **Testing script-specific content (e.g., exact command strings):** Integration tests should validate structure and parseability, not content. Content correctness is the responsibility of the script author and code review. Testing that `results[0].command` equals a specific string makes tests brittle.
- **Skipping the `assert_success` check:** A script that exits non-zero due to a missing mock tool would produce no JSON. The `assert_success` catches this early.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Script discovery | Hardcoded list of 46 script paths | `find` with exclusion pattern (proven in intg-cli-contracts.bats) | Auto-discovers new scripts; no maintenance |
| Mock tool setup | Custom mock infrastructure | Copy/adapt setup_file() from intg-cli-contracts.bats | Already proven, handles 18 tools + 3 wordlists |
| JSON validation | Custom bash parsing of JSON | `jq -e` for validation, `jq -e 'expression'` for structure | jq handles escaping, types, nested keys correctly |
| Test registration | 46 static `@test` blocks | `bats_test_function` dynamic registration (proven in intg-cli-contracts.bats) | DRY, auto-discovers, single test function |
| Per-script target args | Complex logic for which scripts need targets | Pass `dummy_target` to all; scripts default if arg unused | All 46 scripts have default targets (no `require_target` calls) |

**Key insight:** The existing `intg-cli-contracts.bats` file is the direct blueprint. Its patterns (discovery, mocking, dynamic registration, setup_file/teardown_file) are exactly what Phase 26 needs. The only difference is the test function body: instead of testing `--help` or `-x`, it tests `-j` JSON output.

## Common Pitfalls

### Pitfall 1: Script Exits Non-Zero When Mock Tool Not Available

**What goes wrong:** A use-case script calls `require_cmd <tool>` which exits 1 if the tool is not found. If the mock binary is not in PATH, the script exits before json_finalize, producing no JSON output.
**Why it happens:** setup() prepends MOCK_BIN to PATH, but if a tool is missing from the mock list, require_cmd fails.
**How to avoid:** Ensure the mock tool list in setup_file() covers ALL 18 tools used by the 46 scripts. The list from intg-cli-contracts.bats is: nmap, tshark, msfconsole, msfvenom, aircrack-ng, hashcat, skipfish, sqlmap, hping3, john, nikto, foremost, dig, curl, nc, traceroute, mtr, gobuster, ffuf.
**Warning signs:** Tests fail with `assert_success` and `$output` is empty or contains "[ERROR] ... not found".

### Pitfall 2: Wordlist Files Missing

**What goes wrong:** Some scripts (gobuster, ffuf, hashcat) check for wordlist files at startup and exit if not found. No JSON is produced.
**Why it happens:** The scripts verify `wordlists/rockyou.txt` (or similar) exists before proceeding.
**How to avoid:** Create dummy wordlist files in setup_file(), just as intg-cli-contracts.bats does (common.txt, subdomains-top1million-5000.txt, rockyou.txt).
**Warning signs:** Tests fail only for gobuster/ffuf/hashcat scripts.

### Pitfall 3: Duplicate JSON on stdout

**What goes wrong:** If a script's `info` or `echo` calls somehow still reach stdout (instead of stderr), the `$output` contains non-JSON text before or after the JSON envelope, causing `jq .` to fail.
**Why it happens:** Some edge case where `exec 1>&2` didn't run (e.g., error during parse_common_args before the exec redirect).
**How to avoid:** This was verified NOT to be an issue for the 46 migrated scripts -- all of them go through parse_common_args which handles the redirect. If a new script is added incorrectly, the test will catch it (that's the point). No special handling needed.
**Warning signs:** `jq .` fails with "parse error: Expected separator between values".

### Pitfall 4: diagnose-latency.sh Requires sudo on macOS

**What goes wrong:** On macOS, `traceroute/diagnose-latency.sh` may behave differently because mtr requires sudo.
**Why it happens:** The script detects macOS and adjusts behavior.
**How to avoid:** This script is already mocked (mtr mock binary). With the mock, require_cmd passes and the script runs in show mode (no actual mtr execution). Verified that mock tool + JSON mode works. No special handling needed beyond the standard mock setup.
**Warning signs:** None expected (the mock handles this).

### Pitfall 5: BATS Timeout with 46 Scripts

**What goes wrong:** Running 46 scripts sequentially could be slow if each script takes significant time.
**Why it happens:** Each `run bash "$script" -j` spawns a subprocess, sources common.sh, runs through all 10 examples, and produces JSON.
**How to avoid:** This is unlikely to be an issue. Each script in show mode (no -x) only prints output and accumulates JSON -- there are no actual tool executions (tools are mocked anyway). Experimentally verified: a single script runs in < 500ms. 46 scripts should complete in under 30 seconds.
**Warning signs:** CI timeout (the GitHub Actions job has no explicit timeout, defaulting to 6 hours).

### Pitfall 6: JSON Output Contains Results from Mock Execution

**What goes wrong:** Mock tools return exit 0 with no output. In show mode, this is fine (json_add_example stores the command string). But if someone accidentally adds `-x`, mock tools would produce empty stdout/stderr in json_add_result.
**How to avoid:** Do NOT pass `-x` in integration tests. Only `-j` is needed. Show mode tests JSON structure without executing commands.
**Warning signs:** `results[].exit_code` appearing in show-mode output (indicates execute mode was used).

### Pitfall 7: Count Mismatch After Adding New Scripts

**What goes wrong:** If a new use-case script is added to the project (Phase 28+), the static meta-test that asserts `count == 46` would need updating.
**How to avoid:** Use `assert [ "$count" -ge 46 ]` instead of exact equality. This way, adding scripts doesn't break existing tests. The dynamic registration automatically includes new scripts.
**Warning signs:** Meta-test fails after adding new scripts.

## Code Examples

### Complete intg-json-output.bats File Structure

```bash
#!/usr/bin/env bats
# tests/intg-json-output.bats -- Integration tests for JSON output
# TEST-03: Every use-case script produces valid JSON with -j
# TEST-04: JSON output passes jq . and has correct envelope structure

# --- File-Level Setup (runs at parse time) ---
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Discover the 46 use-case scripts
_discover_json_scripts() {
    find "${PROJECT_ROOT}/scripts" -name '*.sh' \
        -not -path '*/lib/*' \
        -not -name 'common.sh' \
        -not -name 'check-docs-completeness.sh' \
        -not -path '*/diagnostics/*' \
        -not -name 'check-tools.sh' \
        -not -name 'examples.sh' \
        | sort
}

# --- Test Functions ---

# Combined TEST-03 + TEST-04: Valid JSON with correct envelope structure
_test_json_output() {
    local script="$1"
    # Capture JSON output (stdout); discard human-readable output (stderr)
    run bash "$script" -j dummy_target 2>/dev/null
    assert_success

    # TEST-04: Valid JSON (passes jq .)
    echo "$output" | jq -e '.' > /dev/null

    # TEST-03: Envelope has required top-level keys
    echo "$output" | jq -e 'has("meta") and has("results") and has("summary")' > /dev/null

    # TEST-03: meta has required fields
    echo "$output" | jq -e '.meta | has("tool") and has("script") and has("started")' > /dev/null
    echo "$output" | jq -e '.meta.tool | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.meta.script | type == "string" and length > 0' > /dev/null

    # TEST-03: results is an array
    echo "$output" | jq -e '.results | type == "array"' > /dev/null

    # TEST-03: summary has required fields
    echo "$output" | jq -e '.summary | has("total") and has("succeeded") and has("failed")' > /dev/null
    echo "$output" | jq -e '.summary.total | type == "number"' > /dev/null
}

# --- Dynamic Test Registration ---
while IFS= read -r script; do
    local_path="${script#"${PROJECT_ROOT}"/}"
    bats_test_function \
        --description "JSON-01 ${local_path}: -j produces valid JSON with correct envelope" \
        -- _test_json_output "$script"
done < <(_discover_json_scripts)

# --- Static Meta-Tests ---

@test "JSON-META: discovery finds at least 46 use-case scripts" {
    local count
    count=$(_discover_json_scripts | wc -l | tr -d ' ')
    assert [ "$count" -ge 46 ]
}

@test "JSON-META: jq is available for JSON validation" {
    run command -v jq
    assert_success
}

# --- File-Level Lifecycle ---

setup_file() {
    MOCK_BIN="${BATS_FILE_TMPDIR}/mock-bin"
    mkdir -p "$MOCK_BIN"
    export MOCK_BIN

    local tools=(
        nmap tshark msfconsole msfvenom aircrack-ng hashcat skipfish
        sqlmap hping3 john nikto foremost dig curl nc traceroute mtr
        gobuster ffuf
    )
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            printf '#!/bin/sh\nexit 0\n' > "${MOCK_BIN}/${tool}"
            chmod +x "${MOCK_BIN}/${tool}"
        fi
    done

    local wordlist_dir="${PROJECT_ROOT}/wordlists"
    mkdir -p "$wordlist_dir"
    local wordlists=(common.txt subdomains-top1million-5000.txt rockyou.txt)
    for wl in "${wordlists[@]}"; do
        if [[ ! -f "${wordlist_dir}/${wl}" ]]; then
            echo "dummy" > "${wordlist_dir}/${wl}"
            echo "${wordlist_dir}/${wl}" >> "${BATS_FILE_TMPDIR}/created-wordlists"
        fi
    done
}

teardown_file() {
    if [[ -f "${BATS_FILE_TMPDIR}/created-wordlists" ]]; then
        while IFS= read -r wl; do
            rm -f "$wl"
        done < "${BATS_FILE_TMPDIR}/created-wordlists"
    fi
}

setup() {
    load 'test_helper/common-setup'
    _common_setup
    export PATH="${MOCK_BIN}:${PATH}"
}
```

### jq Assertion Pattern (Verified)

```bash
# Source: Experimentally verified 2026-02-14
# Run any use-case script with -j; capture stdout; validate with jq -e
run bash "$script" -j dummy_target 2>/dev/null
assert_success

# jq -e exits non-zero if expression evaluates to false/null
echo "$output" | jq -e '.'                                          # Valid JSON
echo "$output" | jq -e '.meta.tool'                                 # Key exists
echo "$output" | jq -e '.meta.tool | type == "string"'              # Type check
echo "$output" | jq -e '.meta.tool | length > 0'                    # Non-empty
echo "$output" | jq -e 'has("meta") and has("results")'             # Multiple keys
echo "$output" | jq -e '.summary | has("total", "succeeded")'       # Nested keys
echo "$output" | jq -e '.results | type == "array"'                 # Array check
echo "$output" | jq -e '.summary.total >= 0'                        # Numeric check
```

### How fd3 Capture Works (Verified 2026-02-14)

```
Caller's perspective:
  stdout (fd1) -- receives JSON envelope (via fd3 -> original stdout path)
  stderr (fd2) -- receives human-readable output (info, echo, etc.)

Inside the script:
  1. parse_common_args sees -j
  2. exec 3>&1   -- saves original stdout as fd3
  3. exec 1>&2   -- redirects stdout to stderr (so echo/info go to stderr)
  4. Script runs: all echo/info go to stderr; run_or_show/json_add_example accumulate
  5. json_finalize writes to fd3 (= original stdout)

In BATS:
  run bash "$script" -j [args] 2>/dev/null
  # $output = only JSON from json_finalize (via fd3 -> original stdout)
  # stderr is discarded
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual JSON validation (run script, pipe to jq manually) | Automated BATS integration tests | Phase 26 | CI catches regressions automatically |
| Phase 25 verification: sampled 10 scripts manually | Phase 26: all 46 scripts tested programmatically | Phase 26 | 100% coverage vs ~22% sample |
| Static test registration per script | Dynamic `bats_test_function` discovery | Already established in intg-cli-contracts.bats | Zero maintenance when scripts are added/removed |

## Open Questions

1. **Should integration tests verify result count (e.g., exactly 10 results per script)?**
   - What we know: Most scripts have exactly 10 examples. Some have 11-12 (compare-routes.sh has 12, trace-network-path.sh has 11).
   - What's unclear: Whether enforcing count adds value vs. brittleness.
   - Recommendation: Do NOT enforce exact count. Validate `results | length > 0` (non-empty array). Exact count enforcement belongs in per-script unit tests, not integration tests. The integration test's job is "is it valid JSON with the right structure?" not "does it have the right number of examples?"

2. **Should the integration test also verify `meta.category` presence?**
   - What we know: All 46 scripts set category via json_set_meta's 3rd arg. The success criteria mention `meta.tool`, `meta.script`, `meta.timestamp`, `results`, `summary`.
   - What's unclear: Whether `meta.category` is a required key for the integration test.
   - Recommendation: Yes, include `meta.category` in the structure validation. It was added in Phase 25 and is present in all scripts. Add `has("category")` to the meta validation. However, it is not listed as a hard requirement in the success criteria, so it could be a soft check.

3. **Should the existing 295-test suite continue to pass without modification?**
   - What we know: Success criteria #3 says "All integration tests pass in CI alongside existing 265-test suite" (the count was 265 at the time of writing; it's now 295).
   - What's unclear: Whether the existing test count might change between now and Phase 26 implementation.
   - Recommendation: Run `bats tests/` after adding the new file to verify all tests pass together. The new file is additive -- it doesn't modify any existing test files.

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis of `tests/intg-cli-contracts.bats` -- dynamic test registration, mock setup, discovery patterns
- Direct codebase analysis of `tests/intg-script-headers.bats` -- simpler dynamic registration pattern
- Direct codebase analysis of `scripts/lib/json.sh` -- json_finalize fd3 output pattern
- Direct codebase analysis of `scripts/lib/args.sh` -- `exec 3>&1; exec 1>&2` fd redirect in parse_common_args
- Experimental verification (2026-02-14): Ran multiple scripts with `-j` flag, confirmed stdout-only JSON capture works via `output=$(bash script.sh -j 2>/dev/null)` with both real and mocked tools
- `.planning/phases/25-script-migration/25-VERIFICATION.md` -- Confirms all 46 scripts have json_set_meta + json_finalize + correct categories
- `.planning/phases/24-library-unit-tests/24-RESEARCH.md` -- fd3 conflict documentation and subprocess patterns
- `.github/workflows/tests.yml` -- CI configuration: `bats tests/` runs all .bats files in tests/ directory

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` -- TEST-03, TEST-04 requirement definitions
- `.planning/ROADMAP.md` -- Phase 26 success criteria

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools already in use; no new dependencies
- Architecture: HIGH -- all patterns directly derived from existing intg-cli-contracts.bats; JSON capture experimentally verified
- Pitfalls: HIGH -- identified from existing test infrastructure and experimental runs; mock tool coverage matches existing tests
- Code examples: HIGH -- test function verified to work with jq assertions on actual script output

**Research date:** 2026-02-14
**Valid until:** 2026-06-14 (stable domain; BATS and jq APIs are mature; script structure is settled post-Phase 25)
