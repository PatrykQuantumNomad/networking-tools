# Domain Pitfalls

**Domain:** Pentesting learning lab expansion (docs site, diagnostic scripts, new tools)
**Researched:** 2026-02-10

## Critical Pitfalls

Mistakes that cause rewrites, broken deployments, or unusable scripts.

### Pitfall 1: Astro base path breaks every internal link and asset

**What goes wrong:** The site deploys to `https://<user>.github.io/networking-tools/` but all links, images, and CSS/JS assets point to the root `/` instead of `/networking-tools/`. The site appears to deploy successfully but every page is broken -- stylesheets missing, images 404, navigation links go to GitHub's 404 page.

**Why it happens:** Astro generates root-relative URLs by default. When deployed to a GitHub Pages project site (not a `<user>.github.io` repo), every asset needs the `/networking-tools/` prefix. Developers build locally where `/` works fine, never see the breakage until after deployment.

**Consequences:** Site looks completely broken on GitHub Pages. Every internal `<a href>`, every `<img src>`, every CSS/JS import fails. Users see unstyled content or blank pages.

**Prevention:**
1. Set both `site` and `base` in `astro.config.mjs` from day one:
   ```js
   export default defineConfig({
     site: 'https://<user>.github.io',
     base: '/networking-tools',
   });
   ```
2. Use Astro's built-in link helpers (`import.meta.env.BASE_URL`) instead of hardcoded paths
3. Test with `astro preview` after `astro build` -- the preview server respects the base path
4. Add a CI step that checks for hardcoded `/` paths in built HTML

**Detection:** Site works perfectly on `localhost:4321` but breaks on GitHub Pages. All CSS missing, navigation 404s.

**Phase mapping:** Must be addressed in the very first Astro setup task, not deferred.

