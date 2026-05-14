# Hak5 Packet Squirrel MK1 – MITM Attack Scripts & Presentation

## EDUCATIONAL & ACADEMIC USE ONLY

> This repository contains strictly educational materials, proof-of-concept scripts, and documentation created **exclusively for academic assessment**. These scripts demonstrate network attack vectors (Man-in-the-Middle, packet sniffing, DNS spoofing, traffic blocking, reverse SSH tunnels, reconnaissance) using the **Hak5 Packet Squirrel MK1** hardware platform. They are intended **solely for authorized security testing, academic study, and defensive research**. Any use of these tools outside of a controlled, authorized laboratory environment is strictly prohibited. The author does not condone illegal activity.

---

## Motivation

I decided to choose this project because I felt that computer networks were my weak point. While I am comfortable with software development and embedded systems, network infrastructure, routing, and low-level traffic manipulation always seemed somewhat abstract to me. I wanted to step out of my comfort zone and expand my knowledge in this area. Using the Hak5 Packet Squirrel MK1 provided the perfect hands-on opportunity to bridge the gap between theoretical network concepts and practical, real-world security applications.

---

## What I Learned

Working on this project provided me with a deep, practical understanding of network protocols and security vulnerabilities. Key takeaways include:

* **Low-Level Traffic Analysis:** I learned how to passively intercept and analyze raw network packets using `tcpdump` and Wireshark, gaining insight into how data is transmitted in plain text across unencrypted protocols.
* **Traffic Manipulation with iptables:** I gained hands-on experience writing routing rules and configuring `iptables` to actively manipulate traffic. This included selective packet dropping (sending TCP RST packets) and redirecting traffic to a rogue local server for DNS spoofing.
* **Working with Hardware Constraints:** The limited resources of the Packet Squirrel (64 MB RAM, 400 MHz CPU) taught me how to optimize payloads. I learned firsthand that heavy cryptographic protocols like OpenVPN can overwhelm small devices, making lightweight alternatives like Reverse SSH Tunnels much more effective for remote implants.
* **The Importance of Defense-in-Depth:** Successfully executing Man-in-the-Middle attacks highlighted exactly why modern security standards are critical. I now clearly understand the practical impact of HSTS for enforcing encryption, DoH (DNS over HTTPS) for preventing spoofing, and 802.1X for port-level physical security.

---

## Overview

The **Packet Squirrel MK1** is a pocket-sized MITM device by Hak5. It sits physically inline between a target and the network — all traffic flows through it. This project provides a collection of attack payloads and a presentation demonstrating various offensive and defensive techniques.

All scripts are designed to run on the **Packet Squirrel MK1** (OpenWrt-based, Atheros AR9331 @ 400 MHz, 64 MB RAM).

---

## Repository Structure

```text
.
├── README.md                              # This file
├── Scripts
│   ├── 01_packet_sniffing/                # Passive traffic capture → PCAP
│   ├── 02_killport/                       # Active traffic blocking (TCP RST)
│   ├── 03_dns_spoofing/                   # DNS spoofing + phishing server
│   ├── 04_nmap_autoscan/                  # Automated network scanning → Discord
│   └── 05_tunnel_ssh/                     # Reverse SSH tunnel (remote implant)
└── Demonstration
    └── Packet_Squirrel.pdf                # Presentation slides (Polish)
```

---

## Attack Scenarios

| # | Name | Type | NETMODE | Description |
|---|------|------|---------|-------------|
| 1 | **Packet Sniffing** | Passive | TRANSPARENT | Captures all traffic to PCAP on USB |
| 2 | **Traffic Blocking** | Active DoS | NAT | iptables REJECT with TCP RST |
| 3 | **DNS Spoofing** | Active MITM | NAT | iptables REDIRECT + dnsmasq + phishing |
| 4 | **Nmap Autoscan** | Recon | udhcpc | Auto-scan network → Discord webhook |
| 5 | **Reverse SSH Tunnel** | Implant | BRIDGE | SSH -R tunnel to VPS for remote access |

---

## Key Security Lessons

- **HTTPS** encrypts content — but does not protect against DNS spoofing
- **DoH/DoT** encrypts DNS queries — prevents DNS spoofing
- **VPN** encrypts everything including DNS
- **HSTS** forces HTTPS for preloaded domains (facebook.com, google.com)
- **802.1X** on network switches prevents physical device injection
- MK1 vs MK2: MK1 lacks SPOOFDNS, DYNAMICPROXY, KILLPORT, Web UI, and Wi-Fi — but has NETMODE, LED, BUTTON, and all necessary tools for MITM attacks

---

## Usage

1. Place PS in **ARMING mode** (switch position 4)
2. SSH to `172.16.32.1` (password: `hak5squirrel`)
3. Upload the desired payload to `/root/payloads/switchN/payload.sh`
4. Set switch to the corresponding position
5. Connect IN → target, OUT → router, power on
6. Observe LED: SETUP → ATTACK → SUCCESS/FAIL

---

## Disclaimer

These materials are provided for **educational and authorized security testing purposes only**. Unauthorized use of these techniques against systems you do not own or have explicit permission to test is illegal. The author and the Gdańsk University of Technology assume no liability for misuse.

---

## References
[Hak5 Packet Squirrel Documentation](https://docs.hak5.org/packet-squirrel/packet-squirrel-mark-by-hak5/)

---

*Author: Karol Kwiatek*  
*Project focuses on Packet Squirrel Mark I (MK1).*
