# Phase 7: Web Enumeration Tools - Research

**Researched:** 2026-02-10
**Domain:** Web content discovery and fuzzing (gobuster, ffuf, SecLists wordlists)
**Confidence:** HIGH

## Summary

Phase 7 adds two web enumeration tools -- gobuster (directory/DNS/vhost enumeration) and ffuf (flexible web fuzzing) -- plus wordlist infrastructure that downloads SecLists files for immediate use. Both tools are written in Go and available via Homebrew, making installation straightforward on macOS. They follow the same bash script patterns established by the 16 existing tools in the project.

The key technical consideration is that both tools require wordlists to function, unlike most other tools in this project that work with just a target argument. The wordlist download helper must be created before the tools are practically usable against lab targets. Both tools also require special handling in `check-tools.sh` because neither supports the standard `--version` flag used by the existing `get_version()` function -- gobuster uses a `version` subcommand, and ffuf uses `-V`.

**Primary recommendation:** Build gobuster and ffuf scripts following the exact existing pattern (examples.sh + use-case scripts), add SecLists wordlist downloads to the existing `wordlists/download.sh`, and add site documentation pages (required by CI docs-completeness validation).

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| gobuster | 3.8.2 | Directory/file, DNS, and vhost enumeration | De facto standard for directory brute-forcing; fast Go implementation, 7 modes |
| ffuf | 2.1.0 | Flexible web fuzzing (directories, parameters, headers, POST data) | Most versatile web fuzzer; FUZZ keyword system allows fuzzing any part of a request |

### Supporting
| Resource | Source | Purpose | When to Use |
|----------|--------|---------|-------------|
| SecLists common.txt | danielmiessler/SecLists | Small general-purpose directory wordlist (~4,700 entries) | Quick initial directory enumeration |
| SecLists directory-list-2.3-small.txt | danielmiessler/SecLists | DirBuster-derived directory wordlist (~87,000 entries) | Thorough directory enumeration |
| SecLists subdomains-top1million-5000.txt | danielmiessler/SecLists | Top 5,000 most common subdomains | Quick subdomain enumeration |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| gobuster | dirsearch (Python) | dirsearch is slower but easier to install (pip); gobuster is faster and already in Homebrew |
| ffuf | wfuzz (Python) | wfuzz is the older standard; ffuf is faster, more flexible, and actively maintained |
| SecLists | Custom wordlists | SecLists is the industry standard; no reason to hand-roll wordlists |

### Installation

```bash
# macOS (Homebrew)
brew install gobuster ffuf

# Go install (if Go is available)
go install github.com/OJ/gobuster/v3@latest
go install github.com/ffuf/ffuf/v2@latest

# Linux (Debian/Ubuntu)
sudo apt install gobuster
# ffuf: download binary from https://github.com/ffuf/ffuf/releases
```

## Architecture Patterns

### Project Structure (new files)
```
scripts/
  gobuster/
    examples.sh              # 10 numbered gobuster examples
    discover-directories.sh  # Use-case: directory enumeration against target
    enumerate-subdomains.sh  # Use-case: DNS subdomain discovery
  ffuf/
    examples.sh              # 10 numbered ffuf examples
    fuzz-parameters.sh       # Use-case: GET/POST parameter fuzzing
wordlists/
  download.sh               # Extended to download SecLists wordlists
site/src/content/docs/tools/
  gobuster.mdx              # Site documentation page
  ffuf.mdx                  # Site documentation page
```

### Pattern: examples.sh (Pattern A -- Educational Examples)

Every examples.sh follows the identical structure. Source: existing `scripts/nikto/examples.sh`, `scripts/nmap/examples.sh`.

```bash
#!/usr/bin/env bash
# <tool>/examples.sh -- <tool description>
source "$(dirname "$0")/../common.sh"

show_help() {
    cat <<'EOF'
Usage: examples.sh <target>
...
EOF
    exit 0
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help

require_cmd <tool> "<install-hint>"
require_target "${1:-}"
safety_banner

TARGET="$1"

info "=== <Tool> Examples ==="
info "Target: ${TARGET}"
echo ""

# 1-10 numbered examples with info "N) Title" + echo "   command"

[[ -t 0 ]] || exit 0
read -rp "Run a basic <action> against ${TARGET} now? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: <safe demo command>"
    <command> || true
fi
```

### Pattern: Use-Case Scripts (sensible defaults)

Use-case scripts use `${1:-<default>}` for target (no `require_target`). Source: existing `scripts/nmap/discover-live-hosts.sh`.

