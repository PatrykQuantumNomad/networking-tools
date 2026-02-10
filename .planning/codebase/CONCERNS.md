# Codebase Concerns

**Analysis Date:** 2026-02-10

## Temp File Handling

**Unsafe mktemp usage with predictable templates:**
- Issue: Multiple scripts use `mktemp /tmp/<prefix>-demo.XXXXXX` with hardcoded /tmp directory and predictable naming patterns. While X's are replaced, the prefix itself is guessable, making files discoverable by other users on shared systems.
- Files:
  - `scripts/hashcat/crack-ntlm-hashes.sh` (line 108)
  - `scripts/hashcat/crack-web-hashes.sh` (line 113)
  - `scripts/john/crack-linux-passwords.sh` (line 102)
  - `scripts/john/crack-archive-passwords.sh` (line 111: mktemp -d with TMPDIR)
- Impact: Temporary files containing sensitive data (password hashes, test data) are world-readable on multi-user systems. If scripts are interrupted, temp files may persist.
- Fix approach:
  1. Use `mktemp` without directory prefix to use system default (usually /tmp with restrictive perms)
  2. Add trap handler to ensure cleanup on script exit: `trap 'rm -f "$TMPFILE"' EXIT`
  3. Change from `$(mktemp /tmp/name.XXXXXX)` to `$(mktemp)` or `$(mktemp -t <prefix>)`

**Incomplete cleanup:**
- Issue: Only 4 occurrences of `rm -f` cleanup across ~50 scripts. Interactive demo sections create temp files but cleanup only happens if user responds with 'y'.
- Files: `scripts/hashcat/*.sh`, `scripts/john/*.sh`
- Impact: If script is killed with Ctrl+C during demo, temp files containing test passwords/hashes remain in /tmp indefinitely.
- Fix approach: Use EXIT traps in all scripts that create temp files:
  ```bash
  TMPFILE=$(mktemp)
  trap 'rm -f "$TMPFILE"' EXIT
  ```

## Error Handling Gaps

**Unquoted variables in command substitution:**
- Issue: Variables used in command substitution without quotes may cause issues with spaces or special characters.
- Files: `scripts/common.sh` line 69 (PROJECT_ROOT path construction)
- Impact: If code is moved to paths with spaces, PROJECT_ROOT expansion could fail.
- Example: `PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` is properly quoted, but pattern should be verified throughout.

**Silent failures in pipelines:**
- Issue: Scripts use `set -euo pipefail` but some commands use `|| true` to suppress errors globally, masking real problems.
- Files: All scripts with `|| true` patterns (e.g., `scripts/hashcat/crack-ntlm-hashes.sh` line 112, 115)
- Impact: Failed tool invocations appear to succeed, giving false confidence in results.
- Fix approach: Be selective with error suppression; only suppress known non-critical stderr output: `hashcat ... 2>/dev/null | grep pattern || true`

**Timeout handling for msfconsole:**
- Issue: `scripts/check-tools.sh` line 59 uses `timeout 5` for version detection, but msfconsole is known to take >5 seconds to start.
- Files: `scripts/check-tools.sh` (line 59)
- Impact: Metasploit framework falsely reports as "installed" without actually running version check.
- Fix approach: Increase timeout for msfconsole or use special case handling (check manifest file instead, which is already done at line 52-56).

## Security Considerations

**Insufficient input validation:**
- Issue: Scripts accept target parameters but don't validate IP/URL format before passing to tools. A malformed target could cause command injection or unexpected behavior.
- Files: Most tool scripts (e.g., `scripts/nmap/examples.sh`, `scripts/sqlmap/dump-database.sh`)
- Impact: Malicious input like `; rm -rf /` could be injected via target parameter.
- Current mitigation: Tools themselves handle validation and likely reject bad input, but no defensive validation in scripts.
- Recommendations:
  1. Add basic regex validation for IPs: `[[ $target =~ ^[0-9.]+$ ]]`
  2. Add URL validation for web tools: `[[ $url =~ ^https?:// ]]`
  3. Quote all command expansions: `sqlmap -u "$TARGET"` (already done in most cases)

