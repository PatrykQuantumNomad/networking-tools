# Phase 25: Script Migration - Research

**Researched:** 2026-02-13
**Domain:** Migrating 46 use-case scripts to produce structured JSON output via `-j` flag
**Confidence:** HIGH

## Summary

Phase 25 migrates all 46 use-case scripts to support the JSON output infrastructure built in Phase 23 (lib/json.sh, args.sh, output.sh). Each script needs two additions: a `json_set_meta` call near the top (after target assignment) and a `json_finalize` call at the bottom (before the interactive demo block). For the 25 scripts that use `run_or_show`, this is sufficient -- the library hook in `run_or_show` already captures commands as JSON results automatically. For the 21 scripts that use bare `info`+`echo` patterns (or the mixed scripts that have some examples outside `run_or_show`), those bare examples need explicit `json_add_example` calls to appear in the JSON output.

There is a key gap between the requirements and the current API: SCRIPT-04 requires a "category" field in meta, but `json_set_meta` currently only accepts "tool" and "target" (with "script" auto-derived from `BASH_SOURCE`). The function signature must be extended to accept a category parameter, and `json_finalize` must include it in the envelope. This is a small library change (3-5 lines) that should be done as part of this phase.

The migration is highly mechanical and repetitive -- the same pattern applied 46 times with per-script variations only in the tool name, category, target variable name, and which bare `info`+`echo` blocks need `json_add_example` conversion. This makes it ideal for batch execution with strong verification (run each script with `-j`, pipe through `jq .`, validate envelope fields).

**Primary recommendation:** Extend `json_set_meta` to accept a third "category" parameter, then migrate all 46 scripts in batches grouped by tool (17 tools, 1-3 scripts each). Apply the `json_set_meta`/`json_finalize` boilerplate to every script, and convert bare `info`+`echo` patterns to `json_add_example` calls in the 21 pure-echo scripts plus the mixed-pattern examples in 14 additional scripts.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| lib/json.sh | current (Phase 23) | JSON state, accumulation, finalization | Already built. Provides json_set_meta, json_add_example, json_add_result, json_finalize |
| lib/args.sh | current (Phase 23) | `-j` flag parsing, fd3 redirect | Already built. parse_common_args handles -j activation |
| lib/output.sh | current (Phase 23) | run_or_show with 4 JSON/text code paths | Already built. Automatic JSON accumulation for run_or_show calls |
| jq | >= 1.6 | JSON construction via `--arg`/`--argjson` | Hard dependency when -j is used. Already enforced by _json_require_jq |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BATS | 1.13.0 (existing) | Test verification | Phase 26 integration tests validate migrated scripts |
| bats-assert | v2.2.0 (existing) | Test assertions | Validating JSON output structure |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-script json_add_example calls | A wrapper function that auto-captures info+echo pairs | Would require modifying logging.sh or creating a new helper. More complex, less explicit, harder to debug. Direct calls are clear and consistent. |
| Manual category strings per script | Auto-derive category from tool directory name | Not reliable -- tool names don't map cleanly to categories (e.g., "dig" is "dns-recon" not "dig"). Explicit is better. |
| Extending json_set_meta with category | Separate json_set_category function | Extra API surface for a single string. Better to extend the existing function. |

## Architecture Patterns

### Pattern 1: Minimal Per-Script Changes (json_set_meta + json_finalize)

**What:** Every script gets exactly 2 new lines (plus any info+echo conversions).

**When to use:** All 46 scripts.

**Example (script using run_or_show -- e.g., nmap/discover-live-hosts.sh):**

```bash
# EXISTING: parse_common_args, require_cmd, TARGET assignment
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"
require_cmd nmap "brew install nmap"
TARGET="${1:-localhost}"

# NEW LINE 1: Set JSON metadata (after TARGET, before confirm_execute)
json_set_meta "nmap" "$TARGET" "network-scanner"

confirm_execute "${1:-}"
safety_banner

# ... existing run_or_show calls (automatically captured by library) ...

# NEW LINE 2: Finalize JSON output (before interactive demo block)
json_finalize

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    # ... interactive demo ...
fi
```

