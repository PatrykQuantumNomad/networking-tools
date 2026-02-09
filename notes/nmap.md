# Nmap — Network Mapper

## What It Does

Nmap discovers hosts on a network and scans their ports to find running services. It answers: what's on this network, what ports are open, and what software is listening?

## Running the Examples Script

```bash
# Requires a target argument (IP or hostname)
bash scripts/nmap/examples.sh <target>

# Or via Makefile
make nmap TARGET=<target>

# Examples with lab targets
bash scripts/nmap/examples.sh localhost
bash scripts/nmap/examples.sh 192.168.1.1
```

The script prints 10 example commands with explanations, then offers to run a ping scan interactively.

## Key Flags to Remember

| Flag | What It Does |
|------|-------------|
| `-sn` | Ping scan only (no port scan) — just checks if host is up |
| `-F` | Fast scan — top 100 ports |
| `-sV` | Detect service versions on open ports |
| `-O` | OS detection (needs sudo) |
| `-A` | Aggressive — combines OS, version, scripts, traceroute (needs sudo) |
| `-p-` | Scan all 65535 TCP ports |
| `-sU` | UDP scan (needs sudo, slow) |
| `--script vuln` | Run NSE vulnerability detection scripts |
| `-sn <cidr>` | Scan an entire subnet, e.g. `192.168.1.0/24` |
| `-oA <name>` | Save output in all 3 formats (normal, XML, grepable) |

## Scan Progression (recommended order)

1. `nmap -sn <target>` — is it alive?
2. `nmap -F <target>` — what common ports are open?
3. `nmap -sV <target>` — what services/versions are running?
4. `sudo nmap -A <target>` — full aggressive scan
5. `nmap --script vuln <target>` — any known vulnerabilities?

## Practice Against Lab Targets

```bash
make lab-up
nmap -sV localhost -p 8080,3030,8888,8180
nmap -F localhost
```

## Identifying Unknown Ports

If your scan shows many ports as "unknown", you're missing the `-sV` flag. A SYN scan (`-sS`) only checks open/closed — it doesn't probe what service is running.

**Local machine (you own it):**
```bash
# What process is listening on port 8080?
lsof -i :8080 -P -n

# List ALL listening ports with process names
lsof -iTCP -P -n | grep LISTEN

# Helper script with more examples
bash scripts/nmap/identify-ports.sh
```

**Remote target (network probing):**
```bash
# Service version detection (the key missing flag)
nmap -sV <target>

# Probe specific ports
nmap -sV -p 8080,3030,8888 <target>

# Maximum effort version detection (slow)
nmap -sV --version-all <target>
```

**Why `-sS -O -p-` showed "unknown":**
`-sS` sends a SYN packet and checks if the port responds — that's it. It doesn't send HTTP requests, TLS handshakes, or any service-specific probes. Add `-sV` and nmap will actively fingerprint each open port.

## Notes

- Scans without sudo use TCP connect (`-sT`), which is slower and more visible
- Scans with sudo use raw SYN packets (`-sS`), which are faster and stealthier
- UDP scans (`-sU`) are very slow — use `--top-ports 20` to limit
- NSE scripts live in `/usr/share/nmap/scripts/` — browse them for specific checks
- XML output (`-oX`) can be imported into Metasploit with `db_import`
