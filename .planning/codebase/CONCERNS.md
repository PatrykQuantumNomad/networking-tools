# Codebase Concerns

**Analysis Date:** 2026-02-23

---

## Tech Debt

**Interactive demo section bypasses `make_temp()` in three scripts:**
- Issue: Three scripts create temp files directly via `mktemp /tmp/<name>.XXXXXX` in the interactive demo block, bypassing the `make_temp()` abstraction from `lib/cleanup.sh`. If the user kills the script mid-demo (Ctrl-C), these files are not cleaned up by the EXIT trap because they were never registered in `_CLEANUP_BASE_DIR`.
- Files:
  - `scripts/john/crack-linux-passwords.sh:139` — `TMPFILE=$(mktemp /tmp/john-demo.XXXXXX)`
  - `scripts/hashcat/crack-ntlm-hashes.sh:144` — `TMPFILE=$(mktemp /tmp/ntlm-demo.XXXXXX)`
  - `scripts/hashcat/crack-web-hashes.sh:149` — `TMPFILE=$(mktemp /tmp/md5-demo.XXXXXX)`
- Impact: Stale temp files accumulate in `/tmp/` if the demo is interrupted. Minor but inconsistent with the established `make_temp` contract.
- Fix approach: Replace `mktemp /tmp/...` calls with `make_temp file "prefix"` so files fall inside `_CLEANUP_BASE_DIR` and are auto-cleaned on exit.

**`TMPDIR` variable clobbered in interactive demo block:**
- Issue: `scripts/john/crack-archive-passwords.sh:155` assigns `TMPDIR=$(mktemp -d /tmp/john-zip-demo.XXXXXX)`. `TMPDIR` is a POSIX/macOS system variable that controls the default temp directory. Overwriting it inside the demo block means any subsequent `mktemp` calls (including those in `make_temp`) would use this temp dir, which is then `rm -rf`'d at line 177. In practice the scope is local to the if-block, but under `set -e` a mid-demo failure could leave `TMPDIR` pointing to a deleted directory for the rest of the process.
- Files: `scripts/john/crack-archive-passwords.sh:155–177`
- Impact: Low likelihood of hitting this, but if anything calls `mktemp` after line 177 and before the script exits, it may fail silently or write files into the deleted path.
- Fix approach: Rename to a local variable (`DEMO_TMPDIR`) and use `make_temp dir "john-zip-demo"`.

**`eval` usage in `register_cleanup` dispatch:**
- Issue: `scripts/lib/cleanup.sh:31` uses `eval "$cmd"` to execute registered cleanup commands. Any caller passing unsanitized strings to `register_cleanup()` would introduce arbitrary code execution.
- Files: `scripts/lib/cleanup.sh:31`
- Impact: No current callers appear to pass user input to `register_cleanup()`, so exploitation risk is low in practice. However, the pattern is fragile — a future caller could accidentally pass interpolated user-controlled data.
- Fix approach: Accept a function name + args array instead of a raw string, invoke with `"$@"` rather than `eval`.

**`retry_with_backoff` depends on `bc` for exponential backoff:**
- Issue: `scripts/lib/cleanup.sh:83` computes the delay as `delay=$(echo "$delay * 2" | bc)`. `bc` is not installed by default on all minimal Linux environments (Alpine, some container base images).
- Files: `scripts/lib/cleanup.sh:83`
- Impact: `retry_with_backoff` silently fails to multiply the delay if `bc` is absent (it gets an empty string, which is treated as 0 by arithmetic). The function still retries but with no delay.
- Fix approach: Replace with pure Bash arithmetic: `delay=$(( delay * 2 ))`.

**`mtr` listed in `check-tools.sh` but has no dedicated `scripts/mtr/` directory:**
- Issue: `scripts/check-tools.sh:53` includes `mtr` in `TOOL_ORDER` alongside all other tools, implying it is a first-class tool. However, `mtr` has no `scripts/mtr/` directory, no `examples.sh`, and no use-case scripts of its own. It appears exclusively as a dependency in `scripts/traceroute/` and `scripts/diagnostics/`.
- Files: `scripts/check-tools.sh:53`, `scripts/traceroute/examples.sh:36,68–92`
- Impact: Users running `make check` see `mtr` in the tool list but cannot run `make mtr` or find dedicated examples. Adds confusion about the tool scope.
- Fix approach: Either add a `scripts/mtr/` directory with an `examples.sh` consistent with the other tools, or remove `mtr` from `TOOL_ORDER` and document it as an optional dependency of the traceroute tool instead.

