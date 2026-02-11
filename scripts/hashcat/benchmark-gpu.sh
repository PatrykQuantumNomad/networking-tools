#!/usr/bin/env bash
# hashcat/benchmark-gpu.sh — Benchmark GPU cracking performance and estimate crack times
source "$(dirname "$0")/../common.sh"

show_help() {
    echo "Usage: $(basename "$0") [-h|--help]"
    echo ""
    echo "Description:"
    echo "  Benchmarks GPU hash cracking performance using hashcat. Shows hashes"
    echo "  per second (H/s) for various hash types and helps estimate how long"
    echo "  it would take to crack different password keyspaces."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")        # Show benchmark commands"
    echo "  $(basename "$0") -x     # Run benchmarks interactively"
    echo "  $(basename "$0") --help # Show this help message"
}

parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+${REMAINING_ARGS[@]}}"

require_cmd hashcat "brew install hashcat"

confirm_execute
safety_banner

info "=== GPU Cracking Benchmark ==="
echo ""

info "Why benchmark your GPU?"
echo "   Hash cracking speed is measured in H/s (hashes per second)."
echo "   GPU cracking is orders of magnitude faster than CPU:"
echo "   - CPU: ~100 million MD5/s    vs  GPU: ~50 billion MD5/s"
echo "   - CPU: ~10 million NTLM/s    vs  GPU: ~40 billion NTLM/s"
echo "   - CPU: ~10,000 bcrypt/s      vs  GPU: ~100,000 bcrypt/s"
echo ""
echo "   Knowing your H/s lets you estimate crack time:"
echo "   Time = Keyspace / Speed"
echo "   Example: 8-char lowercase = 26^8 = 208 billion combinations"
echo "   At 40 billion NTLM/s = ~5 seconds to exhaust keyspace."
echo ""

# 1. Benchmark all hash types
run_or_show "1) Benchmark all supported hash types" \
    hashcat -b

# 2. Benchmark NTLM only
run_or_show "2) Benchmark NTLM only (mode 1000)" \
    hashcat -b -m 1000

# 3. Benchmark MD5
run_or_show "3) Benchmark MD5 (mode 0)" \
    hashcat -b -m 0

# 4. Benchmark SHA-256
run_or_show "4) Benchmark SHA-256 (mode 1400)" \
    hashcat -b -m 1400

# 5. Benchmark bcrypt (slow hash)
run_or_show "5) Benchmark bcrypt (mode 3200) — intentionally slow" \
    hashcat -b -m 3200

# 6. Benchmark WPA/WPA2
run_or_show "6) Benchmark WPA/WPA2 (mode 22000)" \
    hashcat -b -m 22000

# 7. List available compute devices
run_or_show "7) List available compute devices (GPUs, CPUs)" \
    hashcat -I

# 8. Benchmark with specific device
run_or_show "8) Benchmark with a specific device" \
    hashcat -b -d 1

# 9. Benchmark with workload tuning
run_or_show "9) Benchmark with maximum workload profile" \
    hashcat -b -w 3

# 10. Time-limited cracking run
info "10) Run a time-limited cracking session (60 seconds)"
echo "    hashcat -m 1000 --runtime=60 hashes.txt wordlist.txt"
echo ""

# Interactive demo (skip if non-interactive)
if [[ "${EXECUTE_MODE:-show}" == "show" ]]; then
    [[ ! -t 0 ]] && exit 0

    read -rp "Run a quick benchmark for MD5 and NTLM? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Running: hashcat -b -m 0 -m 1000"
        echo ""
        hashcat -b -m 0 -m 1000 2>/dev/null || warn "Benchmark failed — check GPU/driver support"
    fi
fi
