# Phase 28: Safety Architecture - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

All Claude Code tool invocations pass through deterministic safety validation (PreToolUse/PostToolUse hooks) before execution, with structured feedback for both users and Claude, and a complete audit trail. This phase delivers the safety infrastructure that all subsequent skill pack phases depend on.

Scope file management UI (`/scope` command) belongs in Phase 32 (Workflow Skills). This phase creates the hooks that read the scope, not the command that writes it.

</domain>

<decisions>
## Implementation Decisions

### Target allowlist design
- **Claude's Discretion:** Allowlist mechanism (scope file vs env var vs hybrid) — Claude picks what integrates best with Claude Code hooks
- **Claude's Discretion:** Whether Docker lab targets (localhost:8080, :3000, :8888, :8180) are auto-allowed or require explicit scope — Claude picks what's most practical
- No scope set = **block everything**. No commands pass without an explicit allowlist. Safest default.

### Blocked command feedback
- Block messages are **terse + actionable**: what was blocked and what to do about it. No lengthy explanations.
- When a raw tool command is intercepted (e.g., `nmap` called directly), the message **names the specific wrapper script** to use instead (e.g., "Use scripts/nmap/discover-live-hosts.sh instead")
- **Claude receives richer context** than the user on blocks — structured data (blocked target, reason, current scope contents) so Claude can help the user fix the issue without re-reading files
- **Claude's Discretion:** Whether PostToolUse parses `-j` JSON output into a summary or passes raw JSON through — Claude picks based on context window budget and hook complexity tradeoffs
- **Claude's Discretion:** Whether raw tool bypass is a hard block or a block-with-redirect — Claude picks what fits hook mechanics best

### Audit log structure
- Log lives in **hidden directory**: `.pentest/` (gitignored)
- Format: **JSON Lines (.jsonl)** — one JSON object per line, machine-parseable with jq
- **Log everything**: both successful invocations and blocked commands. Full picture of what was attempted.
- **Session-based files**: each session gets its own log file (e.g., `audit-2026-02-17.jsonl`). Natural rotation by date, easy to archive.
- **Claude's Discretion:** Exact fields per log entry (timestamp, tool, script, target, result, etc.)

### Health-check UX
- **Full verification**: hook files exist, hooks are registered in Claude Code settings, scope file is loadable, audit directory is writable
- Output: **checklist with pass/fail** per check item (e.g., "check PreToolUse hook registered", "x Scope file not found")
- Available as **both** a standalone bash script (for debugging outside Claude) and a Claude Code skill slash command
- When issues found: **offer to fix** each one interactively (e.g., "Scope file missing. Create one? [y/N]"). Guided repair, not silent auto-fix.

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 28-safety-architecture*
*Context gathered: 2026-02-17*
