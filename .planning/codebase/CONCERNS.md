# Codebase Concerns

**Analysis Date:** 2026-02-17

## Tech Debt

**BC dependency in retry_with_backoff:**
- Issue: `scripts/lib/cleanup.sh:83` uses `bc` for exponential backoff calculation (`delay=$(echo "$delay * 2" | bc)`)
- Files: `scripts/lib/cleanup.sh`
- Impact: Runtime failure if `bc` is not installed (not a default macOS/Linux tool on minimal systems)
- Fix approach: Replace with pure bash arithmetic: `delay=$((delay * 2))` for integer delays, or use bash printf for decimal math

**eval in cleanup handler:**
- Issue: `scripts/lib/cleanup.sh:31` uses `eval "$cmd"` to execute registered cleanup commands
- Files: `scripts/lib/cleanup.sh`
- Impact: Potential command injection if untrusted input reaches `register_cleanup()`. Currently low risk (only internal usage), but fragile design pattern.
- Fix approach: Store cleanup commands as function names instead of arbitrary strings, or use associative arrays with validated callback patterns

**Large diagnostic scripts:**
- Issue: Diagnostic scripts have grown to 243-345 lines with complex control flow
- Files: `scripts/diagnostics/connectivity.sh` (345 lines), `scripts/diagnostics/performance.sh` (292 lines), `scripts/diagnostics/dns.sh` (243 lines)
- Impact: Harder to test, maintain, and extend. Multiple responsibilities (parsing, execution, reporting, OS detection)
- Fix approach: Extract helper functions to `scripts/lib/diagnostic.sh`, create shared report renderer, isolate OS-specific logic

**Platform-specific code scattered:**
- Issue: OS detection (`uname -s`) and Darwin/Linux branching appears in multiple individual scripts instead of centralized helpers
- Files: `scripts/diagnostics/connectivity.sh`, `scripts/diagnostics/performance.sh`, `scripts/diagnostics/dns.sh`
- Impact: Inconsistent platform handling, duplicated logic, harder to add new platform support
- Fix approach: Add `scripts/lib/platform.sh` with functions like `is_macos()`, `is_linux()`, `get_primary_interface()`, `portable_ping()`

**JSON mode fd3 fallback complexity:**
- Issue: `scripts/lib/json.sh:142-146` uses file descriptor 3 with fallback to stdout, complicates testing and error handling
- Files: `scripts/lib/json.sh`
- Impact: Harder to debug when fd3 redirect fails silently. Test harness must know to redirect fd3.
- Fix approach: Document fd3 contract in @usage header, add diagnostic mode that warns if fd3 is not available

## Known Bugs

**None identified in core functionality:**
- No open bugs found in script logic or library functions
- All 265 BATS tests passing (v1.3 milestone audit)

## Security Considerations

**Safety banner suppressible:**
- Risk: `safety_banner()` is skipped in JSON mode, potentially allowing automated execution without ethical hacking reminder
- Files: `scripts/lib/output.sh:13-22`
- Current mitigation: `confirm_execute()` still enforces interactive confirmation in execute mode
- Recommendations: Add legal disclaimer to README.md about authorized use only, regardless of JSON mode

**Metasploit payload generation:**
- Risk: Scripts demonstrate reverse shell generation without prominent warnings about payload handling
- Files: `scripts/metasploit/generate-reverse-shell.sh`
- Current mitigation: `safety_banner()` shown before execution, script is educational-only by default
- Recommendations: Add explicit comments warning against uploading generated payloads to shared environments or antivirus scanners

**Wordlists in repository:**
- Risk: 140MB `rockyou.txt` committed to repository, potential for accidental exposure if used with real passwords
- Files: `wordlists/rockyou.txt` (140MB), `wordlists/directory-list-2.3-small.txt` (725KB)
- Current mitigation: Wordlists are public datasets, `.gitignore` excludes output files (*.pot, *.log)
- Recommendations: Consider moving to external download via `make wordlists` exclusively, document that wordlists are public datasets only