**Why this placement:**
- `json_set_meta` goes after TARGET assignment (needs the target value) and before `confirm_execute` (which checks json_is_active)
- `json_finalize` goes before the interactive demo block because the demo block exits early on non-interactive terminals (`[[ ! -t 0 ]] && exit 0`), and JSON consumers are non-interactive. If finalize were after the demo block, the JSON would never be emitted.

### Pattern 2: Converting Bare info+echo to json_add_example

**What:** For scripts (or individual examples within scripts) that use `info "N) Title"` + `echo "   command"` instead of `run_or_show`, add a parallel `json_add_example` call.

**When to use:** 21 pure info+echo scripts and ~35 individual examples across 14 mixed scripts.

**Example (before -- hashcat/crack-ntlm-hashes.sh):**

```bash
# 1. Dictionary attack on NTLM hashes
info "1) Dictionary attack on NTLM hashes"
echo "   hashcat -m 1000 -a 0 ${HFILE} ${WORDLIST}"
echo ""
```

**Example (after):**

```bash
# 1. Dictionary attack on NTLM hashes
run_or_show "1) Dictionary attack on NTLM hashes" \
    hashcat -m 1000 -a 0 "$HFILE" "$WORDLIST"
```

**Alternative approach (if run_or_show conversion is not appropriate):**

Some scripts have commands that include shell pipelines, multiple commands, or complex quoting that cannot be passed to `run_or_show` because it executes `"$@"` directly. For these, use explicit `json_add_example`:

```bash
# 1. Dictionary attack on NTLM hashes
info "1) Dictionary attack on NTLM hashes"
echo "   hashcat -m 1000 -a 0 ${HFILE} ${WORDLIST}"
json_add_example "1) Dictionary attack on NTLM hashes" "hashcat -m 1000 -a 0 ${HFILE} ${WORDLIST}"
echo ""
```

The `json_add_example` call is a no-op when JSON mode is inactive (the function guards with `json_is_active || return 0`), so it has zero cost in normal text mode.

### Pattern 3: Extended json_set_meta API

**What:** Extend `json_set_meta` to accept a third parameter for category, and include category in the JSON envelope.

**Current signature:** `json_set_meta "tool" "target"` (2 args)
**New signature:** `json_set_meta "tool" "target" "category"` (3 args, category optional for backward compatibility)

**Library change in json.sh:**

```bash
json_set_meta() {
    json_is_active || return 0
    _JSON_TOOL="$1"
    _JSON_TARGET="${2:-}"
    _JSON_CATEGORY="${3:-}"     # NEW
    _JSON_SCRIPT="$(basename "${BASH_SOURCE[1]:-unknown}" .sh)"
    _JSON_STARTED="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
```

**Envelope change in json_finalize:** Add `--arg category "$_JSON_CATEGORY"` to the jq call and `category: $category` to the meta object.

### Pattern 4: Category Mapping

**What:** Each tool maps to one of 6 categories. All scripts under a tool share the same category.

| Category | Tools | Script Count |
|----------|-------|-------------|
| `network-scanner` | nmap, netcat, hping3 | 8 |
| `web-scanner` | nikto, skipfish, gobuster, ffuf | 8 |
| `sql-injection` | sqlmap | 3 |
| `password-cracker` | hashcat, john | 6 |
| `network-analysis` | tshark, traceroute, dig, curl | 12 |
| `exploitation` | metasploit, aircrack-ng | 6 |
| `forensics` | foremost | 3 |

**Note:** The FEATURES.md research defined 6 categories: "network-scanner", "web-scanner", "password-cracker", "network-analysis", "exploitation", "diagnostic". Since diagnostic scripts (under `scripts/diagnostics/`) are not part of the 46 use-case scripts, the "diagnostic" category is not needed for Phase 25. I add "forensics" for foremost and "sql-injection" for sqlmap (which doesn't fit cleanly into "web-scanner" since it's specifically SQL injection).

### Pattern 5: Handling Scripts with Conditional/Dynamic Commands

**What:** Some scripts have commands that vary based on runtime detection (e.g., netcat variant detection).

**Example (netcat/setup-listener.sh):**