**Hardcoded wordlist paths without existence checks:**
- Issue: Scripts assume `wordlists/rockyou.txt` exists without verifying. If not present, cracking attempts silently fail.
- Files:
  - `scripts/hashcat/crack-ntlm-hashes.sh` (line 24)
  - `scripts/hashcat/crack-web-hashes.sh` (line 24)
  - `scripts/john/crack-linux-passwords.sh` (line 21)
- Impact: Users run long-running attacks without realizing wordlist is missing.
- Fix approach: Add pre-flight check:
  ```bash
  if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: $WORDLIST"
    info "Download with: make wordlists"
    exit 1
  fi
  ```

**Credential exposure in command examples:**
- Issue: Scripts show actual credentials in comments and example output (DVWA admin/password, default ports).
- Files: `Makefile` (lines 19, 21), `README.md` (lines 47-50), multiple tool scripts
- Impact: While credentials are for intentionally vulnerable lab systems, they're visible in help output and version control.
- Current mitigation: Only used in isolated Docker containers, not production.
- Recommendations: Document in comments that these are lab-only credentials.

**Sensitive data in temp files without permissions restriction:**
- Issue: Hash files and cracking output written to /tmp with default 644 permissions (world-readable).
- Files: `scripts/hashcat/*.sh`, `scripts/john/*.sh`
- Impact: On shared systems, other users can read password hashes and cracking results.
- Fix approach: Create temp files with restricted permissions:
  ```bash
  TMPFILE=$(mktemp)
  chmod 600 "$TMPFILE"
  ```

## Testing Coverage Gaps

**No automated testing:**
- Issue: No test suite (no .test.sh, test/, tests/ directory). Scripts are educational and expected to be run manually, but no regression testing.
- Impact: Changes to common.sh or template patterns could break multiple tools without detection.
- Fix approach: Create basic integration tests for each tool validating:
  1. Help output works
  2. Examples display without errors
  3. Basic command construction is correct

**No validation of tool versions:**
- Issue: `check-tools.sh` only verifies existence, not version compatibility.
- Files: `scripts/check-tools.sh`
- Impact: If user installs incompatible version (e.g., old nmap), scripts may fail silently.
- Fix approach: Add version range validation for critical tools.

## Platform-Specific Limitations

**macOS vs Linux capability mismatch:**
- Issue: Aircrack-ng on macOS is artificially limited by Homebrew package (cracking only, no monitoring tools).
- Files: `README.md` (lines 58-72), `scripts/aircrack-ng/examples.sh`
- Impact: Users expect full WiFi testing but can only crack offline captures.
- Current mitigation: Well documented in README, scripts do not promise what macOS can't deliver.
- Recommendations: Consider Linux container alternative for full aircrack-ng capabilities.

**Skipfish availability:**
- Issue: Skipfish not available in Homebrew, requires MacPorts on macOS.
- Files: `README.md` (line 74), `scripts/skipfish/*.sh`
- Impact: Users on macOS may not have skipfish installed, but scripts don't gracefully handle this.
- Current mitigation: `require_cmd skipfish` will error with install hint.
- Recommendations: Add MacPorts detection and special install message.

## Docker Lab Issues

**No health checks:**
- Issue: Docker Compose file has no health checks for vulnerable targets.
- Files: `labs/docker-compose.yml`
- Impact: `make lab-up` completes but targets may not be ready for immediate scanning.
- Fix approach: Add healthcheck directives to ensure services are listening before declaring success.

**No port conflict detection:**
- Issue: If ports 8080, 3030, 8888, 8180 are already in use, lab-up fails silently or with cryptic error.
- Files: `labs/docker-compose.yml`
- Impact: Users don't know if lab is ready or if a previous lab instance is still running.
- Fix approach: Validate ports are available before launching; improve error messaging.

