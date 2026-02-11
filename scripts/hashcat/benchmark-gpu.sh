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
    echo "  $(basename "$0") --help # Show this help message"
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help && exit 0

require_cmd hashcat "brew install hashcat"

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
info "1) Benchmark all supported hash types"
echo "   hashcat -b"
echo ""

# 2. Benchmark NTLM only
info "2) Benchmark NTLM only (mode 1000)"
echo "   hashcat -b -m 1000"
echo ""

# 3. Benchmark MD5
info "3) Benchmark MD5 (mode 0)"
echo "   hashcat -b -m 0"
echo ""

# 4. Benchmark SHA-256
info "4) Benchmark SHA-256 (mode 1400)"
echo "   hashcat -b -m 1400"
echo ""

# 5. Benchmark bcrypt (slow hash)
info "5) Benchmark bcrypt (mode 3200) — intentionally slow"
echo "   hashcat -b -m 3200"
echo ""

# 6. Benchmark WPA/WPA2
info "6) Benchmark WPA/WPA2 (mode 22000)"
echo "   hashcat -b -m 22000"
echo ""

# 7. List available compute devices
info "7) List available compute devices (GPUs, CPUs)"
echo "   hashcat -I"
echo ""

# 8. Benchmark with specific device
info "8) Benchmark with a specific device"
echo "   hashcat -b -d 1"
echo ""

# 9. Benchmark with workload tuning
info "9) Benchmark with maximum workload profile"
echo "   hashcat -b -w 3"
echo ""

# 10. Time-limited cracking run
info "10) Run a time-limited cracking session (60 seconds)"
echo "    hashcat -m 1000 --runtime=60 hashes.txt wordlist.txt"
echo ""

# Interactive demo (skip if non-interactive)
[[ ! -t 0 ]] && exit 0

read -rp "Run a quick benchmark for MD5 and NTLM? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Running: hashcat -b -m 0 -m 1000"
    echo ""
    hashcat -b -m 0 -m 1000 2>/dev/null || warn "Benchmark failed — check GPU/driver support"
fi
