# README: Shark Jack Cable - Network Reconnaissance

## Overview

This payload transforms the **Hak5 Shark Jack Cable (SJC)** into an automated
network reconnaissance platform. Upon physical connection to a target network
via RJ45, the script autonomously performs:

1. **Network Configuration Detection** (IP, Gateway, Subnet)
2. **Host Discovery** (Alive hosts on the subnet)
3. **Deep Port Scanning** (Services and versions per host)
4. **Gateway Audit** (Detailed scan of the router/gateway)
5. **Aggressive OS Fingerprinting** (Operating system detection)
6. **Passive Traffic Analysis** (MDNS, ARP, HTTP broadcast capture)

All results are saved to a **scan_results** and **audit_results** in `/root/loot/` for later
retrieval via SSH or SCP.

> **DISCLAIMER:** This project was created strictly for **educational and research purposes** in a **controlled, isolated lab environment.** The techniques demonstrated here should **never** be used against systems you do not own or have explicit written permission to test. Unauthorized use of these tools is illegal and unethical.

---

## Hardware Requirements

| Component | Specification |
|---|---|
| Device | Hak5 Shark Jack Cable |
| Firmware | OpenWrt 18.06-SNAPSHOT (Hak5 v1.1.0) |
| Architecture | MIPSEL_24KC (MediaTek MT76x8) |
| Connection | RJ45 Ethernet (Primary) |
| Power | USB-C (Host-powered) |
| Management | SSH over LAN or Serial Console |

---

## Software Requirements

### Pre-installed on SJC Firmware:
- `nmap` (v7.70) - Network scanner
- `tcpdump` (v4.9.2) - Packet capture
- `bash` - Script interpreter
- `openssh` - SSH server

### Repository Note ( Important ):

Unfortunatly, during my testing of Shark Jack, it turned out that the version it was refering to during updates and in general no longer are there, or have been moved. I had to check through system files and try to find different, suitable packages to make it possible to run some of the mechanics. I wasn't able to perform my original idea of ARP spoofing, as the tool I need ( and dsniff package ) were not added in this version. There is also issue with certificates being expired by now. Down below I left few steps how to overcome some of the errors.

The default Hak5 package repository
(`http://downloads.hak5.org/packages/shark/1907/`) is **no longer active**.
The OpenWrt 18.06-SNAPSHOT repositories have also been deprecated.

To restore package management functionality, update
`/etc/opkg/distfeeds.conf` with the following archive links:

```text
src/gz openwrt_base http://archive.openwrt.org/releases/18.06.9/packages/mipsel_24kc/base
src/gz openwrt_luci http://archive.openwrt.org/releases/18.06.9/packages/mipsel_24kc/luci
src/gz openwrt_packages http://archive.openwrt.org/releases/18.06.9/packages/mipsel_24kc/packages
src/gz openwrt_routing http://archive.openwrt.org/releases/18.06.9/packages/mipsel_24kc/routing
src/gz openwrt_telephony http://archive.openwrt.org/releases/18.06.9/packages/mipsel_24kc/telephony
```

Also disable signature checking in `/etc/opkg.conf`:
```text
# option check_signature
```

Then run:
```bash
opkg update
```

---

## How it works ( Must read )

The main purpose of this payload is to perform network recon using the Router's LAN port. Once the Shark Jack is connected with its RJ45 end it will start the attack ( in attack mode of course ). Shark Jack is like a mini linux computer, that runs bash scrips hiding from scanning and detection as a Network device. There are a lot of technical information ( from my experience ) about the SJC, but it mostly comes to management and execution. In case of this particular script, SJC changes its NETMODE ( its how the Shark Jack behaves, if its acting as a DHCP server or DHCP client ) to DHCP_CLIENT to not only get itself an IP address, but hide itself, avoiding confilt on the network. Once everything is ready, the rest of the scripts executes with no issues. I used tools like nmap and tcpdump, that are pre-installed on Shark and as said above, due to the issues with repositories I couldn't add packages and tools I wanted to test out as well. Its not a complicated script, but it shows the mechanic and powerfull side of SJC as mutliple usage type tool, that is fast, silent and can attack not only networks, but the devices directly too.

---

## File Structure

```
/root/
├── payload/
│   └── payload.sh              ← Main script
│
└── loot/
    └── scan_results/   ← Scan session folder
        │
        ├── SUMMARY.txt         
        ├── network_info.txt    ← SJC network configuration
        ├── alive_hosts.txt
        │── deep_scan.txt
        │── gateway_scan.txt
        ├── mdns_devices.txt    ← MDNS device identities
        ├── arp_traffic.txt     ← ARP communications map
        └── http_traffic.txt    ← Unencrypted HTTP traffic
    └── audit_results/  ← OS and service fingerprinting
        └── detailed_audit_192.168.X.X.txt
```