**Confidence:** HIGH -- verified against [official Astro deployment docs](https://docs.astro.build/en/guides/deploy/github/) and multiple [GitHub issues](https://github.com/withastro/astro/issues/4229).

---

### Pitfall 2: GitHub Pages Jekyll processing eats underscore-prefixed build output

**What goes wrong:** Astro's build output in `dist/` includes directories like `_astro/` for hashed assets. GitHub Pages runs Jekyll by default, which ignores any file or directory starting with `_`. The deployed site is missing its bundled CSS and JavaScript.

**Why it happens:** GitHub Pages assumes Jekyll unless told otherwise. Jekyll treats `_` prefixed directories as special. Astro's build tooling (Vite) outputs hashed assets to `_astro/` by default.

**Consequences:** The HTML pages deploy but all interactive components, styles, and client-side JavaScript silently vanish. The site appears "deployed" in GitHub's UI but renders as unstyled HTML.

**Prevention:**
1. Use the [official Astro GitHub Action](https://github.com/withastro/action) which handles `.nojekyll` automatically
2. If using a custom workflow, add `.nojekyll` to the `public/` directory so it ends up in build output
3. Verify in CI: check that `dist/_astro/` exists and contains files after build

**Detection:** Site deploys, HTML renders, but no styles or interactivity. Browser dev tools show 404s for `_astro/*` paths.

**Phase mapping:** Address during GitHub Actions workflow setup. The official action handles this, so use it rather than rolling a custom deploy.

**Confidence:** HIGH -- well-documented issue across [multiple sources](https://www.seanmcp.com/articles/fix-missing-astro-files-on-github-pages/).

---

### Pitfall 3: Netcat version incompatibility silently breaks scripts across platforms

**What goes wrong:** Scripts written for one netcat variant fail silently or produce no output on another variant. A script using `nc -e /bin/bash` works on Traditional Netcat but silently fails on macOS (OpenBSD nc) because `-e` does not exist. A script using ncat's `-e` without full path (`-e bash` vs `-e /bin/bash`) instantly drops the connection with no error message.

**Why it happens:** There are at least four incompatible netcat implementations (OpenBSD nc, GNU netcat, ncat from Nmap, BusyBox nc). macOS ships OpenBSD nc. Linux distributions vary between OpenBSD nc and GNU netcat. The binary is always called `nc` regardless of implementation, so scripts cannot detect which version they are using without explicit checks.

**Consequences:** Educational scripts that work on the developer's machine produce confusing results for users on different platforms. Worse, some failures are silent -- the connection opens and immediately closes with no error, making users think the target is unreachable rather than the flag being wrong.

**Prevention:**
1. Add a netcat variant detection function to `common.sh`:
   ```bash
   detect_nc_variant() {
       if nc -h 2>&1 | grep -q 'ncat'; then
           echo "ncat"
       elif nc -h 2>&1 | grep -q 'GNU'; then
           echo "gnu"
       else
           echo "openbsd"
       fi
   }
   ```
2. Show examples for ALL common variants in the examples.sh, clearly labeled
3. Warn in educational context about which flags are variant-specific
4. Use ncat (from nmap package, already a project dependency) as the recommended variant and document why

**Detection:** Script works on developer's macOS but user on Linux (or vice versa) gets "invalid option" errors or silent connection drops.

**Phase mapping:** Address when building the netcat tool integration. This is the trickiest new tool to add because of variant fragmentation.

**Confidence:** HIGH -- verified via [detailed variant comparison](https://grahamhelton.com/blog/which_netcat) and [Baeldung analysis](https://www.baeldung.com/linux/netcat-vs-nc-vs-ncat).

---

### Pitfall 4: Diagnostic scripts using deprecated/missing networking commands

**What goes wrong:** Diagnostic scripts use `ifconfig`, `netstat`, `route`, or `arp` which are deprecated on modern Linux. Some Linux distributions (especially containers, minimal installs, and newer Ubuntu/Debian) do not ship `net-tools` at all. Scripts fail with "command not found" on Linux while working fine on macOS (which still ships these commands).

**Why it happens:** macOS ships BSD versions of `ifconfig`, `netstat`, and `route` and has no plans to deprecate them. Linux has been migrating to `iproute2` (`ip`, `ss`) for years, and modern distributions may not include `net-tools` by default. Developers on macOS never encounter this.

**Consequences:** Diagnostic scripts that should "just work" on any system fail on the very Linux machines users most need to diagnose. This is especially embarrassing for a networking tools project.

**Prevention:**
1. For every diagnostic script, implement fallback chains:
   ```bash
   if check_cmd ip; then
       ip addr show
   elif check_cmd ifconfig; then
       ifconfig
   fi
   ```
2. Prefer modern commands (`ip`, `ss`) as primary, fall back to legacy (`ifconfig`, `netstat`)
3. Show BOTH modern and legacy commands in educational examples with clear labels
4. Test all diagnostic scripts in a minimal Linux container (Alpine, Ubuntu minimal) as part of validation

**Detection:** Works on macOS, fails on fresh Linux installs. `check-tools.sh` does not catch this because these tools are not in the TOOLS array.

**Phase mapping:** Address in the diagnostic scripts phase. Every diagnostic script must be tested on both macOS and a minimal Linux container.

**Confidence:** HIGH -- verified via [2026 deprecation guide](https://thelinuxcode.com/deprecated-linux-networking-commands-and-their-replacements-2026-practical-guide/) and [Red Hat documentation](https://www.redhat.com/en/blog/deprecated-linux-command-replacements).

---

### Pitfall 5: Documentation-code drift makes the docs site a liability instead of an asset

**What goes wrong:** The Astro docs site launches with accurate content, but as scripts are added or modified, the documentation falls behind. Within weeks, the site shows wrong flags, missing tools, or outdated examples. Users follow the site's guidance and get errors.

**Why it happens:** Two sources of truth: the bash scripts contain the actual commands and examples, and the Astro site contains prose documentation of those same commands. Without automation, every script change requires a manual docs update. Nobody remembers to do this consistently.

**Consequences:** The docs site actively misleads users, which is worse than having no docs site. Users lose trust in the project. Maintainer spends more time fixing doc bugs than writing new content.

**Prevention:**
1. Generate docs from scripts where possible -- extract the `show_help()` output, the 10 numbered examples, and require_cmd install hints programmatically
2. Use a build-time script that validates docs against actual script files (e.g., check that every `scripts/*/examples.sh` has a corresponding docs page)
3. Add a CI check: "docs completeness" that fails if a new tool directory exists without a docs page
4. Keep the Astro site as the "guide and context" layer, not a duplicate of what the scripts already print. Reference scripts rather than copying their content

**Detection:** User reports "the site says to use flag X but the script uses flag Y." Docs page lists 10 tools but `check-tools.sh` has 15.

**Phase mapping:** Build the generation/validation tooling in the same phase as the Astro site, not as an afterthought.

**Confidence:** MEDIUM -- this is a universal documentation problem. No project-specific sources, but the two-source-of-truth pattern in this codebase makes it especially likely given 11+ tool directories.

## Moderate Pitfalls

### Pitfall 6: macOS BSD flags vs Linux GNU flags in diagnostic output parsing

**What goes wrong:** Diagnostic scripts that parse command output (e.g., `grep`, `sed`, `awk` on the results of `traceroute`, `netstat`, or `dig`) break because BSD and GNU versions produce different output formats.

**Prevention:**
1. Never parse output with assumptions about column positions or formatting
2. Use tool-specific machine-readable output flags where available (e.g., `dig +short`, `ss -H`, `ip -json`)
3. Test output parsing on both macOS and Linux (the output of `traceroute` differs in header format, `netstat` columns differ between BSD and GNU)
4. For the diagnostic "auto-report" scripts, prefer structured output modes and parse those

**Detection:** Script produces garbled or incomplete reports on one platform. Off-by-one column parsing that silently returns wrong data.

**Phase mapping:** Address during diagnostic script development. Establish parsing patterns early and reuse across all diagnostic scripts.

**Confidence:** HIGH -- well-known cross-platform bash issue.

---

### Pitfall 7: Diagnostic scripts introduce a new pattern that diverges from the established 10-examples pattern

**What goes wrong:** The diagnostic scripts ("run one command, get a report") are architecturally different from the existing educational scripts ("10 examples with explanations + optional demo"). Without a clear pattern definition, each diagnostic script is structured differently. Some print reports, some save files, some do both. The codebase becomes inconsistent.

**Prevention:**
1. Define the diagnostic script pattern explicitly before writing the first one:
   - Same preamble (source common.sh, show_help, require_cmd)
   - Always print a structured report to stdout
   - Use consistent section headers (e.g., `info "=== DNS Resolution ==="`)
   - Support `--json` or `--quiet` flags for machine-readable output if warranted
2. Write a template diagnostic script first, get it reviewed, then clone it for each use case
3. Add the pattern definition to CLAUDE.md so future contributors follow it

**Detection:** Each diagnostic script has a different structure. Some use `info` for headers, some use `echo`. Some scripts are 50 lines, others are 300. Users cannot predict what a diagnostic script will do.

**Phase mapping:** Define the pattern in the first diagnostic script task. Do not build multiple diagnostic scripts in parallel until the pattern is established.

**Confidence:** MEDIUM -- inferred from the existing codebase's strong pattern consistency. Breaking that consistency is the risk.

---

### Pitfall 8: gobuster/ffuf require Go or separate binary installation unlike other new tools

**What goes wrong:** The other new tools (dig, curl, netcat, traceroute, mtr) are pre-installed on macOS and most Linux systems. gobuster and ffuf require either Go installed (to `go install`) or downloading pre-built binaries. This breaks the "just clone and run" experience that the other tools provide.

**Prevention:**
1. Provide multiple install methods in `require_cmd` hints: Homebrew, Go install, and direct binary download
2. Consider adding a `scripts/gobuster/install.sh` helper that handles platform detection and download
3. Document clearly in the Astro site that gobuster/ffuf are the only tools requiring explicit installation
4. In `check-tools.sh`, separate "pre-installed tools" from "tools requiring installation" in the output

**Detection:** User runs `make check` and sees gobuster/ffuf as missing. They try the install hint and it fails because Go is not installed.

**Phase mapping:** Address when adding gobuster/ffuf to `check-tools.sh` and their examples scripts. Consider making these the last tools added.

**Confidence:** HIGH -- gobuster and ffuf are Go binaries; this is a factual dependency.

---

### Pitfall 9: Astro site becomes an unmaintainable separate project

**What goes wrong:** The Astro site grows its own package.json, node_modules, build pipeline, component library, and custom CSS. It becomes a full frontend project that requires Node.js expertise to maintain, in a repo that is otherwise pure bash. The maintainer (a security/networking person) cannot update the site without understanding Astro, Vite, and npm.

**Prevention:**
1. Use [Astro Starlight](https://starlight.astro.build/) theme for docs -- it provides navigation, search, dark mode, and responsive design out of the box with zero custom components
2. Keep the site strictly markdown-driven -- all content in `.md` files, no custom Astro components
3. Pin Astro and Starlight versions; do not chase latest
4. Document how to add a new page in 3 steps or fewer in a CONTRIBUTING section
5. Put the Astro site in a subdirectory (`docs/` or `site/`) with its own `.gitignore` to isolate Node artifacts from the bash project

**Detection:** PRs for the docs site require understanding of `.astro` files, component props, or CSS-in-JS. Dependabot opens 20 PRs a month for npm dependencies.

**Phase mapping:** Enforce during initial Astro setup. Choose Starlight from the start; do not build a custom theme.

**Confidence:** MEDIUM -- Starlight recommendation based on [official documentation](https://starlight.astro.build/) and its explicit design for this use case.

---

### Pitfall 10: traceroute/mtr require root/sudo on macOS for raw sockets

**What goes wrong:** `traceroute` on macOS works without sudo for UDP mode but requires sudo for ICMP mode (`-I`). `mtr` requires sudo on macOS for all modes because it creates raw sockets. Diagnostic scripts that use mtr fail silently or produce permission errors.

**Prevention:**
1. Use `require_root` in scripts that need raw socket access, or detect and warn:
   ```bash
   if [[ $EUID -ne 0 ]] && [[ "$(uname)" == "Darwin" ]]; then
       warn "mtr requires sudo on macOS for raw socket access"
       info "Run: sudo $0 $*"
       exit 1
   fi
   ```
2. Default to `traceroute` (works without sudo in UDP mode) and offer mtr as an enhanced alternative
3. Document the sudo requirement clearly in examples and on the docs site

**Detection:** mtr fails with "Operation not permitted" or produces empty output on macOS.

**Phase mapping:** Address when building traceroute/mtr tool integration and diagnostic scripts.

**Confidence:** HIGH -- macOS raw socket restriction is a well-known platform behavior.

## Minor Pitfalls

### Pitfall 11: wget not installed on macOS by default

**What goes wrong:** The curl/wget tool integration shows wget examples, but macOS does not ship wget. Users try wget examples and get "command not found."

**Prevention:**
1. Lead with curl examples (pre-installed on both platforms)
2. Mark wget examples as "Linux or `brew install wget`"
3. Do NOT use `require_cmd wget` at the top of the script -- check it per-example instead so curl examples still work

**Confidence:** HIGH -- factual; macOS ships curl but not wget.

---

### Pitfall 12: Makefile target name collisions as tools proliferate

**What goes wrong:** With 11 existing tools and 5 new ones, plus diagnostic scripts, the Makefile grows to 50+ targets. Short names collide or become ambiguous (e.g., `make scan` could mean nmap scan, nikto scan, or gobuster scan). `make help` output becomes overwhelming.

**Prevention:**
1. Use namespaced targets: `make diag-dns`, `make diag-connectivity`, `make tool-gobuster`
2. Group related targets in `make help` output with section headers
3. Consider whether ALL scripts need Makefile targets -- diagnostic scripts may only need 3-4 top-level targets

**Detection:** `make help` produces 60+ lines. Users cannot find the target they want.

**Phase mapping:** Address when adding new Makefile targets. Decide on naming convention before adding the first new target.

**Confidence:** MEDIUM -- projected from current 40+ targets in the Makefile.

---

### Pitfall 13: GitHub Actions workflow not triggering on docs-only changes

**What goes wrong:** The GitHub Actions workflow for deploying the Astro site is configured to run on push to main, but if a path filter is added (e.g., only `site/**`), changes to script help text or README that should update the docs do not trigger a rebuild.

**Prevention:**
1. Keep the docs deploy workflow simple: trigger on all pushes to main, not path-filtered
2. Astro builds are fast (seconds for a markdown-only site), so rebuilding on every push is fine
3. If generation tooling extracts content from scripts, the workflow MUST trigger on script changes too

**Detection:** Docs page is stale despite recent commits that changed relevant scripts.

**Phase mapping:** Address during GitHub Actions workflow setup.

**Confidence:** MEDIUM -- common CI/CD configuration mistake.

---

### Pitfall 14: dig command not available on minimal Linux (replaced by drill or missing)

**What goes wrong:** Scripts assume `dig` is available, but some Linux distributions ship without BIND utilities. Alpine Linux and some container images do not include `dig` by default. Some distributions offer `drill` (from ldns) instead.

**Prevention:**
1. Check for `dig` and fall back to `drill` or `nslookup` (more universally available)
2. In the install hint, point to the correct package: `bind-utils` (RHEL/Fedora), `dnsutils` (Debian/Ubuntu), `bind-tools` (Alpine)
3. The diagnostic DNS scripts should detect which DNS tool is available rather than hardcoding `dig`

**Detection:** Works on macOS and full Linux installs but fails in Docker containers or minimal server images.

**Phase mapping:** Address when building the dig/DNS tool integration.

**Confidence:** HIGH -- factual dependency; `dig` is part of BIND utilities, not a core system command on Linux.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Astro site setup | Base path breaks all assets (Pitfall 1, 2) | Set `site` + `base` in config from day one; use official GitHub Action |
| Astro site content | Docs-code drift (Pitfall 5) | Build validation tooling alongside the site, not after |
| Astro site maintenance | Site becomes a frontend project (Pitfall 9) | Use Starlight; keep content markdown-only |
| Diagnostic scripts (DNS) | `dig` missing on minimal Linux (Pitfall 14) | Implement tool detection with fallbacks |
| Diagnostic scripts (all) | Deprecated commands on Linux (Pitfall 4) | Prefer `ip`/`ss` with fallback to legacy |
| Diagnostic scripts (all) | Pattern divergence from existing scripts (Pitfall 7) | Define pattern template before first script |
| Diagnostic scripts (all) | BSD vs GNU output parsing (Pitfall 6) | Use machine-readable output modes; test cross-platform |
| New tool: netcat | Variant incompatibility (Pitfall 3) | Detect variant; show examples for all; recommend ncat |
| New tool: curl/wget | wget not on macOS (Pitfall 11) | Lead with curl; mark wget as optional |
| New tool: traceroute/mtr | Root required for mtr on macOS (Pitfall 10) | Detect and warn; default to traceroute |
| New tool: gobuster/ffuf | Install complexity (Pitfall 8) | Provide install helper; add last |
| Makefile expansion | Target name collisions (Pitfall 12) | Namespace targets; decide convention early |
| GitHub Actions | Workflow trigger scope (Pitfall 13) | Trigger on all main pushes; do not path-filter |

## Sources

- [Astro GitHub Pages deployment guide](https://docs.astro.build/en/guides/deploy/github/)
- [Astro base path issue #4229](https://github.com/withastro/astro/issues/4229)
- [Astro image asset path issue #6504](https://github.com/withastro/astro/issues/6504)
- [Starlight docs site for Astro #2158](https://github.com/withastro/starlight/discussions/2158)
- [Fix missing Astro files on GitHub Pages](https://www.seanmcp.com/articles/fix-missing-astro-files-on-github-pages/)
- [Astro Starlight](https://starlight.astro.build/)
- [Deprecated Linux networking commands (2026)](https://thelinuxcode.com/deprecated-linux-networking-commands-and-their-replacements-2026-practical-guide/)
- [Red Hat deprecated command replacements](https://www.redhat.com/en/blog/deprecated-linux-command-replacements)
- [Netcat variant comparison](https://grahamhelton.com/blog/which_netcat)
- [Netcat vs ncat (Baeldung)](https://www.baeldung.com/linux/netcat-vs-nc-vs-ncat)
- [curl vs wget comparison](https://daniel.haxx.se/docs/curl-vs-wget.html)
- [Bash portability guide](https://moldstud.com/articles/p-maximize-your-bash-scripts-a-guide-to-portability-across-systems)
- [macOS network diagnostic commands](https://osxhub.com/macos-network-diagnostic-commands-guide/)