```bash
info "1) Basic listener on port ${PORT}"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l ${PORT}"
else
    echo "   nc -l -p ${PORT}"
fi
echo ""
```

**Solution:** Call `json_add_example` inside each branch:

```bash
info "1) Basic listener on port ${PORT}"
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    echo "   nc -l ${PORT}"
    json_add_example "1) Basic listener on port ${PORT}" "nc -l ${PORT}"
else
    echo "   nc -l -p ${PORT}"
    json_add_example "1) Basic listener on port ${PORT}" "nc -l -p ${PORT}"
fi
echo ""
```

Or refactor to use a variable:

```bash
if [[ "$NC_VARIANT" == "openbsd" ]]; then
    CMD="nc -l ${PORT}"
else
    CMD="nc -l -p ${PORT}"
fi
info "1) Basic listener on port ${PORT}"
echo "   ${CMD}"
json_add_example "1) Basic listener on port ${PORT}" "$CMD"
echo ""
```

### Anti-Patterns to Avoid

- **Placing json_finalize after the interactive demo block:** The demo block contains `[[ ! -t 0 ]] && exit 0` which exits before json_finalize would run. Always finalize before the demo.
- **Forgetting json_add_example for bare info+echo commands:** Results in incomplete JSON output -- some examples missing from the results array. Phase 26 integration tests will catch this.
- **Using run_or_show for commands with shell metacharacters:** `run_or_show` passes args via `"$@"` which does NOT do shell expansion. Commands like `hashcat -m 1000 -a 0 ${HFILE} wordlist.txt -r /usr/share/hashcat/rules/best64.rule` would try to execute with the literal `${HFILE}` if HFILE is empty. Use `json_add_example` for display-only commands with placeholder variables.
- **Passing different descriptions to info() and json_add_example():** The descriptions should match exactly for consistency.
- **Modifying the interactive demo block for JSON mode:** The demo block is already naturally suppressed in JSON mode via `[[ ! -t 0 ]]` (non-interactive) and `confirm_execute` (which returns early in JSON mode). No changes needed to demo blocks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Category string per script | Hardcoded strings scattered across scripts | Centralized category map or constant in json.sh | Typos, inconsistency. A constant ensures valid values. |
| JSON output for bare echo commands | Custom wrapper around info+echo | `json_add_example` (already exists) | Library function handles escaping, array accumulation, no-op when inactive |
| Suppressing interactive demos in JSON mode | Per-script `json_is_active && exit 0` checks | Existing `[[ ! -t 0 ]] && exit 0` pattern | Already works because JSON consumers are non-interactive. Finalize before demo. |
| Converting all info+echo to run_or_show | Rewriting every script's display logic | Keep info+echo for display, add parallel json_add_example | Some commands have complex quoting, pipelines, or placeholders that cannot be passed to run_or_show for execution |

**Key insight:** The migration is additive -- existing behavior is preserved unchanged. Each script gets 2 new lines (json_set_meta, json_finalize) plus json_add_example calls for any bare info+echo commands. No existing lines are removed or modified (except in the case of converting info+echo to run_or_show where appropriate).

## Common Pitfalls

### Pitfall 1: json_finalize After Interactive Demo Exit

**What goes wrong:** Script exits at `[[ ! -t 0 ]] && exit 0` in the interactive demo block, and json_finalize is never called. JSON consumers get no output.
**Why it happens:** The demo block is typically the last section of each script. If json_finalize is placed after it, it never runs in non-interactive mode.
**How to avoid:** Always place `json_finalize` BEFORE the interactive demo block. The demo block is a no-op in JSON mode anyway.
**Warning signs:** Scripts produce no JSON output when run with `-j` in a pipeline.

### Pitfall 2: Missing json_add_example for Mixed Scripts

**What goes wrong:** A script has 10 examples -- 6 via `run_or_show` (captured automatically) and 4 via bare `info`+`echo` (not captured). JSON output shows only 6 results instead of 10.
**Why it happens:** The `run_or_show` library hook only captures commands that go through `run_or_show`. Bare `info`+`echo` patterns are invisible to the JSON system.
**How to avoid:** Audit every numbered example in each script. Any example that uses bare `info`+`echo` needs an explicit `json_add_example` call.
**Warning signs:** JSON output `summary.total` is less than the expected number of examples (typically 10 per script).

