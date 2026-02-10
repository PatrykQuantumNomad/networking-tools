---
phase: 06-site-polish-and-learning-paths
plan: 01
subsystem: docs
tags: [mdx, starlight, tabs, cross-references, install-instructions]

# Dependency graph
requires:
  - phase: 04-content-migration-and-tool-pages
    provides: 15 tool pages as .md files with content
provides:
  - 15 MDX tool pages with Starlight Tabs component for OS-specific install instructions
  - Cross-reference Related Tools sections linking tools by workflow context
  - syncKey-based tab synchronization across all tool pages
affects: [06-02, 06-03]

# Tech tracking
tech-stack:
  added: ["@astrojs/starlight Tabs component"]
  patterns: ["syncKey='os' for OS tab persistence across pages", "MDX import pattern for Starlight components"]

key-files:
  created: []
  modified:
    - site/src/content/docs/tools/nmap.mdx
    - site/src/content/docs/tools/tshark.mdx
    - site/src/content/docs/tools/sqlmap.mdx
    - site/src/content/docs/tools/nikto.mdx
    - site/src/content/docs/tools/metasploit.mdx
    - site/src/content/docs/tools/hashcat.mdx
    - site/src/content/docs/tools/john.mdx
    - site/src/content/docs/tools/hping3.mdx
    - site/src/content/docs/tools/aircrack-ng.mdx
    - site/src/content/docs/tools/skipfish.mdx
    - site/src/content/docs/tools/foremost.mdx
    - site/src/content/docs/tools/dig.mdx
    - site/src/content/docs/tools/curl.mdx
    - site/src/content/docs/tools/netcat.mdx
    - site/src/content/docs/tools/traceroute.mdx

key-decisions:
  - "Metasploit uses 2-tab layout (macOS/Linux installer + Kali pre-installed) instead of standard 3-tab OS pattern"
  - "Skipfish uses 2-tab layout (MacPorts + Debian only) since not available in Homebrew or RHEL repos"
  - "Pre-installed tools (curl, netcat, traceroute) show informational text instead of install commands for macOS tab"

patterns-established:
  - "MDX import pattern: import { Tabs, TabItem } from '@astrojs/starlight/components' immediately after frontmatter"
  - "Install tabs pattern: syncKey='os' with icon='apple' for macOS, icon='linux' for Linux tabs"
  - "Related Tools pattern: ## Related Tools section at page bottom with workflow-context descriptions"

# Metrics
duration: 7min
completed: 2026-02-10
---

# Phase 06 Plan 01: Tool Page MDX Conversion and Cross-References Summary

**15 tool pages converted to MDX with synced OS-specific install tabs and workflow-based Related Tools cross-references**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-10T22:43:23Z
- **Completed:** 2026-02-10T22:50:27Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Renamed all 15 tool pages from .md to .mdx with git mv (preserves git history)
- Added Starlight Tabs component with syncKey="os" for synchronized OS tab selection across all pages
- Platform-specific install commands for macOS, Debian/Ubuntu, and RHEL/Fedora (with special cases for metasploit, skipfish, and pre-installed tools)
- Removed stale "New" badges from dig, curl, netcat, and traceroute pages
- Added Related Tools cross-reference sections to all 15 pages with workflow context explaining why tools are related

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename 15 tool pages to .mdx and add OS-specific install tabs** - `17e740f` (feat)
2. **Task 2: Add Related Tools cross-reference sections to all 15 tool pages** - `0b5e946` (feat)

## Files Created/Modified

- `site/src/content/docs/tools/nmap.mdx` - Network mapper with 3-tab install + 4 related tools
- `site/src/content/docs/tools/tshark.mdx` - Wireshark CLI with 3-tab install + 3 related tools
- `site/src/content/docs/tools/sqlmap.mdx` - SQL injection with 3-tab install + 4 related tools
- `site/src/content/docs/tools/nikto.mdx` - Web scanner with 3-tab install + 3 related tools
- `site/src/content/docs/tools/metasploit.mdx` - Pentest platform with 2-tab install + 3 related tools
- `site/src/content/docs/tools/hashcat.mdx` - GPU cracker with 3-tab install + 2 related tools
- `site/src/content/docs/tools/john.mdx` - CPU cracker with 3-tab install + 2 related tools
- `site/src/content/docs/tools/hping3.mdx` - Packet crafting with 3-tab install (custom brew tap) + 2 related tools
- `site/src/content/docs/tools/aircrack-ng.mdx` - WiFi auditing with 3-tab install + 1 related tool
- `site/src/content/docs/tools/skipfish.mdx` - Web scanner with 2-tab install (MacPorts + Debian) + 2 related tools
- `site/src/content/docs/tools/foremost.mdx` - File carving with 3-tab install + 1 related tool
- `site/src/content/docs/tools/dig.mdx` - DNS lookup with 3-tab install (replaced table) + 2 related tools
- `site/src/content/docs/tools/curl.mdx` - HTTP client with 3-tab install (pre-installed note) + 3 related tools
- `site/src/content/docs/tools/netcat.mdx` - Network swiss knife with 3-tab install (replaced table) + 2 related tools
- `site/src/content/docs/tools/traceroute.mdx` - Route tracing with 3-tab install (incl. mtr) + 2 related tools

## Decisions Made

- Metasploit uses 2-tab layout (macOS/Linux nightly installer link + Kali pre-installed) instead of standard 3-OS-tab pattern since it has no standard package manager install
- Skipfish uses 2-tab layout (MacPorts + Debian/Ubuntu only) since it is not available in Homebrew or RHEL/Fedora repos
- Pre-installed tools (curl, netcat, traceroute on macOS) show informational text instead of install commands in their macOS tab
- hping3 uses special Homebrew tap path: `brew install draftbrew/tap/hping`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 15 tool pages are MDX-ready for any future component additions
- syncKey="os" established as standard pattern for OS-specific content
- Related Tools cross-references create navigation network between tool pages
- Ready for Plan 02 (learning path guides) and Plan 03 (remaining polish)

---
*Phase: 06-site-polish-and-learning-paths*
*Completed: 2026-02-10*
