# Feature Research

**Domain:** Pentesting/networking learning lab with documentation site, diagnostic scripts, and tool onboarding
**Researched:** 2026-02-10
**Confidence:** MEDIUM-HIGH

Research covers three expansion areas: (1) Astro/Starlight documentation site, (2) diagnostic network scripts, and (3) new tool onboarding (dig, curl, netcat, traceroute/mtr, gobuster/ffuf). Findings synthesized from competitor analysis of HackTricks, ired.team Red Team Notes, highon.coffee, pentestmonkey, existing bash diagnostic script collections, and Astro Starlight official docs.

---

## Area 1: Documentation Site (Astro/Starlight GitHub Pages)

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Full-text search | Every reference site (HackTricks, ired.team) has search. Pentesters use Ctrl+F constantly. Starlight provides Pagefind search out of the box. | LOW | Starlight built-in, zero config. |
| Copy-to-clipboard on code blocks | Pentesters copy commands verbatim. HackTricks, ired.team, and every modern docs site have this. Starlight includes it via Expressive Code. | LOW | Starlight built-in via Expressive Code integration. |
| Tool-per-page reference | Each tool needs its own page with flags, examples, and "when to use." Matches how HackTricks and highon.coffee organize content. The existing `notes/*.md` files are the starting point. | MEDIUM | 11 existing tools + 5 new tools = 16 pages. Content exists in notes/ already. |
| Command examples with syntax highlighting | Code blocks with bash highlighting. Starlight does this automatically for fenced code blocks. | LOW | Starlight built-in. |
| Mobile-responsive layout | People reference docs from phones during CTFs and engagements. Starlight is responsive by default. | LOW | Starlight built-in. |
| Dark mode | Security folks overwhelmingly prefer dark mode. Starlight ships dark/light/auto toggle. | LOW | Starlight built-in, zero config. |
| Sidebar navigation organized by category | Pentest tools vs. networking tools vs. diagnostics need clear separation. Starlight auto-generates sidebar from folder structure. | LOW | Folder structure = sidebar structure. Plan: `pentest-tools/`, `network-tools/`, `diagnostics/`, `guides/`. |
| "When to use this tool" context per page | HackTricks excels because it explains WHEN, not just HOW. The existing notes/*.md files already include "What It Does" and "Scan Progression." | MEDIUM | Content writing effort, but high value. |
| GitHub Pages deployment with CI | Expected for any open-source docs site. Standard GitHub Actions workflow for Astro. | LOW | Standard `astro build` + deploy action. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Runnable command snippets with TARGET placeholders | Unlike static cheatsheets, commands include `<target>` placeholders that match the script conventions. User copies, replaces one variable, runs. Most cheatsheets use hardcoded IPs. | LOW | Convention in existing scripts already. Carry forward to docs. |
| "I want to..." task index page | Most pentest docs organize by tool. Organizing by TASK ("I want to find live hosts", "I want to crack a hash") is rare and valuable. Maps directly to existing use-case scripts. | MEDIUM | The existing USECASES.md pattern. Becomes a Starlight page with links to relevant tool pages. |
| Guided learning paths (progression) | HTB Academy and TryHackMe offer learning paths. A static site can offer ordered "start here" sequences: Recon Path, Web App Path, Network Debugging Path. Rare for open-source tool docs. | MEDIUM | Starlight sidebar ordering + a few "path" pages that link tools in recommended order. |
| Lab walkthrough integrated into docs | The existing 8-phase lab walkthrough (lab-walkthrough.md) is unique content. Making it a first-class guided page with step-by-step commands tied to lab targets is a differentiator. | MEDIUM | Content exists. Needs formatting into Starlight pages with asides/callouts for tips and warnings. |
| OS-specific install tabs | Starlight Tabs component can show macOS (Homebrew) vs. Linux (apt/yum) install commands side-by-side. Better than "install it somehow." | LOW | Use Starlight `<Tabs>` component. Each tool page gets an install section. |
| Difficulty/complexity indicators per example | Flag commands as Beginner/Intermediate/Advanced. Helps learners gauge what to try first. Rare in cheatsheet sites. | LOW | Starlight asides (note/tip/caution) or badge components. |
| Cross-references between tools | "After scanning with nmap, use nikto for web vuln scanning" links. Creates a workflow, not just isolated tool pages. | LOW | Markdown links between pages. Minimal effort, high value for learning flow. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Interactive terminal in browser | "Run commands from the docs!" | Massive security and complexity liability. Requires backend, sandboxing, auth. Completely out of scope for static site. | Copy button + clear instructions. Link to lab targets for practice. |
| User accounts and progress tracking | "Track my learning progress!" | Requires backend, database, auth. Transforms static docs into a full web app. | Suggest users bookmark pages. The value is reference, not courseware. |
| Video walkthroughs embedded | "Show me, don't tell me." | Video is expensive to produce, maintain, and host. Goes stale quickly as tools update. | Detailed step-by-step text with expected output shown in code blocks. |
| Real-time tool output rendering | "Show live scan results." | Requires server infrastructure. Output varies per environment. | Show representative sample output in static code blocks. |
| Comments/discussion per page | "Let users contribute tips." | Moderation burden. Spam. Outdated comments. | Link to GitHub Issues/Discussions for feedback. |
| Multilingual/i18n | "Reach wider audience." | Translation maintenance burden for technical content that changes frequently. | English-only. Starlight supports i18n if needed later, but defer. |
| Blog section | "Share updates and tutorials." | Maintenance commitment. Goes stale. Scope creep from reference docs. | Changelog in a single page if needed. Focus on reference content. |

---

## Area 2: Diagnostic Network Scripts

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| DNS diagnostic script | DNS resolution failures are the most common networking issue. Must check: resolution against multiple nameservers, record types (A, AAAA, MX, NS, SOA), propagation comparison, reverse lookup. | MEDIUM | Uses dig. Single command: `bash scripts/dig/diagnose-dns.sh example.com` produces full report. |
| Connectivity diagnostic script | "Is it the network or the app?" Must check: ping reachability, port open/closed, TCP handshake, HTTP response code, SSL certificate validity. | MEDIUM | Uses ping, nc, curl. Single command produces layered report. |
| Latency/path diagnostic script | "Why is it slow?" Must check: traceroute hops, per-hop latency, packet loss percentage, MTR-style continuous results. | MEDIUM | Uses traceroute/mtr. Report shows where latency spikes. |
| Structured text output (not raw tool dumps) | Existing scripts use colored `info/warn/error` output. Diagnostic scripts must do the same -- summarize findings, not dump raw output. | LOW | Follows existing common.sh patterns. Adds a `summary` section at end. |
| macOS + Linux compatibility | Existing project constraint. Tools like `lsof` vs `ss`, `netstat` flags differ. Diagnostics must handle both. | MEDIUM | Use `check_cmd` to detect platform and choose correct flags. Already have this pattern. |
| No external dependencies beyond standard tools | Diagnostic scripts should use tools that come pre-installed (ping, dig, curl, nc, traceroute). Users should not need to install anything to run basic diagnostics. | LOW | dig and traceroute are pre-installed on macOS. Linux may need `dnsutils` and `traceroute` packages. Provide install hints via `require_cmd`. |
| Non-destructive (safe to run anytime) | Diagnostic scripts must NEVER modify system state. Read-only network probes. No safety_banner needed since these are passive. | LOW | Architecture decision: diagnostics skip `safety_banner`, use a lighter "diagnostic mode" header. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Single-command full report | Most diagnostic guides say "run ping, then run dig, then run traceroute." This project runs ALL checks with one command and produces a consolidated report. Matches project core value. | MEDIUM | Main script: `diagnose-connectivity.sh <target>` that calls sub-checks and prints organized report. |
| Layer-by-layer diagnosis | Report walks OSI layers: DNS resolution -> IP reachability -> TCP port -> HTTP response -> TLS certificate. Shows WHERE the problem is, not just THAT there is a problem. | MEDIUM | Script logic follows diagnostic ladder. Each layer prints pass/fail before moving to next. |
| Machine-parseable output option | Add `--json` flag for structured output. Rare in bash diagnostic scripts. Useful for piping into other tools. | HIGH | Defer to v2. Nice-to-have, not essential. JSON from bash is fragile. |
| Comparison mode (test against multiple targets) | `diagnose-dns.sh example.com --compare 8.8.8.8 1.1.1.1 9.9.9.9` shows results from multiple resolvers side-by-side. | MEDIUM | Valuable for DNS debugging. Loop over resolvers, format as table. |
| Port discovery + service identification combined | Scan common ports AND identify what service is behind them in one report. Combines nmap + lsof patterns from existing `identify-ports.sh`. | LOW | Extend existing pattern. Already 80% built in `identify-ports.sh`. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Continuous monitoring/daemon mode | "Monitor my network 24/7." | Scripts are run-once tools, not daemons. Monitoring is a different domain (Nagios, Prometheus). PROJECT.md explicitly excludes this. | Run the diagnostic script when you notice a problem. Suggest monitoring tools in docs. |
| Automatic fix/remediation | "Fix my DNS for me." | Modifying system DNS, routes, or firewall is dangerous and out of scope. PROJECT.md excludes automated remediation. | Diagnose the problem and print what the user should do manually. |
| GUI/TUI dashboard | "Show results in a nice dashboard." | Adds ncurses or similar dependency. Bash TUI is fragile across terminals. | Clean colored text output with clear sections. Structured enough to read, simple enough to maintain. |
| Email/Slack alerting | "Notify me when something fails." | Requires credentials, auth, external service setup. Way beyond script scope. | Pipe output to wherever you want: `diagnose-connectivity.sh target \| mail -s "report" user@example.com`. |

---

## Area 3: New Tool Onboarding (dig, curl, netcat, traceroute/mtr, gobuster/ffuf)

### Table Stakes (Users Expect These)

Each new tool MUST follow the established pattern: `examples.sh` + use-case scripts + notes/*.md + Makefile targets.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `examples.sh` per tool (10 examples) | Established pattern across all 11 existing tools. Consistency is the entire project's identity. | LOW per tool | 5 tools x 10 examples = 50 example commands total. |
| 2-3 use-case scripts per tool | Established pattern. Existing tools average 2.5 use-case scripts each. | MEDIUM per tool | See tool-specific breakdown below. |
| `notes/<tool>.md` per tool | Every existing tool has one. Quick reference outside the docs site. | LOW per tool | Template: What It Does, Key Flags, Scan Progression, Practice section. |
| Makefile targets | Every existing tool has `make <tool>` and use-case targets. | LOW | Extend Makefile with new entries. |
| `check-tools.sh` integration | Script detects installed tools. New tools must be added. | LOW | Add to TOOLS array and TOOL_ORDER. |
| Install hints per platform | `require_cmd` shows install instructions when tool is missing. | LOW | Homebrew for macOS, apt for Debian/Ubuntu. |

### Tool-Specific Essential Use Cases

**dig (DNS toolkit)**

| Use Case Script | Why Essential | Complexity |
|-----------------|---------------|------------|
| `query-dns-records.sh` | Core dig use: query A, AAAA, MX, NS, TXT, SOA records for a domain. Every DNS guide starts here. | LOW |
| `check-dns-propagation.sh` | Compare DNS results across resolvers (8.8.8.8, 1.1.1.1, authoritative NS). Common real-world need after DNS changes. | MEDIUM |
| `attempt-zone-transfer.sh` | AXFR is a fundamental pentesting technique. dig is the standard tool. Reveals all records if misconfigured. | LOW |

**curl (HTTP toolkit)**

| Use Case Script | Why Essential | Complexity |
|-----------------|---------------|------------|
| `test-http-endpoints.sh` | GET/POST/PUT/DELETE with headers, auth, JSON payloads. The most common curl use case. | LOW |
| `check-ssl-certificate.sh` | Verify SSL cert validity, expiry, chain. Common debugging scenario. `curl -vI https://target 2>&1 \| grep -A6 "Server certificate"`. | LOW |
| `debug-http-response.sh` | Verbose mode showing DNS resolution, TCP connect, TLS handshake, headers, timing breakdown. Essential for "why is this request slow?" | MEDIUM |

**netcat (TCP/UDP Swiss Army knife)**

| Use Case Script | Why Essential | Complexity |
|-----------------|---------------|------------|
| `scan-ports.sh` | Basic port scanning without nmap. `nc -zv target 1-1000`. Useful when nmap isn't installed. | LOW |
| `setup-listener.sh` | Listen on a port for incoming connections. Foundation for reverse shells and file transfer. | LOW |
| `transfer-files.sh` | Send/receive files over TCP. Classic netcat use case: pipe in on one end, pipe out on the other. | LOW |

**traceroute/mtr (path analysis)**

| Use Case Script | Why Essential | Complexity |
|-----------------|---------------|------------|
| `trace-network-path.sh` | Basic traceroute with annotation of what each hop means. | LOW |
| `diagnose-latency.sh` | mtr with packet loss and jitter stats per hop. Identifies where slowness occurs. | MEDIUM |
| `compare-routes.sh` | Trace to same target via TCP vs. ICMP vs. UDP. Different protocols can take different paths, revealing firewall behavior. | MEDIUM |

**gobuster/ffuf (web content discovery)**

| Use Case Script | Why Essential | Complexity |
|-----------------|---------------|------------|
| `discover-directories.sh` | Basic directory brute-forcing against a web target. The primary use case. | LOW |
| `enumerate-subdomains.sh` | DNS subdomain enumeration. Gobuster's `dns` mode or ffuf with Host header fuzzing. | MEDIUM |
| `fuzz-parameters.sh` | Parameter fuzzing to find hidden inputs. ffuf excels here with FUZZ placeholder. | MEDIUM |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Networking tools treated as first-class (not afterthought) | Most pentesting tool collections ignore dig/curl/traceroute as "too basic." But these are the tools people use daily and still forget flags for. | LOW | Give them the same treatment as nmap: full examples.sh, use cases, docs page. |
| Wordlist management for gobuster/ffuf | Include a `wordlists/download.sh` (already exists for rockyou.txt) that also fetches SecLists common directories/subdomains. | LOW | Extend existing download script. Essential for gobuster/ffuf to be useful. |
| Cross-tool workflows in use cases | "First dig for DNS, then curl to test HTTP, then nmap for full scan." Use-case scripts that chain tools together in realistic workflow. | MEDIUM | New pattern: workflow scripts in a `workflows/` directory. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| wget as curl alternative | "Some people prefer wget." | wget and curl overlap significantly. Maintaining examples for both doubles work. curl is more capable and more commonly available. | Cover curl only. Note wget equivalents in docs if relevant. |
| socat as netcat alternative | "socat is more powerful." | socat syntax is much more complex. This is a learning tool -- netcat's simplicity is the point. | Mention socat in docs as "advanced alternative" but don't build scripts for it. |
| nslookup alongside dig | "nslookup is what I learned first." | dig provides superset of nslookup functionality with better output. nslookup is considered deprecated by many. | Use dig exclusively. Note in docs that dig replaces nslookup. |
| Recursive directory brute-force by default | "Scan all nested directories automatically." | Extremely noisy, slow, and can trigger WAF bans. gobuster doesn't support recursion. ffuf can but shouldn't by default. | Default to single-level scan. Document recursive option as advanced use case with warnings. |
| Automated wordlist download on first run | "Just download everything needed automatically." | Downloads can be large (SecLists is 500MB+). Surprise bandwidth usage is rude. | Provide `make wordlists` and document what's needed per tool. Explicit opt-in. |

---

## Feature Dependencies

```
Astro Site
    |-- requires --> Tool reference pages (content from notes/*.md)
    |-- requires --> Use-case index page (content from USECASES.md)
    |-- enhances <-- Lab walkthrough pages (content from lab-walkthrough.md)
    |-- enhances <-- Learning path pages (new content, references tool pages)

Diagnostic Scripts
    |-- requires --> dig installed (for DNS diagnostics)
    |-- requires --> curl installed (for connectivity diagnostics)
    |-- requires --> traceroute/mtr installed (for latency diagnostics)
    |-- requires --> New tool examples.sh (so users can learn the underlying tools)
    |-- enhances <-- Docs site (diagnostic scripts get their own docs section)

New Tool: dig
    |-- requires --> check-tools.sh update
    |-- requires --> Makefile update
    |-- enhances --> DNS diagnostic scripts (provides the underlying tool knowledge)

New Tool: curl
    |-- requires --> check-tools.sh update
    |-- requires --> Makefile update
    |-- enhances --> Connectivity diagnostic scripts

New Tool: netcat
    |-- requires --> check-tools.sh update
    |-- requires --> Makefile update
    (independent -- no diagnostic scripts depend on it)

New Tool: traceroute/mtr
    |-- requires --> check-tools.sh update
    |-- requires --> Makefile update
    |-- enhances --> Latency diagnostic scripts

New Tool: gobuster/ffuf
    |-- requires --> check-tools.sh update
    |-- requires --> Makefile update
    |-- requires --> wordlists (extend download.sh)
    (independent -- no diagnostic scripts depend on it)

Diagnostic Scripts --> depend on --> dig, curl, traceroute being onboarded first
Docs Site --> depends on --> all tool content existing (can build incrementally)
Learning Paths --> depend on --> tool pages + diagnostic script docs existing
```

### Dependency Notes

- **Diagnostic scripts require new tools onboarded first:** The DNS diagnostic script calls dig, the connectivity diagnostic calls curl and nc, the latency diagnostic calls traceroute/mtr. Tool onboarding must happen before or alongside diagnostics.
- **Docs site can be built incrementally:** Start with existing 11 tools, add new tool pages as they are built. No hard dependency on all content being ready.
- **Learning paths require all other content:** These are meta-content that links existing pages together. Build last.
- **gobuster/ffuf requires wordlists:** Unlike other new tools, gobuster and ffuf are useless without wordlists. Extend `wordlists/download.sh` as part of onboarding.

---

## MVP Definition

### Launch With (v1)

Minimum viable expansion -- what's needed to validate the new directions.

- [ ] **Astro/Starlight site with existing content** -- Deploy the 11 existing tool pages (from notes/*.md), the lab walkthrough, and the USECASES task index. Proves the docs site concept with zero new content creation.
- [ ] **dig, curl, netcat examples.sh + use-case scripts** -- These three tools are the most universally needed networking tools. Pre-installed on most systems. Low barrier.
- [ ] **DNS diagnostic script** -- Single most useful diagnostic. "Why can't I resolve this domain?" is the #1 networking question.
- [ ] **Connectivity diagnostic script** -- Layer-by-layer check from DNS through HTTP. Demonstrates the diagnostic report pattern.
- [ ] **check-tools.sh and Makefile updates** -- Keep the project's integration points current with new tools.

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] **traceroute/mtr onboarding + latency diagnostic** -- Add once the diagnostic pattern is proven with DNS and connectivity scripts.
- [ ] **gobuster/ffuf onboarding + wordlist expansion** -- Add once site and tool pattern is stable. These need wordlists and are pentest-specific (not networking diagnostic).
- [ ] **Learning path pages on docs site** -- Beginner/Intermediate/Advanced paths linking tool pages in recommended order. Requires enough tool pages to make paths meaningful.
- [ ] **OS-specific install tabs on docs site** -- Starlight Tabs showing macOS vs. Linux install commands per tool page.
- [ ] **Cross-tool workflow scripts** -- Scripts that chain multiple tools in a realistic sequence (recon workflow, web app testing workflow).

### Future Consideration (v2+)

Features to defer until the expansion is established.

- [ ] **Machine-parseable output (--json)** -- Structured output from diagnostic scripts. Nice but bash JSON is fragile. Defer.
- [ ] **Docs site search analytics** -- Track what people search for to guide future content. Requires analytics setup.
- [ ] **Community contribution guide** -- Templates for adding new tools, style guide for scripts. Only needed if external contributors appear.
- [ ] **Performance diagnostic script** -- Throughput testing, bandwidth measurement. More specialized than DNS/connectivity.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Astro/Starlight site (existing content) | HIGH | MEDIUM | P1 |
| dig examples.sh + use cases | HIGH | LOW | P1 |
| curl examples.sh + use cases | HIGH | LOW | P1 |
| netcat examples.sh + use cases | MEDIUM | LOW | P1 |
| DNS diagnostic script | HIGH | MEDIUM | P1 |
| Connectivity diagnostic script | HIGH | MEDIUM | P1 |
| check-tools.sh + Makefile updates | MEDIUM | LOW | P1 |
| traceroute/mtr examples.sh + use cases | MEDIUM | LOW | P2 |
| Latency diagnostic script | MEDIUM | MEDIUM | P2 |
| gobuster/ffuf examples.sh + use cases | MEDIUM | MEDIUM | P2 |
| Wordlist expansion for gobuster/ffuf | MEDIUM | LOW | P2 |
| Learning path pages | MEDIUM | MEDIUM | P2 |
| "I want to..." task index on site | HIGH | LOW | P2 |
| OS-specific install tabs | LOW | LOW | P2 |
| Lab walkthrough as Starlight pages | MEDIUM | LOW | P2 |
| Cross-tool workflow scripts | MEDIUM | HIGH | P3 |
| Machine-parseable diagnostic output | LOW | HIGH | P3 |
| Difficulty indicators per example | LOW | LOW | P3 |
| DNS comparison mode (multi-resolver) | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for first milestone delivery
- P2: Should have, add in subsequent phases
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | HackTricks | ired.team | highon.coffee | This Project |
|---------|-----------|-----------|---------------|--------------|
| Searchable docs site | Yes (custom search) | Yes (GitBook search) | No (Ctrl+F only) | Yes (Starlight Pagefind) |
| Copy-to-clipboard code | Yes | Yes | No | Yes (Starlight built-in) |
| Tool-organized pages | Yes (by service/port) | Yes (by technique) | Yes (by tool) | Yes (by tool + by task) |
| Task-organized index | No | No | No | **Yes -- differentiator** |
| Runnable scripts | No (reference only) | No | No | **Yes -- differentiator** |
| Lab environment | No | No | No | **Yes -- differentiator** |
| Learning paths | No | Partial (sections ordered) | No | **Yes -- differentiator** |
| Diagnostic scripts | No | No | No | **Yes -- differentiator** |
| Dark mode | Yes | Yes (GitBook) | No | Yes (Starlight built-in) |
| Mobile responsive | Yes | Yes | Partial | Yes (Starlight built-in) |
| Guided walkthroughs | No | No | No | **Yes (lab walkthrough) -- differentiator** |

Key insight: HackTricks and ired.team are reference-only. They document commands but provide no runnable scripts, no lab environment, and no diagnostic tools. This project's combination of docs + scripts + lab is unique in the space.

---

## Sources

- [HackTricks Wiki](https://book.hacktricks.wiki/) -- Comprehensive pentesting reference site. MEDIUM confidence (verified features via WebFetch).
- [Red Team Notes (ired.team)](https://www.ired.team/offensive-security-experiments/offensive-security-cheetsheets) -- Pentesting cheatsheets organized by technique. MEDIUM confidence.
- [highon.coffee Pentest Cheat Sheet](https://highon.coffee/blog/penetration-testing-tools-cheat-sheet/) -- Tool-organized cheatsheet covering 50+ tools. MEDIUM confidence.
- [Astro Starlight Official Docs](https://starlight.astro.build/) -- Documentation theme features: search, dark mode, tabs, code blocks, i18n, sidebar. HIGH confidence (official docs verified via WebFetch).
- [Starlight Code Components](https://starlight.astro.build/components/code/) -- Expressive Code integration with copy buttons, syntax highlighting, file labels. HIGH confidence.
- [Framework Computer Network Diagnostic Scripts](https://github.com/FrameworkComputer/linux-docs/tree/main/Network-Diagnostic-Scripts) -- Real-world bash diagnostic script patterns. MEDIUM confidence.
- [DigitalOcean MTR/Traceroute Guide](https://www.digitalocean.com/community/tutorials/how-to-use-traceroute-and-mtr-to-diagnose-network-issues) -- Traceroute/MTR diagnostic patterns. MEDIUM confidence.
- [ffuf GitHub](https://github.com/ffuf/ffuf) -- Web fuzzer features and capabilities. HIGH confidence (official repo).
- [gobuster GitHub](https://github.com/OJ/gobuster) -- Directory/DNS/VHost busting capabilities. HIGH confidence (official repo).
- [Netcat for Pentester (hackingarticles.in)](https://www.hackingarticles.in/netcat-for-pentester/) -- Netcat use case catalog. MEDIUM confidence.
- [DNS Pentesting Methodology (BlackWolfed)](https://github.com/BlackWolfed/DNS-Penetration-Testing-Methodology) -- dig use cases for pentesting. MEDIUM confidence.

---
*Feature research for: pentesting/networking learning lab expansion*
*Researched: 2026-02-10*
