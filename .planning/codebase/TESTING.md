# Testing Patterns

**Analysis Date:** 2026-02-10

## Test Framework & Approach

**Testing Strategy:** Manual testing and integration testing via shell scripts

**Framework:**
- No unit testing framework detected (no Jest, Mocha, pytest, or similar)
- No automated test runner or test suite
- Testing is implicit in the script structure: each script is designed to be executable and demonstrate its own functionality

**Test Execution:**
```bash
# Check tools installation
make check                          # Verify which tools are available

# Run a specific tool example
bash scripts/nmap/examples.sh <target>
make nmap TARGET=<ip>              # Via Makefile

# Test use-case scripts
bash scripts/nmap/discover-live-hosts.sh <target>
make discover-hosts TARGET=<subnet>
```

**Manual Verification:**
- Each script prints numbered examples (1-10) showing commands
- Interactive demos allow manual testing of each command
- Real execution against lab targets verifies functionality

## Lab Environment for Testing

**Lab Targets (Docker-based):**
Located in `labs/docker-compose.yml`

| Service | Port | Purpose |
|---------|------|---------|
| DVWA | 8080 | Damn Vulnerable Web Application (SQL injection, XSS) |
| Juice Shop | 3030 | OWASP Juice Shop (modern vulnerabilities) |
| WebGoat | 8888 | OWASP WebGoat (security lessons with vulnerable app) |
| VulnerableApp | 8180/2222 | Custom vulnerable target |

**Lab Operations:**
```bash
make lab-up                         # Start all vulnerable targets
make lab-down                       # Stop all targets
make lab-status                     # Show running containers
```

**Example Testing Workflow:**
1. `make lab-up` — Start DVWA and other targets
2. `make nmap TARGET=localhost` — Run nmap against DVWA
3. `make sqlmap TARGET=http://localhost:8080` — Test SQL injection
4. `make lab-down` — Clean up

## Test File Organization

**Structure:**
- No separate test files (testing is integrated into each script)
- Each `examples.sh` is both documentation AND executable test
- Each use-case script (e.g., `discover-live-hosts.sh`) is testable standalone

**File Locations:**
- Generic tool examples: `scripts/<tool>/examples.sh`
- Specific use-cases: `scripts/<tool>/<use-case>.sh`
- No separate `tests/` directory
- Lab targets: `labs/docker-compose.yml`

**Naming Convention:**
- Use-case scripts: `<verb>-<noun>(-<noun>).sh` (kebab-case)
- Examples: `discover-live-hosts.sh`, `crack-ntlm-hashes.sh`, `capture-http-credentials.sh`

## Test Structure Pattern

**Every Example Script (`examples.sh`) follows this structure:**

```bash
#!/usr/bin/env bash
# tool/examples.sh — Description

# 1. Source utilities
source "$(dirname "$0")/../common.sh"

# 2. Define help function
show_help() {
    cat <<EOF
Usage: $(basename "$0") [args]
Description: ...
Examples:
    $(basename "$0") arg1
    $(basename "$0") --help
EOF
}

# 3. Check for help flag
[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

# 4. Validate requirements
require_cmd tool_name "install_hint"
require_target "${1:-}"              # If target argument needed

# 5. Print safety banner
safety_banner

# 6. Set variables
TARGET="$1"

# 7. Display title and context
info "=== Tool Name Examples ==="
info "Target: ${TARGET}"
echo ""

# 8. Print 10 numbered examples
info "1) Example title"
echo "   command here"
echo ""

# 9. Interactive demo (if terminal)
[[ -t 0 ]] || exit 0
read -rp "Run command? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: command"
    command "$TARGET"
fi
```

**Concrete Example from `scripts/nmap/examples.sh` (lines 33-41):**
```bash
# 1. Quick host discovery (ping scan — no port scan)
info "1) Ping scan — is the host up?"
echo "   nmap -sn ${TARGET}"
echo ""

# 2. Fast top-100 port scan
info "2) Quick scan — top 100 ports"
echo "   nmap -F ${TARGET}"
echo ""
```

## Use-Case Script Pattern

**Every use-case script (e.g., `crack-linux-passwords.sh`) extends the basic pattern:**

```bash
#!/usr/bin/env bash
# tool/use-case.sh — Description

source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [arg] [-h|--help]"
    echo ""
    echo "Description: ..."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") arg          # Do this"
    echo "  $(basename "$0") --help       # Show help"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd tool_name "install_hint"
# Note: No require_target if no argument needed

TARGET="${1:-default_value}"

safety_banner

# Educational context (WHY section)
info "=== Context Title ==="
echo "   Explain why this matters..."
echo "   What's being demonstrated..."
echo ""

# 10 numbered examples
info "1) Example title"
echo "   command"
echo ""

# Interactive demo
[[ ! -t 0 ]] && exit 0

read -rp "Prompt for user action? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: command"
    # Execute demo
fi
```

**Example from `scripts/john/crack-linux-passwords.sh` (lines 24-40):**
```bash
info "=== Linux Password Cracking ==="
echo ""

info "How Linux stores passwords"
echo "   Linux passwords are hashed in /etc/shadow (readable only by root)."
echo "   The hash format is: \$id\$salt\$hash"
echo ""
echo "   Common hash type prefixes:"
echo "   \$6\$  = SHA-512 (most common on modern Linux)"
echo "   \$5\$  = SHA-256"
# ... more context ...
echo ""
```

## Interactive Testing Pattern

**Terminal Detection:**
```bash
# Skip interactive demo if piped or in non-interactive environment
[[ -t 0 ]] || exit 0

# OR check with is_interactive helper
is_interactive && {
    # Run demo
}
```