**Mixed scripts requiring attention (14 scripts, ~35 bare examples total):**

| Script | run_or_show | bare info+echo | Total |
|--------|-------------|----------------|-------|
| nmap/identify-ports.sh | 4 | 6 | 10 |
| sqlmap/dump-database.sh | 5 | 5 | 10 |
| curl/test-http-endpoints.sh | 2 | 8 | 10 |
| dig/attempt-zone-transfer.sh | 3 | 7 | 10 |
| gobuster/discover-directories.sh | 8 | 2 | 10 |
| gobuster/enumerate-subdomains.sh | 7 | 3 | 10 |
| nikto/scan-with-auth.sh | 6 | 4 | 10 |
| netcat/scan-ports.sh | 7 | 3 | 10 |
| tshark/analyze-dns-queries.sh | 7 | 3 | 10 |
| tshark/capture-http-credentials.sh | 8 | 2 | 10 |
| traceroute/compare-routes.sh | 8 | 4 | 12 |
| hashcat/benchmark-gpu.sh | 9 | 1 | 10 |
| hping3/detect-firewall.sh | 9 | 1 | 10 |
| hping3/test-firewall-rules.sh | 9 | 1 | 10 |

### Pitfall 3: Incorrect Category String

**What goes wrong:** Typo in category string (e.g., "network_scanner" instead of "network-scanner"). Downstream consumers can't filter or group by category.
**Why it happens:** Category is a free-form string with no validation.
**How to avoid:** Define category constants or validate in json_set_meta. At minimum, use the exact strings from the category table in this document and verify via grep across all scripts after migration.
**Warning signs:** `grep -r 'json_set_meta' scripts/ | awk -F'"' '{print $6}' | sort -u` shows unexpected values.

### Pitfall 4: json_set_meta Placement Before TARGET Assignment

**What goes wrong:** `json_set_meta "nmap" "$TARGET"` is called before `TARGET` is assigned, resulting in empty target in JSON output.
**Why it happens:** The boilerplate is inserted mechanically without checking variable flow.
**How to avoid:** Always place `json_set_meta` AFTER the `TARGET=` assignment line. Pattern: parse_common_args -> require_cmd -> TARGET= -> json_set_meta -> confirm_execute -> safety_banner.
**Warning signs:** JSON output shows `meta.target = ""` when a target was provided.

### Pitfall 5: Scripts Where TARGET Has a Non-Standard Name

**What goes wrong:** Some scripts use different variable names for the target (e.g., `HASHFILE`, `INTERFACE`, `PORT`, `LHOST`, `HASH`, `URL`).
**Why it happens:** Each script has domain-specific parameter semantics. "target" is context-dependent.
**How to avoid:** Pass the appropriate variable to json_set_meta. The "target" field is informational metadata, so passing the primary parameter is correct regardless of its name.

**Non-standard target variables:**

| Script | Primary Variable | json_set_meta Target |
|--------|-----------------|---------------------|
| hashcat/crack-ntlm-hashes.sh | HASHFILE | "$HASHFILE" |
| hashcat/benchmark-gpu.sh | (none) | "" |
| john/identify-hash-type.sh | HASH | "$HASH" |
| john/crack-linux-passwords.sh | SHADOW_FILE | "$SHADOW_FILE" (or similar) |
| netcat/setup-listener.sh | PORT | "$PORT" |
| aircrack-ng/capture-handshake.sh | INTERFACE | "$INTERFACE" |
| metasploit/generate-reverse-shell.sh | LHOST + LPORT | "$LHOST" |
| tshark/capture-http-credentials.sh | TARGET (interface name) | "$TARGET" |
| foremost/recover-deleted-files.sh | TARGET (image file) | "$TARGET" |

### Pitfall 6: The json_set_meta API Needs Category (SCRIPT-04 Gap)