```bash
#!/usr/bin/env bash
# <tool>/<use-case>.sh -- <description>
source "$(dirname "$0")/../common.sh"

show_help() { ... }
[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd <tool> "<install-hint>"

TARGET="${1:-<sensible-default>}"

safety_banner

info "=== <Use Case Title> ==="
info "Target: ${TARGET}"
echo ""

info "Why <educational context>?"
echo "   <explanation>"
echo ""

# 10 numbered examples specific to this use case

[[ ! -t 0 ]] && exit 0
read -rp "Run <demo>? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    <safe demo command>
fi
```

### Pattern: Wordlist Path Convention

Both gobuster and ffuf require `-w <wordlist>` flag. Scripts should use `$PROJECT_ROOT/wordlists/` as the default wordlist location since `$PROJECT_ROOT` is already defined in common.sh.

```bash
WORDLIST="${PROJECT_ROOT}/wordlists/common.txt"
if [[ ! -f "$WORDLIST" ]]; then
    warn "Wordlist not found: $WORDLIST"
    info "Run: make wordlists   (downloads SecLists wordlists)"
    info "Or specify your own: $0 <target> <wordlist>"
fi
```

### Anti-Patterns to Avoid
- **Hardcoding `/usr/share/seclists/` paths:** Not portable. Use `$PROJECT_ROOT/wordlists/` for project wordlists.
- **Using high thread counts in demos:** Gobuster defaults to 10 threads, ffuf to 40. Use 10 or fewer for interactive demos against lab targets to avoid overwhelming Docker containers.
- **Forgetting the wordlist dependency:** Every gobuster/ffuf command needs `-w`. Scripts must check wordlist existence and provide clear download instructions.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Directory wordlists | Custom word lists | SecLists common.txt, directory-list-2.3-small.txt | Industry standard, comprehensive, maintained |
| Subdomain wordlists | Custom word lists | SecLists subdomains-top1million-5000.txt | Derived from real-world DNS data (Cloudflare zone transfers) |
| Web content discovery | Custom curl loops | gobuster dir / ffuf | Handles threading, status filtering, output formatting |
| Parameter discovery | Manual testing | ffuf FUZZ keyword | Systematic, fast, supports filtering by response attributes |

**Key insight:** The wordlist download helper is an extension of the existing `wordlists/download.sh` pattern, not a new system. It should follow the same structure: check if file exists, download if missing, report success.

## Common Pitfalls

### Pitfall 1: gobuster and ffuf Version Detection (PITFALL-8 from roadmap)
**What goes wrong:** `check-tools.sh` uses `$tool --version` which fails for both tools. gobuster uses `gobuster version` subcommand, and ffuf uses `ffuf -V`.
**Why it happens:** Go CLI tools don't follow the `--version` convention consistently.
**How to avoid:** Add special cases in `get_version()` function in `check-tools.sh`, similar to existing special cases for `msfconsole`, `dig`, and `nc`.
**Specific fix:**
```bash
get_version() {
    local tool="$1"
    case "$tool" in
        gobuster)
            gobuster version 2>/dev/null | head -1
            ;;
        ffuf)
            ffuf -V 2>&1 | head -1
            ;;
        # ... existing cases ...
    esac
}
```

### Pitfall 2: Wordlist Not Downloaded Before Running Tools
**What goes wrong:** User runs gobuster/ffuf examples but wordlists are not present, leading to confusing file-not-found errors.
**Why it happens:** Wordlists are gitignored (too large for git). They must be downloaded first.
**How to avoid:** Scripts should check for wordlist presence and print clear instructions: `make wordlists`. The interactive demo in examples.sh should verify the wordlist exists before attempting to run.
**Warning signs:** Error messages about missing files when running demos.

### Pitfall 3: CI Docs-Completeness Validation Failure
**What goes wrong:** Adding `scripts/gobuster/examples.sh` and `scripts/ffuf/examples.sh` without corresponding site pages causes CI to fail.
**Why it happens:** `scripts/check-docs-completeness.sh` checks that every `scripts/*/examples.sh` has a matching `site/src/content/docs/tools/<tool>.md` or `.mdx` file.
**How to avoid:** Create `gobuster.mdx` and `ffuf.mdx` site documentation pages as part of the same plan that creates the examples.sh scripts, or in a dedicated follow-up plan within this phase.
**Warning signs:** `bash scripts/check-docs-completeness.sh` fails locally before pushing.

### Pitfall 4: Install Hint Complexity
**What goes wrong:** Unlike most tools that are a simple `brew install`, gobuster and ffuf can also be installed via `go install` or binary download.
**Why it happens:** Go-based tools have multiple valid install paths, and not all users have Homebrew.
**How to avoid:** Use Homebrew as the primary install hint (consistent with existing tools), but mention `go install` as an alternative. Format: `"brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"`.