**User Prompt Pattern:**
```bash
read -rp "Prompt text? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: command"
    command_to_test "$TARGET"
fi
```

**Examples:**
- From `nmap/examples.sh` (lines 84-89):
  ```bash
  [[ -t 0 ]] || exit 0
  read -rp "Run a quick ping scan on ${TARGET} now? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
      info "Running: nmap -sn ${TARGET}"
      nmap -sn "$TARGET"
  fi
  ```

- From `crack-ntlm-hashes.sh` (lines 99-117):
  ```bash
  [[ ! -t 0 ]] && exit 0

  read -rp "Create a temp hash file and attempt to crack it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
      TMPFILE=$(mktemp /tmp/ntlm-demo.XXXXXX)
      echo "a4f49c406510bdcab6824ee7c30fd852" > "$TMPFILE"
      # ... test command ...
      rm -f "$TMPFILE"
  fi
  ```

## Temporary File Management

**Pattern:**
Use `mktemp` to create safe temporary files, then clean up:

```bash
TMPFILE=$(mktemp /tmp/script-name.XXXXXX)
# Use file
info "Test hash written to: ${TMPFILE}"
# Clean up
rm -f "$TMPFILE"
```

**Example from `crack-linux-passwords.sh` (lines 102-122):**
```bash
TMPFILE=$(mktemp /tmp/john-demo.XXXXXX)
# Generate test hash
echo "$HASH" > "$TMPFILE"
info "Test hash written to: ${TMPFILE}"
# Crack it
john --format=sha512crypt "$TMPFILE"
# Clean up
rm -f "$TMPFILE"
```

## Validation Testing

**Command Existence Check:**
```bash
require_cmd tool_name "install_hint"
```
- Exits with error message if tool not found
- Provides install instructions

**Target Validation:**
```bash
require_target "${1:-}"
```
- Exits with usage error if no target provided
- Reminds user about authorization

**Root Privilege Check:**
```bash
require_root
```
- Exits if not running as root/sudo

**Boolean Command Check:**
```bash
if check_cmd python3; then
    # Use python3
else
    # Use fallback
fi
```

**Example from `crack-linux-passwords.sh` (lines 104-109):**
```bash
if check_cmd python3; then
    HASH=$(python3 -c "import crypt; ..." 2>/dev/null) || true
fi
if [[ -z "${HASH:-}" ]] && check_cmd openssl; then
    HASH="testuser:\$6\$..." || true
fi
```

## Safety Banner Testing

**Requirement:** All scripts that perform active scanning display `safety_banner` before operations

```bash
safety_banner                       # From common.sh
# Output:
# ========================================
# AUTHORIZED USE ONLY
# Only scan targets you own or have
# explicit written permission to test.
# ========================================
```

**Scripts requiring banner:**
- `nmap/examples.sh` (line 25)
- `tshark/examples.sh` (line 23)
- `sqlmap/examples.sh` (line 24)
- All use-case scripts that perform active scanning

## Makefile Testing Targets

**Convenience targets for running tests:**
```bash
make check              # Verify tool installation
make lab-up             # Start vulnerable test targets
make lab-down           # Stop test targets
make lab-status         # Check container status

# Tool-specific runners (pass TARGET variable)
make nmap TARGET=localhost
make sqlmap TARGET=http://localhost:8080
make discover-hosts TARGET=192.168.1.0/24
```

## Coverage Strategy

**What's Tested:**
- Tool availability via `check-tools.sh`
- Lab target startup via Docker compose
- Command syntax validation (examples show correct flags)
- Interactive demonstrations (manual testing)

**What's NOT Tested:**
- Automated regression testing (no test suite)
- Unit tests for individual functions (not applicable for shell utilities)
- End-to-end scanning against live production targets
- Performance benchmarks (except `hashcat/benchmark-gpu.sh`)

**Gap: Test Coverage**
- No automated validation of example commands
- No test runner to verify all scripts are syntactically valid
- Lab targets are tested manually, not in CI/CD pipeline
- No validation that examples match actual tool behavior

## Wordlist Resources

**Location:** `wordlists/`

**Download:**
```bash
make wordlists          # Download rockyou.txt (required for cracking scripts)
bash wordlists/download.sh
```

**Used By:**
- `scripts/john/crack-linux-passwords.sh` — References `${PROJECT_ROOT}/wordlists/rockyou.txt`
- `scripts/hashcat/crack-ntlm-hashes.sh` — References `${PROJECT_ROOT}/wordlists/rockyou.txt`
- `scripts/hashcat/crack-web-hashes.sh`

**Pattern:**
```bash
WORDLIST="${PROJECT_ROOT}/wordlists/rockyou.txt"
```

## Error Scenarios

**Testing error conditions:**

1. **Missing tool:** Script exits with requirement error
   ```bash
   require_cmd toolname "install hint"
   ```

2. **Missing target:** Script exits with usage error
   ```bash
   require_target "${1:-}"
   ```

3. **Temporary file failure:** Graceful cleanup
   ```bash
   TMPFILE=$(mktemp /tmp/xxx.XXXXXX)
   # Use file
   rm -f "$TMPFILE"
   ```

4. **Command timeout:** Use `timeout` with fallback
   ```bash
   timeout 5 "$tool" --version 2>/dev/null | head -1 || echo "installed"
   ```

5. **Optional tools:** Fallback handling in demos
   ```bash
   if check_cmd python3; then
       # Use python3
   elif check_cmd openssl; then
       # Use openssl
   else
       warn "No hash generator available"
   fi
   ```

---

*Testing analysis: 2026-02-10*
