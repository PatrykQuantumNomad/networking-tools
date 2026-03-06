#!/usr/bin/env bats
# tests/test-dual-mode-skills.bats -- Structural validation for dual-mode SKILL.md files
# TOOL-01: Standalone mode with inline tool knowledge
# TOOL-02: In-repo mode with wrapper script references
# TOOL-03: Tool install detection with platform-specific guidance
# TOOL-04: Description keywords optimized for auto-matching
# SYNC:    Plugin and in-repo skills are identical (validates final state after Plan 03)

setup() {
    load 'test_helper/common-setup'
    _common_setup
}

# All 17 tool skills
TOOLS=(nmap tshark metasploit aircrack-ng hashcat skipfish sqlmap hping3 john nikto foremost dig curl netcat traceroute gobuster ffuf)

# Resolve skill name to binary name for command -v checks
_binary_for() {
    case "$1" in
        metasploit) echo "msfconsole" ;;
        netcat)     echo "nc" ;;
        *)          echo "$1" ;;
    esac
}

# Extract section content between a heading and the next ## heading
# Usage: _section_content "## Mode: Standalone" <file>
_section_content() {
    local heading="$1" file="$2"
    awk -v h="$heading" '
        $0 == h { found=1; next }
        found && /^## / { exit }
        found { print }
    ' "$file"
}

# Extract description from YAML frontmatter (handles >- multi-line)
_extract_description() {
    awk '
        /^---$/ { fm++; next }
        fm == 1 && /^description:/ {
            found=1
            sub(/^description:[[:space:]]*>-?[[:space:]]*/, "")
            if (length($0) > 0) printf "%s ", $0
            next
        }
        found && /^[[:space:]]/ {
            gsub(/^[[:space:]]+/, "")
            printf "%s ", $0
            next
        }
        found { exit }
    ' "$1"
}

# ---------------------------------------------------------------------------
# TOOL-01: Standalone mode -- each SKILL.md has inline tool commands
# ---------------------------------------------------------------------------

@test "TOOL-01: each tool skill has a Standalone section header" {
    local missing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        if [[ ! -f "$skill" ]]; then
            missing+=("$tool (file missing)")
            continue
        fi
        if ! grep -q "## Mode: Standalone" "$skill"; then
            missing+=("$tool")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing '## Mode: Standalone' section in: ${missing[*]}"
    fi
}

@test "TOOL-01: standalone section has at least 3 command examples per tool" {
    local failing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$tool (file missing)"); continue; }

        local count
        count=$(_section_content "## Mode: Standalone (Direct Commands)" "$skill" | grep -c '^- `' || true)
        if [[ "$count" -lt 3 ]]; then
            failing+=("$tool (found $count, need 3+)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Insufficient standalone command examples: ${failing[*]}"
    fi
}

# ---------------------------------------------------------------------------
# TOOL-02: In-repo mode -- wrapper script references with -j -x flags
# ---------------------------------------------------------------------------

@test "TOOL-02: each tool skill has a Wrapper Scripts Available section header" {
    local missing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        if [[ ! -f "$skill" ]]; then
            missing+=("$tool (file missing)")
            continue
        fi
        if ! grep -q "## Mode: Wrapper Scripts Available" "$skill"; then
            missing+=("$tool")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing '## Mode: Wrapper Scripts Available' section in: ${missing[*]}"
    fi
}

@test "TOOL-02: wrapper section references scripts/<tool>/ with -j -x flags" {
    local failing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$tool (file missing)"); continue; }

        local wrapper_section
        wrapper_section=$(_section_content "## Mode: Wrapper Scripts Available" "$skill")

        if ! echo "$wrapper_section" | grep -q "scripts/${tool}/"; then
            failing+=("$tool (no scripts/${tool}/ reference)")
            continue
        fi
        # Check that both -j and -x appear somewhere in the wrapper section
        if ! echo "$wrapper_section" | grep -q "\-j" || ! echo "$wrapper_section" | grep -q "\-x"; then
            failing+=("$tool (missing -j -x flags)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Wrapper section issues: ${failing[*]}"
    fi
}

# ---------------------------------------------------------------------------
# TOOL-03: Install detection -- command -v dynamic injection
# ---------------------------------------------------------------------------

@test "TOOL-03: each tool skill has command -v dynamic injection for correct binary" {
    local failing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$tool (file missing)"); continue; }

        local binary
        binary=$(_binary_for "$tool")
        if ! grep -q "command -v ${binary}" "$skill"; then
            failing+=("$tool (missing command -v ${binary})")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Missing install detection: ${failing[*]}"
    fi
}

@test "TOOL-03: each tool skill has install guidance (brew or apt)" {
    local failing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$tool (file missing)"); continue; }

        if ! grep -qi "brew\|apt\|pip\|go install\|https://" "$skill"; then
            failing+=("$tool (no install guidance)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Missing install guidance: ${failing[*]}"
    fi
}

# ---------------------------------------------------------------------------
# TOOL-04: Description keywords -- action verbs, no "wrapper scripts", <200 chars
# ---------------------------------------------------------------------------

@test "TOOL-04: description does not contain 'wrapper scripts'" {
    local failing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$tool (file missing)"); continue; }

        local desc
        desc=$(_extract_description "$skill")
        if echo "$desc" | grep -qi "wrapper scripts"; then
            failing+=("$tool")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Description contains 'wrapper scripts': ${failing[*]}"
    fi
}

@test "TOOL-04: description is under 200 characters" {
    local failing=()
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$tool (file missing)"); continue; }

        local desc
        desc=$(_extract_description "$skill")
        local len=${#desc}
        if [[ "$len" -gt 200 ]]; then
            failing+=("$tool (${len} chars)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Description too long: ${failing[*]}"
    fi
}

@test "TOOL-04: description contains an action verb" {
    local failing=()
    local verbs="Scan|Capture|Crack|Debug|Discover|Detect|Generate|Fuzz|Query|Trace|Recover|Audit|Test|Set up|Craft"
    for tool in "${TOOLS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$tool (file missing)"); continue; }

        local desc
        desc=$(_extract_description "$skill")
        if ! echo "$desc" | grep -qiE "$verbs"; then
            failing+=("$tool")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Description missing action verb: ${failing[*]}"
    fi
}

# ---------------------------------------------------------------------------
# SYNC: Plugin and in-repo skills are identical
# NOTE: This test validates the final state after Plan 03 replaces symlinks
#       with real files and syncs all 17 tools. Expected to fail until then.
# ---------------------------------------------------------------------------

@test "SYNC: in-repo and plugin SKILL.md files are identical" {
    local failing=()
    for tool in "${TOOLS[@]}"; do
        local inrepo="${PROJECT_ROOT}/.claude/skills/${tool}/SKILL.md"
        local plugin="${PROJECT_ROOT}/netsec-skills/skills/tools/${tool}/SKILL.md"
        [[ ! -f "$inrepo" ]] && { failing+=("$tool (in-repo missing)"); continue; }
        [[ ! -f "$plugin" ]] && { failing+=("$tool (plugin missing)"); continue; }

        if ! cmp -s "$inrepo" "$plugin"; then
            failing+=("$tool")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Out of sync: ${failing[*]}"
    fi
}
