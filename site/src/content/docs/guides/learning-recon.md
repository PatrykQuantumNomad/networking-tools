---
title: "Learning Path: Reconnaissance"
description: "Step-by-step network reconnaissance learning path using dig, nmap, tshark, and metasploit. From DNS enumeration to service exploitation."
sidebar:
  order: 10
---

Reconnaissance is the first phase of any security assessment. Before testing for vulnerabilities, you need to know what exists on the network -- which hosts are alive, what ports are open, what services are running, and what versions they expose. This path walks you through that process in a logical order, from passive DNS lookups to active service enumeration.

**Who this is for:** Beginners learning penetration testing methodology.

**Prerequisites:**
- Run `make check` and install at least nmap and dig
- Start the lab with `make lab-up` (see [Getting Started](/guides/getting-started/))

---

## Step 1: DNS Reconnaissance (dig)

DNS is the natural starting point because it is passive and non-intrusive. Before sending any packets to a target, you can learn about its infrastructure by querying public DNS records. This reveals hostnames, mail servers, name servers, and sometimes internal network details through misconfigured zone transfers.

**Tool:** [dig](/tools/dig/)

**Practice:**

```bash
make diagnose-dns TARGET=example.com
```

**What you will learn:** How to query A, AAAA, MX, NS, TXT, and SOA records. The diagnostic report shows which record types exist and flags missing or misconfigured entries.

**Expected outcome:** A structured DNS report showing the target's IP addresses, mail servers, and name servers. This gives you concrete IPs to scan in the next step.

---

## Step 2: Host Discovery (nmap)

With IP addresses from DNS, the next step is confirming which hosts are actually alive on the network. Host discovery uses a combination of ARP, ICMP, and TCP probes to find responsive systems without doing a full port scan. This is faster and less noisy than scanning every port on every address.

**Tool:** [nmap](/tools/nmap/)

**Practice:**

```bash
make discover-hosts TARGET=localhost
```

**What you will learn:** Multiple discovery techniques -- ARP scan for local networks, ICMP echo for routed networks, and TCP SYN probes for hosts that block ICMP.

**Expected outcome:** A list of live hosts. Against the lab, you will confirm that the Docker containers are reachable.

---

## Step 3: Port Scanning and Service Detection (nmap)

Once you know which hosts are alive, you need to know what services they expose. Port scanning identifies open TCP and UDP ports, and service detection fingerprints the software listening on each port. This is where you transition from "what exists" to "what is running."

**Tool:** [nmap](/tools/nmap/)

**Practice:**

```bash
make identify-ports TARGET=localhost
```

**What you will learn:** SYN scan, version detection (`-sV`), OS fingerprinting (`-O`), and script scanning (`-sC`). The script demonstrates 10 progressively deeper scanning techniques.

**Expected outcome:** You should see ports 8080 (DVWA), 3030 (Juice Shop), 8888 (WebGoat), and 8180 (VulnerableApp) with HTTP service versions identified.

---

## Step 4: Traffic Analysis (tshark)

Running a packet capture during reconnaissance reveals information that port scans miss. You can see DNS queries your tools make (revealing which domains they resolve), observe the full TCP handshake timing, and capture banner data that nmap might not report. Starting a capture early means you have a complete record of all network activity.

**Tool:** [tshark](/tools/tshark/)

**Practice:**

```bash
make analyze-dns
```

Leave this running in a background terminal while you work through other steps. Review the captured queries afterward.

**What you will learn:** Live packet capture, display filters for DNS traffic, and how to interpret query/response patterns.

**Expected outcome:** A stream of DNS queries and responses showing which domains are being resolved on your network. This is especially revealing when combined with active scanning.

---

## Step 5: Service Enumeration (metasploit)

After discovering hosts, ports, and services, you can use Metasploit's auxiliary scanners for deeper enumeration. These scanners go beyond version strings to test for specific behaviors -- default credentials, known misconfigurations, and information disclosure. This bridges the gap between reconnaissance and exploitation.

**Tool:** [metasploit](/tools/metasploit/)

**Practice:**

```bash
make scan-services TARGET=localhost
```

**What you will learn:** How to use Metasploit auxiliary modules for HTTP version detection, banner grabbing, and service fingerprinting without launching exploits.

**Expected outcome:** Detailed service information for the lab targets, including HTTP server headers and application frameworks. This data drives your next decisions about which vulnerabilities to test.

---

## Next Steps

You now know how to map a network from DNS through service enumeration. Continue with the [Web App Testing](/guides/learning-webapp/) learning path to start finding and exploiting vulnerabilities in the web applications you discovered.