**Container restart policy may conflict:**
- Issue: All services set `restart: unless-stopped`, meaning they persist across system reboots.
- Files: `labs/docker-compose.yml` (lines 15, 22, 31, 41)
- Impact: If user forgets to `make lab-down`, containers continue consuming resources.
- Recommendations: Document in comments to run `make lab-down` when finished; consider using `no` instead for demo usage.

## Fragile Areas

**Metasploit framework integration:**
- Files: `scripts/metasploit/*`, `scripts/check-tools.sh` (lines 50-56)
- Why fragile: Metasploit is large and slow; version-manifest.txt location is hard-coded and may change. msfvenom/msfconsole paths not added to PATH by default on macOS.
- Safe modification: Verify Metasploit paths before using; consider wrapping in Docker.
- Test coverage: No verification that msfvenom actually works, only that command exists.

**Common.sh functions relied on globally:**
- Files: `scripts/common.sh`
- Why fragile: All scripts source this file. Any syntax error breaks everything.
- Safe modification: Test common.sh independently; use shellcheck to validate.
- Test coverage: No unit tests for individual functions.

**Wordlist download script:**
- Files: `wordlists/download.sh`
- Why fragile: Downloads rockyou.txt from internet (300+ MB). Network failures aren't handled well.
- Safe modification: Verify download completion with checksums; add resume capability.
- Test coverage: No tests for successful/failed downloads.

## Missing Critical Features

**No support for authenticated scanning:**
- Issue: Most tools show examples for unauthenticated access, but real-world targets require credentials.
- Files: Most tool scripts
- Impact: Limited practice value on authentication-required targets.
- Blockers: Web app scanning (nikto, skipfish) have auth examples but NTLM/domain auth not covered.

**No proxy/proxy chain support:**
- Issue: Scripts hardcoded for direct connections; no example of using Burp Suite, OWASP ZAP proxies.
- Files: All network tool scripts
- Impact: Users can't intercept/modify traffic for deeper learning.
- Blockers: Adds complexity; would require sophisticated examples.

**No support for TLS certificate pinning bypass:**
- Issue: Scripts assume standard TLS; no examples of mitmproxy, sslstrip alternatives.
- Files: `scripts/tshark/*`, `scripts/nikto/*`
- Impact: Can't practice against secured targets.

## Scaling & Performance Issues

**GPU-intensive tools without resource checks:**
- Issue: Hashcat and aircrack-ng can consume entire GPU, potentially making system unresponsive.
- Files: `scripts/hashcat/benchmark-gpu.sh`, `scripts/aircrack-ng/crack-wpa-handshake.sh`
- Impact: Users may not realize tool is running hot; no throttling/resource limiting.
- Improvement path: Add warnings about resource usage; provide conservative mode (--workload 1).

**No parallel execution safeguards:**
- Issue: Makefile targets can't be run in parallel without conflicts (e.g., multiple cracking sessions on same GPU).
- Files: `Makefile`
- Impact: User runs `make crack-wpa & make crack-ntlm &` expecting parallel, but GPU cache conflicts occur.
- Improvement path: Add locking mechanism or warn against parallel runs.

**Database dump sizing:**
- Issue: `sqlmap/dump-database.sh` example 6 (--dump-all) can extract gigabytes without warning.
- Files: `scripts/sqlmap/dump-database.sh` (line 74)
- Impact: Demo fills disk unexpectedly; network connection gets exhausted.
- Improvement path: Add size estimate before dump; provide --batch-size option.

## Dependencies at Risk

**Metasploit framework aging:**
- Risk: Metasploit requires Ruby and large number of gem dependencies; maintenance overhead increasing.
- Impact: If Metasploit team stops supporting older Ruby versions, framework may fail.
- Migration plan: Consider alternatives (msfvenom can be used independently; consider python-based tools).

**Aircrack-ng limited on macOS:**
- Risk: Homebrew formula is outdated; source distribution has more features.
- Impact: Scripts can't use latest aircrack features on macOS.
- Migration plan: Build from source or use Linux container.

---

*Concerns audit: 2026-02-10*