**`diagnostics/` scripts do not participate in the JSON output system:**
- Issue: All scripts under `scripts/diagnostics/` use Pattern B (auto-report, no `parse_common_args`, no `json_set_meta`/`json_finalize`). This means they cannot be consumed via the `-j` flag that all other use-case scripts support. The integration tests explicitly exclude `diagnostics/` from JSON output checks.
- Files: `scripts/diagnostics/connectivity.sh`, `scripts/diagnostics/dns.sh`, `scripts/diagnostics/performance.sh`
- Impact: Inconsistent user-facing API: most scripts support `-j`/`--json`, diagnostic scripts do not. Automation/tooling that wraps the whole suite with `-j` will silently skip diagnostics output.
- Fix approach: Either accept the two-pattern design as intentional and document it explicitly, or refactor diagnostics scripts to support `parse_common_args` and `json_finalize` with `run_check` results accumulated as JSON.

---

## Security Considerations

**Docker lab containers bind to all interfaces with `restart: unless-stopped`:**
- Risk: All four lab containers (DVWA, Juice Shop, WebGoat, VulnerableApp) use `restart: unless-stopped` and bind to ports without specifying a host interface. Docker maps these to `0.0.0.0` by default, meaning the intentionally vulnerable apps are reachable on all network interfaces after `make lab-up`, including any LAN or VPN interface. They will also auto-restart on system reboot.
- Files: `labs/docker-compose.yml:15,23,32,41`
- Current mitigation: The compose file header warns to only run on isolated networks.
- Recommendations: Bind ports to localhost explicitly (`"127.0.0.1:8080:80"` etc.) so containers are not accidentally exposed on LAN. Consider removing `restart: unless-stopped` or using `restart: no` so containers do not auto-start after a reboot when the user may not expect them to be running.

**`tshark/capture-http-credentials.sh` defaults to `en0` (macOS primary interface):**
- Risk: The default interface `en0` in `scripts/tshark/capture-http-credentials.sh:33` and `scripts/tshark/analyze-dns-queries.sh:34` is the primary Wi-Fi adapter on macOS. Running with `-x` against the default target on a shared network captures traffic from the real LAN, not just the lab environment.
- Files: `scripts/tshark/capture-http-credentials.sh:33`, `scripts/tshark/analyze-dns-queries.sh:34`
- Current mitigation: `safety_banner` is displayed; `confirm_execute` requires interactive confirmation before `-x` mode runs.
- Recommendations: Change the default interface to `lo0` (loopback) to make accidental real-network capture harder. Document clearly that `en0` is only appropriate when targeting lab traffic on the same interface.

**`metasploit/setup-listener.sh` and `generate-reverse-shell.sh` use macOS-only IP auto-detection:**
- Risk: `LHOST="${1:-$(ipconfig getifaddr en0 2>/dev/null || echo '10.0.0.1')}"` in both scripts silently falls back to `10.0.0.1` on Linux (where `ipconfig` is not available). A listener or payload generated with `LHOST=10.0.0.1` will not work unless the host happens to have that IP.
- Files: `scripts/metasploit/setup-listener.sh:34`, `scripts/metasploit/generate-reverse-shell.sh:34`
- Current mitigation: These are show-mode scripts by default — they print commands, they do not execute them.
- Recommendations: Use a portable IP detection fallback (`hostname -I | awk '{print $1}'` on Linux; `ifconfig en0 | awk '/inet /{print $2}'` on macOS) or prompt the user if auto-detection fails.

**`register_cleanup` uses `eval` on caller-supplied strings:**
- Risk: See Tech Debt section above. The `eval "$cmd"` pattern in `scripts/lib/cleanup.sh:31` would execute arbitrary bash code if user-controlled data reaches it.
- Files: `scripts/lib/cleanup.sh:31`
- Current mitigation: No current callers pass user input.
- Recommendations: Refactor to function-name-based dispatch.

---

## Fragile Areas

