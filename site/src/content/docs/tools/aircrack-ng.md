---
title: "Aircrack-ng — WiFi Security Auditing Suite"
description: Aircrack-ng is a complete suite for WiFi security auditing including tools for monitoring, attacking, and cracking
sidebar:
  order: 13
---

## What It Does

Aircrack-ng is a complete suite for WiFi security auditing. It includes tools for monitoring (airodump-ng), attacking (aireplay-ng), and cracking (aircrack-ng). Used to test WPA/WPA2 password strength by capturing the 4-way handshake and running offline dictionary attacks. It answers: how secure is this wireless network?

## macOS Compatibility

The Homebrew package (`brew install aircrack-ng`) only includes a subset of the full suite. Monitor mode tools are **Linux-only**.

| Tool | What It Does | macOS | Linux |
|------|-------------|-------|-------|
| `aircrack-ng` | Crack WPA/WPA2 handshakes | **Yes** | Yes |
| `aircrack-ng -S` | Benchmark cracking speed | **Yes** | Yes |
| `aircrack-ng -J` | Convert .cap to hashcat format | **Yes** | Yes |
| `airdecap-ng` | Decrypt WEP/WPA captures | **Yes** | Yes |
| `airolib-ng` | Precompute PMK databases | **Yes** | Yes |
| `wpaclean` | Clean capture files | **Yes** | Yes |
| `airmon-ng` | Enable/disable monitor mode | No | Yes |
| `airodump-ng` | Scan networks, capture handshakes | No | Yes |
| `aireplay-ng` | Inject packets, send deauths | No | Yes |

**On macOS you can**: crack .cap files, benchmark, convert captures, precompute PMKs.
**On macOS you cannot**: scan for networks, capture handshakes, or inject packets. Use a Linux VM (Kali) with a USB WiFi adapter for these.

## Running the Examples Script

```bash
# No target argument required -- WiFi tools work with local interfaces
bash scripts/aircrack-ng/examples.sh

# Or via Makefile
make aircrack-ng

# Examples
bash scripts/aircrack-ng/examples.sh
```

The script prints 10 example commands covering the full WiFi auditing workflow from monitor mode to handshake cracking.

## Wordlist Setup

Aircrack-ng needs a wordlist for WPA/WPA2 dictionary attacks. Download rockyou.txt (~14M passwords, ~140MB):

```bash
make wordlists
# or: bash wordlists/download.sh
```

This places `rockyou.txt` in the project's `wordlists/` directory. The use-case scripts reference it automatically via `$WORDLIST`.

## Key Flags to Remember

| Flag / Command | What It Does | macOS |
| ------ | ------------- | ----- |
| `airmon-ng` | List wireless interfaces and manage monitor mode | Linux only |
| `airmon-ng start <iface>` | Enable monitor mode on an interface | Linux only |
| `airmon-ng stop <iface>mon` | Disable monitor mode | Linux only |
| `airodump-ng <iface>mon` | Scan for nearby wireless networks | Linux only |
| `airodump-ng --bssid <mac> -c <ch> -w <file>` | Capture traffic from a specific network | Linux only |
| `airodump-ng --band abg` | Scan both 2.4GHz and 5GHz bands | Linux only |
| `airodump-ng --encrypt wpa2` | Show only WPA2 networks | Linux only |
| `aireplay-ng --deauth <n> -a <AP>` | Send N deauthentication frames | Linux only |
| `aireplay-ng -c <client>` | Target a specific client for deauth | Linux only |
| `aircrack-ng -w <wordlist> <cap>` | Crack WPA handshake with a dictionary | **Yes** |
| `aircrack-ng -b <bssid> <cap>` | Target a specific network in a capture file | **Yes** |
| `aircrack-ng -J <file> <cap>` | Convert capture to hashcat format | **Yes** |
| `aircrack-ng -l <file>` | Save cracked key to file | **Yes** |
| `aircrack-ng -S` | Benchmark cracking speed | **Yes** |

## WiFi Auditing Workflow (recommended order)

Steps 1-6 require Linux. Steps 7-8 work on macOS.

1. `airmon-ng` -- check available wireless interfaces (Linux only)
2. `sudo airmon-ng start wlan0` -- enable monitor mode (Linux only)
3. `sudo airodump-ng wlan0mon` -- scan for networks (Linux only)
4. `sudo airodump-ng --bssid <AP> -c <ch> -w capture wlan0mon` -- target a network (Linux only)
5. `sudo aireplay-ng --deauth 5 -a <AP> wlan0mon` -- force handshake capture (Linux only)
6. Wait for "WPA handshake" message in airodump-ng output (Linux only)
7. `aircrack-ng -w wordlist.txt capture-01.cap` -- crack the password offline (**works on macOS**)
8. `sudo airmon-ng stop wlan0mon` -- restore normal wireless mode (Linux only)

## Use-Case Scripts

### capture-handshake.sh -- Capture WPA/WPA2 4-way handshake from wireless network (Linux only)

Shows the complete workflow from enabling monitor mode to capturing a WPA/WPA2 4-way handshake for offline cracking. Covers both passive capture (waiting for a client to naturally connect -- slow but stealthy) and active capture (sending deauthentication frames to force reconnection -- fast but detectable). Includes converting captures for hashcat GPU cracking.

**When to use:** First step in testing WPA/WPA2 password strength. You need the handshake before you can crack. Requires a wireless adapter that supports monitor mode and physical proximity to the target network.

**macOS**: This script shows the commands but cannot run them. On macOS it offers a benchmark demo instead.

**Key commands:**

