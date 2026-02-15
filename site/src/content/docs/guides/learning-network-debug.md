---
title: "Learning Path: Network Debugging"
description: "Step-by-step network debugging learning path using dig, traceroute, hping3, curl, and tshark. Diagnose DNS, routing, firewall, and TLS issues."
sidebar:
  order: 12
---

Network debugging is a systematic process of narrowing down where a connection fails. You start at the DNS layer, work through connectivity and routing, test firewall behavior, inspect HTTP exchanges, and finally capture raw packets for deep analysis. This path follows that top-down approach, giving you a structured methodology for diagnosing any network issue.

**Who this is for:** Sysadmins, developers debugging connectivity problems, and anyone learning network troubleshooting.

**Prerequisites:**
- Run `make check` and install at least dig, curl, and traceroute
- No lab required for most steps (these tools work against any network target)

---

## Step 1: DNS Diagnostics (dig)

DNS is the first thing to check because most connectivity problems that look like "the server is down" are actually DNS failures. A misconfigured resolver, an expired record, or a propagation delay can make a perfectly healthy server unreachable. Start here to rule out name resolution before investigating deeper.

**Tool:** [dig](/tools/dig/) | **Diagnostic:** [DNS Diagnostic](/diagnostics/dns/)

**Practice:**

```bash
make diagnose-dns TARGET=example.com
```

**What you will learn:** How to check A, AAAA, MX, NS, SOA, and TXT records, verify propagation across resolvers, and test reverse lookups. The structured report flags missing or misconfigured records with pass/fail/warn indicators.

**Expected outcome:** A complete DNS health report showing which record types resolve correctly and which need attention. If DNS is healthy, move to the next layer.

---

## Step 2: Connectivity Check

Once DNS resolves correctly, verify that you can actually reach the target. The connectivity diagnostic walks through each network layer -- DNS resolution, ICMP reachability, TCP port connectivity, HTTP response, and TLS handshake. This pinpoints exactly which layer fails.

**Diagnostic:** [Connectivity Diagnostic](/diagnostics/connectivity/)

**Practice:**

```bash
make diagnose-connectivity TARGET=example.com
```

**What you will learn:** Layer-by-layer connectivity testing using dig, ping, netcat, and curl. Each layer depends on the previous one, so failures cascade predictably -- if TCP fails, HTTP will too.

**Expected outcome:** A structured report showing pass/fail for each network layer. If everything passes, the issue is application-level. If TCP fails but ICMP works, suspect a firewall.

---

## Step 3: Route Tracing (traceroute / mtr)

When connectivity fails at the network layer, route tracing shows where packets are being dropped or delayed. Traceroute reveals each hop between you and the target, while mtr adds continuous monitoring with per-hop statistics. This identifies routing problems, congested links, and ISP-level issues.

**Tool:** [traceroute](/tools/traceroute/) | **Diagnostic:** [Performance Diagnostic](/diagnostics/performance/)

**Practice:**

```bash
make trace-path TARGET=example.com
```

For a full performance diagnostic with latency analysis:

```bash
make diagnose-performance TARGET=example.com
```

**What you will learn:** How to read traceroute output, identify packet loss at specific hops, compare ICMP/TCP/UDP routes, and use mtr for continuous latency monitoring.

**Expected outcome:** A hop-by-hop path to the target showing round-trip times at each router. Sudden latency spikes or packet loss at a specific hop indicate where the problem is.

---

## Step 4: Firewall Testing (hping3)

If route tracing shows the path is clear but certain ports are unreachable, the target may have a firewall dropping or rejecting traffic. Hping3 sends crafted packets -- SYN, ACK, FIN, and Xmas probes -- to test how the target responds to different TCP flags. This reveals firewall rules without needing access to the firewall configuration.

**Tool:** [hping3](/tools/hping3/)

**Practice:**

```bash
make test-firewall TARGET=localhost
```

To detect whether a firewall exists:

```bash
make detect-firewall TARGET=localhost
```

**What you will learn:** How firewalls treat different packet types, the difference between DROP and REJECT policies, and how to identify filtered ports versus closed ports.

**Expected outcome:** Against the lab (no firewall), all probes get responses. Against a real firewall, you will see selective responses revealing which ports are allowed, blocked, or filtered.

---

## Step 5: HTTP Debugging (curl)

When the network path is clear and ports are open, HTTP-level issues require inspecting the actual request-response exchange. Curl lets you see headers, follow redirects, test authentication, and measure timing for each phase of the connection (DNS lookup, TCP connect, TLS handshake, first byte, total transfer).

**Tool:** [curl](/tools/curl/)

**Practice:**

```bash
bash scripts/curl/debug-http-response.sh https://example.com
```

**What you will learn:** How to inspect response headers, follow redirect chains, test with specific HTTP methods, send custom headers, and measure connection timing breakdowns.

**Expected outcome:** A detailed view of the HTTP exchange showing status codes, headers, redirect behavior, and timing for each connection phase. Slow TLS handshakes, unexpected redirects, and missing headers become immediately visible.

---

## Step 6: Packet Capture (tshark)

When higher-level tools do not reveal the issue, packet capture gives you the raw truth. Tshark captures every packet on the wire, letting you see exactly what is being sent and received. This is the last resort for debugging -- it is the most powerful tool but also the most complex to interpret.

**Tool:** [tshark](/tools/tshark/)

**Practice:**

```bash
make capture-creds
```

This captures HTTP traffic on the loopback interface, showing request/response details including any credentials sent in plaintext.

**What you will learn:** Live packet capture, display filters (HTTP, DNS, TCP), and how to identify retransmissions, resets, and other TCP anomalies that cause connection failures.

**Expected outcome:** A stream of captured packets showing the actual network conversation. Compare what you see in the capture against what curl reports to identify discrepancies between expected and actual behavior.

---

## Next Steps

You now have a complete network debugging toolkit, from DNS through packet capture. For an offensive perspective on the same tools, try the [Reconnaissance](/guides/learning-recon/) learning path to see how these debugging techniques apply to security assessments.
