# Disable Windows Defender and Windows Update on Windows 11

## Introduction

**Disable_Defender_WindowsUpdate.ps1** is a powerful PowerShell script designed to completely and thoroughly disable Windows Defender (Microsoft Defender Antivirus) and Windows Update services on Windows 11. This script is ideal for advanced users, system administrators, and power users who want to stop automatic updates and security features that are difficult to turn off through standard Windows settings.

> **Disclaimer:** Disabling Windows Defender and Windows Update exposes your system to security risks and may affect system stability. Use this script at your own risk and only if you understand the consequences.

## Features
- Disables Windows Defender real-time protection and related features
- Disables Tamper Protection via the Windows Registry
- Stops and disables Windows Defender and related services (WinDefend, WdNisSvc, etc.)
- Stops and disables Windows Update and auxiliary services (wuauserv, UsoSvc, WaaSMedicSvc, BITS, sedsvc, etc.)
- Disables scheduled tasks that can re-enable updates or Defender
- Sets Group Policy registry keys to block automatic updates
- Blocks Windows Update servers via the hosts file and firewall rules
- Disables Defender periodic scanning
- Provides clear warnings and prompts for user awareness

## Important Warnings
- **Security Risk:** Your PC will be vulnerable to malware and security threats.
- **Persistence:** Major Windows feature updates may re-enable some services. No script can guarantee 100% permanent disablement on Windows 11.
- **Re-enabling:** You must manually re-enable these services if you want to restore updates or Defender protection.

## How to Use

1. **Open PowerShell as Administrator**
   - Search for "PowerShell" in the Start Menu.
   - Right-click and select **Run as Administrator**.

2. **Allow Script Execution**
   - In the PowerShell window, run:
     ```powershell
     Set-ExecutionPolicy Bypass -Scope Process -Force
     ```

3. **Navigate to the Script Location**
   - Use `cd` to change to the folder where you saved the script. For example:
     ```powershell
     cd "C:\Users\YourUsername\Downloads"
     ```

4. **Run the Script**
   - Execute the script by running:
     ```powershell
     .\Disable_Defender_WindowsUpdate.ps1
     ```
   - The script will request administrator rights if not already elevated.
   - Follow the on-screen messages and warnings.
   - Press ENTER when prompted to close the window.

5. **Reboot Your System**
   - For all changes to take effect, manually reboot your computer after running the script.

## How to Re-enable Windows Defender and Windows Update
To restore Windows Defender and Windows Update, you will need to manually re-enable the services, scheduled tasks, and undo the registry and firewall changes. This process is not automated by this script. Consider searching for a dedicated re-enablement script or manually reversing the changes.

## SEO Keywords
- Disable Windows Defender Windows 11
- Turn off Windows Update Windows 11
- PowerShell script disable Defender
- Stop automatic updates Windows 11
- Permanently disable Windows Defender and Update

---

**Use this script responsibly. For questions or improvements, open an issue or pull request on GitHub.**