```bash
# Start monitor mode
sudo airmon-ng start wlan0

# Scan for networks (all channels)
sudo airodump-ng wlan0mon

# Target a specific network by BSSID and channel
sudo airodump-ng --bssid AA:BB:CC:DD:EE:FF -c 6 -w capture wlan0mon

# Send deauth to force client reconnection (5 frames)
sudo aireplay-ng --deauth 5 -a AA:BB:CC:DD:EE:FF wlan0mon

# Targeted deauth to a specific client
sudo aireplay-ng --deauth 5 -a AA:BB:CC:DD:EE:FF -c 11:22:33:44:55:66 wlan0mon

# Verify handshake was captured
aircrack-ng capture-01.cap

# Stop monitor mode when done
sudo airmon-ng stop wlan0mon
```

**Make target:** `make capture-handshake`

---

### crack-wpa-handshake.sh -- Crack captured WPA handshake with dictionary attack (works on macOS)

Cracks a captured WPA/WPA2 handshake using dictionary attacks. WPA cracking is entirely offline -- you do not need network access after capturing the handshake. Supports aircrack-ng (CPU, ~5,000 keys/sec), hashcat conversion (GPU, ~500,000+ keys/sec), piping from password generators, and John the Ripper.

**When to use:** After capturing a 4-way handshake with airodump-ng (or using a sample .cap file). For serious cracking, convert to hashcat format and use GPU acceleration.

**macOS**: Fully functional. You need a .cap file with a captured handshake (capture on Linux, or use a sample file for practice).

**Key commands:**

```bash
# Basic dictionary attack with rockyou
aircrack-ng -w wordlists/rockyou.txt capture.cap

# Specify target BSSID (when multiple networks in capture)
aircrack-ng -w rockyou.txt -b AA:BB:CC:DD:EE:FF capture.cap

# Use multiple wordlists
aircrack-ng -w wordlist1.txt,wordlist2.txt capture.cap

# Save cracked key to file
aircrack-ng -w rockyou.txt -l cracked_key.txt capture.cap

# Pipe from password generator (crunch)
crunch 8 8 abcdefghijklmnop | aircrack-ng -w - capture.cap

# Convert to hashcat format for GPU cracking
aircrack-ng capture.cap -J handshake_hccapx

# Benchmark cracking speed
aircrack-ng -S
```

**Make target:** `make crack-wpa TARGET=<cap-file>`

---

### analyze-wireless-networks.sh -- Survey and analyze nearby wireless networks (Linux only)

Surveys and analyzes nearby wireless networks in monitor mode. Shows encryption types (WEP, WPA, WPA2, WPA3), signal strength, connected clients, hidden SSIDs, and channel usage. Passive monitoring sends no packets and is completely undetectable. Supports filtering by encryption, band, ESSID, and exporting to CSV or Kismet format.

**When to use:** First step in any wireless engagement. Map all nearby networks before targeting a specific one. Also useful for identifying rogue access points, weak encryption (WEP), and channel congestion.

**macOS**: This script shows the commands but cannot run them. On macOS it shows your WiFi hardware info via `system_profiler` instead.

**Key commands:**

```bash
# Enable monitor mode
sudo airmon-ng start wlan0

# Basic network survey -- all channels
sudo airodump-ng wlan0mon

# Survey all bands (2.4GHz + 5GHz)
sudo airodump-ng --band abg wlan0mon

# Show only WPA2 networks
sudo airodump-ng --encrypt wpa2 wlan0mon

# Save survey to CSV for analysis
sudo airodump-ng -w survey --output-format csv wlan0mon

# Channel hop on specific channels only (common 2.4GHz)
sudo airodump-ng -c 1,6,11 wlan0mon

# Show connected clients for a specific network
sudo airodump-ng --bssid AA:BB:CC:DD:EE:FF wlan0mon
```

**Make target:** `make analyze-wifi`

## Practice Against Lab Targets

```bash
# Aircrack-ng requires a wireless adapter in monitor mode, so Docker lab
# targets are not directly applicable. Practice with these alternatives:

# Benchmark your CPU cracking speed
aircrack-ng -S

# Test cracking with a sample capture file and wordlist
aircrack-ng -w wordlists/rockyou.txt sample-handshake.cap

# Show details about a captured handshake file
aircrack-ng capture-01.cap

# Convert a capture for hashcat GPU cracking
aircrack-ng capture-01.cap -J handshake_hccapx

# For hands-on practice with live wireless:
#   - Use a Linux VM (Kali recommended) with a USB WiFi adapter
#   - Set up a test access point you own with a known password
#   - Capture the handshake and crack it with your own wordlist
```

## Notes

- On macOS, only cracking/benchmarking/converting works -- scanning, capturing, and injecting require Linux
- For full WiFi testing, use a Linux VM (Kali) with a compatible USB WiFi adapter
- Monitor mode captures ALL nearby wireless traffic passively -- no packets are sent during scanning
- Deauthentication (`aireplay-ng --deauth`) is active and detectable -- use sparingly and only on networks you own
- WPA cracking speed depends entirely on hardware: CPU is ~5,000 keys/sec, GPU with hashcat is ~500,000+ keys/sec
- The rockyou.txt wordlist is the standard starting point -- it contains ~14 million common passwords
- Convert captures to hashcat format (`-J` flag or `hcxpcapngtool`) for GPU-accelerated cracking
- Always stop monitor mode when done (`airmon-ng stop`) to restore normal wireless functionality
- WPA3 uses SAE (Simultaneous Authentication of Equals) and is resistant to offline dictionary attacks
- Use `crunch` to generate custom wordlists if standard dictionary attacks fail
