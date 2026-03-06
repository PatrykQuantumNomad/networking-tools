#!/usr/bin/env bats
# tests/test-workflow-skills.bats -- Structural validation for dual-mode workflow SKILL.md files
# WORK-01: Standalone mode with direct tool commands at every step
# WORK-02: Dual-mode branching with wrapper script detection and per-step branching
# SYNC:    Plugin and in-repo workflow skills are identical

setup() {
    load 'test_helper/common-setup'
    _common_setup
}

# All 6 workflow skills
WORKFLOWS=(recon scan fuzz crack sniff diagnose)

# Extract section content between a heading and the next same-or-higher-level heading
# Usage: _section_content "## Steps" <file>
_section_content() {
    local heading="$1" file="$2"
    awk -v h="$heading" '
        $0 == h { found=1; next }
        found && /^## / { exit }
        found { print }
    ' "$file"
}

# Extract the Steps section (between "## Steps" and "## After Each Step" or "## Decision Guidance" or "## Summary")
_steps_content() {
    local file="$1"
    awk '
        /^## Steps/ { found=1; next }
        found && /^## (After Each Step|Decision Guidance|Summary)/ { exit }
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

# Extract standalone block content for a given step (between "If standalone" and the next "###" heading)
_standalone_block() {
    local step_num="$1" file="$2"
    awk -v sn="$step_num" '
        /^### / {
            match($0, /^### ([0-9]+)/, arr)
            if (arr[1] == sn) { in_step=1 }
            else if (in_step) { exit }
            next
        }
        in_step && /[Ii]f standalone/ { in_standalone=1; next }
        in_standalone && /^### / { exit }
        in_standalone { print }
    ' "$file"
}

# ---------------------------------------------------------------------------
# WORK-01: Standalone mode -- each workflow step has direct tool commands
# ---------------------------------------------------------------------------

@test "WORK-01: each workflow skill has an Environment Detection section" {
    local missing=()
    for wf in "${WORKFLOWS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        if [[ ! -f "$skill" ]]; then
            missing+=("$wf (file missing)")
            continue
        fi
        if ! grep -q "## Environment Detection" "$skill"; then
            missing+=("$wf")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing '## Environment Detection' section in: ${missing[*]}"
    fi
}

@test "WORK-01: each workflow step has standalone direct commands" {
    local failing=()
    for wf in "${WORKFLOWS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$wf (file missing)"); continue; }

        local steps_text
        steps_text=$(_steps_content "$skill")

        # Count step headings (### N.)
        local step_count
        step_count=$(echo "$steps_text" | grep -c '^### [0-9]' || true)

        # Count steps that have standalone branch text
        local standalone_count
        standalone_count=$(echo "$steps_text" | grep -ci 'if standalone' || true)

        if [[ "$standalone_count" -lt "$step_count" ]]; then
            failing+=("$wf (${standalone_count}/${step_count} steps have standalone)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Steps missing standalone commands: ${failing[*]}"
    fi
}

@test "WORK-01: standalone sections do not reference scripts/ paths" {
    local failing=()
    for wf in "${WORKFLOWS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$wf (file missing)"); continue; }

        # Extract all standalone blocks: content between "If standalone" lines and next "###" heading
        local standalone_text
        standalone_text=$(awk '
            /[Ii]f standalone/ { in_sa=1; next }
            in_sa && /^### / { in_sa=0; next }
            in_sa && /[Ii]f wrapper/ { in_sa=0; next }
            in_sa { print }
        ' "$skill")

        if echo "$standalone_text" | grep -q 'scripts/'; then
            failing+=("$wf")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Standalone sections reference scripts/ paths: ${failing[*]}"
    fi
}

# ---------------------------------------------------------------------------
# WORK-02: Dual-mode branching -- wrapper script detection and references
# ---------------------------------------------------------------------------

@test "WORK-02: each workflow has test -f dynamic injection in Environment Detection" {
    local missing=()
    for wf in "${WORKFLOWS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        if [[ ! -f "$skill" ]]; then
            missing+=("$wf (file missing)")
            continue
        fi
        if ! grep -q 'test -f scripts/' "$skill"; then
            missing+=("$wf")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        fail "Missing 'test -f scripts/' dynamic injection: ${missing[*]}"
    fi
}

@test "WORK-02: each workflow step has wrapper script references" {
    local failing=()
    for wf in "${WORKFLOWS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$wf (file missing)"); continue; }

        local steps_text
        steps_text=$(_steps_content "$skill")

        local wrapper_count
        wrapper_count=$(echo "$steps_text" | grep -c 'bash scripts/' || true)

        if [[ "$wrapper_count" -lt 1 ]]; then
            failing+=("$wf (no wrapper script references)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Missing wrapper script references in Steps: ${failing[*]}"
    fi
}

@test "WORK-02: wrapper branches include -j -x flags" {
    local failing=()
    for wf in "${WORKFLOWS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$wf (file missing)"); continue; }

        local steps_text
        steps_text=$(_steps_content "$skill")

        local jx_count
        jx_count=$(echo "$steps_text" | grep -c '\-j \-x' || true)

        # diagnose is special: steps 1-3 use diagnostic scripts without -j -x
        # so diagnose needs at least 2 (steps 4-5)
        local min_required=1
        if [[ "$wf" == "diagnose" ]]; then
            min_required=2
        fi

        if [[ "$jx_count" -lt "$min_required" ]]; then
            failing+=("$wf (found $jx_count, need $min_required+)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Insufficient -j -x flags in wrapper branches: ${failing[*]}"
    fi
}

# ---------------------------------------------------------------------------
# SYNC: Plugin and in-repo workflow skills are identical
# ---------------------------------------------------------------------------

@test "SYNC: in-repo and plugin workflow SKILL.md files are identical" {
    local failing=()
    for wf in "${WORKFLOWS[@]}"; do
        local inrepo="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        local plugin="${PROJECT_ROOT}/netsec-skills/skills/workflows/${wf}/SKILL.md"
        [[ ! -f "$inrepo" ]] && { failing+=("$wf (in-repo missing)"); continue; }
        [[ ! -f "$plugin" ]] && { failing+=("$wf (plugin missing)"); continue; }

        if ! cmp -s "$inrepo" "$plugin"; then
            failing+=("$wf")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Out of sync: ${failing[*]}"
    fi
}

# ---------------------------------------------------------------------------
# WORK-01: Description keywords
# ---------------------------------------------------------------------------

@test "WORK-01: workflow description does not contain 'wrapper scripts'" {
    local failing=()
    for wf in "${WORKFLOWS[@]}"; do
        local skill="${PROJECT_ROOT}/.claude/skills/${wf}/SKILL.md"
        [[ ! -f "$skill" ]] && { failing+=("$wf (file missing)"); continue; }

        local desc
        desc=$(_extract_description "$skill")
        if echo "$desc" | grep -qi "wrapper scripts"; then
            failing+=("$wf")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Description contains 'wrapper scripts': ${failing[*]}"
    fi
}
