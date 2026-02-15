---
title: "Learning Path: Web App Testing"
description: "Step-by-step web app security testing path using nmap, nikto, skipfish, sqlmap, and hash crackers. From discovery to exploitation against Docker targets."
sidebar:
  order: 11
---

Web application testing follows reconnaissance. Once you know which hosts run web services, you systematically probe those applications for vulnerabilities -- from broad automated scans down to targeted exploitation and credential extraction. This path takes you through that workflow against the Docker lab targets.

**Who this is for:** Beginners who have completed the [Reconnaissance](/guides/learning-recon/) path or already know how to identify web services on a network.

**Prerequisites:**
- Lab running with `make lab-up`
- DVWA initialized (browse to http://localhost:8080, log in as admin/password, go to setup.php, click Create/Reset Database)
- Recommended: Complete the [Reconnaissance](/guides/learning-recon/) path first

---

## Step 1: Find Web Ports (nmap)

Before testing web applications, confirm which ports serve HTTP. Nmap's NSE scripts specifically target web vulnerabilities -- default credentials, directory listings, known CVEs, and dangerous HTTP methods. This is a focused scan that builds on the broader port scan from the recon phase.

**Tool:** [nmap](/tools/nmap/)

**Practice:**

```bash
make scan-web-vulns TARGET=localhost
```

**What you will learn:** Nmap NSE web vulnerability scripts, including `http-enum`, `http-default-accounts`, and `http-sql-injection`. These scripts provide a quick initial assessment before dedicated web scanners.

**Expected outcome:** A list of web-specific findings across ports 8080, 3030, 8888, and 8180 -- interesting directories, server headers, and potential misconfigurations.

---

## Step 2: Vulnerability Scanning (nikto)

Nikto performs a comprehensive check against a web server, testing thousands of known issues including outdated software, dangerous files, and misconfigured headers. It is louder than nmap NSE scripts but catches issues that nmap does not test for. Run it against each web target separately to get detailed results.

**Tool:** [nikto](/tools/nikto/)

**Practice:**

```bash
make scan-vulns TARGET=http://localhost:8080
```

**What you will learn:** How nikto identifies server software versions, checks for known vulnerabilities, and reports missing security headers. Compare DVWA results against Juice Shop (`TARGET=http://localhost:3030`) to see how findings differ between PHP and Node.js applications.

**Expected outcome:** A report listing SQL injection indicators, XSS opportunities, server misconfigurations, and software versions with known vulnerabilities on DVWA.

---

## Step 3: Application Crawling (skipfish)

Skipfish takes a different approach from nikto -- it actively crawls the application, discovering pages and parameters dynamically rather than checking a static list of known issues. This finds application-specific vulnerabilities that signature-based scanners miss. The quick scan mode limits runtime so it does not run indefinitely.

**Tool:** [skipfish](/tools/skipfish/)

**Practice:**

```bash
make quick-scan TARGET=http://localhost:3030
```

**What you will learn:** How automated crawling discovers application structure, hidden parameters, and input handling issues. Skipfish generates an HTML report you can browse afterward.

**Expected outcome:** A crawl of Juice Shop revealing its page structure, API endpoints, and potential injection points. Review the generated report for findings ranked by severity.

---

## Step 4: SQL Injection Testing (sqlmap)

The previous scanners flag potential SQL injection points. Sqlmap confirms and exploits them. It automates the entire injection process -- detection, fingerprinting the database, enumerating tables, and extracting data. Against DVWA's SQL Injection page (set to Low security), sqlmap will extract the full users table including password hashes.

**Tool:** [sqlmap](/tools/sqlmap/)

**Practice:**

First, get your DVWA session cookie:
1. Log in to DVWA at http://localhost:8080 (admin / password)
2. Set Security Level to **Low** (DVWA Security menu)
3. Navigate to the SQL Injection page
4. Open browser DevTools (F12) > Application > Cookies
5. Copy the `PHPSESSID` value

Then run:

```bash
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=<your-session-id>;security=low" \
  --batch --dbs
```

For educational examples of all dump techniques:

```bash
make dump-db TARGET="http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit"
```

**What you will learn:** How sqlmap identifies injection types (UNION, boolean-blind, time-blind), enumerates databases and tables, and dumps data. Save the extracted password hashes for the next step.

**Expected outcome:** The DVWA `users` table extracted, containing usernames and MD5 password hashes.

---

## Step 5: Crack Extracted Hashes (hashcat / john)

The final step closes the loop -- turning extracted hashes into plaintext passwords. Hashcat uses GPU acceleration for fast cracking, while John the Ripper offers flexible format support and rule-based attacks. DVWA's default passwords are simple MD5 hashes that crack in seconds with a dictionary attack.

**Tools:** [hashcat](/tools/hashcat/) and [john](/tools/john/)

**Practice:**

Save the hashes from Step 4 to a file:

```bash
echo "5f4dcc3b5aa765d61d8327deb882cf99" > /tmp/dvwa-hashes.txt
```

Then crack with hashcat (MD5 = mode 0):

```bash
make crack-web-hashes TARGET=/tmp/dvwa-hashes.txt
```

Or identify the hash type and crack with john:

```bash
make identify-hash TARGET="5f4dcc3b5aa765d61d8327deb882cf99"
```

**What you will learn:** Hash identification, dictionary attacks with rockyou.txt, and the difference between GPU-accelerated cracking (hashcat) and CPU-based cracking (john).

**Expected outcome:** Plaintext passwords recovered from the DVWA user hashes. In a real engagement, these credentials enable lateral movement and privilege escalation.

---

## Next Steps

You have gone from discovering web services to extracting and cracking credentials. Continue with the [Network Debugging](/guides/learning-network-debug/) learning path to learn how to diagnose connectivity issues and debug network behavior at the packet level.