---

## File Documentation

```bash
#!/bin/bash

# TITLE: Network Recon and Aggressive Scanning
# AUTHOR: Szymon Stefański ( KN PING GDAŃSK )
# DESCRIPTION: This script performs a network scan to discover alive hosts
# and runs aggressive scans on the first discovered host. It also captures
# some passive network intelligence
# VERSION: 2.0

LOOT_DIR_SCAN="/root/loot/scan_results"
LOOT_DIR_AUDIT="/root/loot/audit_results"
SCAN_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p $LOOT_DIR_SCAN
mkdir -p $LOOT_DIR_AUDIT

# >>>>> SETUP <<<<<

# Setting up client mode for stealth and Internet access

LED SETUP
SERIAL_WRITE "[*] Configuring network..." # SERIAL_WRITE is used to send messages to the serial console
NETMODE DHCP_CLIENT
sleep 10

# Gathering network information and Shark Jack's IP address

IP=""
TIMEOUT=0
while [ -z "$IP" ]; do
    IP=$(ifconfig eth0 | grep 'inet' | awk -F: '{print $2}' | awk '{print $1}')
    # we check interface eth0 for the assigned IP address
    # then using grep we select IPv4 line
    # awk is used to extract the IP address from the output
    sleep 2
    TIMEOUT=$((TIMEOUT + 2))
    if [ $TIMEOUT -ge 30 ]; then
        SERIAL_WRITE "[!] Failed to obtain IP address."
        LED FAIL
        exit 1
    fi
done

GATEWAY=$(route -n | grep 'UG' | awk '{print $2}')
SUBNET=$(echo $IP | awk -F. '{print $1"."$2"."$3".0/24"}')
# We set the subnet based on the Shark Jack's IP, asuming a /24 network

# Save network info to network_info.txt

echo "============================================" > $LOOT_DIR_SCAN/network_info.txt
echo "Shark Jack Network Report" >> $LOOT_DIR_SCAN/network_info.txt
echo "Scan Time: $SCAN_TIME" >> $LOOT_DIR_SCAN/network_info.txt
echo "============================================" >> $LOOT_DIR_SCAN/network_info.txt
echo "SJC IP: $IP" >> $LOOT_DIR_SCAN/network_info.txt
echo "Gateway: $GATEWAY" >> $LOOT_DIR_SCAN/network_info.txt
echo "Subnet: $SUBNET" >> $LOOT_DIR_SCAN/network_info.txt
echo "============================================" >> $LOOT_DIR_SCAN/network_info.txt

SERIAL_WRITE "[*] IP: $IP"
SERIAL_WRITE "[*] Gateway: $GATEWAY"
SERIAL_WRITE "[*] Subnet: $SUBNET"

# >>>>> HOST DISCOVERY AND DEEP SCANNING <<<<<

# Host discovery and deep scanning

LED ATTACK
SERIAL_WRITE "[*] Discovering alive hosts..."
nmap -sn $SUBNET -oG $LOOT_DIR_SCAN/alive_hosts.txt

# Count alive hosts ( we exclude the gateway and the Shark Jack itself using grep -v )

HOST_COUNT=$(grep "Up" $LOOT_DIR_SCAN/alive_hosts.txt | grep -v "$GATEWAY" | grep -v "$IP" | wc -l)
ALIVE_HOSTS=$(grep "Up" $LOOT_DIR_SCAN/alive_hosts.txt | grep -v "$GATEWAY" | grep -v "$IP" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

if [ -z "$ALIVE_HOSTS" ]; then
    SERIAL_WRITE "[!] No targets found on the network."
    LED FAIL
    exit 1
fi

SERIAL_WRITE "[*] Deep port scanning all alive hosts..."
nmap -sV -O -T4 --top-ports 100 $SUBNET -oN $LOOT_DIR_SCAN/deep_scan.txt
sleep 5
nmap -sV -A $GATEWAY -oN $LOOT_DIR_SCAN/gateway_scan.txt

# >>>>> AGGRESSIVE SCANNING <<<<<

# We take the first alive host, better for testing reason
# For production / real use it is recommended to implement logic to select the most interesting target
# based on open ports and services or any other criteria.
# For example based on deep_scan.txt and gateway_scan we could select hosts with specfic services
# and / or ports open.

TARGET_IP=$(echo "$ALIVE_HOSTS" | head -n 1)
SERIAL_WRITE "[*] Aggressive scan on $TARGET_IP..."

# Aggressive scan with OS detection, version detection, script scanning and traceroute
# Limiting to top 20 ports, for speed and storage reasons on Shark Jack

nmap -sV -O -A --osscan-guess --top-ports 20 $TARGET_IP -oN $LOOT_DIR_AUDIT/detailed_audit_$TARGET_IP.txt

# >>>>> TRAFFIC CAPTURE <<<<<

# Passive traffic capture for network intelligence

SERIAL_WRITE "[*] Capturing broadcast traffic (60s)..."

# Capture MDNS (device names and services)

tcpdump -i eth0 -vv -t udp port 5353 -c 100 > $LOOT_DIR_SCAN/mdns_devices.txt 2>&1 &

# Capture ARP traffic (who is talking to whom)

tcpdump -i eth0 -n arp -c 100 > $LOOT_DIR_SCAN/arp_traffic.txt 2>&1 &

# Capture any unencrypted HTTP traffic

tcpdump -i eth0 -A -l -c 100 'tcp port 80' > $LOOT_DIR_SCAN/http_traffic.txt 2>&1 &

sleep 60

# >>>>> CLEANUP AND FINAL REPORT <<<<<

# Clean up and final report
SERIAL_WRITE "[*] Generating final report..."
LED CLEANUP

killall tcpdump 2>/dev/null
killall nmap 2>/dev/null

# Generate summary report
echo "============================================" > $LOOT_DIR_SCAN/SUMMARY.txt
echo "SCAN SUMMARY" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "============================================" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "Date: $SCAN_TIME" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "SJC IP: $IP" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "Gateway: $GATEWAY" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "Subnet: $SUBNET" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "Hosts Found: $HOST_COUNT" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "Primary Target: $TARGET_IP" >> $LOOT_DIR_SCAN/SUMMARY.txt
echo "============================================" >> $LOOT_DIR_SCAN/SUMMARY.txt

SERIAL_WRITE "[*] Scan complete. Results saved to $LOOT_DIR_SCAN and $LOOT_DIR_AUDIT"
SERIAL_WRITE "[*] Files generated:"
SERIAL_WRITE "    - network_info.txt"
SERIAL_WRITE "    - alive_hosts.txt"
SERIAL_WRITE "    - deep_scan.txt"
SERIAL_WRITE "    - gateway_scan.txt"
SERIAL_WRITE "    - detailed_audit_*.txt"
SERIAL_WRITE "    - mdns_devices.txt"
SERIAL_WRITE "    - arp_traffic.txt"
SERIAL_WRITE "    - http_traffic.txt"
SERIAL_WRITE "    - SUMMARY.txt"

LED FINISH
```