**Vulnerable lab containers:**
- Risk: Docker Compose runs intentionally vulnerable apps (DVWA, Juice Shop, WebGoat, VulnerableApp) without network isolation warnings
- Files: `labs/docker-compose.yml`
- Current mitigation: Warning comment in docker-compose.yml: "Only run them on isolated networks. Never expose to the internet."
- Recommendations: Add `networks: internal` configuration to Docker Compose to enforce isolation, update README.md with explicit "DO NOT expose ports beyond localhost" section

## Performance Bottlenecks

**Retry function sleep blocking:**
- Problem: `retry_with_backoff()` uses blocking `sleep` calls with exponential backoff
- Files: `scripts/lib/cleanup.sh:82`
- Cause: Synchronous sleep with `bc` calculation overhead
- Improvement path: Acceptable for current use case (rare retries), but could use bash `SECONDS` for non-blocking checks if used in tight loops

**Diagnostic timeout fallback:**
- Problem: macOS fallback for timeout uses background processes and `sleep` watchdog
- Files: `scripts/lib/diagnostic.sh:23-39`
- Cause: macOS lacks GNU `timeout` command, POSIX fallback spawns 3 processes per check
- Improvement path: Install GNU coreutils on macOS (already common in CI/CD), or use bash `read -t` for simpler timeout pattern

## Fragile Areas

**Bash 4.0+ requirement:**
- Files: `scripts/common.sh:8-15`
- Why fragile: Breaks on default macOS bash (3.2), error message depends on Bash 2.x syntax working
- Safe modification: Always test changes to `common.sh` on macOS default bash and brew-installed bash 5.x
- Test coverage: Covered by smoke.bats suite, but no explicit test for error message readability on bash 3.2

**Netcat variant detection:**
- Files: `scripts/lib/nc_detect.sh`, `scripts/netcat/setup-listener.sh`, `scripts/netcat/transfer-files.sh`, `scripts/netcat/scan-ports.sh`
- Why fragile: Detection relies on parsing help text from `nc -h` which varies across 4+ implementations (ncat, GNU nc, traditional nc, OpenBSD nc)
- Safe modification: Add new variants to `detect_nc_variant()` first, then update scripts. Test on ncat (Nmap), GNU netcat, and OpenBSD netcat (macOS default).
- Test coverage: No unit tests for variant detection (relies on manual testing per platform)

**ShellCheck disable directives:**
- Files: `scripts/lib/args.sh:70` (SC2034 for color vars), `scripts/lib/output.sh:31` (SC2034 for PROJECT_ROOT)
- Why fragile: Disabling checks can mask real issues if code refactored without revisiting suppression
- Safe modification: Always re-run ShellCheck after library refactors, document WHY each directive is needed (already done in comments)
- Test coverage: CI runs ShellCheck on every commit (`.github/workflows/shellcheck.yml`)

**John the Ripper *2john path setup:**
- Files: `scripts/lib/validation.sh:36-65`
- Why fragile: Homebrew, MacPorts, and Linux packages install zip2john/rar2john in different locations. Detection searches 4 possible paths.
- Safe modification: Test on both Homebrew Intel (`/usr/local/opt/john-jumbo`) and Apple Silicon (`/opt/homebrew/opt/john-jumbo`)
- Test coverage: Not tested in CI (John not installed in GH Actions), relies on local verification

## Scaling Limits

**BATS test discovery:**
- Current capacity: 265 tests across 9 BATS files
- Limit: As scripts grow beyond 100 files, `find` + `bats_test_function` may slow down test startup
- Scaling path: Already using efficient pattern (dynamic discovery), no immediate issue. Could parallelize with `bats -j` flag if needed.

