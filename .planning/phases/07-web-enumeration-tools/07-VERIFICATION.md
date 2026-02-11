---
phase: 07-web-enumeration-tools
verified: 2026-02-11T02:19:51Z
status: gaps_found
score: 4/5 must-haves verified
gaps:
  - truth: "Running bash scripts/gobuster/examples.sh <url> prints 10 numbered educational examples for gobuster"
    status: partial
    reason: "Script exists and prints 10 examples, but uses incorrect -d flag instead of -do for DNS mode (gobuster v3.6+ requirement)"
    artifacts:
      - path: "scripts/gobuster/examples.sh"
        issue: "Lines 64, 69 use 'gobuster dns -d' instead of 'gobuster dns -do'"
      - path: "scripts/gobuster/enumerate-subdomains.sh"
        issue: "Lines 54-107 use 'gobuster dns -d' instead of 'gobuster dns -do' (8 occurrences)"
      - path: "site/src/content/docs/tools/gobuster.mdx"
        issue: "Lines 138, 141, 144 show 'gobuster dns -d' instead of 'gobuster dns -do'"
    missing:
      - "Change all 'gobuster dns -d' to 'gobuster dns -do' in examples.sh"
      - "Change all 'gobuster dns -d' to 'gobuster dns -do' in enumerate-subdomains.sh"
      - "Update gobuster.mdx DNS mode examples to use -do flag"
      - "Update gobuster.mdx Key Flags table to show '-d DOMAIN' changed to '-do DOMAIN' for DNS mode"
---

# Phase 7: Web Enumeration Tools Verification Report

**Phase Goal:** Users can learn gobuster and ffuf for web content discovery and fuzzing, with wordlist infrastructure that makes the tools immediately usable against lab targets.

**Verified:** 2026-02-11T02:19:51Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running `bash scripts/gobuster/examples.sh http://localhost:8080` prints 10 numbered educational examples for gobuster | ⚠️ PARTIAL | Script exists (96 lines), prints 10 numbered examples (lines 33-80), follows Pattern A with source common.sh, require_cmd, safety_banner, and interactive demo. **BUT** uses incorrect `-d` flag instead of `-do` for DNS mode (examples 7-8). PLAN explicitly states "use -do not -d per research" for gobuster v3.6+ compatibility. |
| 2 | Running `bash scripts/ffuf/examples.sh http://localhost:8080` prints 10 numbered educational examples for ffuf | ✓ VERIFIED | Script exists (100 lines), prints 10 numbered examples with FUZZ keyword explanation, all commands use `-t 10` as required, follows Pattern A, includes wordlist existence check and interactive demo. |
| 3 | Use-case scripts discover-directories, enumerate-subdomains (gobuster) and fuzz-parameters (ffuf) work against lab targets | ⚠️ PARTIAL | All 3 use-case scripts exist and follow pattern (110, 109, 109 lines). discover-directories.sh and fuzz-parameters.sh are correct. **BUT** enumerate-subdomains.sh uses `-d` flag instead of `-do` throughout (8 occurrences), will fail on gobuster v3.6+. |
| 4 | A wordlist download helper fetches SecLists common directories and subdomains wordlists for use with both tools | ✓ VERIFIED | wordlists/download.sh (83 lines) downloads 4 wordlists: rockyou.txt (existing), common.txt, directory-list-2.3-small.txt, and subdomains-top1million-5000.txt from SecLists. Skip logic for already-downloaded files present. Links to danielmiessler/SecLists verified. |
| 5 | `make check` detects gobuster and ffuf with clear install hints (Homebrew, Go install, binary download) | ✓ VERIFIED | check-tools.sh has both tools in TOOLS array (lines 44-45) and TOOL_ORDER array. get_version() cases for gobuster (gobuster version) and ffuf (ffuf -V) present. Test shows correct detection with install hints: "brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)" and same for ffuf. |

**Score:** 4/5 truths verified (1 partial due to -d vs -do flag issue)

### Required Artifacts

