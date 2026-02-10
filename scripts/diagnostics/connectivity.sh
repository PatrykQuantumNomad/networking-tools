#!/usr/bin/env bash
# diagnostics/connectivity.sh -- Connectivity diagnostic auto-report
# Walks through network layers (DNS -> ICMP -> TCP -> HTTP -> TLS -> Timing)
# to diagnose connectivity issues for a target domain.
# Pattern B: Diagnostic auto-report (non-interactive, no safety_banner)

source "$(dirname "$0")/../common.sh"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

show_help() {
    cat <<EOF
Usage: $(basename "$0") [target] [-h|--help]

Description:
  Runs a layered connectivity diagnostic for the given domain.
  Checks local network, DNS resolution, ICMP reachability, TCP port
  connectivity, HTTP/HTTPS responses, TLS certificate, and connection
  timing.

  Default target: example.com

Examples:
    $(basename "$0")                        # Diagnose example.com
    $(basename "$0") google.com             # Diagnose google.com
    $(basename "$0") https://mysite.com     # Protocol prefix stripped automatically
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

# ---------------------------------------------------------------------------
# Requirements
# ---------------------------------------------------------------------------

require_cmd curl "apt install curl (Debian/Ubuntu) | dnf install curl (RHEL/Fedora) | brew install curl (macOS)"
require_cmd dig  "apt install dnsutils (Debian/Ubuntu) | dnf install bind-utils (RHEL/Fedora) | brew install bind (macOS)"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

# ---------------------------------------------------------------------------
# Helper: Strip protocol prefix from TARGET
# ---------------------------------------------------------------------------

strip_protocol() {
    echo "$1" | sed -E 's|^https?://||' | sed -E 's|/.*||'
}

HOST=$(strip_protocol "$TARGET")

# ---------------------------------------------------------------------------
# Helper: Portable ping
# ---------------------------------------------------------------------------

ping_host() {
    local target="$1"
    local count="${2:-3}"
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        ping -c "$count" -t 5 "$target" 2>/dev/null
    else
        ping -c "$count" -w 5 "$target" 2>/dev/null
    fi
}

# ---------------------------------------------------------------------------
# Helper: Get local IP address
# ---------------------------------------------------------------------------

get_local_ip() {
    local result=""
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # macOS: ifconfig is reliable; ip may exist but behaves differently
        result=$(ifconfig 2>/dev/null | awk '/inet / && !/127\.0\.0\.1/ {print $2}' | head -1 || true)
    elif check_cmd ip; then
        result=$(ip -4 addr show scope global 2>/dev/null | awk '/inet / {print $2}' | head -1 || true)
    else
        result=$(ifconfig 2>/dev/null | awk '/inet / && !/127\.0\.0\.1/ {print $2}' | head -1 || true)
    fi
    echo "$result"
}

# ---------------------------------------------------------------------------
# Helper: Get default gateway
# ---------------------------------------------------------------------------

get_default_gateway() {
    local result=""
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        result=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}' || true)
    elif check_cmd ip; then
        result=$(ip route show default 2>/dev/null | awk '{print $3}' | head -1 || true)
    else
        result=$(route -n 2>/dev/null | awk '/^0\.0\.0\.0/ {print $2}' | head -1 || true)
    fi
    echo "$result"
}

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

info "=== Connectivity Diagnostic Report ==="
info "Target: ${TARGET} (host: ${HOST})"
info "Date:   $(date)"
echo ""

# ===================================================================
# Section 1: Local Network Info
# ===================================================================

report_section "Local Network"

local_ip=$(get_local_ip)
if [[ -n "$local_ip" ]]; then
    count_pass "Local IP: ${local_ip}"
else
    count_warn "Could not detect local IP address"
fi

gateway=$(get_default_gateway)
if [[ -n "$gateway" ]]; then
    count_pass "Default gateway: ${gateway}"
else
    count_warn "Could not detect default gateway"
fi

# ===================================================================
# Section 2: DNS Resolution
# ===================================================================

report_section "DNS Resolution"

