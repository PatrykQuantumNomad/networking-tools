#!/usr/bin/env bats
# tests/test-agent-personas.bats -- Structural validation for agent persona files
# AGEN-01: Agent files exist as real files in plugin with correct skill references and dual-mode body
# AGEN-02: Invoker skills exist as real files in plugin with context: fork and agent: fields
# SYNC:    Plugin and in-repo agent/invoker/utility files are identical; no remaining symlinks

setup() {
    load 'test_helper/common-setup'
    _common_setup
}

# All 3 agent personas
AGENTS=(pentester defender analyst)

# All 3 invoker skills (same names, different paths)
INVOKERS=(pentester defender analyst)

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
# AGEN-01: Agent file structural tests
# ---------------------------------------------------------------------------

@test "AGEN-01: each agent file exists as real file in plugin" {
    local failing=()
    for agent in "${AGENTS[@]}"; do
        local plugin_file="${PROJECT_ROOT}/netsec-skills/agents/${agent}.md"
        if [[ ! -f "$plugin_file" ]]; then
            failing+=("$agent (missing)")
        elif [[ -L "$plugin_file" ]]; then
            failing+=("$agent (symlink)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Agent file issues: ${failing[*]}"
    fi
}

@test "AGEN-01: each agent has skills: field in frontmatter" {
    local failing=()
    for agent in "${AGENTS[@]}"; do
        local file="${PROJECT_ROOT}/.claude/agents/${agent}.md"
        if ! grep -q "^skills:" "$file"; then
            failing+=("$agent")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Missing skills: in frontmatter: ${failing[*]}"
    fi
}

@test "AGEN-01: each agent skills: reference resolves to a plugin skill" {
    local failing=()
    for agent in "${AGENTS[@]}"; do
        local file="${PROJECT_ROOT}/.claude/agents/${agent}.md"

        # Extract skill names from skills: block (lines matching "  - name" after "skills:" up to next non-indented line or ---)
        local in_skills=0
        local skill_names=()
        while IFS= read -r line; do
            if [[ "$line" == "skills:" ]]; then
                in_skills=1
                continue
            fi
            if [[ $in_skills -eq 1 ]]; then
                if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.*) ]]; then
                    skill_names+=("${BASH_REMATCH[1]}")
                else
                    break
                fi
            fi
        done < "$file"

        # For each skill name, verify a SKILL.md with matching name: field exists in plugin
        for skill_name in "${skill_names[@]}"; do
            local found=0
            while IFS= read -r skill_file; do
                if grep -q "^name: ${skill_name}$" "$skill_file" 2>/dev/null; then
                    found=1
                    break
                fi
            done < <(find "$PROJECT_ROOT/netsec-skills/skills" -name SKILL.md 2>/dev/null)
            if [[ $found -eq 0 ]]; then
                failing+=("${agent}:${skill_name} (not found in plugin)")
            fi
        done
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Skill references not found in plugin: ${failing[*]}"
    fi
}

