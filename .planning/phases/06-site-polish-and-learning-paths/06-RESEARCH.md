# Phase 6: Site Polish and Learning Paths - Research

**Researched:** 2026-02-10
**Domain:** Starlight MDX components (Tabs, Asides), content organization, CI validation
**Confidence:** HIGH

## Summary

Phase 6 transforms the existing documentation site from a flat reference into a guided learning resource. The work spans three distinct areas: (1) content organization (task index page from USECASES.md, three learning path pages), (2) component-level enhancements (OS-specific install tabs on tool pages, asides/callouts on the lab walkthrough, cross-references between related tool pages), and (3) CI validation (a script that verifies every `scripts/*/examples.sh` has a corresponding documentation page).

The key technical decision is that install tabs require MDX. Starlight's `<Tabs>` and `<TabItem>` components only work in `.mdx` files -- they cannot be used in plain `.md` files (confirmed by Starlight maintainers in [withastro/starlight#2092](https://github.com/withastro/starlight/discussions/2092)). This means all 15 tool pages that need install tabs must be renamed from `.md` to `.mdx`. The `@astrojs/mdx` package is already installed as a dependency of `@astrojs/starlight` (v4.2.3), so no new packages are needed. Aside/callout syntax (`:::note`, `:::tip`, `:::caution`, `:::danger`) works in both `.md` and `.mdx` files via Starlight's built-in remark plugin -- no conversion needed for the lab walkthrough.

The existing site has 15 tool pages, 3 diagnostic pages, 2 guide pages, and 3 index pages -- all plain `.md`. The current sidebar uses `autogenerate` with directories (`tools`, `guides`, `diagnostics`). This phase adds new guide pages (task index, learning paths) and creates the CI validation. The CI validation script is a simple bash loop that maps `scripts/<tool>/examples.sh` to `site/src/content/docs/tools/<tool>.{md,mdx}` and fails if any mapping is missing.

**Primary recommendation:** Rename all 15 tool pages from `.md` to `.mdx`, add `<Tabs>` install sections to each, add `:::` asides to the lab walkthrough (no rename needed), create task index and learning path pages as plain `.md`, and add a CI step to the existing `deploy-site.yml` workflow.

## Standard Stack

### Core (All Pre-Existing)

| Library | Version | Purpose | Phase 6 Usage |
|---------|---------|---------|---------------|
| Astro | 5.6.1+ | Static site framework | Already installed |
| @astrojs/starlight | 0.37.6 | Documentation theme | Tabs, TabItem, Aside, Card, CardGrid, LinkCard components |
| @astrojs/mdx | 4.2.3 | MDX support | Already installed as Starlight dependency; enables component imports in `.mdx` |

### No New Dependencies

Phase 6 does not add any packages. All components (`Tabs`, `TabItem`, `Aside`, `Card`, `CardGrid`, `LinkCard`, `Steps`) are built into `@astrojs/starlight/components`. MDX support is already available.

## Architecture Patterns

### Content Directory Structure (Phase 6 Final State)

```
site/src/content/docs/
  index.md                      # Landing page (unchanged)
  tools/
    index.md                    # Tools overview (unchanged)
    nmap.mdx                    # RENAMED from .md -- adds install tabs
    tshark.mdx                  # RENAMED from .md
    sqlmap.mdx                  # RENAMED from .md
    nikto.mdx                   # RENAMED from .md
    metasploit.mdx              # RENAMED from .md
    hashcat.mdx                 # RENAMED from .md
    john.mdx                    # RENAMED from .md
    hping3.mdx                  # RENAMED from .md
    aircrack-ng.mdx             # RENAMED from .md
    skipfish.mdx                # RENAMED from .md
    foremost.mdx                # RENAMED from .md
    dig.mdx                     # RENAMED from .md
    curl.mdx                    # RENAMED from .md
    netcat.mdx                  # RENAMED from .md
    traceroute.mdx              # RENAMED from .md
  guides/
    index.md                    # Guides overview (unchanged)
    getting-started.md          # Unchanged
    lab-walkthrough.md          # ENHANCED with :::note/:::tip/:::caution asides
    task-index.md               # NEW -- "I want to..." page
    learning-recon.md           # NEW -- Recon learning path
    learning-webapp.md          # NEW -- Web App Testing learning path
    learning-network-debug.md   # NEW -- Network Debugging learning path
  diagnostics/
    index.md                    # Unchanged
    dns.md                      # Unchanged
    connectivity.md             # Unchanged
    performance.md              # Unchanged
```