### Pitfall 5: ffuf Default Thread Count Too High for Lab Targets
**What goes wrong:** ffuf defaults to 40 threads, which can overwhelm Docker lab targets (especially DVWA which is a simple PHP app).
**Why it happens:** ffuf is designed for remote scanning where high concurrency is desired.
**How to avoid:** Use `-t 10` or `-rate 50` in all demo commands and examples that target lab URLs. Document this clearly in the educational context.

### Pitfall 6: gobuster dns Mode Flag Change
**What goes wrong:** Older gobuster tutorials show `-d` for domain in DNS mode, but v3.8+ uses `-do` for the domain flag.
**Why it happens:** gobuster v3.6+ changed the DNS domain flag from `-d` to `-do`.
**How to avoid:** Use `-do` in all DNS mode examples. Verify against current gobuster help output.

## Code Examples

### gobuster dir -- Basic Directory Enumeration
```bash
# Source: https://github.com/OJ/gobuster README
gobuster dir -u http://localhost:8080 -w wordlists/common.txt
```

### gobuster dir -- With Extensions and Status Filtering
```bash
# Source: https://hackertarget.com/gobuster-tutorial/
gobuster dir -u http://localhost:8080 -w wordlists/common.txt -x php,html,txt -t 10
```

### gobuster dns -- Subdomain Enumeration
```bash
# Source: https://github.com/OJ/gobuster README
gobuster dns -do example.com -w wordlists/subdomains-top1million-5000.txt -r 8.8.8.8:53
```

### gobuster vhost -- Virtual Host Discovery
```bash
# Source: https://github.com/OJ/gobuster README
gobuster vhost -u http://localhost:8080 --append-domain -w wordlists/subdomains-top1million-5000.txt
```

### ffuf -- Basic Directory Fuzzing
```bash
# Source: https://github.com/ffuf/ffuf README
ffuf -u http://localhost:8080/FUZZ -w wordlists/common.txt -t 10
```

### ffuf -- Filter by Status Code
```bash
# Source: https://github.com/ffuf/ffuf README
ffuf -u http://localhost:8080/FUZZ -w wordlists/common.txt -mc 200,301 -t 10
```

### ffuf -- GET Parameter Fuzzing
```bash
# Source: https://github.com/ffuf/ffuf README
ffuf -u "http://localhost:8080/page.php?FUZZ=test" -w wordlists/burp-parameter-names.txt -fs 4242 -t 10
```

### ffuf -- POST Data Fuzzing
```bash
# Source: https://github.com/ffuf/ffuf README
ffuf -u http://localhost:8080/login.php -X POST \
  -d "username=admin&password=FUZZ" \
  -w wordlists/rockyou.txt -fc 401 -t 10
```

### ffuf -- Auto-Calibration (filters noise automatically)
```bash
# Source: https://github.com/ffuf/ffuf README
ffuf -u http://localhost:8080/FUZZ -w wordlists/common.txt -ac -t 10
```

### Wordlist Download Pattern
```bash
# Source: existing wordlists/download.sh pattern
COMMON_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
COMMON="${WORDLIST_DIR}/common.txt"

if [[ -f "$COMMON" ]]; then
    info "common.txt already exists ($(wc -l < "$COMMON" | tr -d ' ') entries)"
else
    info "Downloading SecLists common.txt (~40KB)..."
    curl -L -o "$COMMON" "$COMMON_URL"
    if [[ -f "$COMMON" ]]; then
        success "Downloaded common.txt ($(wc -l < "$COMMON" | tr -d ' ') entries)"
    else
        error "Download failed -- check your internet connection"
    fi
fi
```

## Integration Points

### check-tools.sh Changes
Add to `TOOLS` associative array:
```bash
[gobuster]="brew install gobuster (or: go install github.com/OJ/gobuster/v3@latest)"
[ffuf]="brew install ffuf (or: go install github.com/ffuf/ffuf/v2@latest)"
```

Add to `TOOL_ORDER` array (append after existing tools):
```bash
TOOL_ORDER=(... gobuster ffuf)
```

Add to `get_version()` case statement:
```bash
gobuster)
    gobuster version 2>/dev/null | head -1
    ;;
ffuf)
    ffuf -V 2>&1 | head -1
    ;;
```

### Makefile Changes
Add targets following existing naming convention:
```makefile
gobuster: ## Run gobuster examples (usage: make gobuster TARGET=<url>)
	@bash scripts/gobuster/examples.sh $(TARGET)

ffuf: ## Run ffuf examples (usage: make ffuf TARGET=<url>)
	@bash scripts/ffuf/examples.sh $(TARGET)

discover-dirs: ## Discover directories (usage: make discover-dirs TARGET=<url>)
	@bash scripts/gobuster/discover-directories.sh $(or $(TARGET),http://localhost:8080)

enum-subdomains: ## Enumerate subdomains (usage: make enum-subdomains TARGET=<domain>)
	@bash scripts/gobuster/enumerate-subdomains.sh $(or $(TARGET),example.com)

fuzz-params: ## Fuzz parameters (usage: make fuzz-params TARGET=<url>)
	@bash scripts/ffuf/fuzz-parameters.sh $(or $(TARGET),http://localhost:8080)
```