@test "AGEN-01: agent body does not contain in-repo-only instructions" {
    local failing=()
    for agent in "${AGENTS[@]}"; do
        local file="${PROJECT_ROOT}/.claude/agents/${agent}.md"

        # Extract body content after closing --- frontmatter delimiter
        local body
        body=$(awk '
            /^---$/ { fm++; next }
            fm >= 2 { print }
        ' "$file")

        if echo "$body" | grep -qi "Never invoke raw"; then
            failing+=("$agent (contains 'Never invoke raw')")
        fi
        if echo "$body" | grep -qi "Always use wrapper"; then
            failing+=("$agent (contains 'Always use wrapper')")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "In-repo-only instructions found: ${failing[*]}"
    fi
}

@test "AGEN-01: pentester agent has dual-mode execution rules" {
    local file="${PROJECT_ROOT}/.claude/agents/pentester.md"

    # Extract body content after closing --- frontmatter delimiter
    local body
    body=$(awk '
        /^---$/ { fm++; next }
        fm >= 2 { print }
    ' "$file")

    local has_wrapper=0
    local has_standalone=0

    if echo "$body" | grep -qi "wrapper scripts"; then
        has_wrapper=1
    fi
    if echo "$body" | grep -qi "standalone\|direct"; then
        has_standalone=1
    fi

    if [[ $has_wrapper -eq 0 ]]; then
        fail "Pentester agent body missing 'wrapper scripts' reference for dual-mode"
    fi
    if [[ $has_standalone -eq 0 ]]; then
        fail "Pentester agent body missing 'standalone' or 'direct' reference for dual-mode"
    fi
}

# ---------------------------------------------------------------------------
# AGEN-02: Invoker skill structural tests
# ---------------------------------------------------------------------------

@test "AGEN-02: each invoker skill exists as real file in plugin" {
    local failing=()
    for invoker in "${INVOKERS[@]}"; do
        local plugin_dir="${PROJECT_ROOT}/netsec-skills/skills/agents/${invoker}"
        local plugin_file="${plugin_dir}/SKILL.md"
        if [[ ! -f "$plugin_file" ]]; then
            failing+=("$invoker (missing)")
        elif [[ -L "$plugin_dir" ]]; then
            failing+=("$invoker (directory is symlink)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Invoker skill issues: ${failing[*]}"
    fi
}

@test "AGEN-02: each invoker skill has context: fork and agent: fields" {
    local failing=()
    for invoker in "${INVOKERS[@]}"; do
        local file="${PROJECT_ROOT}/.claude/skills/${invoker}/SKILL.md"
        if ! grep -q "^context: fork" "$file"; then
            failing+=("$invoker (missing context: fork)")
        fi
        if ! grep -q "^agent:" "$file"; then
            failing+=("$invoker (missing agent: field)")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Invoker frontmatter issues: ${failing[*]}"
    fi
}

@test "AGEN-02: pentest-conventions exists in plugin as real file" {
    local plugin_dir="${PROJECT_ROOT}/netsec-skills/skills/utility/pentest-conventions"
    local plugin_file="${plugin_dir}/SKILL.md"

    if [[ ! -f "$plugin_file" ]]; then
        fail "pentest-conventions SKILL.md missing from plugin at ${plugin_file}"
    fi
    if [[ -L "$plugin_dir" ]]; then
        fail "pentest-conventions directory is a symlink (should be real directory)"
    fi
}

# ---------------------------------------------------------------------------
# SYNC: In-repo and plugin files are identical
# ---------------------------------------------------------------------------

@test "SYNC: in-repo and plugin agent files are identical" {
    local failing=()
    for agent in "${AGENTS[@]}"; do
        local inrepo="${PROJECT_ROOT}/.claude/agents/${agent}.md"
        local plugin="${PROJECT_ROOT}/netsec-skills/agents/${agent}.md"
        [[ ! -f "$inrepo" ]] && { failing+=("$agent (in-repo missing)"); continue; }
        [[ ! -f "$plugin" ]] && { failing+=("$agent (plugin missing)"); continue; }

        if ! cmp -s "$inrepo" "$plugin"; then
            failing+=("$agent")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Agent files out of sync: ${failing[*]}"
    fi
}

@test "SYNC: in-repo and plugin invoker skills are identical" {
    local failing=()
    for invoker in "${INVOKERS[@]}"; do
        local inrepo="${PROJECT_ROOT}/.claude/skills/${invoker}/SKILL.md"
        local plugin="${PROJECT_ROOT}/netsec-skills/skills/agents/${invoker}/SKILL.md"
        [[ ! -f "$inrepo" ]] && { failing+=("$invoker (in-repo missing)"); continue; }
        [[ ! -f "$plugin" ]] && { failing+=("$invoker (plugin missing)"); continue; }

        if ! cmp -s "$inrepo" "$plugin"; then
            failing+=("$invoker")
        fi
    done
    if [[ ${#failing[@]} -gt 0 ]]; then
        fail "Invoker skills out of sync: ${failing[*]}"
    fi
}

@test "SYNC: in-repo and plugin pentest-conventions are identical" {
    local inrepo="${PROJECT_ROOT}/.claude/skills/pentest-conventions/SKILL.md"
    local plugin="${PROJECT_ROOT}/netsec-skills/skills/utility/pentest-conventions/SKILL.md"

    [[ ! -f "$inrepo" ]] && fail "In-repo pentest-conventions missing"
    [[ ! -f "$plugin" ]] && fail "Plugin pentest-conventions missing"

    if ! cmp -s "$inrepo" "$plugin"; then
        fail "pentest-conventions out of sync between in-repo and plugin"
    fi
}

# ---------------------------------------------------------------------------
# Utility skill tests
# ---------------------------------------------------------------------------

@test "AGEN-01: report skill exists as real file in plugin" {
    local plugin_dir="${PROJECT_ROOT}/netsec-skills/skills/utility/report"
    local plugin_file="${plugin_dir}/SKILL.md"

    if [[ ! -f "$plugin_file" ]]; then
        fail "report SKILL.md missing from plugin at ${plugin_file}"
    fi
    if [[ -L "$plugin_dir" ]]; then
        fail "report directory is a symlink (should be real directory)"
    fi
}

@test "SYNC: in-repo and plugin report skills are identical" {
    local inrepo="${PROJECT_ROOT}/.claude/skills/report/SKILL.md"
    local plugin="${PROJECT_ROOT}/netsec-skills/skills/utility/report/SKILL.md"

    [[ ! -f "$inrepo" ]] && fail "In-repo report skill missing"
    [[ ! -f "$plugin" ]] && fail "Plugin report skill missing"

    if ! cmp -s "$inrepo" "$plugin"; then
        fail "report skill out of sync between in-repo and plugin"
    fi
}

@test "SYNC: no remaining symlinks in plugin directory" {
    local symlinks
    symlinks=$(find "$PROJECT_ROOT/netsec-skills" -type l 2>/dev/null)

    if [[ -n "$symlinks" ]]; then
        fail "Remaining symlinks in plugin directory:
${symlinks}"
    fi
}