#### Plan 07-01 (gobuster)

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/gobuster/examples.sh` | 10 numbered gobuster examples following Pattern A, min 80 lines | ⚠️ STUB | ✓ EXISTS (96 lines), ✓ SUBSTANTIVE (10 examples, safety_banner, require_cmd, interactive demo), ✓ WIRED (sources common.sh line 3). **BUT** uses `-d` instead of `-do` for DNS mode (lines 64, 69) — violates PLAN requirement. |
| `scripts/gobuster/discover-directories.sh` | Directory enumeration use-case with wordlist check, min 60 lines | ✓ VERIFIED | ✓ EXISTS (110 lines), ✓ SUBSTANTIVE (10 examples, wordlist existence check, educational context), ✓ WIRED (sources common.sh, uses PROJECT_ROOT/wordlists/) |
| `scripts/gobuster/enumerate-subdomains.sh` | DNS subdomain enumeration use-case, min 60 lines | ⚠️ STUB | ✓ EXISTS (109 lines), ✓ SUBSTANTIVE (10 examples, wordlist check, educational context), ✓ WIRED (sources common.sh, uses PROJECT_ROOT/wordlists/). **BUT** uses `-d` instead of `-do` for DNS mode throughout (8 occurrences) — will fail on gobuster v3.6+. |
| `site/src/content/docs/tools/gobuster.mdx` | Site documentation with install tabs | ⚠️ PARTIAL | ✓ EXISTS (181 lines), ✓ SUBSTANTIVE (contains Tabs import, 3 OS install tabs, key flags table, use-case descriptions), ✓ WIRED (linked from navigation). **BUT** DNS mode examples use `-d` instead of `-do` (lines 138, 141, 144), and Key Flags table shows `-d DOMAIN` instead of `-do DOMAIN` for DNS mode. |

#### Plan 07-02 (ffuf)

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/ffuf/examples.sh` | 10 numbered ffuf examples following Pattern A, min 80 lines | ✓ VERIFIED | ✓ EXISTS (100 lines), ✓ SUBSTANTIVE (10 examples with FUZZ keyword explanation, all use `-t 10`), ✓ WIRED (sources common.sh line 3, uses PROJECT_ROOT/wordlists/) |
| `scripts/ffuf/fuzz-parameters.sh` | Parameter fuzzing use-case with wordlist check, min 60 lines | ✓ VERIFIED | ✓ EXISTS (109 lines), ✓ SUBSTANTIVE (10 parameter fuzzing examples, wordlist check, educational context on IDOR/debug flags), ✓ WIRED (sources common.sh, uses PROJECT_ROOT/wordlists/) |
| `site/src/content/docs/tools/ffuf.mdx` | Site documentation with install tabs | ✓ VERIFIED | ✓ EXISTS (182 lines, verified via head check), ✓ SUBSTANTIVE (contains Tabs import line 7, install tabs, FUZZ keyword explanation), ✓ WIRED (linked from navigation, sidebar order 18) |

