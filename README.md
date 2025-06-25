# Disable Windows Defender and Windows Update on Windows 11

## Introduction

**Disable_Defender_WindowsUpdate.ps1** is a powerful PowerShell script designed to completely and thoroughly disable Windows Defender (Microsoft Defender Antivirus) and Windows Update services on Windows 11. This script is ideal for advanced users, system administrators, and power users who want to stop automatic updates and security features that are difficult to turn off through standard Windows settings.

> **Disclaimer:** Disabling Windows Defender and Windows Update exposes your system to security risks and may affect system stability. Use this script at your own risk and only if you understand the consequences.

## Features
- Disables Windows Defender real-time protection and related features
- Disables Tamper Protection via the Windows Registry (attempts automatic disable, but manual action may be required)
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
- **Real-Time Protection:** The script checks if Windows Defender Real-Time Protection is ON or OFF at the start and will inform you. If it is already OFF, you can proceed to fully disable Defender. If it is ON, the script will attempt to turn it off using both standard and forceful methods (registry, WMI, and service changes). If you want to keep Real-Time Protection ON, do not proceed. If you want to re-enable it, use the re-enable script.
- **Tamper Protection:** The script checks if Windows Defender Tamper Protection is enabled and will warn you at the start if it is. You should manually turn off Tamper Protection in Windows Security settings before running the script for best results. If the script reports failure to disable Tamper Protection or other Defender features, disable Tamper Protection manually and re-run the script.

## Troubleshooting

### Real-Time Protection Status
At the start, the script checks if Windows Defender Real-Time Protection is ON or OFF. If it is already OFF, you can proceed to fully disable Defender. If it is ON, the script will attempt to turn it off. If you want to keep Real-Time Protection ON, do not proceed. If you want to re-enable it, use the re-enable script.

### Tamper Protection or Defender Features Not Disabled
If you see warnings or errors about failing to disable Tamper Protection or Defender features, it is likely because Tamper Protection is enabled, a third-party antivirus is installed, or the OS is blocking changes. To resolve:
- Open **Windows Security > Virus & threat protection > Manage settings > Tamper Protection** and turn it **Off**.
- Reboot your computer and run the script again as Administrator.

### Hosts File Write Errors
If you see errors about the script not being able to write to the hosts file, it may be locked by another process or protected by the OS. To block Windows Update servers manually:
1. Open Notepad as Administrator.
2. Open `C:\Windows\System32\drivers\etc\hosts`.
3. Add the following lines (one per update server):
   ```
   127.0.0.1    windowsupdate.microsoft.com
   127.0.0.1    update.microsoft.com
   127.0.0.1    download.windowsupdate.com
   127.0.0.1    wustat.windows.com
   ```
4. Save the file and close Notepad.

### Other Errors
Some services or scheduled tasks may fail to disable due to OS protection or because they do not exist on your system. This is normal and expected on some Windows 11 builds. For best results, always run the script as Administrator and reboot after running.

### Forceful Disable and Re-enable Attempts
The script now includes a forceful attempt to disable Real-Time Protection and related Defender features using registry edits, WMI, and service changes. The re-enable script will attempt to fully restore these settings, including removing registry keys and restoring WMI/Defender preferences. If you encounter issues, reboot and run the re-enable script as Administrator.

## Download Instructions

1. Go to the [GitHub repository page](https://github.com/mgadaphy/Disable-Windows-Defender-Update) in your web browser.
2. Click the green **Code** button and select **Download ZIP**.
3. Extract the ZIP file to a folder on your computer, such as `C:\Users\YourUsername\Downloads\Disable-Windows-Defender-Update`.
4. Alternatively, if you have Git installed, you can clone the repository:
   ```powershell
   git clone https://github.com/mgadaphy/Disable-Windows-Defender-Update.git
   ```

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
     cd "C:\Users\YourUsername\Downloads\Disable-Windows-Defender-Update"
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
To restore Windows Defender and Windows Update, use the provided `Reenable_Defender_WindowsUpdate.ps1` script. This script will attempt to:
- Remove all registry and Group Policy blocks for Defender and Windows Update
- Remove forceful disable keys for Real-Time Protection and AntiSpyware
- Restore Defender settings via WMI
- Re-enable all relevant services and scheduled tasks
- Remove hosts file and firewall blocks
Run the script as Administrator, then reboot your computer. If you still encounter issues, check the Troubleshooting section or manually review the registry and service settings.

---

**Use this script responsibly. For questions or improvements, open an issue or pull request on GitHub.**