### Pattern 1: MDX Tool Page with Install Tabs

**What:** Each tool page is renamed to `.mdx` and gains a `<Tabs>` component for OS-specific installation instructions.

**When to use:** Every tool page that needs platform-specific install commands.

**Import pattern (top of .mdx file, after frontmatter):**

```mdx
---
title: "dig -- DNS Lookup Utility"
description: "Query DNS records, trace delegation paths, and test DNS propagation"
sidebar:
  order: 4
---

import { Tabs, TabItem } from '@astrojs/starlight/components';

## Install

<Tabs syncKey="os">
  <TabItem label="macOS" icon="apple">
    ```bash
    brew install bind
    ```
  </TabItem>
  <TabItem label="Linux (Debian/Ubuntu)" icon="linux">
    ```bash
    sudo apt install dnsutils
    ```
  </TabItem>
  <TabItem label="Linux (RHEL/Fedora)" icon="linux">
    ```bash
    sudo dnf install bind-utils
    ```
  </TabItem>
</Tabs>
```

**Key details:**
- The `syncKey="os"` attribute synchronizes all install tabs on the same page and across pages -- when a user selects "macOS" on one tab group, all other synced tab groups on the page and future pages also switch to "macOS". This persists via `localStorage`.
- The `icon` prop on `<TabItem>` accepts Starlight icon names. Both `"apple"` and `"linux"` icons are confirmed to exist in Starlight 0.37.6 (verified in `site/node_modules/@astrojs/starlight/components/Icons.ts`). A `"laptop"` icon is also available.
- Import statements go immediately after frontmatter and before any markdown content.
- All existing markdown content in the file works identically in `.mdx` -- the only change is the file extension and the addition of import/component blocks.

