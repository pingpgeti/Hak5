# 🐊 Hak5 Key Croc: Active HID Proxy & Command Center

> **Author:** Mateusz Turowski  
> **Organization:** PING Science Club | Gdańsk University of Technology  
> **Category:** Hardware Security / Penetration Testing

---
## 🚨 EDUCATIONAL & ACADEMIC USE ONLY 🚨
**ATTENTION GITHUB MODERATION:** This repository contains strictly educational materials, proof-of-concept scripts, and documentation created **exclusively for academic assessment** at the Gdańsk University of Technology.

These scripts do not contain destructive malware, ransomware, or actual malicious payloads. They are benign demonstrations (e.g., text expansion, local notepad alerts) designed to study hardware-based attack vectors (BadUSB/Dual-Role HID) and improve defensive mechanisms. **Any use of these tools outside of a controlled, authorized laboratory environment is strictly prohibited.**
---

## 📋 Executive Summary
This repository contains a comprehensive suite of tools developed for the **Hak5 Key Croc**, transforming a standard hardware data logger into an active, Dual-Role HID Man-in-the-Middle (MitM) device. The project bridges the gap between offensive security demonstrations (out-of-band exfiltration concepts) and developer productivity, all managed through a custom-built, interactive Linux terminal dashboard.

## 🚀 Key Features & Payloads

### 1. Croc Controller (Command & Control)
An interactive, menu-driven Bash dashboard accessible via SSH. It acts as the core management interface for the device, providing:
* **Live Reconnaissance:** Real-time keystroke monitoring and automated log parsing.
* **Data Extraction:** Custom Regex implementations for extracting specific strings (e.g., email addresses) from raw `.log` files.
* **Remote Administration:** Remote keyboard control, hardware-level screen locking (`Win+L`), and system reboot capabilities.

### 2. Security Awareness Alert (OOB Exfiltration Concept)
* **Trigger:** Passive pattern-matching for high-value keywords (e.g., `login`, `password`, `bank`).
* **Execution:** Demonstrates how local network restrictions (EDR/DLP) can be bypassed by utilizing the Key Croc's built-in Wi-Fi module for **Out-of-Band (OOB) exfiltration** via a Webhook API.
* **Feedback:** Injects a payload that opens Notepad with a security warning, demonstrating the "Evil Maid" attack vector directly to the end-user.

### 3. C++ Boilerplate (White-Hat Productivity)
* **Trigger:** Typing `!cpp`
* **Execution:** Hardware-level text expansion. Instantly injects a C++ boilerplate (headers, main function) to optimize developer workflow, demonstrating the legitimate, productivity-enhancing applications of HID injection.

## 📂 Repository Structure

```text
.
├── Scripts
│   ├── controller.sh                    # Interactive Bash management dashboard
│   ├── payload_cpp.txt                  # DuckyScript/MATCH payload for C++ boilerplate
│   └── payload_alert.txt                # MATCH payload for educational Discord exfiltration
└── Demonstration
    └── Presentation_ENG.pdf  # Slide deck (English version)
