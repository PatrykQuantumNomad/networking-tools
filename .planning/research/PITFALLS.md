# Domain Pitfalls: Bash Script Hardening for Networking Tools

**Domain:** Adding strict mode, structured logging, argument parsing, and dual-mode execution to 65+ existing educational bash scripts
**Researched:** 2026-02-11
**Overall confidence:** HIGH -- pitfalls verified against actual codebase patterns, bash documentation, and community reports

## Critical Pitfalls

Mistakes that break currently-working scripts, cause silent failures in CI, or require touching every script twice.

---

### Pitfall 1: `set -e` kills `read -rp` interactive demos when stdin is not a terminal

**What goes wrong:** All 65+ scripts inherit `set -euo pipefail` from `common.sh` (line 5). The `read` builtin returns exit code 1 when it encounters EOF on stdin. When scripts run non-interactively (piped input, `make` targets, CI), stdin is not a terminal and `read` hits EOF immediately, returning 1. With `set -e` active, the script dies at the `read -rp` line instead of gracefully skipping the interactive demo.

**Why it happens:** The scripts already have `[[ ! -t 0 ]] && exit 0` or `[[ -t 0 ]] || exit 0` guards before `read -rp` (found in all 63 scripts with interactive demos). These guards correctly prevent `read` from running in non-interactive contexts today. The pitfall arises if someone refactors the interactive section -- for example, wrapping the guard and `read` inside a function, where `exit 0` would exit the function but `set -e` would still kill the script if the function returns non-zero. Or if someone adds a second `read` call after the guard without realizing the guard only protects the first one.

**This is already partially mitigated** in the current codebase. The danger is during refactoring.

**Consequences:** Scripts that work perfectly today die with exit code 1 when run via `make` or in CI. The error is silent -- no error message, just an abrupt exit.

**Prevention:**
1. When refactoring interactive sections into functions, use `read -rp "..." answer || return 0` to handle EOF gracefully.
2. Never move the `[[ -t 0 ]]` guard into a function that uses `exit 0` -- `exit` in a function exits the whole script in some contexts, not just the function.
3. For dual-mode execution, the interactive demo section should be a separate function called only from `main()`, never from the library path.
4. Add a smoke test: `echo "" | bash scripts/nmap/examples.sh scanme.nmap.org` should not produce a non-zero exit code.

**Detection:** Run `make nmap TARGET=scanme.nmap.org` and verify exit code 0. Run each script with stdin redirected from `/dev/null`.

**Affected scripts:** All 63 scripts with `read -rp` patterns. Two equivalent guard styles exist:
- `[[ -t 0 ]] || exit 0` (19 scripts, examples.sh pattern)
- `[[ ! -t 0 ]] && exit 0` (44 scripts, use-case script pattern)

**Phase mapping:** Address in strict mode phase. Create a canonical `run_interactive_demo()` wrapper that handles all edge cases.

**Confidence:** HIGH -- verified by examining all 63 `read -rp` locations in the codebase and the existing `set -euo pipefail` in `common.sh`.

---

### Pitfall 2: `((counter++))` returns exit code 1 when counter starts at 0, killing script under `set -e`

**What goes wrong:** Bash arithmetic `(( ))` returns exit code 1 when the expression evaluates to 0. The expression `((counter++))` post-increments: it returns the old value (0) as the expression result, which maps to exit code 1. Under `set -e`, this kills the script on the very first increment.

**Why it happens:** In bash, `((0))` has exit code 1 (false) and `((1))` has exit code 0 (true). Post-increment `((x++))` evaluates to the value BEFORE increment. So when `x=0`, `((x++))` evaluates to 0, which is exit code 1, even though x is now 1.

**This is already known and guarded.** The codebase uses `((installed++)) || true` in `check-tools.sh` (line 92) and `((errors++)) || true` in `check-docs-completeness.sh` (line 16). The diagnostic scripts use `PASS_COUNT=$((PASS_COUNT + 1))` which is safe because `$(( ))` is arithmetic expansion (always exit 0), not arithmetic evaluation.

**Consequences:** Without `|| true`, any counter starting from 0 kills the script on first increment. The `check-tools.sh` script would die after finding the first installed tool.

**Prevention:**
1. Use `count=$((count + 1))` (arithmetic expansion) instead of `((count++))` (arithmetic evaluation). The `$()` form always returns exit 0.
2. If `(( ))` is preferred for readability, always append `|| true`: `((count++)) || true`.
3. Establish a project convention: "Always use `var=$((var + 1))` for counters. Never use `((var++))` without `|| true`."
4. The diagnostic scripts already follow the safe pattern -- do not regress when adding new counters.