**What goes wrong:** SCRIPT-04 requires "correct tool name, script name, and category in meta." The current `json_set_meta` only takes "tool" and "target" -- there is no category parameter.
**Why it happens:** Phase 23 built the API based on the Phase 23 scope. Category was deferred.
**How to avoid:** Extend `json_set_meta` to accept a third parameter and add `_JSON_CATEGORY` to the envelope. This is a small library change (5 lines in json.sh, 2 lines in json_finalize) that must happen at the start of Phase 25 before script migration begins.
**Warning signs:** JSON output has no "category" field in meta despite SCRIPT-04 requirement.

### Pitfall 7: Existing BATS Tests Must Still Pass After Library Changes

**What goes wrong:** Extending json_set_meta with a third parameter changes the function signature. Existing Phase 24 tests call json_set_meta with 2 args. If the third arg is required, tests break.
**Why it happens:** API change without backward compatibility.
**How to avoid:** Make the third parameter optional with a default: `_JSON_CATEGORY="${3:-}"`. Existing tests that call `json_set_meta "tool" "target"` continue to work, producing an empty category.
**Warning signs:** `bats tests/lib-json.bats` fails after library changes.

## Code Examples

Verified patterns from the current codebase and library API.

### Complete Migration Example: Pure run_or_show Script (dig/query-dns-records.sh)

```bash
# This script has 10 run_or_show calls and 0 bare info+echo examples.
# Only 2 new lines needed.

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"
require_cmd dig "..."
TARGET="${1:-example.com}"

json_set_meta "dig" "$TARGET" "network-analysis"    # NEW

confirm_execute "${1:-}"
safety_banner

# ... all 10 run_or_show calls (no changes needed) ...

json_finalize                                        # NEW

# Interactive demo (no changes needed)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    # ...
fi
```

### Complete Migration Example: Pure info+echo Script (hashcat/crack-ntlm-hashes.sh)

```bash
# This script has 0 run_or_show calls and 10 bare info+echo examples.
# Needs 2 boilerplate lines + 10 json_add_example calls.

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"
require_cmd hashcat "brew install hashcat"
HASHFILE="${1:-}"

json_set_meta "hashcat" "$HASHFILE" "password-cracker"    # NEW

confirm_execute
safety_banner

# 1. Dictionary attack on NTLM hashes
info "1) Dictionary attack on NTLM hashes"
echo "   hashcat -m 1000 -a 0 ${HFILE} ${WORDLIST}"
json_add_example "1) Dictionary attack on NTLM hashes" "hashcat -m 1000 -a 0 ${HFILE} ${WORDLIST}"    # NEW
echo ""

# ... repeat for examples 2-10 ...

json_finalize                                              # NEW

# Interactive demo (no changes needed)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0
    # ...
fi
```

### Complete Migration Example: Mixed Script (nmap/identify-ports.sh)

```bash
# This script has 4 run_or_show calls and 6 bare info+echo examples.
# Needs 2 boilerplate lines + 6 json_add_example calls.

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"
TARGET="${1:-localhost}"

json_set_meta "nmap" "$TARGET" "network-scanner"    # NEW

confirm_execute "${1:-}"

# ... educational context (no changes) ...

# 1. Local process lookup (bare info+echo -- needs json_add_example)
info "1) Identify which process owns a specific port"
echo "   lsof -i :8080 -P -n"
json_add_example "1) Identify which process owns a specific port" "lsof -i :8080 -P -n"    # NEW
echo ""

# ... examples 2-5 similar (bare info+echo, add json_add_example) ...

# 6. Nmap service version detection (run_or_show -- no changes needed)
run_or_show "6) Nmap service probing (remote -- works on any target)" \
    nmap -sV "$TARGET"

# ... examples 7-9 similar (run_or_show, no changes needed) ...

# 10. Combined workflow (bare info+echo -- needs json_add_example)
info "10) Full workflow: scan then identify"
echo "    sudo nmap -sV -p- ${TARGET} -oG - | grep open"
echo "    lsof -i -P -n | grep LISTEN"
json_add_example "10) Full workflow: scan then identify" "sudo nmap -sV -p- ${TARGET} -oG - | grep open && lsof -i -P -n | grep LISTEN"    # NEW
echo ""

json_finalize                                        # NEW

# Interactive demo (no changes needed)
```