#### Plan 07-03 (wordlists & docs)

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wordlists/download.sh` | Downloads 4 wordlists (rockyou + 3 SecLists), contains "common.txt" | ✓ VERIFIED | ✓ EXISTS (83 lines), ✓ SUBSTANTIVE (downloads rockyou.txt, common.txt, directory-list-2.3-small.txt, subdomains-top1million-5000.txt with skip logic), ✓ WIRED (sources common.sh, curl to danielmiessler/SecLists URLs verified lines 32, 48, 64) |
| `USECASES.md` | Updated use-case reference with web enumeration entries, contains "discover-dirs" | ✓ VERIFIED | ✓ EXISTS, ✓ SUBSTANTIVE (grep shows "discover-dirs" line 40, "fuzz-params" line 42, "Web Enumeration & Fuzzing" section, engagement flow updated with "Enumerate" step lines 122-123), ✓ WIRED (referenced in project docs) |

### Key Link Verification

#### Plan 07-01 Links

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `scripts/gobuster/examples.sh` | `scripts/common.sh` | source directive | ✓ WIRED | Line 3: `source "$(dirname "$0")/../common.sh"` |
| `scripts/gobuster/discover-directories.sh` | `wordlists/` | WORDLIST variable pointing to PROJECT_ROOT/wordlists/ | ✓ WIRED | Line 26: `WORDLIST="${2:-$PROJECT_ROOT/wordlists/common.txt}"` |
| `scripts/check-tools.sh` | gobuster | TOOLS array and TOOL_ORDER | ✓ WIRED | Line 44: `[gobuster]="brew install..."`, TOOL_ORDER includes gobuster, get_version() has gobuster case |
| `Makefile` | `scripts/gobuster/examples.sh` | gobuster target | ✓ WIRED | Line 212: `gobuster:` target calls `scripts/gobuster/examples.sh $(TARGET)` |

#### Plan 07-02 Links

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `scripts/ffuf/examples.sh` | `scripts/common.sh` | source directive | ✓ WIRED | Line 3: `source "$(dirname "$0")/../common.sh"` |
| `scripts/ffuf/fuzz-parameters.sh` | `wordlists/` | WORDLIST variable pointing to PROJECT_ROOT/wordlists/ | ✓ WIRED | Line 26: `WORDLIST="${2:-$PROJECT_ROOT/wordlists/common.txt}"` |
| `scripts/check-tools.sh` | ffuf | TOOLS array and TOOL_ORDER | ✓ WIRED | Line 45: `[ffuf]="brew install..."`, TOOL_ORDER includes ffuf, get_version() has ffuf case |
| `Makefile` | `scripts/ffuf/examples.sh` | ffuf target | ✓ WIRED | Line 221: `ffuf:` target calls `scripts/ffuf/examples.sh $(TARGET)` |

#### Plan 07-03 Links

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `wordlists/download.sh` | `scripts/common.sh` | source directive | ✓ WIRED | Line 3: `source "$(dirname "$0")/../scripts/common.sh"` |
| `wordlists/download.sh` | SecLists | curl download URLs | ✓ WIRED | Lines 32, 48, 64: curl to danielmiessler/SecLists URLs for common.txt, directory-list, subdomains |
| `Makefile` | `wordlists/download.sh` | wordlists target (already exists) | ✓ WIRED | Existing target verified working |

### Requirements Coverage

Phase 7 maps to requirements: TOOL-019, TOOL-020, TOOL-021, TOOL-022, TOOL-023, TOOL-024, INFRA-008, INFRA-009 (partial)

| Requirement | Description | Status | Blocking Issue |
|-------------|-------------|--------|----------------|
| TOOL-019 | gobuster examples.sh | ⚠️ PARTIAL | Uses `-d` instead of `-do` for DNS mode |
| TOOL-020 | gobuster: discover-directories.sh | ✓ SATISFIED | All checks pass |
| TOOL-021 | gobuster: enumerate-subdomains.sh | ⚠️ PARTIAL | Uses `-d` instead of `-do` for DNS mode |
| TOOL-022 | ffuf examples.sh | ✓ SATISFIED | All checks pass |
| TOOL-023 | ffuf: fuzz-parameters.sh | ✓ SATISFIED | All checks pass |
| TOOL-024 | Wordlist download extension | ✓ SATISFIED | All checks pass |
| INFRA-008 | check-tools.sh: gobuster, ffuf | ✓ SATISFIED | Both tools detected with version commands and install hints |
| INFRA-009 | Makefile: gobuster/ffuf targets (partial) | ✓ SATISFIED | All 5 targets present: gobuster, discover-dirs, enum-subdomains, ffuf, fuzz-params |

**Coverage:** 6/8 requirements fully satisfied, 2/8 partial (blocked by -d vs -do flag issue)

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `scripts/gobuster/examples.sh` | 64 | Incorrect flag: `gobuster dns -d` | 🛑 Blocker | Will fail on gobuster v3.6+ which requires `-do` for DNS mode. PLAN explicitly states "use -do not -d per research". |
| `scripts/gobuster/examples.sh` | 69 | Incorrect flag: `gobuster dns -d` | 🛑 Blocker | Same as above, second DNS example |
| `scripts/gobuster/enumerate-subdomains.sh` | 54, 59, 64, 69, 74, 84, 89, 99, 107 | Incorrect flag: `gobuster dns -d` (8 occurrences) | 🛑 Blocker | All DNS examples will fail on gobuster v3.6+. Interactive demo (line 107) will also fail. |
| `site/src/content/docs/tools/gobuster.mdx` | 138, 141, 144 | Incorrect flag: `gobuster dns -d` | 🛑 Blocker | Documentation shows incorrect syntax that will fail on modern gobuster |
| `site/src/content/docs/tools/gobuster.mdx` | ~56 | Key Flags table shows `-d DOMAIN` for DNS mode | ⚠️ Warning | Documentation inconsistency — should show `-do DOMAIN` or `-d DOMAIN (legacy, use -do in v3.6+)` |

### Human Verification Required

None. All verification was programmatic via file checks and grep patterns. The `-d` vs `-do` flag issue is objective and does not require human testing.

### Gaps Summary

**Critical Gap:** The gobuster DNS mode implementation uses the legacy `-d` flag instead of the modern `-do` flag required by gobuster v3.6+. This affects:

1. **scripts/gobuster/examples.sh** — Examples 7 and 8 (DNS subdomain enumeration) use `gobuster dns -d example.com` instead of `gobuster dns -do example.com`
2. **scripts/gobuster/enumerate-subdomains.sh** — All 10 examples plus the interactive demo use `-d` flag (8 occurrences total)
3. **site/src/content/docs/tools/gobuster.mdx** — All DNS mode code examples show `-d` syntax (3 occurrences)

The PLAN explicitly states: "DNS subdomain enumeration: gobuster dns -do example.com ... (use -do not -d per research)" and "enumerate-subdomains.sh example 1: Basic subdomain enumeration with -do flag (NOT -d)". The PLAN's Notes section also says: "Notes section covering: wordlist requirement, -do flag (not -d) for DNS mode in v3.6+".

This is a **blocker gap** because:
- Users with gobuster v3.6+ will get errors when running DNS examples
- The interactive demo in enumerate-subdomains.sh will fail
- Documentation teaches incorrect syntax
- Violates explicit PLAN requirements based on research findings

**Impact:** Medium severity — dir mode and vhost mode examples work correctly. Only DNS subdomain enumeration is affected. But for users specifically wanting to enumerate subdomains (a core use case listed in success criteria), the scripts are broken.

**Fix required:**
1. Change `gobuster dns -d` to `gobuster dns -do` in all 3 files (13 total changes)
2. Update gobuster.mdx Key Flags table to show `-do DOMAIN` for DNS mode (or note that `-d` is legacy)

All other must-haves are verified and working correctly.

---

_Verified: 2026-02-11T02:19:51Z_
_Verifier: Claude (gsd-verifier)_
