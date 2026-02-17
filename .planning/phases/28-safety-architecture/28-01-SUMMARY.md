---
phase: 28-safety-architecture
plan: 01
subsystem: safety
tags: [hooks, pretooluse, posttooluse, audit, scope, jq, bash, jsonl]

# Dependency graph
requires: []
provides:
  - "PreToolUse hook for target validation and raw tool interception"
  - "PostToolUse hook for JSON bridge and audit logging"
  - "Hook registrations in settings.json with Bash matcher"
  - ".pentest/ gitignore for scope and audit data"
affects: [29-tool-skill-development, 30-json-output-framework, 31-claude-skill-packaging, 32-testing-quality-assurance, 33-documentation-polish]

# Tech tracking
tech-stack:
  added: [jq, bash-hooks]
  patterns: [pretooluse-safety-hook, posttooluse-json-bridge, jsonl-audit-logging, scope-allowlist-validation]

key-files:
  created:
    - .claude/hooks/netsec-pretool.sh
    - .claude/hooks/netsec-posttool.sh
  modified:
    - .claude/settings.json
    - .gitignore

key-decisions:
  - "Used jq for all JSON construction to avoid escaping bugs in string concatenation"
  - "curl/dig exception: skip interception when command contains http:// or https:// URLs"
  - "CIDR /24 support via simple 3-octet prefix match (documented limitation)"
  - "Localhost and 127.0.0.1 treated as equivalent in scope validation"
  - "Target extraction strips shell metacharacters to handle embedded quotes"

patterns-established:
  - "Hook fast-exit: non-Bash tools exit 0 immediately, then non-security commands exit 0, minimizing latency for unrelated commands"
  - "Hook deny JSON: {hookSpecificOutput:{permissionDecision:'deny',permissionDecisionReason:...,additionalContext:...}}"
  - "Hook additionalContext JSON: {hookSpecificOutput:{hookEventName:'PostToolUse',additionalContext:...}}"
  - "Audit JSONL format: {timestamp, event, tool, command, target, reason, script, session}"
  - "Scope file at .pentest/scope.json with {targets:[...]} structure"

requirements-completed: [SAFE-01, SAFE-02, SAFE-03, SAFE-04]

# Metrics
duration: 8min
completed: 2026-02-17
---

# Phase 28 Plan 01: Safety Hooks Summary

**PreToolUse/PostToolUse bash+jq safety hooks with target allowlist validation, raw tool interception with wrapper redirect, JSON envelope bridge to additionalContext, and JSONL audit logging**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-17T20:09:06Z
- **Completed:** 2026-02-17T20:16:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- PreToolUse hook blocks raw tool commands (nmap, tshark, etc.) with actionable redirect to wrapper scripts in scripts/ directory
- PreToolUse hook validates targets against .pentest/scope.json allowlist with CIDR /24 and localhost equivalence support
- PostToolUse hook parses JSON envelope output from -j wrapper scripts and injects one-line summary as additionalContext for Claude
- Both hooks log all security-tool events (blocked, allowed, executed) to date-stamped JSONL audit files
- Non-security commands (git, ls, npm, node, python) fast-exit with zero processing overhead
- Both hooks registered in settings.json with Bash matcher alongside existing SessionStart hook

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PreToolUse hook for target validation and raw tool interception** - `d65e7d3` (feat)
2. **Task 2: Create PostToolUse hook, register both hooks in settings.json, and gitignore .pentest/** - `9518c1f` (feat)

## Files Created/Modified
- `.claude/hooks/netsec-pretool.sh` - PreToolUse hook: target validation (SAFE-01), raw tool interception (SAFE-02), audit logging (SAFE-04) -- 216 lines
- `.claude/hooks/netsec-posttool.sh` - PostToolUse hook: JSON bridge (SAFE-03), audit logging (SAFE-04) -- 114 lines
- `.claude/settings.json` - Added PreToolUse and PostToolUse hook registrations with Bash matcher
- `.gitignore` - Added .pentest/ exclusion for scope and audit data

## Decisions Made
- Used jq for all JSON construction (both output and audit entries) to prevent escaping bugs from string concatenation
- curl and dig get special treatment: only intercepted for bare IP/hostname usage, not for URL-based commands (http:// https://)
- CIDR /24 matching uses simple 3-octet prefix comparison (sufficient for lab use, documented limitation for production)
- Target extraction strips shell metacharacters (quotes, semicolons, backticks, pipes) to handle edge cases where hook sees expanded command text
- Tool-to-script-directory mapping uses bash associative array for O(1) lookup

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Target extraction captured trailing quotes from expanded command text**
- **Found during:** Task 2 verification (PostToolUse testing)
- **Issue:** When the PreToolUse hook processed commands containing embedded JSON strings (e.g., `echo '...' | bash`), the target extraction regex captured trailing quote characters as part of the target, causing scope validation to fail with `localhost"` instead of `localhost`
- **Fix:** Added sed filter to strip shell metacharacters (`"';\`|&(){}`) from the extracted target
- **Files modified:** .claude/hooks/netsec-pretool.sh (line 140)
- **Verification:** Re-ran all tests with scope file; targets extracted cleanly without trailing quotes
- **Committed in:** 9518c1f (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential fix for correctness when hooks process commands with embedded strings. No scope creep.

## Issues Encountered
- The PreToolUse hook became active immediately after settings.json was updated in Task 2, which caused it to intercept test commands that contained `scripts/` in their JSON payload strings. Resolved by creating a temporary scope file before running PostToolUse verification tests.

## User Setup Required

None - no external service configuration required. Users will need to create `.pentest/scope.json` with their allowed targets before running wrapper scripts, but the hook itself provides actionable error messages guiding this setup.

## Next Phase Readiness
- Safety hooks are the foundation for all subsequent v1.5 phases
- Phase 29 (tool skill development) can now rely on hooks to enforce scope and intercept raw tools
- Phase 30 (JSON output framework) will produce the envelope format that PostToolUse already parses
- PostToolUse `tool_response.stdout` field access works as expected (blocker from STATE.md resolved)

## Self-Check: PASSED

All files found, all commits verified, all must_have artifacts validated (line counts, key patterns, key_links).

---
*Phase: 28-safety-architecture*
*Completed: 2026-02-17*