**Detection:** `shellcheck` catches this with warning SC2219: "Instead of `let expr`, prefer `(( expr ))` for clarity. Alternatively, use `(( expr )) || true` to allow it to fail."

**Affected scripts:** `check-tools.sh`, `check-docs-completeness.sh`, and all 3 diagnostic scripts (`dns.sh`, `connectivity.sh`, `performance.sh`) which use `PASS_COUNT`, `FAIL_COUNT`, `WARN_COUNT` counters.

**Phase mapping:** Address in strict mode phase. Audit and standardize all counter patterns.

**Confidence:** HIGH -- verified from [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105), [Bash Hackers arithmetic expressions](https://bash-hackers.gabe565.com/syntax/arith_expr/), and confirmed in the actual codebase.

---

### Pitfall 3: `grep` returns exit code 1 on no match, breaking pipelines under `set -e` + `pipefail`

**What goes wrong:** `grep` returns exit code 0 on match, 1 on no match, 2 on error. With `set -o pipefail`, a `grep` with no match in ANY position of a pipeline kills the script. The pattern `some_command | grep "pattern" | head -1` fails when `grep` finds nothing -- even though "no match" is a perfectly valid outcome for networking tool output.

**Why it happens:** `pipefail` makes the pipeline's exit code the rightmost non-zero exit code from any command in the pipe. `grep` returning 1 (no match) is treated identically to a real error.

**This is already partially handled.** The codebase has 40+ instances of `|| true` guards, many specifically protecting `grep`:
- `grep -cE '...' || true` in `performance.sh` (line 99)
- `grep -nE '...' || true` in `performance.sh` (line 110)
- `grep -oE '...' ... | awk '{print $1}' || true` in `performance.sh` (line 246)

**But not all grep usages are guarded.** Several scripts use grep in pipelines without guards:
- `connectivity.sh` line 176: `echo "$ping_output" | grep -E 'packets|received' | tail -1` -- safe because it is inside an `if` conditional (set -e is suspended in conditionals)
- `check-tools.sh` line 25: `echo "$help_text" | grep -qi 'ncat'` in `detect_nc_variant()` -- safe because it is inside an `if`
- `curl/check-ssl-certificate.sh` line 104: `curl ... 2>&1 | grep -E "subject:|issuer:|expire|SSL connection"` -- this is in the interactive demo section, and if the grep finds nothing (e.g., self-signed cert with different output), the script dies

**Consequences:** Scripts that work today against expected targets fail against targets with unexpected output. DNS diagnostics fail when a record type does not exist. SSL checks fail when certificate format differs. Port scans fail when no ports are open.

**Prevention:**
1. Any `grep` that could legitimately find zero matches MUST have `|| true` (standalone) or be inside an `if`/`while` conditional.
2. For pipelines: `command | grep "pattern" || true` guards the WHOLE pipeline. For finer control: `command | { grep "pattern" || true; }`.
3. In diagnostic scripts, "no match" is information, not an error. Use `result=$(grep ... || true)` and check `[[ -n "$result" ]]`.
4. Create a helper function: `safe_grep() { grep "$@" || true; }` for consistent usage.
5. Note: `grep -c` returns 0 (the count) as output but exit code 1 when count is 0. Both the output and exit code matter.

**Detection:** Run diagnostic scripts against hosts that return unusual output. Run SSL check against a self-signed cert. Run DNS check against a nonexistent domain.

**Affected scripts:** All 3 diagnostic scripts (24 grep usages), `detect_nc_variant()` in `common.sh`, `check-tools.sh`, and any interactive demo that pipes through grep.

**Phase mapping:** Address in strict mode phase. Audit every `grep` call -- categorize as "inside conditional" (safe), "has || true" (safe), or "unguarded" (needs fix).

**Confidence:** HIGH -- verified from codebase grep analysis (40+ `|| true` guards already present means the team knows about this), [Bash Strict Mode article](http://redsymbol.net/articles/unofficial-bash-strict-mode/), and [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105).

---

### Pitfall 4: Tools that output to stderr cause false pipeline failures under `pipefail`

**What goes wrong:** Several networking tools write their output to stderr, not stdout:
- `nc -h` exits non-zero AND writes to stderr (already guarded with `2>&1 || true`)
- `hashcat --help` writes to stderr
- `dig -v` writes version to stderr
- `hping3` writes scan output to stderr
- `aircrack-ng -S` writes to stderr
- `curl -v` writes verbose headers to stderr

When capturing output with `2>&1`, the tool's non-zero exit code propagates through the pipeline. When using `2>/dev/null` to suppress, the diagnostic information is lost.

**Why it happens:** Security tools frequently use stderr for their primary output because stdout is reserved for machine-parseable data (like nmap -oX -). This is correct behavior for the tools but surprising when scripting around them.

**This is already well-handled in the codebase.** The pattern `tool_command 2>&1 || true` appears 20+ times. The `detect_nc_variant()` function (common.sh line 77) correctly uses `nc -h 2>&1 || true`. The `check-tools.sh` `get_version()` function handles each tool's stderr quirks individually.

**Consequences:** Adding new tool wrappers or refactoring existing ones without understanding each tool's stderr behavior breaks the script. The most dangerous case is when a tool writes useful output to stderr AND returns non-zero -- `2>&1` captures the output but `set -e` kills the script.

**Prevention:**
1. Document each tool's stderr behavior in a comment near its usage. The codebase already does this implicitly with `|| true` guards.
2. For any command that might return non-zero but produce useful output: `output=$(command 2>&1) || true`.
3. For commands where you need to distinguish "failed with error" from "succeeded with stderr output": capture exit code explicitly:
   ```bash
   output=$(command 2>&1) && rc=0 || rc=$?
   ```
4. Maintain a per-tool compatibility table documenting stderr/exit-code behavior.

**Detection:** Remove `|| true` guards and see which scripts fail. (Do not actually do this -- the guards are correct.)

**Affected scripts:** `common.sh` detect_nc_variant, `check-tools.sh` get_version, all interactive demos that run external tools (`hping3`, `aircrack-ng`, `nikto`, `hashcat`, `nc`).

**Phase mapping:** Document tool behaviors during strict mode phase. Create a tool compatibility matrix as part of the hardening work.

**Confidence:** HIGH -- verified from codebase analysis (20+ `2>&1 || true` patterns) and tool documentation.

---

### Pitfall 5: Dual-mode execution (`source` vs execute) breaks `set -e` propagation

**What goes wrong:** If scripts are refactored to support dual-mode (sourceable as library + executable), `set -e` behaves differently when a file is sourced vs executed:
- **Executed:** `set -e` in `common.sh` applies to the child script's entire execution.
- **Sourced:** `set -e` in `common.sh` modifies the CALLING shell's options. If the caller did not have `set -e`, it now does. If the caller already had `set -e`, functions from the sourced file may unexpectedly be "immune" when called from conditional contexts.

Additionally, the `BASH_SOURCE[0]` vs `$0` check used for dual-mode (`if [[ "$0" == "${BASH_SOURCE[0]}" ]]`) interacts with `set -u` -- `BASH_SOURCE` is always set in bash, but accessing `BASH_SOURCE[0]` in certain contexts can trigger issues.

**Why it happens:** Bash's `set -e` has notoriously complex scoping rules. When a function is called in a conditional context (`if my_func; then`), `set -e` is suspended INSIDE that function, even if the function itself set `set -e`. This is a bash spec behavior, not a bug. When dual-mode scripts are sourced, all their functions run in the caller's shell, inheriting the caller's `set -e` context -- which may be different from the script's intended context.

**Consequences:** Functions that rely on `set -e` for error handling silently swallow errors when called from conditional contexts. This is especially dangerous for `require_cmd`, `require_target`, and `require_root` -- these are meant to exit on failure, but if called as `if require_cmd nmap; then`, the `exit 1` inside the function DOES still exit the script (exit is not affected by set -e), but any intermediate commands that fail before the explicit `exit` are silently ignored.

**Prevention:**
1. Do not rely on `set -e` for control flow inside library functions. Use explicit `return 1` and check return values.
2. For dual-mode, use the standard guard pattern and keep it simple:
   ```bash
   main() {
       # All script logic here
   }
   [[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
   ```
3. `common.sh` should NOT set `set -euo pipefail` if it is being sourced by a script that might have different expectations. However, since ALL scripts in this project source `common.sh` and expect strict mode, this is safe for this specific project. The pitfall is if `common.sh` is ever sourced from an external script.
4. Keep the current architecture: `common.sh` sets strict mode, all scripts source it. Do not add dual-mode to `common.sh` itself.

**Detection:** Source `common.sh` from an interactive shell and observe that your shell now has `set -e` enabled. Type a command that fails -- your shell exits.

**Affected scripts:** `common.sh` (already sets strict mode for all scripts), any script that gets refactored for dual-mode.

**Phase mapping:** Address in dual-mode execution phase. Decide upfront whether dual-mode applies to `common.sh`, examples scripts, or both. Recommendation: only add dual-mode to individual scripts, not to `common.sh`.

**Confidence:** HIGH -- verified from [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105) and [Greg's Wiki BashGuide/Practices](https://mywiki.wooledge.org/BashGuide/Practices).

---

## Moderate Pitfalls

---

### Pitfall 6: `set -u` breaks scripts that check `$1` without default value in certain positions

**What goes wrong:** `set -u` (nounset) causes the script to exit when referencing an unset variable. The current codebase correctly uses `${1:-}` for all positional parameter checks. But adding argument parsing with `getopts` or `while` loops introduces new contexts where `$1`, `$OPTARG`, or shift-ed arguments might be unset.

**Why it happens:** After `shift`, `$1` becomes the next argument. If there are no more arguments, `$1` is unset. Under `set -u`, accessing `$1` after shifting past the last argument kills the script. Similarly, `getopts` sets `OPTARG` for options with required arguments, but `OPTARG` is unset for options without arguments.

**Consequences:** Argument parsing loop exits the script prematurely when it encounters the last argument or an option without a required argument.

**Prevention:**
1. In `while` loops over arguments, always check `$#` before accessing `$1`:
   ```bash
   while [[ $# -gt 0 ]]; do
       case "$1" in
           -v|--verbose) VERBOSE=true; shift ;;
           *) TARGET="$1"; shift ;;
       esac
   done
   ```
2. With `getopts`, initialize `OPTARG` or always use `${OPTARG:-}`.
3. For the help check pattern `[[ "${1:-}" =~ ^(-h|--help)$ ]]` -- this is already correct. Do not "simplify" to `[[ "$1" =~ ... ]]`.
4. After parsing, use defaults: `TARGET="${TARGET:-localhost}"`.

**Detection:** Run scripts with zero arguments, with only `--help`, with only flags and no positional argument.

**Affected scripts:** All 65+ scripts. The existing `${1:-}` pattern is correct and must be preserved through any argument parsing refactor.

**Phase mapping:** Address in argument parsing phase.

**Confidence:** HIGH -- verified from [Bash Strict Mode article](http://redsymbol.net/articles/unofficial-bash-strict-mode/) and codebase analysis showing consistent `${1:-}` usage.

---

### Pitfall 7: Structured logging breaks educational output when applied uniformly

**What goes wrong:** The scripts are educational tools whose primary value is human-readable output. Adding structured logging (JSON, syslog format, or even just timestamps + severity levels to every line) destroys the carefully formatted example output. The scripts currently use `info "1) Ping scan -- is the host up?"` followed by `echo "   nmap -sn ${TARGET}"` -- this formatting IS the product.

**Why it happens:** Structured logging is designed for machine-parseable operational scripts, not for educational CLI tools. Applying it uniformly treats the scripts as services instead of teaching tools.

**Consequences:** Every `echo` statement would need to be categorized as "log" vs "output". The numbered examples (the core educational content) should NOT be logged -- they ARE the output. But operational information (which tool is being run, what target, whether it succeeded) should be structured. Mixing both creates confusing output.

**Prevention:**
1. Distinguish between "script operations" (setup, validation, errors) and "educational content" (examples, explanations). Only structure the operations.
2. Keep the existing `info/warn/error/success` functions for operational messages. These can gain structured output (JSON to a file, timestamps) without changing their terminal appearance.
3. The `echo "   command"` lines (educational content) should NEVER go through the logging system.
4. For diagnostic scripts (Pattern B), structured logging makes more sense because their output IS operational data. The `report_pass/fail/warn` functions could gain structured output.
5. Implement logging levels: `--verbose` shows structured operational logs, default shows clean educational output.

**Detection:** Run an examples.sh script after adding structured logging. If the 10 numbered examples are buried in log metadata, the educational value is destroyed.

**Affected scripts:** All 17 examples.sh scripts (educational output), all 28 use-case scripts (mixed), 3 diagnostic scripts (operational output).

**Phase mapping:** Address in structured logging phase. Define the boundary between "educational content" and "operational logging" before writing any code.

**Confidence:** HIGH -- this is an architecture decision informed by the project's stated purpose in CLAUDE.md: "scripts demonstrating 10 open-source security tools... print example commands with explanations."

---

### Pitfall 8: `getopts` cannot parse long options, and `getopt` is not portable across macOS/Linux

**What goes wrong:** The project targets both macOS (BSD tools) and Linux (GNU tools). `getopts` (bash builtin) only supports short options (`-v`, `-t`). GNU `getopt` supports long options (`--verbose`, `--target`) but macOS ships BSD `getopt` which has different syntax and does not support long options. The current help pattern `[[ "${1:-}" =~ ^(-h|--help)$ ]]` handles both short and long help flags, but a full argument parser needs more.

**Why it happens:** The scripts currently use positional arguments (`$1` = target, `$2` = optional parameter) and a simple help check. Adding flags like `--verbose`, `--json`, `--non-interactive` requires parsing mixed flags and positional arguments. `getopts` cannot handle long options. GNU `getopt` is not available on macOS without `brew install gnu-getopt`.

**Consequences:** Either the argument parser only supports short flags (poor UX for educational scripts), or it depends on GNU `getopt` (breaks macOS portability), or a custom parser is implemented (complexity, bugs).

**Prevention:**
1. Use a manual `while/case` argument parser. This is the most portable approach and is already the de facto standard for cross-platform bash scripts:
   ```bash
   while [[ $# -gt 0 ]]; do
       case "$1" in
           -h|--help) show_help; exit 0 ;;
           -v|--verbose) VERBOSE=true; shift ;;
           -j|--json) JSON_OUTPUT=true; shift ;;
           --) shift; break ;;  # end of flags
           -*) error "Unknown option: $1"; exit 1 ;;
           *) break ;;  # positional args
       esac
   done
   ```
2. Do NOT use `getopts` -- it cannot handle long options and the scripts already have long option expectations (`--help`).
3. Do NOT use `getopt` -- it is not portable between macOS BSD and Linux GNU.
4. Keep the argument parser simple. These are educational scripts, not complex CLI tools. Support: `--help`, `--verbose`/`-v`, and the target as a positional argument. That is likely sufficient.

**Detection:** Test argument parsing on both macOS and Linux (or in a Docker container).

**Affected scripts:** All 65+ scripts if argument parsing is standardized.

**Phase mapping:** Address in argument parsing phase. Build the parser in `common.sh` as a reusable function.

**Confidence:** HIGH -- verified from [getopts POSIX spec](https://pubs.opengroup.org/onlinepubs/7908799/xcu/getopts.html), [Bash Hackers getopts tutorial](https://bash-hackers.gabe565.com/howto/getopts_tutorial/), and confirmed that macOS ships BSD getopt by default.

---

### Pitfall 9: Two inconsistent interactive-guard patterns create maintenance confusion

**What goes wrong:** The codebase uses two logically equivalent but syntactically different patterns for the interactive guard:
- Pattern A (19 scripts): `[[ -t 0 ]] || exit 0`
- Pattern B (44 scripts): `[[ ! -t 0 ]] && exit 0`

These are functionally identical but look different. When adding dual-mode execution, the refactor must touch all 63 of these lines. Inconsistency increases the chance that some are missed or refactored differently.

**Why it happens:** The two patterns evolved at different times. The `examples.sh` scripts (written first) use Pattern A. The use-case scripts (written later) use Pattern B.

**Consequences:** Not a runtime issue -- both patterns work correctly. But during the hardening refactor, if only one pattern is searched for, ~30% of scripts are missed. Additionally, code review becomes harder when the same concept is expressed two different ways.

**Prevention:**
1. Standardize on ONE pattern before beginning the dual-mode refactor. Recommendation: `[[ ! -t 0 ]] && exit 0` (Pattern B) because it reads more naturally ("if not interactive, exit").
2. Or better: replace both with a function call:
   ```bash
   # In common.sh
   require_interactive() {
       [[ -t 0 ]] || exit 0
   }
   ```
   Then all scripts use `require_interactive` before the demo section.
3. Use a single search-and-replace pass to normalize before beginning other refactoring.

**Detection:** `grep -rn '\-t 0\]' scripts/` shows both patterns.

**Affected scripts:** All 63 scripts with interactive demos.

**Phase mapping:** Address FIRST, before dual-mode or any other refactoring. This is a 5-minute normalization that prevents mistakes in later phases.

**Confidence:** HIGH -- directly observed in codebase grep results.

---

### Pitfall 10: `awk "BEGIN {exit !($var > threshold)}"` pattern for float comparison is fragile under `set -e`

**What goes wrong:** The diagnostic scripts use awk for floating-point comparison:
```bash
if awk "BEGIN {exit !($total_time > 5.0)}" 2>/dev/null; then
```
This works because awk's `exit` with 0 means "true" (the condition was met) and exit 1 means "false". But if `$total_time` is empty, malformed, or contains characters that break awk syntax, awk crashes with exit code 2. Under `set -e`, even inside an `if` conditional, a syntax error in the awk program can cause unexpected behavior.

The pattern also embeds shell variables directly into awk programs via string interpolation, which is an injection risk if variables contain unexpected characters (e.g., from parsed network output containing spaces or special characters).

**Why it happens:** Bash has no native floating-point arithmetic. The awk workaround is standard but fragile. Network tool output can contain unexpected characters, and the diagnostic scripts parse this output into variables that are then interpolated into awk programs.

**Consequences:** Diagnostic scripts crash on edge cases: latency values like "N/A", negative values, or empty strings from tools that timed out. The `2>/dev/null` suppresses the awk error message but the exit code still propagates.

**Prevention:**
1. Always validate the variable before the awk comparison:
   ```bash
   if [[ -n "$total_time" && "$total_time" =~ ^[0-9]+\.?[0-9]*$ ]] && \
      awk "BEGIN {exit !($total_time > 5.0)}" 2>/dev/null; then
   ```
2. The current code partially does this with `[[ -n "$total_time" ]] &&` but does not validate the format.
3. Consider a helper function:
   ```bash
   float_gt() {
       local a="${1:-0}" b="${2:-0}"
       [[ "$a" =~ ^[0-9]+\.?[0-9]*$ ]] || return 1
       [[ "$b" =~ ^[0-9]+\.?[0-9]*$ ]] || return 1
       awk "BEGIN {exit !($a > $b)}" 2>/dev/null
   }
   ```
4. Alternatively, use `bc` where available: `(( $(echo "$total_time > 5.0" | bc -l) ))` -- but `bc` is not always installed.

**Detection:** Run performance diagnostic against a host that returns unusual mtr/traceroute output (e.g., all hops timeout, giving empty timing values).

**Affected scripts:** `diagnostics/performance.sh` (6 instances), `diagnostics/connectivity.sh` (1 instance).

**Phase mapping:** Address in strict mode phase when auditing all conditional patterns.

**Confidence:** MEDIUM -- the current guards are partially effective. The injection risk is theoretical (variables come from tool output, not user input). But the empty/malformed value case is a real edge case.

---

## Minor Pitfalls

---

### Pitfall 11: macOS `date` syntax differs from GNU `date` for timestamp formatting

**What goes wrong:** Adding structured logging with timestamps requires `date` formatting. macOS ships BSD `date` which uses `-j -f` for custom formats. GNU/Linux `date` uses `-d` for date parsing. The connectivity diagnostic already handles this (line 273-274):
```bash
expire_epoch=$(date -j -f "%b %d %T %Y %Z" "$expire_line" "+%s" 2>/dev/null || \
               date -d "$expire_line" "+%s" 2>/dev/null || echo "")
```

**Prevention:**
1. For timestamps in logs, `date +"%Y-%m-%dT%H:%M:%S%z"` (ISO 8601) works on both macOS and Linux.
2. For epoch timestamps, `date +%s` works on both platforms.
3. For parsing dates (like certificate expiry), use the fallback pattern already in the codebase.
4. Avoid `date -v` (macOS-only) and `date -d` (GNU-only) in new code without a fallback.

**Detection:** Run on both macOS and Linux (or in Docker).

**Affected scripts:** Any new logging infrastructure added to `common.sh`.

**Phase mapping:** Address in structured logging phase.

**Confidence:** HIGH -- the codebase already handles this in `connectivity.sh`.

---

### Pitfall 12: Adding argument parsing to scripts that share positional parameter conventions with the Makefile

**What goes wrong:** The Makefile passes `TARGET` to scripts as `$1`:
```makefile
nmap: ## Run nmap examples
    @bash scripts/nmap/examples.sh $(TARGET)
```
If argument parsing is added and the script starts expecting `--target` instead of a positional argument, all 50+ Makefile targets break simultaneously.

**Prevention:**
1. Maintain backward compatibility: positional `$1` MUST still work as the target. New flags are additive.
2. The parser should treat the first non-flag argument as TARGET:
   ```bash
   # These must all work:
   # ./script.sh 192.168.1.1
   # ./script.sh --verbose 192.168.1.1
   # ./script.sh 192.168.1.1 --verbose
   ```
3. Update the Makefile only after all scripts are updated and tested.
4. Do NOT add `--` requirements between flags and positional arguments for simple scripts.

**Detection:** Run `make nmap TARGET=scanme.nmap.org` after adding argument parsing. Must still work.

**Affected scripts:** All 50+ scripts called from Makefile targets.

**Phase mapping:** Address in argument parsing phase. Test Makefile compatibility before and after.

**Confidence:** HIGH -- directly observed from Makefile analysis.

---

### Pitfall 13: Over-engineering the logging system with external dependencies (jq, logger, etc.)

**What goes wrong:** Structured logging articles recommend using `jq` for JSON output, `logger` for syslog integration, or external logging libraries. Adding any external dependency to the logging path means every script now requires that dependency. The project's value proposition is "run one command, get what you need" -- adding `jq` as a requirement for basic script operation contradicts this.

**Prevention:**
1. The logging system must use ONLY bash builtins and `printf`/`date` (universally available).
2. JSON output (if needed) should be generated with `printf` string formatting, not `jq`.
3. `logger` (syslog) is optional and should never be required for script operation.
4. The default output MUST remain human-readable colored text (the current format). Structured output is an OPT-IN mode triggered by `--json` or an environment variable like `LOG_FORMAT=json`.
5. Do not add `jq`, `yq`, or any other JSON processor as a dependency.

**Detection:** Run `scripts/check-tools.sh` -- the logging system should work even if only the most basic Unix tools are installed.

**Affected scripts:** `common.sh` logging functions, all 65+ scripts that use `info/warn/error/success`.

**Phase mapping:** Address in structured logging phase. Define constraints before implementation.

**Confidence:** HIGH -- architectural decision based on project principles in CLAUDE.md.

---

### Pitfall 14: Dual-mode `main()` wrapper hides errors that `set -e` would catch at top level

**What goes wrong:** Wrapping script logic in `main() { ... }` and calling it as `main "$@"` changes how `set -e` behaves. If `main` is ever called from a conditional context (e.g., `if main; then` or `main || handle_error`), `set -e` is SUSPENDED inside `main`. Errors that would have killed the script at top level now silently pass.

**Why it happens:** This is bash spec behavior: "The ERR trap and the -e setting are not inherited by command substitutions" and "The -e setting is disabled while executing a compound list following the while, until, if, or elif reserved word, a pipeline beginning with !, or any command of an AND-OR list except the last."

**Consequences:** A script that "works" when run directly may silently swallow errors when called from another script with error handling.

**Prevention:**
1. The `main` function should ALWAYS be called unconditionally at the bottom of the script:
   ```bash
   [[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
   ```
   Never: `[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@" || exit 1`
2. Do not call `main` from conditional contexts.
3. Inside `main`, use explicit error checking (`if ! command; then exit 1; fi`) rather than relying on `set -e` for critical operations.
4. For library usage (when sourced), callers should call individual functions, not `main`.

**Detection:** Hard to detect. Requires understanding of bash's `set -e` scoping rules.

**Affected scripts:** Any script refactored to use `main()` wrapper.

**Phase mapping:** Address in dual-mode execution phase. Document the pattern clearly.

**Confidence:** HIGH -- verified from [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105) and [Greg's Wiki](https://mywiki.wooledge.org/BashGuide/Practices).

---

### Pitfall 15: `declare -A` (associative array) in `check-tools.sh` requires bash 4+, but macOS ships bash 3.2

**What goes wrong:** `check-tools.sh` uses `declare -A TOOLS=()` (line 27) for associative arrays. macOS ships bash 3.2 (from 2007, due to GPLv3 licensing). Associative arrays require bash 4.0+. The script currently works because most macOS users have a newer bash from Homebrew, and the shebang `#!/usr/bin/env bash` picks up the Homebrew version.

**Why it happens:** macOS system bash is `/bin/bash` (version 3.2). Homebrew bash is `/opt/homebrew/bin/bash` or `/usr/local/bin/bash` (version 5.x). The `#!/usr/bin/env bash` shebang finds whichever is first in `$PATH`. If a user has not installed Homebrew bash, `declare -A` fails with a syntax error.

**Consequences:** Not a new issue -- this exists today. But when hardening scripts, be aware that adding new bash 4+ features (like `${var,,}` for lowercase, `${!array[@]}` for indirect expansion, or `readarray`/`mapfile`) makes the macOS system bash problem worse.

**Prevention:**
1. Document that bash 4+ is required in the project README.
2. `common.sh` could add a version check: `[[ ${BASH_VERSINFO[0]} -lt 4 ]] && error "Requires bash 4+" && exit 1`.
3. Avoid adding more bash 4+ features unless they provide clear value.
4. The `_run_with_timeout` function in `common.sh` already handles the macOS `timeout` absence -- apply the same portability mindset to bash features.

**Detection:** Run `check-tools.sh` with `/bin/bash` on macOS: `/bin/bash scripts/check-tools.sh`.

**Affected scripts:** `check-tools.sh` (currently), potentially all scripts if new features are added.

**Phase mapping:** Address at the start of the hardening work with a bash version check in `common.sh`.

**Confidence:** HIGH -- verified: macOS Sequoia still ships bash 3.2.57.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Strict mode audit | `grep` without `|| true` in non-conditional context (Pitfall 3) | Audit every grep call; categorize by context |
| Strict mode audit | `((counter++))` from zero (Pitfall 2) | Standardize on `var=$((var + 1))` |
| Strict mode audit | awk float comparison with empty/malformed variables (Pitfall 10) | Add format validation before awk calls |
| Structured logging | Logging metadata obscures educational content (Pitfall 7) | Separate "operations" from "educational content" |
| Structured logging | External dependencies like jq (Pitfall 13) | Use only bash builtins for logging |
| Structured logging | macOS date format differences (Pitfall 11) | Use ISO 8601 format which works on both platforms |
| Argument parsing | `getopt` not portable (Pitfall 8) | Use manual `while/case` parser |
| Argument parsing | Makefile backward compatibility (Pitfall 12) | Positional `$1` must still work as target |
| Argument parsing | `set -u` after shift (Pitfall 6) | Check `$#` before accessing `$1` in parse loops |
| Dual-mode execution | `set -e` not inherited in conditional contexts (Pitfall 14) | Call `main` unconditionally |
| Dual-mode execution | `set -e` propagation when sourced (Pitfall 5) | Do not add dual-mode to `common.sh` |
| Pre-refactor cleanup | Two interactive guard patterns (Pitfall 9) | Normalize to one pattern before other refactoring |
| Cross-platform | bash 4+ features on macOS system bash (Pitfall 15) | Add version check to `common.sh` |
| Tool wrappers | stderr output tools under pipefail (Pitfall 4) | Document per-tool stderr behavior |

## Over-Engineering Traps

These are not pitfalls in the traditional sense, but traps where the hardening work itself becomes counterproductive.

### Trap A: Adding `set -e` error handling that is MORE fragile than no error handling

`set -e` has so many exceptions and edge cases that it can give a false sense of safety. Code that "works" without `set -e` can break WITH it due to the complex rules about conditional contexts, subshells, and command lists. The current codebase already has `set -euo pipefail` in `common.sh` and handles the known edge cases. Do not add additional layers of error handling on top (like trap ERR) unless there is a specific gap.

### Trap B: Making every script accept 15 flags when it only needs 2

These are educational scripts. The argument parser should support `--help`, `--verbose` (maybe), and the target as a positional argument. Do not add `--format`, `--output-file`, `--timeout`, `--no-color`, `--config` etc. unless there is a demonstrated need. Each flag is a maintenance burden multiplied by 65+ scripts.

### Trap C: Building a "framework" instead of hardening scripts

The goal is to harden existing scripts, not to build a bash framework. If the common.sh changes require every script to be restructured around a new execution model, the scope has expanded beyond the original goal. Changes to common.sh should be additive -- new functions that scripts can opt into, not breaking changes to existing functions.

### Trap D: JSON logging that nobody will parse

If no downstream system (CI, monitoring, log aggregation) consumes JSON logs, then JSON output is overhead without benefit. Add structured logging only if there is a consumer. For this educational project, the consumer is a human reading the terminal -- the current colored text format is already optimized for this consumer.

## Sources

- [BashFAQ/105 - Why doesn't set -e do what I expected?](https://mywiki.wooledge.org/BashFAQ/105) -- comprehensive set -e pitfalls
- [Unofficial Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/) -- grep, arithmetic, and pipefail issues
- [Bash Hackers Wiki - Arithmetic Expressions](https://bash-hackers.gabe565.com/syntax/arith_expr/) -- exit code behavior of `(( ))`
- [Greg's Wiki - BashGuide/Practices](https://mywiki.wooledge.org/BashGuide/Practices) -- sourcing, error handling, and dual-mode patterns
- [Greg's Wiki - BashPitfalls](https://mywiki.wooledge.org/BashPitfalls) -- comprehensive list of common bash mistakes
- [getopts POSIX specification](https://pubs.opengroup.org/onlinepubs/7908799/xcu/getopts.html) -- long option limitations
- [Bash Hackers - getopts tutorial](https://bash-hackers.gabe565.com/howto/getopts_tutorial/) -- getopts capabilities and constraints
- [set -e pipefail explanation (GitHub Gist)](https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425) -- community-maintained set -e reference
- Codebase analysis: 65+ scripts in `/Users/patrykattc/work/git/networking-tools/scripts/`, `common.sh`, Makefile