**Diagnostic script execution time:**
- Current capacity: 3 diagnostic scripts (connectivity, dns, performance) run in 5-15 seconds each
- Limit: As checks increase, sequential `run_check()` calls could exceed 1 minute
- Scaling path: Parallelize independent checks with background jobs, collect results via wait + associative array

**Site build with 17+ tool pages:**
- Current capacity: Astro builds 17 tool pages + guides in ~10 seconds
- Limit: Static site generation scales well, but adding 50+ more tool pages could slow dev server HMR
- Scaling path: Astro is already optimized for hundreds of pages, no action needed

## Dependencies at Risk

**Aircrack-ng macOS limitations:**
- Risk: Homebrew `aircrack-ng` package only includes cracking tools, not monitor mode tools
- Impact: Examples scripts show Linux-only commands that fail on macOS
- Migration plan: Already handled with `check_cmd airmon-ng` and OS-specific warnings in output. Document limitations in README.md (already present).

**Skipfish not in Homebrew:**
- Risk: Requires MacPorts installation (`sudo port install skipfish`), adds setup friction
- Impact: Tool not available on default macOS Homebrew setup
- Migration plan: Add Homebrew tap if skipfish becomes available, or provide Docker-based alternative

**jq required for JSON mode:**
- Risk: JSON mode (`-j` flag) fails if `jq` not installed
- Impact: Scripts exit with error before generating any output
- Migration plan: Already handled with `_json_require_jq()` check in `scripts/lib/json.sh:32-36`. Clear error message provided.

## Missing Critical Features

**No macOS timeout command:**
- Problem: Diagnostic scripts use POSIX fallback (`sleep` + background kill) instead of GNU timeout
- Blocks: Reliable process timeouts on macOS without external dependencies
- Solution: Document GNU coreutils installation (`brew install coreutils`) for `gtimeout`, or accept fallback behavior

**No automated tool installation:**
- Problem: `make check` detects missing tools but doesn't offer to install them
- Blocks: One-command setup for new contributors
- Solution: Add `make install-tools` target with OS detection (Homebrew for macOS, apt/dnf for Linux)

## Test Coverage Gaps

**Netcat variant detection:**
- What's not tested: `detect_nc_variant()` function behavior across 4 netcat implementations
- Files: `scripts/lib/nc_detect.sh`
- Risk: Variant detection could break on new netcat versions without CI catching it
- Priority: Medium (manual testing currently covers this, but fragile)

**Platform-specific code paths:**
- What's not tested: macOS vs Linux branching in diagnostic scripts
- Files: `scripts/diagnostics/connectivity.sh:60-68`, `scripts/diagnostics/performance.sh`, `scripts/diagnostics/dns.sh`
- Risk: macOS-specific code could break on Linux CI (which only tests Linux paths)
- Priority: Medium (covered by manual testing, but no automated cross-platform verification)

**setup_john_path() function:**
- What's not tested: John the Ripper *2john utility path setup
- Files: `scripts/lib/validation.sh:36-65`
- Risk: Path detection could fail on new package manager versions
- Priority: Low (stable across Homebrew/MacPorts/Linux packages for years)

**EXIT trap cleanup under SIGKILL:**
- What's not tested: Temp file cleanup when scripts are killed with SIGKILL
- Files: `scripts/lib/cleanup.sh:21-38`
- Risk: SIGKILL cannot be trapped, orphaned temp files in `/tmp/ntool-session.*`
- Priority: Low (EXIT trap handles SIGTERM/SIGINT correctly, SIGKILL is rare)

**JSON mode fd3 edge cases:**
- What's not tested: Behavior when fd3 cannot be opened (e.g., all file descriptors exhausted)
- Files: `scripts/lib/json.sh:142-146`
- Risk: JSON output goes to stdout instead of fd3, mixing with stderr redirects
- Priority: Low (fd3 redirect failure is extremely rare, fallback to stdout is documented)

---

*Concerns audit: 2026-02-17*
