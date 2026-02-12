#!/usr/bin/env bash
# ============================================================================
# @description  DNS diagnostic auto-report with propagation and record checks
# @usage        diagnostics/dns.sh [target] [-h|--help]
# @dependencies dig, common.sh
# ============================================================================
# Pattern B: Diagnostic auto-report (non-interactive, no safety_banner)

source "$(dirname "$0")/../common.sh"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

show_help() {
    cat <<EOF
Usage: $(basename "$0") [target] [-h|--help]

Description:
  Runs a comprehensive DNS diagnostic for the given domain.
  Checks resolution, record types, propagation across public
  resolvers, and reverse DNS lookup.

  Default target: example.com

Examples:
    $(basename "$0")                 # Diagnose example.com
    $(basename "$0") mysite.com      # Diagnose mysite.com
    $(basename "$0") google.com      # Diagnose google.com
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

# ---------------------------------------------------------------------------
# Requirements
# ---------------------------------------------------------------------------

require_cmd dig "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"

# ---------------------------------------------------------------------------
# Public DNS resolvers for propagation checks
# ---------------------------------------------------------------------------

RESOLVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9" "208.67.222.222")
RESOLVER_NAMES=("Google" "Cloudflare" "Quad9" "OpenDNS")

# ---------------------------------------------------------------------------
# Pass / Fail / Warn counters
# ---------------------------------------------------------------------------

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

count_pass() {
    report_pass "$@"
    PASS_COUNT=$((PASS_COUNT + 1))
}

count_fail() {
    report_fail "$@"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

count_warn() {
    report_warn "$@"
    WARN_COUNT=$((WARN_COUNT + 1))
}

# ---------------------------------------------------------------------------
# Report header
# ---------------------------------------------------------------------------

info "=== DNS Diagnostic Report ==="
info "Target: ${TARGET}"
info "Date:   $(date)"
echo ""

# ===================================================================
# Section 1: DNS Resolution
# ===================================================================

report_section "DNS Resolution"

# A record
a_result=$(dig +short "${TARGET}" A 2>/dev/null | grep -E '^[0-9]+\.' | head -5)
if [[ -n "$a_result" ]]; then
    count_pass "A record for ${TARGET}"
    while IFS= read -r line; do
        echo "   ${line}"
    done <<< "$a_result"
else
    count_fail "A record for ${TARGET} (no IPv4 address found)"
fi

# AAAA record (warn if missing -- many domains lack IPv6)
aaaa_result=$(dig +short "${TARGET}" AAAA 2>/dev/null | grep -E '^[0-9a-fA-F:]+' | head -5)
if [[ -n "$aaaa_result" ]]; then
    count_pass "AAAA record for ${TARGET} (IPv6)"
    while IFS= read -r line; do
        echo "   ${line}"
    done <<< "$aaaa_result"
else
    count_warn "No AAAA record for ${TARGET} (IPv6 not configured)"
fi

# CNAME for www subdomain
cname_result=$(dig +short "www.${TARGET}" CNAME 2>/dev/null | head -3)
if [[ -n "$cname_result" ]]; then
    count_pass "CNAME record for www.${TARGET}"
    while IFS= read -r line; do
        echo "   ${line}"
    done <<< "$cname_result"
else
    # www might resolve via A record directly -- check that
    www_a=$(dig +short "www.${TARGET}" A 2>/dev/null | head -1)
    if [[ -n "$www_a" ]]; then
        count_pass "www.${TARGET} resolves via A record (no CNAME)"
        echo "   ${www_a}"
    else
        count_warn "www.${TARGET} does not resolve (no CNAME or A record)"
    fi
fi

# ===================================================================
# Section 2: DNS Record Types
# ===================================================================

report_section "DNS Record Types"

# MX records (warn if empty -- not all domains have mail)
mx_result=$(dig +short "${TARGET}" MX 2>/dev/null | head -5)
if [[ -n "$mx_result" ]]; then
    count_pass "MX records for ${TARGET}"
    while IFS= read -r line; do
        echo "   ${line}"
    done <<< "$mx_result"
else
    count_warn "No MX records for ${TARGET} (no mail configuration)"
fi

# NS records (fail if empty -- every domain must have NS)
ns_result=$(dig +short "${TARGET}" NS 2>/dev/null | head -5)
if [[ -n "$ns_result" ]]; then
    count_pass "NS records for ${TARGET}"
    while IFS= read -r line; do
        echo "   ${line}"
    done <<< "$ns_result"
else
    count_fail "NS records for ${TARGET} (no nameservers found)"
fi

# TXT records (warn if empty)
txt_result=$(dig +short "${TARGET}" TXT 2>/dev/null | head -5)
if [[ -n "$txt_result" ]]; then
    count_pass "TXT records for ${TARGET}"
    while IFS= read -r line; do
        echo "   ${line}"
    done <<< "$txt_result"
else
    count_warn "No TXT records for ${TARGET}"
fi

# SOA record (fail if empty -- every domain must have SOA)
soa_result=$(dig +short "${TARGET}" SOA 2>/dev/null | head -1)
if [[ -n "$soa_result" ]]; then
    count_pass "SOA record for ${TARGET}"
    echo "   ${soa_result}"
else
    count_fail "SOA record for ${TARGET} (no SOA found)"
fi

# ===================================================================
# Section 3: DNS Propagation
# ===================================================================

report_section "DNS Propagation"

declare -a propagation_results=()

for i in "${!RESOLVERS[@]}"; do
    resolver="${RESOLVERS[$i]}"
    name="${RESOLVER_NAMES[$i]}"
    result=$(dig +short "@${resolver}" "${TARGET}" A 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
    if [[ -n "$result" ]]; then
        count_pass "${name} (${resolver}): ${result}"
        propagation_results+=("$result")
    else
        count_warn "${name} (${resolver}): no response"
    fi
done

# Check consistency across resolvers
if [[ ${#propagation_results[@]} -gt 0 ]]; then
    unique_count=$(printf '%s\n' "${propagation_results[@]}" | sort -u | wc -l | tr -d ' ')
    if [[ "$unique_count" -le 1 ]]; then
        count_pass "All resolvers agree"
    else
        count_warn "Resolvers returned different results (propagation may be in progress)"
    fi
else
    count_warn "No resolvers returned results"
fi

# ===================================================================
# Section 4: Reverse DNS
# ===================================================================

report_section "Reverse DNS"

# Get the first A record IP for reverse lookup
reverse_ip=$(dig +short "${TARGET}" A 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
if [[ -n "$reverse_ip" ]]; then
    ptr_result=$(dig -x "${reverse_ip}" +short 2>/dev/null | head -1)
    if [[ -n "$ptr_result" ]]; then
        count_pass "Reverse DNS (PTR) for ${reverse_ip}"
        echo "   ${ptr_result}"
    else
        count_warn "No reverse DNS (PTR) for ${reverse_ip} (common but not critical)"
    fi
else
    count_warn "Cannot perform reverse DNS lookup (no A record to resolve)"
fi

# ===================================================================
# Section 5: Summary
# ===================================================================

report_section "Summary"

total=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
summary="${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${WARN_COUNT} warnings (${total} checks)"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    count_fail "$summary"
elif [[ "$WARN_COUNT" -gt 0 ]]; then
    count_warn "$summary"
else
    count_pass "$summary"
fi