**Short Explanation**  
This payload can be divided into few sections: **Setup, Deep scanning, Aggressive scanning, Traffic capture and Clean up**.  
During setup SJC changes its netmode to **DHCP_CLIENT**, meaning that for now on it will act as a guest and receive its own IP address. Based on that, Shark extracts information about the gateway and subnet to gather information for nmap usage. During Deep scanning, nmap scans for alive hosts on network, later on using that data to scan them ( names, open ports, IP addresses, MAC addresses etc. ).   
Then comes Aggressive scanning, which in this case, for testing and because of the packages issues, scans the first target it found, checking it ports, OS system and more ( at first it was supposed to be arp spoofing mechanic with MITM type of performance, but packages were not very cooparative ).   
At last there is traffic scanning, which does 3 things: Checks the MDNS devices, performs arp checks between devices on eth0 interface and checks for HTTP traffic, if there are any.  
After all is done as saved to .txt files, there is a clean up section, where I kill active processes and generate summary files.

---

## Setup Instructions

### Step 1: Physical Setup
1. Set the switch on the Shark Jack Cable to **Arming Mode**
   ( switch to the middle ).
2. Connect the **USB-C** end to a power source
   ( laptop, phone charger, or powered USB hub ).
3. Connect the **RJ45** end to your target network router or switch.
4. Wait for the **LED to breathe green** ( device has booted successfully ).

### Step 2: Management Connection
Since USB-C networking (RNDIS) may be unreliable on Windows/Linux,
the recommended management method is **SSH over RJ45**.
>Note that serial console is most usable for debugging!

#### Find the SJC IP Address:
**Serial Console**  
You can connect to serial console, using Serial Android App
or apps like MobaXterm on windows  

Once connected via serial, type:
```bash
ifconfig
```
Look for the `inet addr:` value. That is your SJC IP.

#### Connect via SSH:
```bash
ssh root@<SJC_IP>
# Default password: hak5shark
```