**`_CLEANUP_BASE_DIR` created at source time in `lib/cleanup.sh`:**
- Files: `scripts/lib/cleanup.sh:15`
- Why fragile: The base temp directory is created via `mktemp -d` when `common.sh` is sourced — before any argument parsing or target validation. If `mktemp` fails (e.g., disk full), the script exits immediately with a cryptic error before even printing help or a useful error message. Additionally, in BATS tests every `source common.sh` call creates a new `ntool-session.*` directory, which gets cleaned up on process exit but may accumulate across parallel test runs.
- Safe modification: Always call `source common.sh` first, before any other logic. Do not source `common.sh` more than once per process. Test teardown reliably handles cleanup via the EXIT trap.
- Test coverage: Covered by `tests/lib-cleanup.bats` for normal cases; `mktemp` failure path is not tested.

**`debug()` always includes timestamp, `info/warn/success` only include timestamp in verbose mode:**
- Files: `scripts/lib/logging.sh:49–54`
- Why fragile: `debug()` hardcodes `ts="[$(date '+%H:%M:%S')] "` unconditionally (line 52), while `info`, `warn`, and `success` call `_log_timestamp()` which only returns a timestamp when `VERBOSE >= 1`. This inconsistency means `debug` output always has a timestamp even in default (non-verbose) mode. Since `debug` is gated by `_should_log debug`, it is only visible in verbose mode anyway, so the practical impact is zero — but the code is misleading and could confuse contributors extending the logging module.
- Safe modification: Change `debug()` to call `_log_timestamp()` like the other logging functions.
- Test coverage: `tests/lib-logging.bats` tests log level gating but does not assert timestamp presence/absence.

**`detect_nc_variant()` uses exclusion detection for OpenBSD/macOS nc:**
- Files: `scripts/lib/nc_detect.sh:16–29`
- Why fragile: The function identifies the nc variant by matching against `ncat`, `gnu`, and `connect to somewhere` in the help text. Anything that does not match is classified as `openbsd`. This means unrecognized nc variants (e.g., a custom build or future variant) are silently misclassified as OpenBSD, causing scripts to emit incorrect flag examples (e.g., `nc -l PORT` instead of `nc -l -p PORT`).
- Safe modification: The current approach is pragmatic for the four known variants. If correctness for unknown variants matters, add a fallback `unknown` case and warn the user.
- Test coverage: Not unit-tested. Only covered implicitly through integration tests that check `--help` contract.

**`run_or_show` passes the command word-split as `"$@"` without quoting for display:**
- Files: `scripts/lib/output.sh:66`
- Why fragile: In show mode (text path), `echo "   $*"` joins all arguments with spaces. Arguments with spaces that were quoted by the caller (e.g., a filter expression) are displayed without quotes and would be misleading if a learner copies the printed command verbatim.
- Impact: Cosmetic — the educational display may omit quoting needed to run the command successfully. Does not affect execute mode (which uses `"$@"` correctly).
- Test coverage: Not tested.

---

## Performance Bottlenecks

**`_log_level_num()` spawns a subshell for every log call:**
- Problem: Every call to `info`, `warn`, `success`, or `debug` invokes `_should_log`, which in turn calls `_log_level_num` twice via command substitution (`msg_num=$(_log_level_num "$msg_level")`). Each command substitution forks a subshell. Scripts with many `info`/`echo` pairs (e.g., scripts with 10+ examples) fork dozens of subshells just for log filtering.
- Files: `scripts/lib/logging.sh:22–40`
- Cause: The level comparison is implemented as a function returning via `echo`, requiring command substitution to capture the result.
- Improvement path: Use a `declare -A` associative array for level-to-number mapping and compare directly without subshells. This is a minor optimization for educational scripts but matters if the library is used in tight loops or large-scale automation.

**`retry_with_backoff` delay calculation via `bc` spawns an external process per retry:**
- Problem: `delay=$(echo "$delay * 2" | bc)` pipes to an external `bc` process for a simple integer doubling.
- Files: `scripts/lib/cleanup.sh:83`
- Improvement path: Use `delay=$(( delay * 2 ))` — pure Bash arithmetic, no process spawn.

---

## Scaling Limits

**Wordlists are not versioned or checksummed:**
- Current capacity: `wordlists/download.sh` validates only that the downloaded file is larger than 100 bytes.
- Limit: If the upstream URL (GitHub raw / named release) changes content (e.g., SecLists renames a file — which already happened for `directory-list-2.3-small.txt`, noted in the script comment), the script downloads a 404 HTML page and passes the 100-byte size check, leaving a corrupted wordlist silently.
- Scaling path: Add SHA-256 checksums for each wordlist and validate after download. The script already has a `MIN_BYTES` guard; a checksum guard would make this robust.
- Files: `wordlists/download.sh:60–61` (note comment about upstream rename)