### Library Change: Extend json_set_meta for Category

```bash
# In scripts/lib/json.sh

# State variable (add alongside existing ones)
_JSON_CATEGORY=""

# Updated json_set_meta
json_set_meta() {
    json_is_active || return 0
    _JSON_TOOL="$1"
    _JSON_TARGET="${2:-}"
    _JSON_CATEGORY="${3:-}"     # NEW: optional category parameter
    _JSON_SCRIPT="$(basename "${BASH_SOURCE[1]:-unknown}" .sh)"
    _JSON_STARTED="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}

# Updated json_finalize (add category to envelope)
json_finalize() {
    json_is_active || return 0
    # ... existing code ...

    envelope=$(jq -n \
        --arg tool "$_JSON_TOOL" \
        --arg script "$_JSON_SCRIPT" \
        --arg target "$_JSON_TARGET" \
        --arg category "$_JSON_CATEGORY" \
        --arg started "$_JSON_STARTED" \
        --arg finished "$finished" \
        --arg mode "$mode" \
        --argjson results "$results_json" \
        --argjson count "$count" \
        '{
            meta: {
                tool: $tool,
                script: $script,
                target: $target,
                category: $category,
                started: $started,
                finished: $finished,
                mode: $mode
            },
            results: $results,
            summary: {
                total: $count,
                succeeded: (if $mode == "execute" then ([$results[] | select(.exit_code == 0)] | length) else $count end),
                failed: (if $mode == "execute" then ([$results[] | select(.exit_code != 0)] | length) else 0 end)
            }
        }')

    # ... existing fd3 output logic ...
}
```

### Verification Command (Per-Script)

```bash
# Verify a single script produces valid JSON with correct meta fields
bash scripts/nmap/discover-live-hosts.sh -j localhost 3>&1 1>/dev/null 2>/dev/null | jq -e '
    .meta.tool == "nmap" and
    .meta.script == "discover-live-hosts" and
    .meta.category == "network-scanner" and
    .meta.target == "localhost" and
    (.results | length) == 10 and
    .summary.total == 10
'
```

### Batch Verification Command (All 46 Scripts)

```bash
# Quick validation: every script produces valid JSON
PASS=0 FAIL=0
for script in scripts/*/!(examples).sh; do
    [[ "$(basename "$script")" =~ ^(common|check-tools|check-docs)\.sh$ ]] && continue
    [[ "$script" =~ /lib/ ]] && continue
    [[ "$script" =~ /diagnostics/ ]] && continue
    if bash "$script" -j 3>&1 1>/dev/null 2>/dev/null | jq -e '.' >/dev/null 2>&1; then
        ((PASS++))
    else
        echo "FAIL: $script"
        ((FAIL++))
    fi
done
echo "Passed: $PASS  Failed: $FAIL"
```

## Script Inventory

### Complete List: 46 Use-Case Scripts with Migration Details

#### Group A: Pure run_or_show Scripts (11 scripts -- need only json_set_meta + json_finalize)

| Script | Tool | Category | run_or_show | bare info+echo |
|--------|------|----------|-------------|----------------|
| dig/query-dns-records.sh | dig | network-analysis | 10 | 0 |
| ffuf/fuzz-parameters.sh | ffuf | web-scanner | 10 | 0 |
| nmap/discover-live-hosts.sh | nmap | network-scanner | 10 | 0 |
| nmap/scan-web-vulnerabilities.sh | nmap | network-scanner | 10 | 0 |
| nikto/scan-specific-vulnerabilities.sh | nikto | web-scanner | 10 | 0 |
| skipfish/quick-scan-web-app.sh | skipfish | web-scanner | 9 | 1 |
| skipfish/scan-authenticated-app.sh | skipfish | web-scanner | 9 | 1 |
| sqlmap/bypass-waf.sh | sqlmap | sql-injection | 9 | 1 |
| sqlmap/test-all-parameters.sh | sqlmap | sql-injection | 9 | 1 |
| traceroute/diagnose-latency.sh | traceroute | network-analysis | 9 | 1 |
| traceroute/trace-network-path.sh | traceroute | network-analysis | 11 | 1 |