resolved_ip=$(dig +short "${HOST}" A 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
if [[ -n "$resolved_ip" ]]; then
    count_pass "DNS resolution for ${HOST}"
    echo "   Resolved to: ${resolved_ip}"
else
    count_fail "DNS resolution for ${HOST} (no A record returned)"
fi

# ===================================================================
# Section 3: ICMP Reachability
# ===================================================================

report_section "ICMP Reachability"

if ping_output=$(ping_host "$HOST" 3 2>&1); then
    count_pass "ICMP ping to ${HOST}"
    # Extract summary line (stats)
    stats_line=$(echo "$ping_output" | grep -E 'packets|received' | tail -1)
    [[ -n "$stats_line" ]] && echo "   ${stats_line}"
    rtt_line=$(echo "$ping_output" | grep -E 'rtt|round-trip' | tail -1)
    [[ -n "$rtt_line" ]] && echo "   ${rtt_line}"
else
    count_warn "ICMP ping to ${HOST} failed (host may block ICMP)"
fi

# ===================================================================
# Section 4: TCP Port Connectivity
# ===================================================================

report_section "TCP Port Connectivity"

port80_open=false
port443_open=false

if check_cmd nc; then
    if nc -z -w 3 "$HOST" 80 2>/dev/null; then
        count_pass "TCP port 80 (HTTP) open on ${HOST}"
        port80_open=true
    else
        count_warn "TCP port 80 (HTTP) closed or filtered on ${HOST}"
    fi

    if nc -z -w 3 "$HOST" 443 2>/dev/null; then
        count_pass "TCP port 443 (HTTPS) open on ${HOST}"
        port443_open=true
    else
        count_warn "TCP port 443 (HTTPS) closed or filtered on ${HOST}"
    fi
else
    # Fallback: use curl to test connectivity
    if curl -so /dev/null --connect-timeout 3 "http://${HOST}" 2>/dev/null; then
        count_pass "TCP port 80 (HTTP) reachable via curl"
        port80_open=true
    else
        count_warn "TCP port 80 (HTTP) not reachable"
    fi

    if curl -so /dev/null --connect-timeout 3 "https://${HOST}" 2>/dev/null; then
        count_pass "TCP port 443 (HTTPS) reachable via curl"
        port443_open=true
    else
        count_warn "TCP port 443 (HTTPS) not reachable"
    fi
fi

if [[ "$port80_open" == false && "$port443_open" == false ]]; then
    count_fail "Neither port 80 nor 443 is reachable on ${HOST}"
fi

# ===================================================================
# Section 5: HTTP/HTTPS Response
# ===================================================================

report_section "HTTP/HTTPS Response"

# HTTP check
http_code=$(curl -sI -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "http://${HOST}" 2>/dev/null || echo "000")
if [[ "$http_code" =~ ^[23] ]]; then
    count_pass "HTTP response from ${HOST}: ${http_code}"
elif [[ "$http_code" =~ ^[4] ]]; then
    count_warn "HTTP response from ${HOST}: ${http_code} (client error)"
elif [[ "$http_code" == "000" ]]; then
    count_warn "HTTP connection to ${HOST} failed (no response)"
else
    count_warn "HTTP response from ${HOST}: ${http_code}"
fi

# HTTPS check
https_code=$(curl -sI -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "https://${HOST}" 2>/dev/null || echo "000")
if [[ "$https_code" =~ ^[23] ]]; then
    count_pass "HTTPS response from ${HOST}: ${https_code}"
elif [[ "$https_code" =~ ^[4] ]]; then
    count_warn "HTTPS response from ${HOST}: ${https_code} (client error)"
elif [[ "$https_code" == "000" ]]; then
    count_warn "HTTPS connection to ${HOST} failed (no response)"
else
    count_warn "HTTPS response from ${HOST}: ${https_code}"
fi

# ===================================================================
# Section 6: TLS Certificate
# ===================================================================

report_section "TLS Certificate"

cert_info=$(curl -vI "https://${HOST}" 2>&1 || true)
expire_line=$(echo "$cert_info" | grep -i "expire date:" | head -1 | sed -E 's/.*expire date: //')

if [[ -n "$expire_line" ]]; then
    count_pass "TLS certificate found for ${HOST}"
    echo "   Expires: ${expire_line}"

    # Check expiry with openssl if available, otherwise report the date
    if check_cmd openssl; then
        expire_epoch=$(date -j -f "%b %d %T %Y %Z" "$expire_line" "+%s" 2>/dev/null || \
                       date -d "$expire_line" "+%s" 2>/dev/null || echo "")
        if [[ -n "$expire_epoch" ]]; then
            now_epoch=$(date "+%s")
            days_left=$(( (expire_epoch - now_epoch) / 86400 ))
            if [[ "$days_left" -lt 0 ]]; then
                count_fail "Certificate EXPIRED ${days_left#-} days ago"
            elif [[ "$days_left" -lt 30 ]]; then
                count_warn "Certificate expires in ${days_left} days"
            else
                count_pass "Certificate valid for ${days_left} days"
            fi
        fi
    fi
else
    # Fallback: if HTTPS curl succeeded, cert is likely valid
    if [[ "$https_code" =~ ^[23] ]]; then
        count_pass "TLS connection succeeded (certificate accepted by curl)"
    else
        count_fail "Could not verify TLS certificate for ${HOST}"
    fi
fi

# Check for certificate subject
subject_line=$(echo "$cert_info" | grep -i "subject:" | head -1 | sed -E 's/.*subject: //')
if [[ -n "$subject_line" ]]; then
    echo "   Subject: ${subject_line}"
fi

issuer_line=$(echo "$cert_info" | grep -i "issuer:" | head -1 | sed -E 's/.*issuer: //')
if [[ -n "$issuer_line" ]]; then
    echo "   Issuer: ${issuer_line}"
fi

# ===================================================================
# Section 7: Connection Timing
# ===================================================================

report_section "Connection Timing"

timing_output=$(curl -o /dev/null -s -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nFirst byte: %{time_starttransfer}s\nTotal: %{time_total}s\n" --connect-timeout 10 --max-time 15 "https://${HOST}" 2>/dev/null || echo "")

if [[ -n "$timing_output" ]]; then
    total_time=$(echo "$timing_output" | awk -F': ' '/^Total:/ {print $2}' | sed 's/s$//')
    count_pass "Connection timing for ${HOST}"
    echo "$timing_output" | sed 's/^/   /'

    # Warn if total time is high
    if [[ -n "$total_time" ]] && awk "BEGIN {exit !($total_time > 5.0)}" 2>/dev/null; then
        count_warn "Total connection time exceeds 5 seconds (${total_time}s)"
    fi
else
    count_warn "Could not measure connection timing for ${HOST}"
fi

# ===================================================================
# Section 8: Summary
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
