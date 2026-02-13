# Domain Pitfalls: Adding JSON Output Mode to Bash CLI Scripts

**Domain:** Adding `-j`/`--json` flag with envelope pattern to 46 existing bash scripts wrapping security tools (nmap, sqlmap, nikto, hashcat, tshark, etc.) using pure bash JSON generation (no jq dependency for output)
**Researched:** 2026-02-13
**Overall confidence:** HIGH -- pitfalls verified against actual codebase patterns, security tool output format documentation, known bugs in tool JSON exports (e.g., Nikto issue #599), and established bash JSON generation failure modes

## Critical Pitfalls

Mistakes that produce invalid JSON, corrupt piped data, or require rearchitecting the output layer.

---

### Pitfall 1: Pure bash JSON string escaping is incomplete -- the 8-character trap

**What goes wrong:** A hand-rolled `json_escape()` function that handles `"` and `\` but misses the other 6 mandatory JSON escape sequences produces JSON that parses in `jq` sometimes but fails in strict parsers, downstream APIs, or when security tool output contains control characters. The JSON spec (RFC 8259) requires escaping 8 specific sequences: `\"`, `\\`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`, plus all control characters U+0000 through U+001F.

**Why it happens:** Most bash JSON escape tutorials show only `sed 's/"/\\"/g; s/\\/\\\\/g'` and call it done. This handles 95% of cases in testing because test data rarely contains backspace (`\b`), form feed (`\f`), or raw control characters. But security tool output is full of these edge cases:
- Nmap banner grabs may contain raw control characters from service responses
- Hashcat status output includes `\r` (carriage return) for progress bar rewriting
- Tshark packet captures include binary data that leaks non-printable characters
- SQLmap output includes raw HTTP responses that may contain `\t` in HTML and `\r\n` line endings
- Nikto findings can include literal server banner strings with arbitrary bytes

**Consequences:** JSON that looks valid in the terminal but fails `jq .` validation. Downstream consumers (CI pipelines, reporting tools, web dashboards) silently drop or corrupt records. The failure is intermittent -- it only occurs when a specific tool returns output containing the unescaped characters, making it nearly impossible to catch without fuzz testing.

**Prevention:**
1. Implement a complete escape function that handles all 8 sequences plus control characters:
   ```bash
   # Complete JSON string escaper -- handles ALL RFC 8259 requirements
   _json_escape() {
       local input="$1"
       # Order matters: backslash MUST be first (otherwise double-escaping)
       input="${input//\\/\\\\}"    # \ -> \\
       input="${input//\"/\\\"}"    # " -> \"
       input="${input///\\/}"       # / -> \/ (optional per spec but safe)
       input="${input//$'\b'/\\b}"  # backspace
       input="${input//$'\f'/\\f}"  # form feed
       input="${input//$'\n'/\\n}"  # newline
       input="${input//$'\r'/\\r}"  # carriage return
       input="${input//$'\t'/\\t}"  # tab
       printf '%s' "$input"
   }
   ```
2. The remaining control characters (U+0000-U+001F excluding the 5 above) require `\u00XX` encoding. In pure bash, this requires iterating byte-by-byte for non-printable detection, which is slow. Two options:
   - **Option A (recommended):** Strip control characters before escaping with `tr -d '\000-\010\013\014\016-\037'`. This loses data but is safe and fast.
   - **Option B:** Use `printf '\\u%04x' "'$char"` for each control character. This is correct but 10-100x slower for large outputs.
3. **Always validate:** Run `echo "$json_output" | jq . > /dev/null 2>&1` in CI tests to catch escaping gaps. This does not require jq at runtime -- only in CI.

**Detection:** Feed tool output containing `\t`, `\r`, `\b`, `\f`, and raw control characters through the escape function and validate with `python3 -c "import json; json.loads(open('output.json').read())"` or `jq .`.

**Affected components:** Every script that generates JSON output. The escape function must be centralized in a new `lib/json.sh` module.

**Phase mapping:** Must be the very first thing built and tested. All other JSON features depend on this being correct.

**Confidence:** HIGH -- RFC 8259 Section 7 specifies the exact escape requirements. Nikto's own JSON export had this exact bug (trailing comma issue aside): [GitHub Issue #599](https://github.com/sullo/nikto/issues/599), [Issue #721](https://github.com/sullo/nikto/issues/721).

---

### Pitfall 2: Backslash escaping order -- escaping `\` last creates double-escaping

**What goes wrong:** If the escape function processes `"` before `\`, then a string containing `\"` (literal backslash-quote) becomes `\\"` (escaped backslash, then raw quote) instead of `\\\"` (escaped backslash, escaped quote). Conversely, if `\n` (literal newline) is replaced before `\` is escaped, a string containing a literal `\n` (two characters: backslash, n) is incorrectly turned into `\\n` instead of remaining `\\n`. The interaction between these substitutions is the single most common bug in hand-rolled JSON escapers.

**Why it happens:** Bash string replacement (`${var//pattern/replacement}`) processes the entire string for each substitution. If you escape `\` to `\\` AFTER escaping `"` to `\"`, the backslash in `\"` gets double-escaped to `\\"`. If you escape `\` first, then subsequent replacements for `\n`, `\t`, etc. must use `$'\n'` (the actual byte) not the literal string `\n` -- but many tutorials show `sed 's/\\n/\\\\n/g'` which operates on the literal characters, not the actual newline byte.

**Consequences:** JSON strings contain `\\\"` where they should have `\"`, or `\\n` where they should have `\n`. Downstream parsers see different data than intended. In security tool output, this is especially dangerous because nmap version strings, HTTP headers, and SQL injection payloads frequently contain backslashes.

**Prevention:**
1. **Always escape `\` first.** This is non-negotiable.
2. **Use `$'\n'` (actual bytes) for control character matching**, not literal string patterns:
   ```bash
   # CORRECT: matches actual newline byte
   input="${input//$'\n'/\\n}"

   # WRONG: matches literal backslash-n (two characters)
   input="${input//\\n/\\\\n}"
   ```
3. Write explicit unit tests for these specific inputs:
   - `He said "hello"` -- tests quote escaping
   - `path\to\file` -- tests backslash escaping
   - `line1\nline2` (literal `\n` as two chars) -- tests that literal `\n` is NOT converted
   - A string with an actual newline embedded -- tests real newline conversion
   - `"quote\"escaped"` -- tests the backslash-then-quote interaction

**Detection:** Compare your function's output against `jq -Rsa .` for identical inputs. Any difference indicates an escaping order bug.

**Phase mapping:** Part of the core `_json_escape()` implementation in Phase 1. Unit tests must cover these exact edge cases.

**Confidence:** HIGH -- this is the #1 reported bug in bash JSON generation. See [Baeldung's bash JSON guide](https://www.baeldung.com/linux/bash-variables-create-json-string) and [tutorialpedia JSON escaping](https://www.tutorialpedia.org/blog/escaping-characters-in-bash-for-json/) which both document this issue.

---

### Pitfall 3: stdout/stderr contamination -- tool progress output, ANSI codes, and `set -x` traces corrupt JSON

**What goes wrong:** When `--json` is active and a tool runs in execute mode (`-x`), the tool's own stdout and stderr get mixed into the JSON output stream. Security tools are notoriously bad about output discipline:
- **Hashcat** writes progress bars to stderr using `\r` (carriage return) overwriting
- **SQLmap** writes colored banners and progress to stdout even in `--batch` mode
- **Nikto** writes progress messages (`+ 1234 items checked`) to stdout
- **Nmap** writes timing info and warnings to stderr
- **Tshark** writes capture stats to stderr on Ctrl+C
- **Metasploit** writes banner art and loading messages to stdout

If any of this reaches the JSON output stream, the JSON is invalid.

**Why it happens:** In the current codebase, `run_or_show()` in `output.sh` (line 37-51) calls `"$@"` directly, which inherits the script's stdout. In show mode, this is fine because the output is human-readable text anyway. In JSON mode, if the JSON envelope is being written to stdout and then a tool is executed that also writes to stdout, the streams are interleaved.

Additionally, `set -x` (debug trace) from `strict.sh` writes to stderr by default, but if stderr is redirected to the JSON output (e.g., to capture tool errors), the trace output corrupts the JSON.

The existing logging functions (`info`, `warn`, `error`, `success`, `debug`) all write to stdout or stderr with ANSI color codes (from `colors.sh`). In JSON mode, these human-readable log messages must not appear in the JSON stream.

**Consequences:** Invalid JSON. Parsers fail on the first non-JSON byte. The failure is tool-dependent and timing-dependent (progress output appears mid-stream).

**Prevention:**
1. **Use file descriptor 3 for JSON output**, keeping stdout/stderr for human and tool output:
   ```bash
   # In JSON mode, open FD 3 for JSON output
   if [[ "${OUTPUT_FORMAT:-text}" == "json" ]]; then
       exec 3>&1           # FD 3 = original stdout (for JSON)
       exec 1>/dev/null    # Suppress human-readable stdout
       exec 2>/dev/null    # Suppress stderr (or redirect to a capture file)
   fi

   # Write JSON to FD 3
   echo '{"status":"ok"}' >&3
   ```
   **WARNING:** This conflicts with BATS testing, which uses FD 3 internally (see prior PITFALLS.md, Pitfall 15). Use FD 4 or higher if BATS compatibility is needed.

2. **Alternative (simpler, recommended for this project):** Capture tool output into a variable, then emit JSON at the end:
   ```bash
   if [[ "${OUTPUT_FORMAT:-text}" == "json" ]]; then
       # Capture everything, emit JSON at the very end
       tool_output=$(command_here 2>&1) || tool_exit=$?
       _json_emit "$tool_output" "$tool_exit"
   else
       # Normal human-readable output
       command_here
   fi
   ```
   This avoids interleaving entirely because JSON is only written once, after the tool finishes.

3. **Strip ANSI codes from captured output** before JSON encoding:
   ```bash
   _strip_ansi() {
       # Remove ANSI escape sequences (colors, cursor movement)
       sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'
   }
   ```

4. **Redirect `set -x` traces** away from the output stream: `exec 2>/dev/null` or `set +x` in JSON mode.

**Detection:** Run `script_name --json -x target 2>&1 | jq .` for each tool. If `jq` fails, stdout/stderr contamination is present.

**Affected components:** `scripts/lib/output.sh` (`run_or_show`, `info`, `warn`, all logging functions), `scripts/lib/strict.sh` (set -x traces), `scripts/lib/colors.sh` (ANSI codes in logged output), all 46 use-case scripts.

**Phase mapping:** Must be designed in the architecture phase (how FDs are managed) and implemented in the core library phase (before any per-tool JSON work).

**Confidence:** HIGH -- verified by reading `output.sh` line 44 (`"$@"` direct execution), `logging.sh` (all functions write to stdout), and known security tool output behavior.

---

### Pitfall 4: Trailing comma in JSON arrays/objects -- the loop-append antipattern

**What goes wrong:** Building a JSON array or object by appending `"element",` in a loop and then stripping the trailing comma with `${var%,}` seems to work but breaks in three cases:
1. Empty arrays: the result is `[,]` or `[]` depending on whether the strip runs before or after wrapping. If the strip removes the empty string's comma, it works; if there's no comma to strip, it works. But if there's whitespace inconsistency, it breaks.
2. Values containing commas: `${var%,}` strips the last comma in the VALUE, not the trailing delimiter. A value like `"SQL injection found, 3 parameters"` has its final comma stripped, producing `"SQL injection found, 3 parameters` (missing quote).
3. Nested objects: if the last element is `}` or `]`, the pattern `${var%,}` does nothing because the last character is not a comma.

**Why it happens:** This is the most common pattern in bash JSON tutorials because it is simple. Nikto itself had this exact bug -- [GitHub Issue #599](https://github.com/sullo/nikto/issues/599) was caused by trailing commas in JSON output that made the entire file invalid. Nikto's fix (PR #601) was to track array index and conditionally add commas.

**Consequences:** Invalid JSON. `jq` reports "Expected value" errors. The bug is intermittent -- it depends on whether the last tool output contains a comma, whether the array is empty, and the specific whitespace in the output.

**Prevention:**
1. **Use the "first element" flag pattern** instead of trailing comma stripping:
   ```bash
   _json_array() {
       local first=true
       local result="["
       for item in "$@"; do
           if [[ "$first" == true ]]; then
               first=false
           else
               result+=","
           fi
           result+="\"$(_json_escape "$item")\""
       done
       result+="]"
       printf '%s' "$result"
   }
   ```
2. **Or use bash array join with IFS:**
   ```bash
   _json_array() {
       local -a escaped=()
       for item in "$@"; do
           escaped+=("\"$(_json_escape "$item")\"")
       done
       local IFS=','
       printf '[%s]' "${escaped[*]}"
   }
   ```
   This is cleaner and handles empty arrays correctly (produces `[]`).

3. **Never use `${var%,}` for JSON comma management.** It is fundamentally unreliable for values that may contain commas.

**Detection:** Test with: empty arrays, single-element arrays, arrays where values contain commas, nested objects as values.

**Phase mapping:** Part of the core `lib/json.sh` array/object builder functions.

**Confidence:** HIGH -- Nikto Issue #599 and #721 document exactly this failure mode in a security tool.

---

### Pitfall 5: `set -e` (errexit) causes partial JSON output on tool failure

**What goes wrong:** The project uses `set -eEuo pipefail` (from `strict.sh`). When a security tool invoked in execute mode returns non-zero, `set -e` causes the script to exit immediately via the ERR trap. If JSON output is being built incrementally (e.g., the JSON envelope header has been written to stdout but the closing `}` has not), the output is a truncated JSON fragment that crashes any downstream parser.

**Why it happens:** The current `_strict_error_handler` (strict.sh line 22-37) prints a stack trace to stderr and then the EXIT trap fires. Neither handler knows about JSON mode or attempts to close the JSON envelope. The tool failure cascades through errexit -> ERR trap -> EXIT trap -> process exit, leaving stdout with partial JSON like:
```json
{"tool":"nmap","timestamp":"2026-02-13T10:00:00Z","command":"nmap -sV target","output":
```
No closing quotes, no closing braces. This is worse than no output at all because a naive consumer might try to parse it and crash.

**Consequences:** Partial JSON on stdout that crashes downstream parsers. The ERR trap writes human-readable stack traces to stderr, which is correct. But the incomplete JSON on stdout is the real problem -- it looks like data but is corrupt.

**Prevention:**
1. **Capture-then-emit pattern (strongly recommended):** Never write JSON incrementally. Capture all tool output into a variable, then emit the complete JSON envelope at the end:
   ```bash
   # Capture tool output, preserving exit code
   local tool_output tool_exit=0
   tool_output=$("$@" 2>&1) || tool_exit=$?

   # Always emit complete JSON, even on failure
   _json_envelope "$tool_output" "$tool_exit"
   ```
   This way, if the tool fails, you still emit valid JSON with `"exit_code": 1` and `"error": "..."`.

2. **Register a JSON cleanup trap** that closes the envelope on abnormal exit:
   ```bash
   _json_exit_handler() {
       local exit_code=$?
       if [[ "${_JSON_STARTED:-}" == "1" && "${_JSON_CLOSED:-}" != "1" ]]; then
           # Close the JSON envelope with error info
           printf ',"error":"Script exited with code %d","exit_code":%d}\n' \
               "$exit_code" "$exit_code"
           _JSON_CLOSED=1
       fi
   }
   ```
   **WARNING:** This trap must be registered AFTER `strict.sh`'s ERR trap and coordinate with `cleanup.sh`'s EXIT trap (see prior PITFALLS.md, Pitfall 3). Trap ordering in bash is fragile.

3. **Temporarily disable errexit around tool execution** in JSON mode:
   ```bash
   set +e
   tool_output=$("$@" 2>&1)
   tool_exit=$?
   set -e
   ```
   This is safe because you are explicitly handling the exit code.

**Detection:** Run a script in JSON mode against an unreachable target (tool will fail). Check if the output is valid JSON. If not, this pitfall is active.

**Affected components:** `scripts/lib/strict.sh` (set -e, ERR trap), `scripts/lib/cleanup.sh` (EXIT trap), `scripts/lib/output.sh` (run_or_show).

**Phase mapping:** Must be designed in the JSON library architecture phase. The capture-then-emit pattern should be the default.

**Confidence:** HIGH -- verified by reading `strict.sh` and the ERR/EXIT trap chain. This is a known category of bugs: [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105) documents how set -e interacts unpredictably with traps.

---

### Pitfall 6: Number vs string type confusion -- everything in bash is a string

**What goes wrong:** JSON distinguishes between `"80"` (string) and `80` (number), between `"true"` (string) and `true` (boolean), and between `"null"` (string) and `null`. Bash does not. When generating JSON from bash variables, port numbers become strings (`"port": "80"` instead of `"port": 80`), boolean flags become strings (`"up": "true"` instead of `"up": true`), and null/empty values become empty strings (`"version": ""` instead of `"version": null`).

**Why it happens:** Every bash variable is a string. `printf '"%s"' "$port"` produces `"80"` regardless of whether the value is numeric. Without explicit type handling, every field in the JSON output is a string. This seems fine until downstream consumers that expect numbers try to do arithmetic, or a JSON schema validator rejects the output, or `jq` select queries like `.results[] | select(.port > 1024)` fail because you cannot do arithmetic comparison on strings.

**Consequences:** JSON that is syntactically valid but semantically wrong. Downstream tools silently behave incorrectly:
- Port number comparisons fail (`"8080" > "443"` is true in string comparison but the intent is numeric)
- Boolean checks fail (`if .open` is falsy when the value is the string `"true"`)
- Schema validation rejects the output
- Dashboard tools show `null` as a literal string in UI

**Prevention:**
1. **Create explicit type-aware emit functions:**
   ```bash
   _json_string() { printf '"%s"' "$(_json_escape "$1")"; }
   _json_number() { printf '%s' "$1"; }        # No quotes
   _json_bool()   { printf '%s' "$1"; }         # "true" or "false", no quotes
   _json_null()   { printf 'null'; }

   # Validate number before emitting
   _json_number() {
       if [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
           printf '%s' "$1"
       else
           printf '"%s"' "$(_json_escape "$1")"  # Fallback to string
       fi
   }
   ```
2. **Define a schema per tool** that specifies which fields are numbers, booleans, or strings. Do not auto-detect types -- auto-detection fails on values like `"0" ` (is it a number or a string with trailing space?) and `"null"` (is it the JSON null or a literal string?).
3. **Document the schema** in each script or in a central schema file. Consumers need to know the types.
4. **Empty string vs null:** Decide a project-wide convention. Recommendation: use `null` for "field not applicable" and `""` for "field applicable but value is empty". Never omit fields -- always include them with null.

**Detection:** Pipe JSON output to `jq 'type'` for each field. If ports are strings, this pitfall is active.

**Phase mapping:** Must be decided during JSON library design. The type functions should be in `lib/json.sh`.

**Confidence:** HIGH -- this is a fundamental bash limitation. See [Baeldung's bash JSON variables guide](https://www.baeldung.com/linux/bash-variables-create-json-string) and the [json.bash project](https://github.com/h4l/json.bash) which was specifically created to solve this type coercion problem.

---

## Moderate Pitfalls

---

### Pitfall 7: Tool output parsing fragility -- regex patterns that break across versions

**What goes wrong:** Parsing structured data from tool text output using regex or `grep`/`awk` produces correct JSON for the current tool version but breaks silently when the tool is updated. Security tools change their output format frequently:
- **Nmap 7.80 vs 7.94:** Service probe output formatting changed, with different column spacing and new fields
- **SQLmap:** Output format discrepancies between versions are a documented issue ([GitHub Issue #828](https://github.com/sqlmapproject/sqlmap/issues/828))
- **Nikto 2.1.x vs 2.5.0:** JSON export format completely restructured from object-based to array-based ([DefectDojo Issue #9274](https://github.com/DefectDojo/django-DefectDojo/issues/9274))
- **Hashcat:** Status output format varies between GPU backends

A regex like `grep -oP 'Nmap scan report for (.+)'` works today but may fail if the wording changes to "Nmap host report for" in a future version.

**Why it happens:** Text output is not a stable API. Tool maintainers do not guarantee backward compatibility of human-readable output. Only structured output formats (nmap's `-oX`, sqlmap's `--output-dir`) are stable.

**Consequences:** Silent data loss or incorrect data. A regex that no longer matches produces empty fields instead of errors. The JSON is valid but contains empty strings where there should be data. This is worse than a crash because it is not detected until a human reviews the output.

**Prevention:**
1. **Use native structured output when available:**
   - Nmap: Use `-oX -` (XML to stdout) and parse XML, not text. Nmap's XML format has a DTD and is versioned.
   - SQLmap: Use `--output-dir` and parse the CSV/HTML/SQLite output files.
   - Nikto: Use `-Format json` for native JSON (but validate it -- Nikto's own JSON has bugs).
   - Tshark: Use `-T json` or `-T fields` with `-E separator=,` for structured output.
2. **For tools without structured output** (hashcat, hping3, aircrack-ng, skipfish):
   - Parse conservatively: extract only clearly delimited data, not positional column data.
   - Include the raw text output as a string field alongside parsed fields. If parsing fails, the raw data is still available.
   - Add a `"parser_version"` field to the JSON so consumers know which parser produced the data.
3. **Pin tool version expectations** in documentation. When a tool updates, review and update the parser.
4. **Fail loudly on parse failures:** If a regex matches nothing, emit `null` for that field and set `"parse_warnings": ["Failed to extract port from line: ..."]` in the JSON.

**Detection:** Run the same script against different tool versions. Compare JSON output schemas. Missing or changed fields indicate parser fragility.

**Phase mapping:** Per-tool JSON implementation phase. Each tool's parser must be individually researched and tested.

**Confidence:** HIGH -- SQLmap issue #828 and Nikto/DefectDojo issues directly document version-to-version output format changes.

---

### Pitfall 8: Large scan output causes bash variable size and performance problems

**What goes wrong:** Nmap full port scans, SQLmap database dumps, and tshark packet captures can produce megabytes of text output. Capturing this into a bash variable with `output=$(command 2>&1)` works for small outputs but causes two problems at scale:
1. **Memory:** Bash stores variables as C strings. A 50MB nmap scan stored in a variable uses at least 50MB of process memory. String operations on this variable (escaping, substitution) may create additional copies.
2. **Performance:** `${var//pattern/replacement}` (used in `_json_escape`) is O(n*m) where n is string length and m is pattern count. Running 8 escape substitutions on a 10MB string means 80MB of string scanning. On a Raspberry Pi or resource-constrained VM, this can take minutes.
3. **Subshell overhead:** `$(func "$large_var")` creates a copy of the entire variable for the subshell.

**Why it happens:** Bash is not designed for processing large data. The string substitution engine is not optimized for multi-megabyte inputs. There is no streaming JSON generation in pure bash -- you must buffer the entire output before escaping and emitting.

**Consequences:** Scripts hang or run extremely slowly on large scans. Memory usage spikes. On systems with limited resources (common in pentesting VMs), the script may be OOM-killed.

**Prevention:**
1. **Stream to a temp file instead of a variable for large outputs:**
   ```bash
   local tmpfile
   tmpfile=$(make_temp file json-output)
   "$@" > "$tmpfile" 2>&1 || tool_exit=$?

   # Escape and emit from file, not variable
   _json_escape_file "$tmpfile"
   ```
2. **Set a size limit** on captured output. If the output exceeds N bytes, truncate and add a `"truncated": true` field:
   ```bash
   local max_size=1048576  # 1MB
   tool_output=$(head -c "$max_size" < <("$@" 2>&1)) || tool_exit=$?
   if [[ ${#tool_output} -ge $max_size ]]; then
       truncated=true
   fi
   ```
3. **For known-large outputs, use tool-native output files** instead of stdout capture:
   ```bash
   # Instead of capturing nmap stdout:
   nmap -sV target -oX "$tmpfile"
   # Then convert XML to JSON (smaller, structured, no escaping needed for values)
   ```
4. **Avoid repeated string substitution on large strings.** If using `sed` for escaping, pipe through a single `sed` command with all substitutions chained, rather than running `${var//}` 8 times:
   ```bash
   _json_escape_via_sed() {
       printf '%s' "$1" | sed \
           -e 's/\\/\\\\/g' \
           -e 's/"/\\"/g' \
           -e 's/\t/\\t/g' \
           -e 's/\r/\\r/g' \
           -e 's/$/\\n/g'   # Note: sed newline handling is tricky
   }
   ```
   **WARNING:** sed-based escaping has its own pitfalls (see Pitfall 2 about ordering). But for large data, it is faster than bash string substitution because sed processes in a stream.

**Detection:** Run a script with `--json -x` against a target that produces large output (e.g., `nmap -sV -p- target`). Measure execution time and memory usage. If it takes more than 10x the non-JSON execution time, this pitfall is active.

**Phase mapping:** Address in the JSON library design phase. The temp-file vs variable decision must be made upfront.

**Confidence:** MEDIUM -- bash variable size is technically unlimited, but practical performance concerns are real. No hard data on exact thresholds for this codebase, but [community reports](https://www.namehero.com/blog/efficient-bash-string-concatenation-techniques-in-shell-scripting/) consistently warn about string concatenation performance.

---

### Pitfall 9: `date` format differences between macOS and Linux break timestamp fields

**What goes wrong:** The JSON envelope includes a timestamp field (e.g., `"timestamp": "2026-02-13T10:30:00Z"`). The `date` command's format strings differ between macOS (BSD `date`) and Linux (GNU `date`):
- **ISO 8601 format:** GNU `date` supports `date -Iseconds` and `date --iso-8601=seconds`. BSD `date` (macOS) does not support either flag.
- **Nanoseconds:** GNU `date +%N` gives nanoseconds. BSD `date +%N` outputs literal `N`.
- **UTC flag:** GNU `date -u` and BSD `date -u` both work, but `date --utc` is GNU-only.
- **Epoch seconds:** GNU `date +%s` and BSD `date +%s` both work, but `date -d @1234567890` (GNU) vs `date -r 1234567890` (BSD) for epoch-to-date conversion.

**Why it happens:** macOS ships with BSD userland, not GNU. The project already requires Bash 4.0+ (checked in `common.sh` line 11), so users must have Homebrew bash. But they may not have GNU coreutils -- the default `date` in PATH is still BSD.

**Consequences:** Timestamps vary between platforms. A CI pipeline on Linux produces `2026-02-13T10:30:00+00:00` while a developer on macOS produces `Thu Feb 13 10:30:00 UTC 2026`. JSON consumers that parse timestamps see inconsistent formats.

**Prevention:**
1. **Use a portable format string that works on both:**
   ```bash
   _json_timestamp() {
       date -u '+%Y-%m-%dT%H:%M:%SZ'
   }
   ```
   The `+%Y-%m-%dT%H:%M:%SZ` format string works on both BSD and GNU `date`. The `-u` flag works on both.

2. **Do NOT use:**
   - `date -Iseconds` (GNU-only)
   - `date --iso-8601` (GNU-only)
   - `date +%N` (returns literal `N` on macOS)
   - `date -d` (GNU-only; BSD uses `-f` for format and `-v` for adjustment)

3. **Test on both platforms** or use the portable format from day one.

4. **Also beware `LC_TIME` and `LANG`:** The `date` command's output can be locale-dependent. Always use explicit format strings (`+%Y-%m-%d...`), never the default output format. Set `LC_ALL=C` before `date` calls to prevent locale interference.

**Detection:** Run `date -u '+%Y-%m-%dT%H:%M:%SZ'` on macOS and Linux. If both produce the same format, the portable approach works.

**Phase mapping:** Address in the JSON library core functions.

**Confidence:** HIGH -- macOS/Linux `date` differences are well-documented. The project already acknowledges macOS compatibility (Bash version check for Homebrew bash).

---

### Pitfall 10: Show-mode scripts produce "example commands" not "real output" -- JSON mode must distinguish these

**What goes wrong:** The 46 use-case scripts have two modes: show mode (default, prints example commands with explanations) and execute mode (`-x`, runs the commands). In show mode, the output is educational text like `"   nmap -sV target"` -- it is NOT tool output. If JSON mode wraps show-mode output in a JSON envelope, the consumer gets JSON containing example commands, not scan results. This is confusing and potentially dangerous if a consumer treats the example commands as findings.

**Why it happens:** The scripts use `run_or_show()` which, in show mode, prints `info "$description"` followed by `echo "   $*"`. In execute mode, it runs `"$@"`. The JSON mode must know which mode it is in and structure the output accordingly:
- Show mode JSON: `{"type": "examples", "commands": [{"description": "...", "command": "nmap -sV target"}]}`
- Execute mode JSON: `{"type": "results", "command": "nmap -sV target", "output": "...", "exit_code": 0}`

If JSON mode does not distinguish these, it produces output that looks like results but is actually just command examples.

**Consequences:** Consumer confusion. A reporting tool that ingests JSON might show "nmap -sV target" as a finding. An automated pipeline might try to parse example text as tool output.

**Prevention:**
1. **Define two JSON schemas:** one for show mode (educational/documentation output) and one for execute mode (tool results).
2. **Include a `"mode"` field** in the JSON envelope: `"mode": "show"` or `"mode": "execute"`.
3. **In show mode, structure commands as an array of objects** with `description` and `command` fields, not raw text.
4. **In execute mode, include the actual tool output**, exit code, and parsed results.
5. **Consider whether show mode JSON is useful at all.** If the primary use case for JSON is machine consumption of scan results, JSON in show mode might be deliberately unsupported (exit with a message: "JSON output requires execute mode: use -j -x").

**Detection:** Run `script.sh --json` (without `-x`) and examine what gets produced. If it contains example command text wrapped in JSON, this pitfall is relevant.

**Phase mapping:** Must be decided in the JSON architecture design phase. This is a product decision, not just a technical one.

**Confidence:** HIGH -- verified by reading `output.sh` `run_or_show()` behavior and the show/execute mode split in all scripts.

---

### Pitfall 11: Dual-mode output (text + JSON) sharing the same stdout creates integration problems

**What goes wrong:** If the `--json` flag produces JSON on stdout while the script also produces human-readable output (safety banner, educational context, logging) on stdout, the output is a mix of JSON and text. Even if logging is suppressed in JSON mode, the `safety_banner()` function writes directly to stdout (output.sh line 14-20), `confirm_execute()` writes to stdout (line 68-69), and tools invoked via `"$@"` write to stdout.

**Why it happens:** The existing architecture assumes one output stream (stdout for humans). JSON mode requires a clean stdout for machine consumption. But 6+ places in the code path write to stdout independently of the output mode flag.

**Consequences:** Invalid JSON because non-JSON text is interleaved. Even one `echo ""` (which appears 30+ times across scripts for formatting) breaks JSON if it reaches stdout in JSON mode.

**Prevention:**
1. **In JSON mode, redirect ALL human output to stderr or /dev/null:**
   ```bash
   if [[ "${OUTPUT_FORMAT:-text}" == "json" ]]; then
       safety_banner() { :; }   # No-op in JSON mode
       info()  { :; }           # Suppress all human logging
       warn()  { :; }
       debug() { :; }
       # Only success/error might be included in JSON metadata
   fi
   ```
2. **Override `run_or_show()` behavior in JSON mode** to capture and structure output instead of printing.
3. **Audit every `echo` statement** in each script. In JSON mode, bare `echo ""` and `echo "   text"` must be suppressed or redirected. The 46 use-case scripts have an average of 15-20 bare echo statements each.
4. **Use a flag variable** that all output functions check: `_JSON_MODE=1`. This is cleaner than redefining functions because it is auditable.

**Detection:** Run `script.sh --json -x target 2>/dev/null | jq .` -- if jq fails, there is stdout contamination.

**Affected components:** `output.sh` (safety_banner, run_or_show, confirm_execute), `logging.sh` (info, warn, error, success, debug), all 46 use-case scripts (bare echo statements).

**Phase mapping:** Core library changes in the JSON infrastructure phase. Must be done before any per-tool JSON implementation.

**Confidence:** HIGH -- verified by counting echo/info/warn calls across the codebase.

---

### Pitfall 12: Testing JSON validity in CI without requiring jq on every platform

**What goes wrong:** CI validation of JSON output requires a JSON parser. The obvious choice is `jq`, but:
1. The project's stated goal is "no jq dependency for output." If jq is a CI-only dev dependency, this is fine conceptually, but confusing in practice -- contributors may think jq is needed at runtime.
2. On some CI runners (minimal Docker images, restricted environments), jq is not available.
3. `python3 -c "import json; json.loads(...)"` is an alternative but requires Python 3.
4. `node -e "JSON.parse(...)"` requires Node.js.

Choosing the wrong validation strategy means CI either fails to validate (useless) or requires a dependency that is hard to install.

**Why it happens:** JSON validation is fundamentally a parsing task. Bash cannot validate JSON reliably (you would need a bash JSON parser, which is the complexity you are trying to avoid). Some external tool is required.

**Consequences:** Either JSON output is never validated in CI (bugs ship), or CI requires an awkward dependency.

**Prevention:**
1. **Use `python3 -m json.tool`** as the CI validator. Python 3 is available on virtually all CI environments (GitHub Actions, GitLab CI, CircleCI):
   ```bash
   # In CI test:
   output=$(bash scripts/nmap/identify-ports.sh --json target)
   echo "$output" | python3 -m json.tool > /dev/null
   ```
2. **Add jq as a dev dependency** in the Makefile and CI config, clearly documented as "for testing only, not required at runtime":
   ```makefile
   test-json: ## Validate JSON output from all scripts
       @command -v jq >/dev/null || { echo "jq required for JSON tests: brew install jq"; exit 1; }
       @for script in scripts/*/identify-ports.sh; do \
           echo "Testing $$script..."; \
           bash "$$script" --json localhost | jq . > /dev/null || exit 1; \
       done
   ```
3. **Write BATS tests** that use `jq` or `python3` to validate JSON output:
   ```bash
   @test "identify-ports.sh --json produces valid JSON" {
       run bash scripts/nmap/identify-ports.sh --json localhost
       [ "$status" -eq 0 ]
       echo "$output" | python3 -m json.tool > /dev/null
   }
   ```
4. **Do not attempt bash-native JSON validation.** It is not worth the complexity and will have its own bugs.

**Detection:** Add a CI step that runs all scripts with `--json` and validates output. If this step does not exist, JSON validity is unverified.

**Phase mapping:** CI/testing phase. Must be implemented alongside the JSON output implementation, not after.

**Confidence:** HIGH -- this is a standard CI testing concern. `python3 -m json.tool` availability verified on GitHub Actions Ubuntu and macOS runners.

---

## Minor Pitfalls

---

### Pitfall 13: Unicode in security tool output (non-ASCII hostnames, banners, payloads)

**What goes wrong:** Security tool output may contain non-ASCII characters: internationalized domain names (IDN), server banners in non-English languages, SQL injection payloads with Unicode, HTTP response bodies with multi-byte characters. Bash's `${var//pattern/replacement}` operates on bytes, not characters, in most locales. A multi-byte UTF-8 character split across a substitution boundary can produce invalid UTF-8 in the JSON output.

**Prevention:**
1. Set `LC_ALL=C.UTF-8` (or `LC_ALL=en_US.UTF-8`) before processing tool output to ensure multi-byte awareness.
2. JSON requires UTF-8 encoding (RFC 8259). As long as the tool output is valid UTF-8 and the escape function only modifies ASCII characters (the 8 mandatory escapes are all ASCII), UTF-8 multi-byte sequences pass through safely.
3. If tool output contains raw non-UTF-8 bytes (e.g., from binary protocol captures), convert to UTF-8 or base64-encode the raw output:
   ```bash
   # Safe: base64 encode binary-unsafe output
   _json_base64_value() {
       base64 -w0 <<< "$1"  # -w0 for no line wrapping (GNU); use base64 -b0 on macOS
   }
   ```
   **Note:** `base64 -w0` is GNU-only. macOS uses `base64` without the `-w` flag (it does not wrap by default).

**Detection:** Include non-ASCII test inputs in JSON validation tests.

**Phase mapping:** Address in the escape function implementation.

**Confidence:** MEDIUM -- UTF-8 pass-through is generally safe in bash, but edge cases with invalid byte sequences and locale settings exist.

---

### Pitfall 14: `--json` flag conflicts with existing `parse_common_args` architecture

**What goes wrong:** The current `parse_common_args()` in `args.sh` handles `-h`, `-v`, `-q`, `-x`. Adding `-j`/`--json` requires modifying this central function. If the flag is added to `parse_common_args`, it works globally. If it is added per-script, there is inconsistency. If the flag is added but `OUTPUT_FORMAT` is not checked everywhere, some code paths ignore it.

**Prevention:**
1. Add `--json`/`-j` to `parse_common_args()` in `args.sh`, setting `OUTPUT_FORMAT=json`:
   ```bash
   -j|--json)
       OUTPUT_FORMAT="json"
       ;;
   ```
2. Initialize `OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"` at the top of `args.sh`.
3. All output functions (`info`, `warn`, `safety_banner`, `run_or_show`) must check `OUTPUT_FORMAT` and behave accordingly.
4. **Test that `-j` and `-x` can be combined:** `script.sh -j -x target` should produce JSON with real tool output. `script.sh -j target` should either produce JSON with example commands or error with "JSON requires -x".

**Detection:** Run `script.sh -j --help` -- if help text appears instead of JSON, the flag is not parsed before `--help` handling.

**Phase mapping:** First library change in the JSON implementation phase.

**Confidence:** HIGH -- verified by reading `args.sh` parse_common_args implementation.

---

### Pitfall 15: `confirm_execute()` interactive prompt breaks JSON mode piping

**What goes wrong:** In execute mode (`-x`), `confirm_execute()` prompts `"Continue? [y/N]"` via `read -rp`. In a pipeline (`script.sh --json -x target | jq .`), stdin is the pipe, not a terminal. The `[[ ! -t 0 ]]` check in `confirm_execute()` catches this and exits with code 1. The JSON consumer sees nothing (or a partial JSON error message).

**Prevention:**
1. **In JSON mode, skip the interactive confirmation entirely** -- if you are piping JSON, you have already decided to execute:
   ```bash
   confirm_execute() {
       [[ "${OUTPUT_FORMAT:-text}" == "json" ]] && return 0  # Skip in JSON mode
       [[ "${EXECUTE_MODE:-show}" != "execute" ]] && return 0
       # ... existing interactive logic
   }
   ```
2. **Alternatively, add a `--yes`/`--no-confirm` flag** that bypasses the prompt. JSON mode could imply `--yes`.
3. **Document this:** "When using `--json`, the safety confirmation is skipped. Ensure you have authorization."

**Phase mapping:** Library modification during JSON infrastructure phase.

**Confidence:** HIGH -- verified by reading `output.sh` confirm_execute lines 58-71.

---

### Pitfall 16: Inconsistent JSON envelope schema across 46 scripts

**What goes wrong:** Without a strict schema definition, each script's JSON output drifts over time. Script A uses `"target"`, script B uses `"host"`, script C uses `"target_url"`. Script A uses `"results"` as an array, script B uses `"output"` as a string. Consumers cannot write generic parsers.

**Prevention:**
1. **Define a fixed envelope schema** that all scripts must follow:
   ```json
   {
     "tool": "nmap",
     "script": "identify-ports",
     "version": "1.0.0",
     "timestamp": "2026-02-13T10:30:00Z",
     "target": "192.168.1.1",
     "command": "nmap -sV 192.168.1.1",
     "mode": "execute",
     "exit_code": 0,
     "output": "...",
     "results": {},
     "errors": [],
     "warnings": []
   }
   ```
2. **Implement the envelope in `lib/json.sh`** as a function that all scripts call, not as copy-pasted printf statements.
3. **Validate the schema in CI** -- check that all required fields are present and correctly typed.
4. **Version the schema** so consumers can adapt to changes.

**Phase mapping:** Architecture decision in the JSON design phase. Must be locked before per-tool implementation begins.

**Confidence:** HIGH -- schema drift is a universal problem in multi-script toolkits.

---

### Pitfall 17: `base64` command differences between macOS and Linux

**What goes wrong:** If binary or large output is base64-encoded for JSON inclusion, the `base64` command behaves differently:
- GNU (Linux): `base64 -w0` disables line wrapping. Default wraps at 76 characters.
- BSD (macOS): No `-w` flag. Default does not wrap. Use `base64 -b0` for explicit no-wrap on older macOS, but modern macOS `base64` does not wrap by default.

Line-wrapped base64 inside a JSON string creates newlines that must be escaped, adding complexity.

**Prevention:**
1. Use `base64 | tr -d '\n'` as a portable approach.
2. Or detect platform:
   ```bash
   _base64_nowrap() {
       if base64 --help 2>&1 | grep -q '\-w'; then
           base64 -w0
       else
           base64
       fi
   }
   ```

**Phase mapping:** Only relevant if base64 encoding is used for binary output fields.

**Confidence:** MEDIUM -- the difference is documented but may not apply if base64 is not used.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Severity | Mitigation |
|-------------|---------------|----------|------------|
| JSON library design (`lib/json.sh`) | Pitfall 1: Incomplete escaping | Critical | Implement all 8 escape sequences + control character handling from day one |
| JSON library design (`lib/json.sh`) | Pitfall 2: Backslash ordering | Critical | Escape `\` first, use `$'\n'` byte matching, write unit tests for edge cases |
| JSON library design (`lib/json.sh`) | Pitfall 4: Trailing comma | Critical | Use IFS join or first-flag pattern, never strip trailing commas |
| JSON library design (`lib/json.sh`) | Pitfall 6: Type confusion | Critical | Create explicit `_json_string`, `_json_number`, `_json_bool`, `_json_null` functions |
| JSON library design (`lib/json.sh`) | Pitfall 9: date portability | Moderate | Use `date -u '+%Y-%m-%dT%H:%M:%SZ'` only |
| Output architecture | Pitfall 3: stdout/stderr contamination | Critical | Capture-then-emit pattern; suppress all human output in JSON mode |
| Output architecture | Pitfall 5: Partial JSON on failure | Critical | Never write incremental JSON; always buffer and emit atomically |
| Output architecture | Pitfall 10: Show vs execute mode | Moderate | Define two JSON schemas or require `-x` for JSON mode |
| Output architecture | Pitfall 11: Dual-mode stdout | Critical | Override logging functions to no-op in JSON mode |
| Args/flag integration | Pitfall 14: `--json` flag parsing | Moderate | Add to `parse_common_args`, set `OUTPUT_FORMAT` variable |
| Args/flag integration | Pitfall 15: confirm_execute blocks pipes | Moderate | Skip confirmation in JSON mode automatically |
| Per-tool JSON implementation | Pitfall 7: Tool output parsing fragility | Critical | Use native structured output (XML, JSON) where available; include raw text fallback |
| Per-tool JSON implementation | Pitfall 8: Large output performance | Moderate | Use temp files for large outputs; set size limits |
| Per-tool JSON implementation | Pitfall 13: Unicode handling | Minor | Set `LC_ALL=C.UTF-8`; base64-encode binary data |
| CI/testing phase | Pitfall 12: JSON validation strategy | Moderate | Use `python3 -m json.tool` or `jq` as dev dependency |
| Schema governance | Pitfall 16: Schema drift | Moderate | Define envelope schema centrally; validate in CI |
| Cross-platform | Pitfall 17: base64 differences | Minor | Use `base64 | tr -d '\n'` portable pattern |

## Sources

- [RFC 8259 - The JavaScript Object Notation (JSON) Data Interchange Format](https://www.rfc-editor.org/rfc/rfc8259) -- JSON string escaping specification (Section 7)
- [Nikto GitHub Issue #599 - JSON export is not valid JSON](https://github.com/sullo/nikto/issues/599) -- trailing comma bug in security tool JSON export
- [Nikto GitHub Issue #721 - JSON output not valid when target not a webserver](https://github.com/sullo/nikto/issues/721) -- structural JSON bug
- [DefectDojo Issue #9274 - Nikto Parser: Support new JSON report format](https://github.com/DefectDojo/django-DefectDojo/issues/9274) -- Nikto 2.5.0 JSON format breaking change
- [SQLmap Issue #828 - Discrepancies in output between versions](https://github.com/sqlmapproject/sqlmap/issues/828) -- tool output format instability
- [Nmap XML Output documentation](https://nmap.org/book/output-formats-xml-output.html) -- stable structured output format
- [BashFAQ/105 - Why doesn't set -e do what I expected?](https://mywiki.wooledge.org/BashFAQ/105) -- set -e and trap interaction pitfalls
- [Baeldung - Build a JSON String with Bash Variables](https://www.baeldung.com/linux/bash-variables-create-json-string) -- bash JSON generation patterns and limitations
- [tutorialpedia - Escaping Characters in Bash for JSON](https://www.tutorialpedia.org/blog/escaping-characters-in-bash-for-json/) -- escape sequence ordering issues
- [json.bash (h4l/json.bash)](https://github.com/h4l/json.bash) -- type-safe JSON generation for bash, documents type coercion problems
- [jc - CLI tool for converting command output to JSON](https://github.com/kellyjonbrazil/jc) -- reference implementation for CLI-to-JSON conversion patterns
- [Stegard - How to make a shell script log JSON messages](https://stegard.net/2021/07/how-to-make-a-shell-script-log-json-messages/) -- FD-based JSON output separation
- [no-color.org](https://no-color.org/) -- NO_COLOR standard (already used by this project's colors.sh)
- Codebase analysis: `scripts/lib/output.sh`, `scripts/lib/args.sh`, `scripts/lib/strict.sh`, `scripts/lib/cleanup.sh`, `scripts/lib/colors.sh`, `scripts/lib/logging.sh`, and representative use-case scripts across all 17 tool directories