*Note: Scripts with 1 bare info+echo are included here because the single bare example is minor and could be handled quickly.*

#### Group B: Mixed run_or_show + info+echo Scripts (14 scripts -- need json_set_meta + json_finalize + json_add_example for bare examples)

| Script | Tool | Category | run_or_show | bare info+echo |
|--------|------|----------|-------------|----------------|
| curl/test-http-endpoints.sh | curl | network-analysis | 2 | 8 |
| dig/attempt-zone-transfer.sh | dig | network-analysis | 3 | 7 |
| gobuster/discover-directories.sh | gobuster | web-scanner | 8 | 2 |
| gobuster/enumerate-subdomains.sh | gobuster | web-scanner | 7 | 3 |
| hashcat/benchmark-gpu.sh | hashcat | password-cracker | 9 | 1 |
| hping3/detect-firewall.sh | hping3 | network-scanner | 9 | 1 |
| hping3/test-firewall-rules.sh | hping3 | network-scanner | 9 | 1 |
| netcat/scan-ports.sh | netcat | network-scanner | 7 | 3 |
| nikto/scan-with-auth.sh | nikto | web-scanner | 6 | 4 |
| nmap/identify-ports.sh | nmap | network-scanner | 4 | 6 |
| sqlmap/dump-database.sh | sqlmap | sql-injection | 5 | 5 |
| traceroute/compare-routes.sh | traceroute | network-analysis | 8 | 4 |
| tshark/analyze-dns-queries.sh | tshark | network-analysis | 7 | 3 |
| tshark/capture-http-credentials.sh | tshark | network-analysis | 8 | 2 |

#### Group C: Pure info+echo Scripts (21 scripts -- need json_set_meta + json_finalize + json_add_example for ALL 10 examples)

| Script | Tool | Category |
|--------|------|----------|
| aircrack-ng/analyze-wireless-networks.sh | aircrack-ng | exploitation |
| aircrack-ng/capture-handshake.sh | aircrack-ng | exploitation |
| aircrack-ng/crack-wpa-handshake.sh | aircrack-ng | exploitation |
| curl/check-ssl-certificate.sh | curl | network-analysis |
| curl/debug-http-response.sh | curl | network-analysis |
| dig/check-dns-propagation.sh | dig | network-analysis |
| foremost/analyze-forensic-image.sh | foremost | forensics |
| foremost/carve-specific-filetypes.sh | foremost | forensics |
| foremost/recover-deleted-files.sh | foremost | forensics |
| hashcat/crack-ntlm-hashes.sh | hashcat | password-cracker |
| hashcat/crack-web-hashes.sh | hashcat | password-cracker |
| john/crack-archive-passwords.sh | john | password-cracker |
| john/crack-linux-passwords.sh | john | password-cracker |
| john/identify-hash-type.sh | john | password-cracker |
| metasploit/generate-reverse-shell.sh | metasploit | exploitation |
| metasploit/scan-network-services.sh | metasploit | exploitation |
| metasploit/setup-listener.sh | metasploit | exploitation |
| netcat/setup-listener.sh | netcat | network-scanner |
| netcat/transfer-files.sh | netcat | network-scanner |
| nikto/scan-multiple-hosts.sh | nikto | web-scanner |
| tshark/extract-files-from-capture.sh | tshark | network-analysis |

### Special Cases

**Scripts with conditional/branching commands (variant-dependent):**
- netcat/setup-listener.sh -- 10 examples all have NC_VARIANT branching
- netcat/transfer-files.sh -- Some examples have NC_VARIANT branching
- netcat/scan-ports.sh -- Some examples have NC_VARIANT branching

These need `json_add_example` inside each branch of the conditional.

**Scripts with non-standard target variables:**
- hashcat/benchmark-gpu.sh -- no target (empty string)
- john/identify-hash-type.sh -- HASH variable
- metasploit/generate-reverse-shell.sh -- LHOST + LPORT
- netcat/setup-listener.sh -- PORT variable

**Scripts with multi-line example commands (echo spans multiple lines):**
- Several scripts have examples that span 2-3 echo lines (e.g., "# Receiver:" + "command" + "# Sender:" + "command"). For `json_add_example`, concatenate into a single command string or use the primary command only.