### Step 3: Upload the Payload
From your laptop, copy the script to the Shark Jack:
```bash
# Linux/Mac/Windows (PowerShell with OpenSSH)
scp payload.sh root@<SJC_IP>:/root/payload/payload.sh
```

### Step 4: Fix the System Clock (Optional)
The Shark Jack has no RTC battery. It defaults to 2021 on every boot.
Fix the clock before running the payload to ensure correct timestamps:
```bash
# Manual fix
date -s "YYYY-MM-DD HH:MM:SS"

# Automatic NTP sync (requires internet access via router)
ntpd -n -q -p pool.ntp.org
```

---

## Running the Payload

### Automatic Execution (Attack Mode)
1. Insert the RJ45 end to the target ( in this case the Router )
2. Flip the switch to **Attack Mode**
   (switch away from the USB-C connector).
3. The script will execute automatically.
4. Wait for `LED FINISH` before unplugging and Serial message stating that scan is completed.

---

## Retrieving Loot

After the script completes:

### Option A: SCP (Command Line)
```bash
# Download entire loot folder to your laptop
scp -r root@<SJC_IP>:/root/loot/ ./sjc_loot/
```

### Option B: SFTP (FileZilla / WinSCP)
```
Protocol:  SFTP
Host:      <SJC_IP>
Port:      22
Username:  root
Password:  hak5shark
```
Navigate to `/root/loot/` and download the timestamped folder.

### Option C: Python Web Server (Quick Preview)
On the Shark Jack (via SSH):
```bash
cd /root/loot/
python3 -m http.server 8080
```
On your laptop browser: `http://<SJC_IP>:8080`
Click and download any file directly.

---

## Overview of Files Structure

### `SUMMARY.txt`
High-level overview of the scan session:
```
============================================
SCAN SUMMARY
============================================
Date: 20240521_143022
SJC IP: 192.168.1.X
Gateway: 192.168.1.X
Subnet: 192.168.1.0/24
Hosts Found: X
Primary Target: 192.168.1.X
============================================
```

### `alive_hosts.txt`
Nmap grepable format showing all discovered hosts:
```
Host: 192.168.1.X ()    Status: Up
Host: 192.168.1.X ()    Status: Up
```

### `gateway_scan.txt`
Detailed audit of the router/gateway:
```
PORT     STATE  SERVICE VERSION
53/tcp   open   domain  dnsmasq 2.80
80/tcp   open   http    lighttpd 1.4.53
443/tcp  open   https   lighttpd 1.4.53
```

### `detailed_audit_<IP>.txt`
Aggressive OS fingerprinting results:
```
Device type: general purpose
Running: Linux 4.X
OS CPE: cpe:/o:linux:linux_kernel:4
OS details: Linux 4.4 - 4.9
```

### `mdns_devices.txt`
MDNS broadcast captures revealing device identities:
```
_googlecast._tcp.local  → Chromecast Ultra
_http._tcp.local        → Printer Model XYZ
_apple-mobdev._tcp.local → iPhone
```

### `arp_traffic.txt`
ARP request/reply map:
```
192.168.1.5  > 192.168.1.1  who-has
192.168.1.1  > 192.168.1.5  is-at XX:XX:XX:XX:XX:XX
```

---

## Known Limitations

Read the `Penetration testing research report (Shark)` file to learn more about the enviroment, technical issues and more.

---

## References

1. Hak5. (2021). *Shark Jack Cable Documentation*.
   https://docs.hak5.org/shark-jack/

2. Lyon, G. (2024). *Nmap Reference Guide*.
   https://nmap.org/book/man.html

3. OpenWrt Project. (2024). *OpenWrt Archive*.
   https://archive.openwrt.org/

4. MITRE Corporation. (2024). *T1046: Network Service Scanning*.
   https://attack.mitre.org/techniques/T1046/

5. MITRE Corporation. (2024). *T1557: Man-in-the-Middle* ( ARP spoofing case ).
   https://attack.mitre.org/techniques/T1557/

6. Microsoft. (2023). *Remote NDIS (RNDIS) Design Guide*.
   https://learn.microsoft.com/en-us/windows-hardware/drivers/network/remote-ndis--rndis-

7. Silicon Labs. (2024). *CP210x USB to UART Bridge VCP Drivers*.
   https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers

8. Internet Engineering Task Force. (1997). *RFC 2131: DHCP*.
   https://datatracker.ietf.org/doc/html/rfc2131

9. Internet Engineering Task Force. (1982). *RFC 826: ARP*.
   https://datatracker.ietf.org/doc/html/rfc826

---

## Author

**Szymon Stefański**