**Integration test script-count assertions are hardcoded numbers:**
- Current capacity: `tests/intg-cli-contracts.bats:79` asserts `count -ge 67`; `tests/intg-json-output.bats:72` asserts `count -ge 45`.
- Limit: Adding new scripts without updating these counts does not break the tests, but removing scripts could silently pass if the removal still leaves at least the minimum.
- Scaling path: The counts are documented with comments explaining why the minimum exists (macOS vs Linux difference). This is acceptable but requires manual updates when the script count changes significantly.

---

## Dependencies at Risk

**`skipfish` is not available via Homebrew (`brew install skipfish` fails):**
- Risk: `scripts/check-tools.sh:37` lists `skipfish` with install hint `sudo port install skipfish`. The tool is unmaintained upstream (last release 2012), has no Homebrew formula, and requires MacPorts on macOS. Most modern Kali/Parrot installations have removed it.
- Impact: `make check` consistently shows skipfish as NOT INSTALLED for the majority of users. The Makefile targets `quick-scan` and `scan-auth-app` silently show commands but cannot demonstrate them.
- Migration plan: Consider replacing skipfish with a maintained alternative (e.g., `wfuzz`, `feroxbuster`), or document it as Linux-only and remove the macOS install hint.
- Files: `scripts/check-tools.sh:37`, `scripts/skipfish/examples.sh`, `scripts/skipfish/quick-scan-web-app.sh`, `scripts/skipfish/scan-authenticated-app.sh`

**`vulnerables/web-dvwa` Docker image uses deprecated/unofficial image:**
- Risk: `labs/docker-compose.yml:12` uses `image: vulnerables/web-dvwa`, which is an unofficial community image that has not been updated since 2019. It may have compatibility issues with newer Docker versions or contain unpatched OS vulnerabilities within the container.
- Impact: Lab startup may fail or produce warnings on newer Docker / Docker Desktop versions. The image is intentionally vulnerable, but vulnerabilities in the base OS layer could conflict with the intended lab exercises.
- Migration plan: Switch to the official `ghcr.io/digininja/dvwa` image (actively maintained).
- Files: `labs/docker-compose.yml:12`

---

## Test Coverage Gaps

**Interactive demo blocks are not tested:**
- What's not tested: The `if [[ "${EXECUTE_MODE:-show}" == "show" ]]` block at the end of most use-case scripts (containing `read -rp` prompts and actual tool invocations) is never exercised by the test suite. The integration tests pass `--help` or `-j`, both of which exit before reaching the demo block.
- Files: All scripts under `scripts/*/` with an interactive demo section (~28 use-case scripts)
- Risk: A syntax error or logic bug in the demo block would not be caught until a human runs the script interactively. A broken `rm -rf "$TMPFILE"` in a demo handler, for instance, would leave temp files or silently fail.
- Priority: Low — demo blocks are simple and rarely change. Could be smoke-tested by running with piped stdin and checking exit code 0.

**`detect_nc_variant()` has no unit tests:**
- What's not tested: The nc variant detection logic in `scripts/lib/nc_detect.sh` is never directly tested. The function is called in `scripts/netcat/` scripts, but only through `--help` integration tests, which do not exercise the variant-specific command branches.
- Files: `scripts/lib/nc_detect.sh`
- Risk: Breakage would surface only as wrong flag examples in netcat script output (a correctness issue, not a crash).
- Priority: Low.

**`examples.sh` scripts are excluded from JSON output tests:**
- What's not tested: `tests/intg-json-output.bats:23` explicitly excludes `examples.sh` scripts from JSON coverage. Unlike use-case scripts, `examples.sh` files do call `json_set_meta` and `json_finalize` but their output is not validated.
- Files: All `scripts/*/examples.sh` (18 files)
- Risk: A broken `json_finalize` in an `examples.sh` (e.g., missing `json_set_meta` call) would produce malformed or empty JSON undetected.
- Priority: Medium — the `-j` flag is advertised but untested for this class of scripts.

**`wordlists/download.sh` has no tests:**
- What's not tested: The download validation logic (size check, failure cleanup) in `wordlists/download.sh` has no corresponding test file.
- Files: `wordlists/download.sh`
- Risk: A broken download or URL change would only be discovered when a user runs `make wordlists`. The existing size guard is the only protection.
- Priority: Low — the script is a one-time setup helper, not critical path.

---

*Concerns audit: 2026-02-23*