## State of the Art

| Old Approach (Phase 23) | Current Approach (Phase 25) | When Changed | Impact |
|-------------------------|----------------------------|--------------|--------|
| json_set_meta takes 2 args (tool, target) | json_set_meta takes 3 args (tool, target, category) | Phase 25 start | Library change needed before script migration |
| No category field in envelope | category field in meta object | Phase 25 | Satisfies SCRIPT-04 requirement |
| 0 of 46 scripts produce JSON | All 46 scripts produce JSON with -j | Phase 25 completion | Satisfies SCRIPT-01, SCRIPT-02, SCRIPT-03 |

## Open Questions

1. **Should multi-line echo examples be combined into a single json_add_example call?**
   - What we know: Some scripts (e.g., netcat/transfer-files.sh) have examples that show both "Receiver" and "Sender" commands across multiple echo lines.
   - What's unclear: Should these be 1 json result (combined command) or 2 json results (separate commands)?
   - Recommendation: Treat as 1 result with combined command string. The description says "Send a file" -- it's one conceptual example even if it involves two terminals. Use `\n` or ` && ` to join.

2. **Should the interactive demo block produce JSON output?**
   - What we know: The interactive demo is naturally skipped in JSON mode (non-interactive detection). No JSON is produced from it.
   - What's unclear: Should the demo command be included as a bonus result in JSON output?
   - Recommendation: No. The demo is interactive/optional content. The 10 numbered examples are the structured content. Keep it simple.

3. **Should educational context (the "Why..." sections) appear in JSON output?**
   - What we know: Every script has an explanatory section between the header and the numbered examples. This is pure educational text.
   - What's unclear: Would consumers benefit from having this as a field?
   - Recommendation: No. Keep results focused on commands. Educational text goes to stderr via fd redirect and is available to consumers who capture stderr. Adding it to JSON adds complexity for unclear value. This can be revisited in a future phase if needed.

4. **Task batching strategy: should we migrate by tool (all scripts for one tool) or by pattern (all Group A, then B, then C)?**
   - Recommendation: Migrate by tool. This keeps related scripts together, makes verification natural (test all 3 nmap scripts together), and allows committing per-tool. Within each tool, Group A scripts (pure run_or_show) are faster to migrate, so do those first.

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis of all 46 use-case scripts (pattern classification verified line-by-line)
- `scripts/lib/json.sh` -- current API surface (json_set_meta, json_add_example, json_add_result, json_finalize, json_is_active)
- `scripts/lib/args.sh` -- current parse_common_args with -j flag handling
- `scripts/lib/output.sh` -- current run_or_show with 4 JSON/text code paths
- `.planning/phases/23-json-library-flag-integration/23-RESEARCH.md` -- Phase 23 research with detailed pattern analysis
- `.planning/phases/23-json-library-flag-integration/23-01-PLAN.md` -- Phase 23 implementation plan
- `.planning/REQUIREMENTS.md` -- SCRIPT-01 through SCRIPT-04 requirements
- `.planning/ROADMAP.md` -- Phase 25 success criteria
- `.planning/research/FEATURES.md` -- Category definitions, envelope schema, anti-features

### Secondary (MEDIUM confidence)
- `.planning/research/FEATURES.md` lines 114-258 -- Tool Category Schemas (defined during milestone research)
- USECASES.md -- Use-case groupings by domain (informed category mapping)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All libraries already built and tested in Phase 23/24. 265 BATS tests passing.
- Architecture: HIGH -- Migration pattern verified against all 46 scripts by reading each one. Pattern classification (run_or_show counts vs bare info+echo counts) verified with grep.
- Pitfalls: HIGH -- 7 pitfalls identified from analysis of script structure and API gaps. Category gap (Pitfall 6) is the only one requiring library changes.
- Code examples: HIGH -- Examples use exact function signatures from the existing codebase. Verified against lib/json.sh and lib/output.sh source.

**Research date:** 2026-02-13
**Valid until:** 2026-03-13 (stable domain -- scripts and library APIs do not change frequently)
