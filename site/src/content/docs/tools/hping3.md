---
title: "hping3 — Packet Crafting and Network Probing"
description: hping3 crafts and sends custom TCP, UDP, and ICMP packets to probe network hosts
sidebar:
  order: 3
---

## What It Does

hping3 crafts and sends custom TCP, UDP, and ICMP packets to probe network hosts. Unlike nmap which automates scanning, hping3 gives you direct control over every packet field -- flags, TTL, source port, payload size. It answers: how does this host or firewall respond to specific packet types?

## Running the Examples Script

```bash
# Requires a target argument (IP or hostname)
bash scripts/hping3/examples.sh <target>

# Or via Makefile
make hping3 TARGET=<target>

# Examples with lab targets
bash scripts/hping3/examples.sh localhost
bash scripts/hping3/examples.sh 192.168.1.1
```

The script prints 10 example commands with explanations, then offers to run a quick SYN probe interactively. Most hping3 commands require root/sudo.

## Key Flags to Remember

| Flag | What It Does |
| ------ | ------------- |
| `-S` | Set SYN flag (connection initiation) |
| `-A` | Set ACK flag (firewall testing) |
| `-F` | Set FIN flag (stealth scanning) |
| `-P` | Set PUSH flag |
| `-U` | Set URG flag |
| `-1` | ICMP mode (like ping) |
| `-2` | UDP mode |
| `-p <port>` | Destination port |
| `-s <port>` | Source port |
| `-c <count>` | Number of packets to send |
| `-t <ttl>` | Set custom TTL value |
| `-d <size>` | Set packet data size in bytes |
| `-T` | Traceroute mode (increment TTL) |
| `--scan <range>` | Scan a range of ports (e.g., 1-1024) |
| `-a <ip>` | Spoof source IP address |
| `-p ++1` | Increment port with each packet |

## TCP Flag Response Interpretation

| Sent | Response | Meaning |
| ------ | ------------- | ------------- |
| SYN | SYN-ACK (flags=SA) | Port is open (service listening) |
| SYN | RST (flags=RA) | Port is closed (reachable, no service) |
| SYN | (nothing) | Port is filtered (firewall dropping) |
| ACK | RST | Unfiltered (stateless firewall or no firewall) |
| ACK | (nothing) | Filtered (stateful firewall blocking) |
| FIN | (nothing) | Open or filtered |
| FIN | RST | Closed |
| any | ICMP unreachable | Administratively filtered |

## Use-Case Scripts

### test-firewall-rules.sh -- Test firewall behavior with crafted TCP flag combinations

Tests firewall behavior by sending packets with specific TCP flag combinations and comparing responses. Covers SYN, ACK, FIN, Xmas (FIN+PUSH+URG), and NULL scans. Also demonstrates source port spoofing to appear as DNS traffic, decoy source IPs, and incremental port scanning.

**When to use:** When you need to understand what a firewall allows through. Compare responses across different flag types to determine whether filtering is stateful or stateless, and which ports are open, closed, or filtered.

**Key commands:**

```bash
# SYN scan -- test if port is open
sudo hping3 -S -p 80 -c 3 <target>

# ACK scan -- detect stateful firewall
sudo hping3 -A -p 80 -c 3 <target>

# FIN scan -- bypass simple packet filters
sudo hping3 -F -p 80 -c 3 <target>

# Xmas scan -- FIN+PUSH+URG flags
sudo hping3 -F -P -U -p 80 -c 3 <target>

# NULL scan -- no flags set
sudo hping3 -p 80 -c 3 <target>

# SYN scan with specific source port (appear as DNS traffic)
sudo hping3 -S -p 80 -s 53 -c 3 <target>

# Compare SYN vs ACK responses to map firewall
sudo hping3 -S -p 80 -c 1 <target> && sudo hping3 -A -p 80 -c 1 <target>
```

**Make target:** `make test-firewall TARGET=<ip>`

---

### detect-firewall.sh -- Detect firewall presence and identify filtering behavior

Detects firewall presence by comparing SYN, ACK, and FIN responses on the same port. Identifies whether filtering is stateful or stateless based on response patterns. Also tests UDP and ICMP filtering and uses traceroute to locate the firewall hop.

**When to use:** Early in an engagement to understand the network's filtering posture. Run the 3-probe test (SYN + ACK + FIN) on a known port and compare the results.

**Interpretation guide:**
- ACK gets RST but FIN gets no reply -> Stateful firewall
- Both ACK and FIN get RST -> No firewall or stateless filter
- Both get no reply -> Strict filtering (all dropped)

**Key commands:**

```bash
# SYN probe -- establish baseline response
sudo hping3 -S -p 80 -c 1 <target>

# ACK probe -- detect stateful filtering
sudo hping3 -A -p 80 -c 1 <target>

# FIN probe -- detect deep packet inspection
sudo hping3 -F -p 80 -c 1 <target>

# UDP probe -- test UDP filtering
sudo hping3 --udp -p 53 -c 1 <target>

# ICMP probe -- test ICMP filtering
sudo hping3 --icmp -c 1 <target>

# Traceroute to find the firewall hop
sudo hping3 -S -p 80 -T <target>

# Full firewall detection workflow (SYN + ACK + FIN on port 80)
sudo hping3 -S -p 80 -c 1 <target>; sudo hping3 -A -p 80 -c 1 <target>; sudo hping3 -F -p 80 -c 1 <target>
```

**Make target:** `make detect-firewall TARGET=<ip>`

## Practice Against Lab Targets

```bash
make lab-up

# SYN probe against DVWA port
sudo hping3 -S -p 8080 -c 3 localhost

# ACK probe to check for stateful filtering
sudo hping3 -A -p 8080 -c 3 localhost

# Compare responses on open vs closed port
sudo hping3 -S -p 8080 -c 1 localhost    # open (DVWA)
sudo hping3 -S -p 61234 -c 1 localhost   # likely closed

# Scan all lab ports
sudo hping3 -S --scan 3000,8080,8180,8888 localhost

# TCP traceroute to a lab target
sudo hping3 -S -p 8080 -T --ttl 1 localhost
```

## Notes

- Almost all hping3 commands require root/sudo for raw socket access
- Unlike nmap, hping3 gives you packet-level control -- you choose every flag
- The `flags=SA` in output means SYN-ACK (port open), `flags=RA` means RST-ACK (port closed)
- No response usually means a firewall is silently dropping your packet
- Use `-c 1` for single-packet probes during manual testing to keep traffic minimal
- The `--scan` flag provides nmap-like port scanning but with hping3's customization
- hping3 can also be used for latency measurement -- look at `rtt` values in SYN probe output
- Xmas scan (`-F -P -U`) sets FIN+PUSH+URG -- used to probe firewalls that only filter SYN
- Source port spoofing (`-s 53`) makes traffic look like DNS replies, which some firewalls allow
- TCP traceroute (`-S -p 80 -T`) is more reliable through firewalls than ICMP traceroute
- Combine hping3 with tcpdump or tshark to capture and analyze the full packet exchange
