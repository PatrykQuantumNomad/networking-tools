---
phase: 31-remaining-tool-skills
plan: 01
subsystem: skills
tags: [hashcat, john, aircrack-ng, foremost, claude-skills, password-cracking, wireless, forensics]

requires:
  - phase: 29-initial-tool-skills
    provides: Validated SKILL.md pattern (nmap, tshark, metasploit, nikto, sqlmap)
provides:
  - Hashcat skill with GPU benchmark, NTLM cracking, web hash cracking categories
  - John skill with linux passwords, archive cracking, hash identification categories
  - Aircrack-ng skill with wireless analysis, handshake capture, WPA cracking categories
  - Foremost skill with file recovery, targeted carving, forensic analysis categories
affects: [32-remaining-tool-skills, 33-skill-pack-verification]

tech-stack:
  added: []
  patterns:
    - "Offline-tool Target Validation (no network scope needed)"
    - "Platform restriction documentation (Linux-only for aircrack-ng)"

key-files:
  created:
    - .claude/skills/hashcat/SKILL.md
    - .claude/skills/john/SKILL.md
    - .claude/skills/aircrack-ng/SKILL.md
    - .claude/skills/foremost/SKILL.md
  modified: []

key-decisions:
  - "Used offline-tool Target Validation variant for hashcat, john, foremost (no network scope needed)"
  - "Aircrack-ng gets unique wireless Target Validation (BSSID scope applies to wireless interfaces)"
  - "Followed per-script accurate argument documentation pattern from Phase 29"

patterns-established:
  - "Offline-tool Target Validation: 'operates on local files -- no network scope validation required'"
  - "Platform restriction notes in Defaults section for OS-specific tools"

requirements-completed: [TOOL-06, TOOL-07, TOOL-10, TOOL-17]

duration: 3min
completed: 2026-02-18
---

# Phase 31 Plan 01: Offline/File-Based Tool Skills Summary

**Claude Code skill files for hashcat, john, aircrack-ng, and foremost with accurate per-script arguments and offline-tool Target Validation**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-18T01:59:27Z
- **Completed:** 2026-02-18T02:02:44Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments
- Created hashcat skill with GPU benchmark, NTLM cracking, and web hash cracking script references
- Created john skill with linux password, archive cracking, and hash identification script references
- Created aircrack-ng skill with wireless analysis, handshake capture, and WPA cracking references plus Linux-only platform restriction
- Created foremost skill with file recovery, targeted carving, and forensic analysis references
- All 4 skills use disable-model-invocation: true (zero context overhead)
- Offline tools (hashcat, john, foremost) have modified Target Validation noting no network scope needed

## Task Commits

Each task was committed atomically:

1. **Task 1: Create hashcat and john skills** - `d9284ed` (feat)
2. **Task 2: Create aircrack-ng and foremost skills** - `262eae1` (feat)

**Plan metadata:** `b87dd53` (docs: complete plan)

## Files Created/Modified
- `.claude/skills/hashcat/SKILL.md` - GPU-accelerated password hash cracking skill (52 lines)
- `.claude/skills/john/SKILL.md` - John the Ripper password cracking skill (50 lines)
- `.claude/skills/aircrack-ng/SKILL.md` - WiFi security auditing skill with Linux-only notes (53 lines)
- `.claude/skills/foremost/SKILL.md` - File carving and forensic recovery skill (48 lines)

## Decisions Made
- Used offline-tool Target Validation variant for hashcat, john, foremost -- these tools operate on local files (hash files, archives, disk images) and never need network scope validation
- Aircrack-ng gets a unique wireless Target Validation that mentions BSSID scope since it operates on wireless interfaces rather than files or network targets
- Followed the per-script accurate argument documentation pattern established in Phase 29 (e.g., [hashfile], [archive], [interface], [capture.cap], [disk-image] instead of generic [target])

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- 4 offline/file-based tool skills complete, ready for Phase 31 Plan 02 (network scanning tools: hping3, skipfish)
- 13 of 17 total tool skills now created (nmap, tshark, metasploit, nikto, sqlmap from Phase 29 + hashcat, john, aircrack-ng, foremost from this plan + check-tools, lab, pentest-conventions from Phase 30)
- Remaining: hping3, skipfish (Plan 02), plus any additional tools in Plan 03

## Self-Check: PASSED

- All 4 SKILL.md files exist at expected paths
- Both task commits found in git log (d9284ed, 262eae1)
- All files contain disable-model-invocation: true
- Offline tools have no-network-scope Target Validation
- Aircrack-ng has Linux-only platform restriction documented

---
*Phase: 31-remaining-tool-skills*
*Completed: 2026-02-18*