Add to `.PHONY` line.

### Site Documentation Pages
Both `gobuster.mdx` and `ffuf.mdx` must be created in `site/src/content/docs/tools/` to pass CI docs-completeness validation. Follow the established `.mdx` pattern with:
- Starlight frontmatter (title, description, sidebar order)
- `import { Tabs, TabItem } from '@astrojs/starlight/components'`
- OS-specific install tabs (macOS Homebrew vs Linux apt vs Go install)
- Key flags table
- Use-case descriptions
- Cross-references to related tools

### Wordlist Download Extension
The existing `wordlists/download.sh` currently only downloads `rockyou.txt`. Extend it to also download:
1. `common.txt` -- SecLists Web-Content (~4,700 entries, ~40KB)
2. `directory-list-2.3-small.txt` -- SecLists Web-Content (~87,000 entries, ~1MB)
3. `subdomains-top1million-5000.txt` -- SecLists DNS (~5,000 entries, ~35KB)

Raw download URLs:
- `https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt`
- `https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-small.txt`
- `https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt`

All `.txt` files in `wordlists/` are already gitignored.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| DirBuster (Java GUI) | gobuster (Go CLI) | ~2018 | Much faster, scriptable, no Java dependency |
| wfuzz (Python) | ffuf (Go) | ~2019 | 10x faster, cleaner syntax, actively maintained |
| gobuster dns `-d` flag | gobuster dns `-do` flag | gobuster v3.6+ | Old tutorials show wrong flag |
| Manual wordlist curation | SecLists (community-maintained) | Ongoing | Industry standard, regularly updated |

**Deprecated/outdated:**
- DirBuster: Replaced by gobuster and dirsearch
- wfuzz: Still maintained but ffuf is the modern choice
- gobuster `-d` flag for DNS domain: Changed to `-do` in v3.6+

## Open Questions

1. **gobuster `version` subcommand output format**
   - What we know: hackertarget tutorial shows `gobuster version` outputs just the version number (e.g., `3.1.0`)
   - What's unclear: Whether newer versions (3.8.2) output additional build info that would need `head -1`
   - Recommendation: Use `gobuster version 2>/dev/null | head -1` to be safe; test locally

2. **ffuf `-V` output format**
   - What we know: ffuf uses `-V` flag for version display
   - What's unclear: Exact output format (may include banner text)
   - Recommendation: Use `ffuf -V 2>&1 | head -1` to capture first line only; test locally

3. **Lab target response to high-concurrency scanning**
   - What we know: Docker containers may not handle 40+ concurrent requests well
   - What's unclear: Exact threshold before DVWA/JuiceShop start dropping requests
   - Recommendation: Default to `-t 10` in all demo/use-case commands; document rate limiting

## Sources

### Primary (HIGH confidence)
- [OJ/gobuster GitHub](https://github.com/OJ/gobuster) -- modes, flags, installation, version 3.8.2
- [ffuf/ffuf GitHub](https://github.com/ffuf/ffuf) -- flags, FUZZ keyword, installation, version 2.1.0
- [danielmiessler/SecLists GitHub](https://github.com/danielmiessler/SecLists) -- wordlist file paths and descriptions
- [Homebrew gobuster formula](https://formulae.brew.sh/formula/gobuster) -- current version 3.8.2, Go dependency
- [Homebrew ffuf formula](https://formulae.brew.sh/formula/ffuf) -- current version 2.1.0, Go dependency

### Secondary (MEDIUM confidence)
- [hackertarget.com gobuster tutorial](https://hackertarget.com/gobuster-tutorial/) -- version output format, practical examples
- [Debian gobuster manpage](https://manpages.debian.org/testing/gobuster/gobuster.1.en.html) -- flag documentation for v3.8
- [ffuf hashnode parameter fuzzing](https://ffuf.hashnode.dev/parameter-fuzzing) -- POST data fuzzing patterns

### Tertiary (LOW confidence)
- gobuster `version` subcommand exact output format for v3.8.2 -- not verified against actual binary
- ffuf `-V` exact output format for v2.1.0 -- not verified against actual binary

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- both tools verified on Homebrew with current versions, GitHub repos checked
- Architecture: HIGH -- follows identical patterns to 16 existing tools in the project
- Pitfalls: HIGH -- version detection, wordlist dependency, CI validation all verified against actual codebase
- Integration points: HIGH -- check-tools.sh, Makefile, and site patterns all verified from source

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (stable tools, no rapid changes expected)