**Source:** [Starlight Tabs docs](https://starlight.astro.build/components/tabs/), verified against installed component at `site/node_modules/@astrojs/starlight/user-components/Tabs.astro`. Icons verified in `Icons.ts`.

### Pattern 2: Markdown Asides (No MDX Required)

**What:** Starlight's built-in aside syntax for callouts, tips, warnings, and danger notices.

**When to use:** Lab walkthrough page -- add tips, warnings, and notes throughout.

**Syntax:**

```markdown
:::note
This is a note with default "Note" title.
:::

:::tip[Pro Tip]
Custom title in square brackets.
:::

:::caution
Something to be careful about.
:::

:::danger
Critical warning -- data loss or security risk.
:::
```

**Supported variants:** `note`, `tip`, `caution`, `danger`

**Custom icons (Starlight 0.37+):**
```markdown
:::tip{icon="heart"}
Content here.
:::
```

**Key detail:** This works in both `.md` and `.mdx` files. The lab walkthrough does NOT need to be renamed to `.mdx` just for asides.

**Source:** Verified in `site/node_modules/@astrojs/starlight/integrations/asides.ts` -- the remark plugin processes `:::variant[title]` syntax.

### Pattern 3: Cross-References Between Tool Pages

**What:** Inline links connecting related tools on their documentation pages.

**When to use:** At the bottom of each tool page in a "Related Tools" or "See Also" section.

**Implementation:**

```markdown
## Related Tools

- **[Nmap](/networking-tools/tools/nmap/)** -- discover hosts and open ports before scanning with Nikto
- **[SQLMap](/networking-tools/tools/sqlmap/)** -- follow up on SQL injection findings from Nikto scans
```

**Key detail:** Links must use the full base path (`/networking-tools/tools/<tool>/`) because the site is deployed at a subpath. Relative links (`../nmap/`) also work but are less readable. Each cross-reference should explain WHY the tools are related (workflow connection), not just that they exist.

**Cross-reference map (which tools relate to which):**

| Tool | Related To | Relationship |
|------|-----------|--------------|
| nmap | tshark, nikto, metasploit, hping3 | Discovery feeds into scanning; nmap output importable to Metasploit |
| tshark | nmap, curl, netcat | Captures traffic generated by other tools |
| metasploit | nmap, sqlmap, nikto | Nmap/nikto findings feed exploit selection; sqlmap hashes feed cracking |
| hashcat | john, sqlmap | Cracks hashes extracted by sqlmap; alternative to john |
| john | hashcat, sqlmap | Same as hashcat, different approach |
| sqlmap | nikto, nmap, hashcat, john | Nikto/nmap find injection points; extracted hashes go to crackers |
| nikto | nmap, skipfish, sqlmap | Nmap finds web ports; skipfish is alternative scanner |
| skipfish | nikto, nmap | Alternative web scanner; nmap finds targets |
| hping3 | nmap, traceroute | Crafted packets complement port scanning; firewall testing related to route tracing |
| aircrack-ng | hashcat | Handshakes can be converted for hashcat cracking |
| foremost | tshark | Carves files from captures or disk images |
| dig | curl, traceroute | DNS resolution precedes HTTP requests and route tracing |
| curl | dig, nikto, tshark | Manual HTTP requests complement automated scanning |
| netcat | nmap, metasploit | Port scanning, listener setup related to exploitation |
| traceroute | dig, hping3 | Route tracing after DNS resolution; path analysis vs firewall testing |

### Pattern 4: Task Index Page

**What:** An "I want to..." page that organizes tools and scripts by task rather than by tool name.

**When to use:** Single page, linked from the guides index and sidebar.

**Source content:** `USECASES.md` in the project root contains the complete task table with categories (Recon & Discovery, Web Application Testing, SQL Injection, Password Cracking, WiFi Security, Network & Traffic Analysis, Network Diagnostics, Route Tracing & Performance, File Carving & Forensics, Exploitation).

**Implementation approach:** Migrate the content from `USECASES.md` into a Starlight page at `guides/task-index.md`. Replace `make <target>` commands with links to the relevant tool documentation pages. Keep the "I want to..." column format.

### Pattern 5: Learning Path Pages

**What:** Guided sequences of tool pages organized by learning goal, with numbered steps and context.

**When to use:** Three pages: Recon, Web App Testing, Network Debugging.

**Structure for each learning path:**

```markdown
---
title: "Learning Path: Reconnaissance"
description: "Step-by-step guide to network reconnaissance using nmap, dig, and tshark"
sidebar:
  order: 10
---

## Overview
[What this learning path teaches, who it's for, prerequisites]

## Step 1: DNS Reconnaissance
[Why this is first, what you'll learn]
- Read: [dig documentation](/networking-tools/tools/dig/)
- Practice: `make diagnose-dns TARGET=example.com`
[Expected outcomes]

## Step 2: Host Discovery
[Context, why after DNS]
- Read: [nmap documentation](/networking-tools/tools/nmap/)
- Practice: `make discover-hosts TARGET=192.168.1.0/24`
[Expected outcomes]

...

## Next Steps
[What to learn after completing this path]
```

**Learning path outlines:**

1. **Recon**: dig (DNS recon) -> nmap (host/port discovery) -> tshark (traffic analysis) -> metasploit (service enumeration)
2. **Web App Testing**: nmap (find web ports) -> nikto (vulnerability scan) -> skipfish (app crawl) -> sqlmap (injection testing) -> hashcat/john (crack extracted hashes)
3. **Network Debugging**: dig (DNS diagnostic) -> connectivity diagnostic -> traceroute/mtr (route tracing) -> performance diagnostic -> hping3 (firewall testing) -> curl (HTTP debugging) -> tshark (packet capture)

### Pattern 6: Sidebar Configuration for New Content

**What:** The sidebar needs to accommodate the task index and learning path pages.

**Current sidebar config:**

```javascript
sidebar: [
  { label: 'Tools', autogenerate: { directory: 'tools' } },
  { label: 'Guides', autogenerate: { directory: 'guides' } },
  { label: 'Diagnostics', autogenerate: { directory: 'diagnostics' } },
]
```

**Recommendation:** Keep the existing autogenerate approach for Guides -- the new pages (task-index, learning-recon, learning-webapp, learning-network-debug) will appear automatically in the Guides section. Use `sidebar.order` in frontmatter to control ordering:

| Page | sidebar.order | Rationale |
|------|--------------|-----------|
| getting-started.md | 1 | First thing new users see |
| lab-walkthrough.md | 2 | Setup before learning |
| task-index.md | 3 | Quick reference before deep dives |
| learning-recon.md | 10 | Learning paths after reference material |
| learning-webapp.md | 11 | Learning paths grouped together |
| learning-network-debug.md | 12 | Learning paths grouped together |

No changes to `astro.config.mjs` sidebar configuration needed.

### Anti-Patterns to Avoid

- **Converting .md to .mdx unnecessarily:** Only rename files that actually need JSX components (Tabs). The lab walkthrough and learning path pages use markdown-only features and should stay as `.md`.
- **Importing components in .md files:** This silently fails -- the import statement is rendered as literal text. Always verify the file extension is `.mdx` before adding imports.
- **Using relative links without base path:** Links like `../nmap/` technically work but break if the content structure changes. Use absolute paths with the base path: `/networking-tools/tools/nmap/`.
- **Overusing components:** Starlight's philosophy is content-first. Don't add Cards, CardGrids, or Steps everywhere just because they exist. Use them where they genuinely improve comprehension.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OS-specific install instructions | Custom HTML/CSS toggle | Starlight `<Tabs>` with `syncKey="os"` | Built-in tab syncing, keyboard navigation, localStorage persistence, accessible |
| Callouts/warnings | Custom blockquote styling | `:::note` / `:::tip` / `:::caution` / `:::danger` | Built into Starlight's remark pipeline, styled consistently |
| Card-based navigation | Custom link lists | Starlight `<LinkCard>` or `<CardGrid>` + `<Card>` | Pre-styled, accessible, consistent with theme |
| Numbered learning steps | Manual ordered lists | Starlight `<Steps>` component | Visual step indicators, vertical guideline |
| CI file existence check | Complex GitHub Action marketplace action | Simple bash loop in workflow | 15 lines of bash vs. third-party action dependency |

**Key insight:** Starlight provides all the UI components needed for this phase. The only custom work is content authoring and one CI validation script.

## Common Pitfalls

### Pitfall 1: MDX Whitespace Sensitivity

**What goes wrong:** MDX is stricter about whitespace than Markdown. A blank line between a JSX component and markdown content is required, and indentation inside components can cause rendering issues.

**Why it happens:** MDX treats content inside JSX tags differently than standalone markdown. Without a blank line, the markdown parser may not engage.

**How to avoid:** Always leave a blank line after the opening `<TabItem>` tag and before the closing `</TabItem>` tag. Test every renamed file with `make site-build` after conversion.

**Warning signs:** Code blocks inside tabs render as plain text instead of highlighted code; markdown formatting inside components appears as raw text.

**Example of correct whitespace:**

```mdx
<Tabs syncKey="os">
  <TabItem label="macOS">

    ```bash
    brew install nmap
    ```

  </TabItem>
  <TabItem label="Linux">

    ```bash
    sudo apt install nmap
    ```

  </TabItem>
</Tabs>
```

### Pitfall 2: Breaking Existing Links on .md to .mdx Rename

**What goes wrong:** Internal links pointing to `/tools/nmap/` might break if the rename changes the URL slug.

**Why it happens:** Astro generates URLs from file paths. Both `nmap.md` and `nmap.mdx` generate `/tools/nmap/` -- the extension is stripped. So URLs are preserved.

**How to avoid:** Verify after rename that all pages still build and internal links work. The URL slug is derived from the filename without extension, so `nmap.md` and `nmap.mdx` produce the same URL. This is NOT a risk -- but verify anyway with `make site-build`.

**Warning signs:** 404 errors during site-build or dev server.

### Pitfall 3: Sidebar Badge Removal on Rename

**What goes wrong:** Some tool pages (dig, traceroute) have `badge` frontmatter with `text: 'New'`. This is preserved during rename since frontmatter is identical between `.md` and `.mdx`.

**How to avoid:** Copy frontmatter exactly when renaming. Consider removing "New" badges during this phase since these tools are no longer new.

### Pitfall 4: CI Validation Must Handle Both .md and .mdx Extensions

**What goes wrong:** The CI check looks for `tools/<tool>.md` but the file is now `tools/<tool>.mdx`.

**Why it happens:** The rename from `.md` to `.mdx` means the validation script must check for both extensions.

**How to avoid:** Use a glob or check for both: `[[ -f "tools/${tool}.md" ]] || [[ -f "tools/${tool}.mdx" ]]`

### Pitfall 5: USECASES.md Drift

**What goes wrong:** The task index page is created from `USECASES.md`, but future changes to one won't automatically update the other.

**Why it happens:** Two sources of truth for the same content.

**How to avoid:** After creating the task index page, add a comment to `USECASES.md` pointing readers to the site page. Consider whether `USECASES.md` should be kept (for CLI/GitHub users) or removed (single source of truth on the site).

### Pitfall 6: MDX Expressions in Existing Content

**What goes wrong:** Renaming `.md` to `.mdx` changes how certain characters are interpreted. Curly braces `{}` in markdown content are treated as JSX expressions in MDX and will cause build errors.

**Why it happens:** MDX is a superset of JSX, where `{` starts an expression. Content like `awk '{print $1}'` or regex patterns with braces will break.

**How to avoid:** After renaming each file, build with `make site-build` and check for MDX parse errors. Escape curly braces by wrapping them in expression syntax: `{'{'}`  or use code blocks (code blocks are safe -- MDX doesn't parse inside fenced code blocks).

**Warning signs:** Build errors mentioning "Unexpected token" or "Expression expected" in `.mdx` files.

## Code Examples

### Example 1: Complete MDX Tool Page with Install Tabs

```mdx
---
title: "Nmap -- Network Mapper"
description: "Discovers hosts on a network and scans their ports to find running services"
sidebar:
  order: 1
---

import { Tabs, TabItem } from '@astrojs/starlight/components';

## What It Does

Nmap discovers hosts on a network and scans their ports to find running services.

## Install

<Tabs syncKey="os">
  <TabItem label="macOS" icon="apple">

    ```bash
    brew install nmap
    ```

  </TabItem>
  <TabItem label="Debian / Ubuntu" icon="linux">

    ```bash
    sudo apt install nmap
    ```

  </TabItem>
  <TabItem label="RHEL / Fedora" icon="linux">

    ```bash
    sudo dnf install nmap
    ```

  </TabItem>
</Tabs>

## Key Flags to Remember

[... rest of existing content unchanged ...]

## Related Tools

- **[tshark](/networking-tools/tools/tshark/)** -- capture and analyze traffic from nmap scans
- **[Nikto](/networking-tools/tools/nikto/)** -- scan web services discovered by nmap
- **[Metasploit](/networking-tools/tools/metasploit/)** -- import nmap XML output for exploitation
```

### Example 2: Lab Walkthrough with Asides

```markdown
## Phase 0: Setup

### Check your tools

```bash
make check
```

:::tip[Start Here]
You don't need every tool installed to begin. Start with nmap and work through the phases in order -- install additional tools as you need them.
:::

### Initialize DVWA

1. Browse to http://localhost:8080
2. Log in with **admin / password**
3. Go to http://localhost:8080/setup.php
4. Click **Create / Reset Database**

:::caution
DVWA resets its database when the container restarts. You'll need to repeat this step each time you run `make lab-up`.
:::
```

### Example 3: CI Validation Script

```bash
#!/usr/bin/env bash
# check-docs-completeness.sh -- Verify every tool script has a docs page
set -euo pipefail

SCRIPTS_DIR="scripts"
DOCS_DIR="site/src/content/docs/tools"
errors=0

for examples_sh in "$SCRIPTS_DIR"/*/examples.sh; do
  tool_dir=$(dirname "$examples_sh")
  tool_name=$(basename "$tool_dir")

  if [[ ! -f "$DOCS_DIR/${tool_name}.md" ]] && [[ ! -f "$DOCS_DIR/${tool_name}.mdx" ]]; then
    echo "ERROR: No docs page for scripts/${tool_name}/examples.sh"
    echo "  Expected: $DOCS_DIR/${tool_name}.md or $DOCS_DIR/${tool_name}.mdx"
    ((errors++))
  fi
done

if [[ $errors -gt 0 ]]; then
  echo ""
  echo "FAILED: $errors tool(s) missing documentation pages"
  exit 1
else
  echo "OK: All $(ls "$SCRIPTS_DIR"/*/examples.sh | wc -l | tr -d ' ') tools have documentation pages"
fi
```

### Example 4: GitHub Actions CI Step

```yaml
- name: Validate docs completeness
  run: bash scripts/check-docs-completeness.sh
```

This should be added as a step in the existing `deploy-site.yml` workflow, after the Checkout step but before the Astro build step, so the build fails fast if documentation is missing.

## Install Data for All 15 Tools

Reference data for creating install tabs on each tool page:

| Tool | macOS (Homebrew) | Debian/Ubuntu (apt) | RHEL/Fedora (dnf) | Notes |
|------|-----------------|--------------------|--------------------|-------|
| nmap | `brew install nmap` | `apt install nmap` | `dnf install nmap` | |
| tshark | `brew install wireshark` | `apt install tshark` | `dnf install wireshark-cli` | tshark is part of Wireshark |
| metasploit | [Nightly installer](https://docs.metasploit.com/docs/using-metasploit/getting-started/nightly-installers.html) | Same installer | Same installer | No package manager install |
| aircrack-ng | `brew install aircrack-ng` | `apt install aircrack-ng` | `dnf install aircrack-ng` | Monitor mode tools Linux-only |
| hashcat | `brew install hashcat` | `apt install hashcat` | `dnf install hashcat` | |
| skipfish | `sudo port install skipfish` (MacPorts) | `apt install skipfish` | N/A | Not in Homebrew |
| sqlmap | `brew install sqlmap` | `apt install sqlmap` | `dnf install sqlmap` | |
| hping3 | `brew install draftbrew/tap/hping` | `apt install hping3` | `dnf install hping3` | Different Homebrew tap |
| john | `brew install john` | `apt install john` | `dnf install john` | Homebrew includes jumbo patch |
| nikto | `brew install nikto` | `apt install nikto` | `dnf install nikto` | |
| foremost | `brew install foremost` | `apt install foremost` | `dnf install foremost` | |
| dig | `brew install bind` | `apt install dnsutils` | `dnf install bind-utils` | Package names differ significantly |
| curl | Pre-installed | `apt install curl` | `dnf install curl` | Pre-installed on macOS |
| netcat | `brew install netcat` | `apt install netcat-openbsd` | `dnf install nmap-ncat` | Variants differ by platform |
| traceroute | Pre-installed | `apt install traceroute` | `dnf install traceroute` | Pre-installed on macOS; mtr separate |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plain `.md` for all pages | `.mdx` for pages needing components | Starlight 0.x (always) | Required for Tabs; `.md` stays for simple pages |
| Custom HTML for tabs | `<Tabs>` + `<TabItem>` from Starlight | Starlight 0.20+ | Built-in accessible tabs with sync |
| Blockquotes for callouts | `:::note` / `:::tip` / `:::caution` / `:::danger` | Starlight 0.x (always) | Semantic, styled, accessible asides |
| Manual numbered lists | `<Steps>` component | Starlight 0.28+ | Visual step indicators |

**Deprecated/outdated:**
- None relevant to this phase. Starlight 0.37.6 is current and all features used are stable.

## Open Questions

1. **Keep or remove USECASES.md after task index migration**
   - What we know: The task index page on the site duplicates `USECASES.md` content.
   - What's unclear: Whether CLI-only users benefit from keeping `USECASES.md`.
   - Recommendation: Keep `USECASES.md` but add a header comment: "See also: [site task index page]". This preserves the quick reference for users who don't visit the site.

2. **Metasploit install tabs**
   - What we know: Metasploit doesn't have a simple `brew install` or `apt install` -- it uses a nightly installer script for all platforms.
   - What's unclear: Whether tabs make sense for Metasploit since the install process is the same across platforms.
   - Recommendation: Use a single install section for Metasploit instead of tabs, with a link to the installer. Or use two tabs: "macOS / Linux" (installer script) and "Kali Linux" (pre-installed).

3. **Skipfish on RHEL/Fedora**
   - What we know: Skipfish is available via `apt install skipfish` on Debian and `sudo port install skipfish` on macOS (MacPorts). It is not in Homebrew.
   - What's unclear: Whether skipfish is available in RHEL/Fedora repos.
   - Recommendation: Show only macOS (MacPorts) and Debian/Ubuntu tabs for skipfish. Add a note about building from source if needed.

## Resolved Questions

1. **Starlight icon names for OS tabs** -- RESOLVED
   - Both `apple` and `linux` icons exist in Starlight 0.37.6. Verified in `site/node_modules/@astrojs/starlight/components/Icons.ts` (lines 154, 156). A `laptop` icon (line 40) is also available.
   - Use `icon="apple"` for macOS tabs and `icon="linux"` for Linux tabs.

## Sources

### Primary (HIGH confidence)
- Installed Starlight components at `site/node_modules/@astrojs/starlight/user-components/` -- verified Tabs.astro, TabItem.astro, Aside.astro API and props
- Installed Starlight asides integration at `site/node_modules/@astrojs/starlight/integrations/asides.ts` -- verified `:::variant[title]` syntax
- Installed Starlight Icons at `site/node_modules/@astrojs/starlight/components/Icons.ts` -- verified `apple` (line 154), `linux` (line 156), `laptop` (line 40) icons exist
- `@astrojs/mdx` v4.2.3 installed as Starlight dependency -- confirmed no extra packages needed
- Existing site content at `site/src/content/docs/` -- verified current page structure, frontmatter patterns, install section formats
- `USECASES.md` in project root -- verified task table structure for migration
- `scripts/check-tools.sh` -- verified install commands for macOS (Homebrew) and package names

### Secondary (MEDIUM confidence)
- [Starlight Tabs documentation](https://starlight.astro.build/components/tabs/) -- usage syntax, syncKey feature
- [Starlight Authoring Content guide](https://starlight.astro.build/guides/authoring-content/) -- aside syntax, MDX support
- [withastro/starlight#2092](https://github.com/withastro/starlight/discussions/2092) -- confirmed Tabs only work in .mdx, not .md

### Tertiary (LOW confidence)
- Install commands for RHEL/Fedora (`dnf`) variants -- based on common knowledge, should be verified per-tool during implementation
- Skipfish availability on RHEL/Fedora -- unconfirmed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all components verified against installed packages, no new dependencies
- Architecture: HIGH -- file structure, MDX patterns, and sidebar config verified against existing site
- Content organization: HIGH -- USECASES.md content verified, learning path structure follows existing lab walkthrough pattern
- CI validation: HIGH -- simple bash script, mapping verified (15 scripts, 15 doc pages)
- Install data: MEDIUM -- macOS/Debian verified from check-tools.sh, RHEL/Fedora based on common knowledge
- Pitfalls: HIGH -- MDX whitespace, rename impact, curly brace escaping, and CI extension handling all documented from real Starlight behavior

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (stable -- Starlight components are well-established)
