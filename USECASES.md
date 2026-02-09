# Use-Case Quick Reference

Find the right script by what you're trying to do. All commands support `--help`.

## Recon & Discovery

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Find live hosts on a subnet | `make discover-hosts TARGET=192.168.1.0/24` | nmap |
| Identify what's running on open ports | `make identify-ports TARGET=<ip>` | nmap |
| Survey nearby WiFi networks | `make analyze-wifi TARGET=<interface>` | aircrack-ng |
| Monitor DNS queries on the network | `make analyze-dns` | tshark |
| Enumerate services with Metasploit | `make scan-services TARGET=<ip>` | metasploit |

## Web Application Testing

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Scan a web server for vulnerabilities | `make scan-web-vulns TARGET=<ip>` | nmap |
| Quick web app scan (time-limited) | `make quick-scan TARGET=<url>` | skipfish |
| Scan specific vuln types (SQLi, XSS) | `make scan-vulns TARGET=<url>` | nikto |
| Scan with authentication (cookies/creds) | `make scan-auth TARGET=<url>` | nikto |
| Authenticated web app scan | `make scan-auth-app TARGET=<url>` | skipfish |
| Scan multiple hosts at once | `make scan-hosts TARGET=<hostfile>` | nikto |

## SQL Injection

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Test parameters for SQL injection | `make test-params TARGET=<url>` | sqlmap |
| Dump a database via SQLi | `make dump-db TARGET=<url>` | sqlmap |
| Bypass WAF/IDS with tamper scripts | `make bypass-waf TARGET=<url>` | sqlmap |

## Password Cracking

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Crack Windows NTLM hashes (GPU) | `make crack-ntlm TARGET=<hashfile>` | hashcat |
| Crack web app hashes (MD5/SHA/bcrypt) | `make crack-web-hashes TARGET=<hashfile>` | hashcat |
| Benchmark GPU cracking speed | `make benchmark-gpu` | hashcat |
| Crack Linux /etc/shadow passwords | `make crack-linux-pw` | john |
| Crack password-protected archives | `make crack-archive TARGET=<file>` | john |
| Identify an unknown hash type | `make identify-hash TARGET=<hash>` | john |

## WiFi Security

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Capture a WPA handshake | `make capture-handshake TARGET=<interface>` | aircrack-ng |
| Crack a captured WPA handshake | `make crack-wpa TARGET=<capfile>` | aircrack-ng |
| Survey wireless networks | `make analyze-wifi TARGET=<interface>` | aircrack-ng |

## Network & Traffic Analysis

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Capture HTTP credentials from traffic | `make capture-creds` | tshark |
| Extract files from a packet capture | `make extract-files TARGET=<pcap>` | tshark |
| Test firewall rules with crafted packets | `make test-firewall TARGET=<ip>` | hping3 |
| Detect firewall presence | `make detect-firewall TARGET=<ip>` | hping3 |

## Exploitation

| I want to... | Command | Tool |
| -------------- | --------- | ------ |
| Generate a reverse shell payload | `make gen-payload TARGET=<lhost>` | metasploit |
| Set up a reverse shell listener | `make setup-listener` | metasploit |

## Running Scripts Directly

Every script also works standalone:

```bash
bash scripts/<tool>/<script>.sh [target] [--help]
```

## Typical Engagement Flow

```
1. Discovery     make discover-hosts TARGET=192.168.1.0/24
2. Port scan     make identify-ports TARGET=<ip>
3. Web scan      make scan-web-vulns TARGET=<ip>
                 make scan-vulns TARGET=<url>
4. SQLi test     make test-params TARGET=<url>
5. Crack hashes  make crack-web-hashes TARGET=<hashfile>
6. Report        Check notes/ for detailed documentation
```

## Detailed Notes

See `notes/<tool>.md` for key flags, example progressions, and tips for each tool.
