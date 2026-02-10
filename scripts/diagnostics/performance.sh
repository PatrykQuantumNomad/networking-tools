#!/usr/bin/env bash
# diagnostics/performance.sh -- Latency diagnostic auto-report
# Traces the network path and identifies per-hop latency bottlenecks
# Pattern B: Diagnostic auto-report (non-interactive, no safety_banner)

source "$(dirname "$0")/../common.sh"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

show_help() {
    cat <<EOF
Usage: $(basename "$0") [target] [-h|--help]

Description:
  Runs a performance diagnostic for the given host.
  Traces the network path, measures per-hop latency (with mtr),
  and identifies bottlenecks or packet loss along the route.

  Default target: example.com

Examples:
    $(basename "$0")                 # Diagnose example.com
    $(basename "$0") 8.8.8.8        # Diagnose route to Google DNS
    $(basename "$0") cloudflare.com # Diagnose route to Cloudflare
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

# ---------------------------------------------------------------------------
# Requirements
# ---------------------------------------------------------------------------

require_cmd traceroute "apt install traceroute (Debian/Ubuntu) | dnf install traceroute (RHEL/Fedora) | Pre-installed on macOS"

TARGET="${1:-example.com}"
OS_TYPE="$(uname -s)"

# ---------------------------------------------------------------------------
# Detect mtr availability and usability
# ---------------------------------------------------------------------------

HAS_MTR=false
check_cmd mtr && HAS_MTR=true

MTR_USABLE=false
if [[ "$HAS_MTR" == true ]]; then
    if [[ "$OS_TYPE" == "Darwin" ]] && [[ $EUID -ne 0 ]]; then
        MTR_USABLE=false
    else
        MTR_USABLE=true
    fi
fi

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

info "=== Performance Diagnostic Report ==="
info "Target: ${TARGET}"
info "Date:   $(date)"
echo ""

# ===================================================================
# Section 1: Network Path
# ===================================================================

report_section "Network Path"

traceroute_output=$(_run_with_timeout 30 traceroute -n -q 1 -m 30 "$TARGET" 2>&1 || true)

if [[ -n "$traceroute_output" ]]; then
    # Count hops that returned a response (lines with an IP address, not just * * *)
    hop_count=$(echo "$traceroute_output" | grep -cE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true)

    if [[ "$hop_count" -gt 0 ]]; then
        count_pass "Route found: ${hop_count} responsive hops to ${TARGET}"
    else
        count_fail "No route to ${TARGET} (all hops timed out)"
    fi

    echo "$traceroute_output" | sed 's/^/   /'

    # Check for hops with all asterisks (no response)
    timeout_hops=$(echo "$traceroute_output" | grep -nE '^\s*[0-9]+\s+\*' || true)
    if [[ -n "$timeout_hops" ]]; then
        timeout_count=$(echo "$timeout_hops" | wc -l | tr -d ' ')
        count_warn "${timeout_count} hop(s) returned no response (filtered or timeout)"
    fi
else
    count_fail "Traceroute to ${TARGET} produced no output"
fi

# ===================================================================
# Section 2: Per-Hop Latency
# ===================================================================

report_section "Per-Hop Latency"

mtr_output=""

if [[ "$MTR_USABLE" == true ]]; then
    info "Running mtr (10 cycles, ~10 seconds)..."
    mtr_output=$(_run_with_timeout 60 mtr --report --report-wide -c 10 -n "$TARGET" 2>&1 || true)

    if [[ -n "$mtr_output" ]]; then
        echo "$mtr_output" | sed 's/^/   /'

        # Parse mtr report lines for issues
        # mtr report format: HOST: ... Loss% Snt Last Avg Best Wrst StDev
        has_issue=false

        while IFS= read -r line; do
            # Skip header lines
            [[ "$line" =~ ^HOST: ]] && continue
            [[ "$line" =~ ^Start: ]] && continue
            [[ -z "$line" ]] && continue

            # Extract hop number, loss%, and avg latency
            # Format: " N.|-- IP Loss% Snt Last Avg Best Wrst StDev"
            hop_num=$(echo "$line" | awk '{print $1}' | tr -d '.|' | tr -d '-')
            loss_pct=$(echo "$line" | awk '{print $3}' | tr -d '%')
            avg_latency=$(echo "$line" | awk '{print $6}')

            # Skip lines we cannot parse
            [[ -z "$hop_num" || -z "$loss_pct" || -z "$avg_latency" ]] && continue
            [[ "$loss_pct" == "Loss%" ]] && continue

            # Check for packet loss > 5%
            if [[ -n "$loss_pct" ]] && awk "BEGIN {exit !($loss_pct > 5.0)}" 2>/dev/null; then
                count_warn "Hop ${hop_num}: ${loss_pct}% packet loss"
                has_issue=true
            fi

            # Check for high latency > 100ms
            if [[ -n "$avg_latency" ]] && awk "BEGIN {exit !($avg_latency > 100.0)}" 2>/dev/null; then
                count_warn "Hop ${hop_num}: high latency (${avg_latency}ms avg)"
                has_issue=true
            fi
        done <<< "$mtr_output"

        if [[ "$has_issue" == false ]]; then
            count_pass "All hops within acceptable thresholds (<5% loss, <100ms avg)"
        fi
    else
        count_warn "mtr produced no output for ${TARGET}"
    fi
elif [[ "$HAS_MTR" == false ]]; then
    report_skip "mtr not installed (install: brew install mtr / apt install mtr)"
    info "Per-hop latency analysis requires mtr. Continuing with basic path analysis."
else
    # HAS_MTR is true but MTR_USABLE is false (macOS without sudo)
    count_warn "mtr requires sudo on macOS (raw socket access)"
    info "Run with: sudo $0 ${TARGET}"
    info "Skipping per-hop latency analysis"
fi

# ===================================================================
# Section 3: Latency Analysis
# ===================================================================

report_section "Latency Analysis"

if [[ -n "$mtr_output" ]]; then
    # Analyze mtr output for latency patterns
    # Extract avg latency per hop for spike detection
    prev_avg=0
    max_avg=0
    max_hop=""
    spike_detected=false
    spike_hop=""
    spike_increase=""

    while IFS= read -r line; do
        [[ "$line" =~ ^HOST: ]] && continue
        [[ "$line" =~ ^Start: ]] && continue
        [[ -z "$line" ]] && continue

        hop_num=$(echo "$line" | awk '{print $1}' | tr -d '.|' | tr -d '-')
        avg_latency=$(echo "$line" | awk '{print $6}')

        [[ -z "$hop_num" || -z "$avg_latency" ]] && continue
        [[ "$avg_latency" == "Avg" ]] && continue

        # Track highest latency hop
        if awk "BEGIN {exit !($avg_latency > $max_avg)}" 2>/dev/null; then
            max_avg="$avg_latency"
            max_hop="$hop_num"
        fi

        # Check for latency spike (>50ms jump between consecutive hops)
        if [[ "$prev_avg" != "0" ]] && awk "BEGIN {exit !(($avg_latency - $prev_avg) > 50.0)}" 2>/dev/null; then
            increase=$(awk "BEGIN {printf \"%.1f\", $avg_latency - $prev_avg}")
            spike_detected=true
            spike_hop="$hop_num"
            spike_increase="$increase"
        fi

        prev_avg="$avg_latency"
    done <<< "$mtr_output"

    if [[ -n "$max_hop" ]]; then
        info "Highest latency: hop ${max_hop} (${max_avg}ms avg)"
    fi

    if [[ "$spike_detected" == true ]]; then
        count_warn "Latency spike detected at hop ${spike_hop} (+${spike_increase}ms increase)"
    else
        count_pass "Latency is consistent across hops (no spikes >50ms)"
    fi
elif [[ -n "$traceroute_output" ]]; then
    # Parse traceroute output for basic timing analysis
    # traceroute lines typically look like: " N  IP  Xms" or " N  * * *"
    has_timing=false
    prev_time=0
    spike_detected=false

    while IFS= read -r line; do
        # Extract timing value (last numeric value ending in ms)
        # || true guards against pipefail when grep finds no match
        timing=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\s*ms' | head -1 | awk '{print $1}' || true)

        [[ -z "$timing" ]] && continue
        has_timing=true

        hop_num=$(echo "$line" | awk '{print $1}' | tr -d ' ')

        # Check for spike
        if [[ "$prev_time" != "0" ]] && awk "BEGIN {exit !(($timing - $prev_time) > 50.0)}" 2>/dev/null; then
            increase=$(awk "BEGIN {printf \"%.1f\", $timing - $prev_time}")
            count_warn "Latency spike at hop ${hop_num} (+${increase}ms from previous hop)"
            spike_detected=true
        fi

        prev_time="$timing"
    done <<< "$traceroute_output"

    if [[ "$has_timing" == true ]]; then
        if [[ "$spike_detected" == false ]]; then
            count_pass "No significant latency spikes detected in traceroute"
        fi
    else
        info "Limited analysis available without mtr (traceroute timing data minimal)"
    fi
else
    info "No path data available for latency analysis"
fi

# ===================================================================
# Section 4: Summary
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
