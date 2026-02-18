---
phase: 32-workflow-skills
plan: 02
subsystem: skills

tags: [tshark, hashcat, john, gobuster, ffuf, nikto, workflow-skills, pentesting]

requires:
  - phase: 31-remaining-tool-skills
    provides: tshark, hashcat, john, gobuster, ffuf, nikto use-case scripts with -j/-x support

provides:
  - /fuzz workflow: 3-step web fuzzing orchestrating gobuster, ffuf, and nikto
  - /crack workflow: 5-step password cracking with identification-then-attack flow
  - /sniff workflow: 3-step traffic capture orchestrating 3 tshark scripts

affects:
  - 32-03-workflow-skills (report/scope skills, same SKILL.md pattern)
  - Any future pentesting workflow expansions

tech-stack:
  added: []
  patterns:
    - "Workflow SKILL.md: numbered steps with bash scripts/tool/script.sh $ARGUMENTS -j -x"
    - "Offline workflow variant: no network scope validation for local-file tools (hashcat, john)"
    - "Conditional step execution: identify hash type first, then run only matching cracker"
    - "Dual-mode target: $ARGUMENTS accepts interface OR pcap file (sniff)"

key-files:
  created:
    - .claude/skills/fuzz/SKILL.md
    - .claude/skills/crack/SKILL.md
    - .claude/skills/sniff/SKILL.md
  modified: []

key-decisions:
  - "All 3 workflow skills use disable-model-invocation: true (user must explicitly invoke, prevents auto-triggering)"
  - "/crack Step 4 (crack-linux-passwords.sh) takes no positional argument -- script handles /etc/shadow internally"
  - "/crack uses identification-then-attack flow: always run hash ID first, then only matching cracker steps"
  - "/sniff accepts both live interface and .pcap file as $ARGUMENTS for dual-mode operation"
  - "/crack notes offline operation explicitly -- no network scope validation needed for local hash files"

patterns-established:
  - "Workflow skill offline variant: replace scope validation guard with 'local files -- no network scope needed'"
  - "Conditional step pattern: numbered steps with (if applicable) label and skip instruction"
  - "Decision table pattern: hash-type-to-tool mapping table for workflows requiring branching"

duration: 3min
completed: 2026-02-18
---

# Phase 32 Plan 02: Workflow Skills (fuzz/crack/sniff) Summary

**Three specialized offensive workflow SKILL.md files: /fuzz (gobuster+ffuf+nikto), /crack (john hash-ID + 4 conditional crackers), /sniff (3 tshark scripts, interface or pcap)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T03:10:58Z
- **Completed:** 2026-02-18T03:13:36Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `/fuzz` skill orchestrating directory brute-force (gobuster), parameter fuzzing (ffuf), and web vulnerability scanning (nikto) with numbered steps and `-j -x` flags
- Created `/crack` skill with identification-then-attack flow (5 steps: john hash ID, hashcat NTLM, hashcat web hashes, john linux passwords, john archive passwords) including a decision table mapping hash types to tools; correctly handles offline operation with no network scope validation
- Created `/sniff` skill capturing HTTP credentials, analyzing DNS queries, and extracting files from captures, supporting both live interface and pcap file input

## Task Commits

Each task was committed atomically:

1. **Task 1: Create /fuzz and /sniff workflow skills** - `02ed4e7` (feat)
2. **Task 2: Create /crack workflow skill** - `a9729c1` (feat)

**Plan metadata:** `[final commit hash]` (docs: complete plan)

## Files Created/Modified

- `.claude/skills/fuzz/SKILL.md` -- 3-step web fuzzing workflow (gobuster, ffuf, nikto)
- `.claude/skills/sniff/SKILL.md` -- 3-step traffic capture workflow (tshark x3, live + pcap)
- `.claude/skills/crack/SKILL.md` -- 5-step password cracking workflow with conditional steps and decision table

## Decisions Made

- All 3 skills use `disable-model-invocation: true` (consistent with Phase 32 research recommendation to prevent unintended auto-execution of offensive workflows)
- `/crack` Step 4 (`crack-linux-passwords.sh`) intentionally omits `$ARGUMENTS` -- the script handles `/etc/shadow` internally and takes no positional argument
- `/crack` uses identification-then-attack flow with a decision table: run Step 1 (hash identification) always, then select only the matching cracking step (2-5)
- `/crack` explicitly notes "local files -- no network scope validation needed" to differentiate from network-oriented workflows
- `/sniff` target section explains dual-mode: `$ARGUMENTS` can be a network interface (live capture) or a `.pcap` file (offline analysis)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 3 of 8 workflow skills created (plan 01: recon/scan/diagnose, plan 02: fuzz/crack/sniff)
- Ready for Phase 32-03: /report and /scope management workflows
- Pattern established: offline workflow variant (no network scope) confirmed working for crack skill

## Self-Check

- [x] `.claude/skills/fuzz/SKILL.md` exists with 3 bash scripts and 3 `-j -x` flags
- [x] `.claude/skills/sniff/SKILL.md` exists with 3 bash scripts and 3 `-j -x` flags
- [x] `.claude/skills/crack/SKILL.md` exists with 5 bash scripts and 5 `-j -x` flags
- [x] All 3 have `disable-model-invocation: true`
- [x] `crack-linux-passwords.sh` has no positional `$ARGUMENTS`
- [x] All skills under 200 lines (fuzz: 65, crack: 99, sniff: 66)
- [x] Commits 02ed4e7 and a9729c1 exist

---
*Phase: 32-workflow-skills*
*Completed: 2026-02-18*
