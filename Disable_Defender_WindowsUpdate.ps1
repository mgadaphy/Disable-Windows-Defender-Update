# Request Admin Rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Output "Starting full disable of Windows Defender and Windows Update services..."

# Check Tamper Protection status and warn user if enabled
$tpRegPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
$tpValue = 1
Try {
    $tpValue = (Get-ItemProperty -Path $tpRegPath -Name "TamperProtection" -ErrorAction Stop).TamperProtection
} Catch {}
if ($tpValue -eq 5 -or $tpValue -eq 1) {
    Write-Output "[WARNING] Windows Defender Tamper Protection appears to be ENABLED. Please disable it manually in Windows Security > Virus & threat protection > Manage settings > Tamper Protection before running this script for best results."
    Start-Sleep -Seconds 3
}

# Check Real-Time Protection status and warn user
Try {
    $rtpStatus = (Get-MpPreference).DisableRealtimeMonitoring
    if ($rtpStatus) {
        Write-Output "[INFO] Windows Defender Real-Time Protection is already OFF. If you want to fully disable Defender, proceed. If you want to re-enable it, use the re-enable script."
    } else {
        Write-Output "[INFO] Windows Defender Real-Time Protection is ON. This script will attempt to turn it off. If you want to keep it on, do not proceed."
    }
    Start-Sleep -Seconds 2
} Catch {
    Write-Output "[WARNING] Could not determine Real-Time Protection status. This may be due to Defender being fully disabled or not present."
    Start-Sleep -Seconds 2
}

# Disable Real-Time Protection and Others
$protections = @(
    "DisableRealtimeMonitoring",
    "DisableBehaviorMonitoring",
    "DisableBlockAtFirstSeen",
    "DisableIOAVProtection",
    "DisablePrivacyMode",
    "SignatureDisableUpdateOnStartupWithoutEngine",
    "DisableArchiveScanning",
    "DisableIntrusionPreventionSystem",
    "DisableScriptScanning",
    "SubmitSamplesConsent"
)

foreach ($protection in $protections) {
    Try {
        Set-MpPreference -$protection $true -ErrorAction Stop
        Write-Output "$protection disabled successfully."
    } Catch {
        Write-Output "Failed to disable $protection. This may be due to Tamper Protection, third-party antivirus, or OS restrictions."
    }
}

Start-Sleep -Seconds 2

# Stop Defender Service
Try {
    Stop-Service -Name WinDefend -Force -ErrorAction Stop
    Write-Output "Windows Defender service stopped."
} Catch {
    Write-Output "Failed to stop Windows Defender service. This may be due to Tamper Protection or OS restrictions."
}

# Stop Windows Update Service
Try {
    Stop-Service wuauserv -Force -ErrorAction Stop
    Set-Service wuauserv -StartupType Disabled -ErrorAction Stop
    Write-Output "Windows Update service disabled."
} Catch {
    Write-Output "Failed to disable Windows Update service."
}

# Disable Windows Update Medic Service
Try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Value 4 -ErrorAction Stop
    Write-Output "Windows Update Medic service disabled."
} Catch {
    Write-Output "Failed to disable Windows Update Medic service."
}

# Disable Defender Engine via Registry
Try {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
    Write-Output "Windows Defender Engine disabled via registry."
} Catch {
    Write-Output "Failed to disable Windows Defender Engine."
}

# Forceful attempt to disable Real-Time Protection and related features
Write-Output "[FORCEFUL ATTEMPT] Trying to disable Real-Time Protection and related Defender features via registry and Group Policy..."

# Registry: Disable AntiSpyware
Try {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
    Write-Output "Registry: DisableAntiSpyware set to 1."
} Catch {
    Write-Output "Failed to set DisableAntiSpyware in registry."
}

# Registry: Disable Real-Time Protection
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
    Write-Output "Registry: Real-Time Protection keys set."
} Catch {
    Write-Output "Failed to set Real-Time Protection registry keys."
}

# Group Policy: Disable Defender via WMI (if available)
Try {
    $namespace = "root\Microsoft\Windows\Defender"
    $class = Get-WmiObject -Namespace $namespace -List | Where-Object { $_.Name -eq "MSFT_MpPreference" }
    if ($class) {
        $mp = Get-WmiObject -Namespace $namespace -Class MSFT_MpPreference
        $mp.DisableRealtimeMonitoring = $true
        $mp.Put() | Out-Null
        Write-Output "WMI: DisableRealtimeMonitoring set to true."
    }
} Catch {
    Write-Output "Failed to set DisableRealtimeMonitoring via WMI."
}

# Attempt to stop Defender service again
Try {
    Stop-Service -Name WinDefend -Force -ErrorAction Stop
    Set-Service -Name WinDefend -StartupType Disabled -ErrorAction Stop
    Write-Output "Forcefully stopped and disabled WinDefend service."
} Catch {
    Write-Output "Failed to force stop/disable WinDefend service. This is expected if Tamper Protection is enabled."
}

Write-Output "[FORCEFUL ATTEMPT] If these steps failed, Tamper Protection or OS restrictions are still in effect."

Write-Output "All operations completed."
Write-Output "\n[WARNING] These changes deeply disable Windows Update and Windows Defender. This may expose your system to security risks and could affect system stability. Major Windows updates may still re-enable some services.\n"

# --- Additional Services to Disable ---
$services = @(
    "UsoSvc",      # Update Orchestrator Service
    "BITS",        # Background Intelligent Transfer Service
    "wscsvc",      # Security Center
    "WdNisSvc",    # Defender Antivirus Network Inspection Service
    "sedsvc"       # Windows Remediation Service
)
foreach ($svc in $services) {
    Try {
        Stop-Service -Name $svc -Force -ErrorAction Stop
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Write-Output "$svc service stopped and disabled."
    } Catch {
        Write-Output "Failed to stop/disable $svc. This may be due to OS protection or the service not existing."
    }
}

# --- Disable Windows Update Scheduled Tasks ---
$tasks = @(
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start",
    "\Microsoft\Windows\WindowsUpdate\sih",
    "\Microsoft\Windows\WindowsUpdate\sihboot",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModel",
    "\Microsoft\Windows\UpdateOrchestrator\Reboot",
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker_Display",
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker_ReadyToReboot"
)
foreach ($task in $tasks) {
    Try {
        Disable-ScheduledTask -TaskPath ([System.IO.Path]::GetDirectoryName($task)) -TaskName ([System.IO.Path]::GetFileName($task)) -ErrorAction Stop
        Write-Output "Disabled scheduled task: $task"
    } Catch {
        Write-Output "Failed to disable scheduled task: $task. It may not exist or may be protected by the OS."
    }
}

# --- Set Group Policy Registry Keys for Windows Update ---
Try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force | Out-Null
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 1 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 2 -PropertyType DWORD -Force | Out-Null
    Write-Output "Group Policy registry keys for Windows Update set."
} Catch {
    Write-Output "Failed to set Group Policy registry keys for Windows Update."
}

# --- Block Windows Update Servers via Hosts File ---
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$updateHosts = @(
    "127.0.0.1    windowsupdate.microsoft.com",
    "127.0.0.1    update.microsoft.com",
    "127.0.0.1    download.windowsupdate.com",
    "127.0.0.1    wustat.windows.com"
)
foreach ($entry in $updateHosts) {
    if (-not (Select-String -Path $hostsPath -Pattern $entry -Quiet)) {
        Try {
            Add-Content -Path $hostsPath -Value $entry -ErrorAction Stop
        } Catch {
            Write-Output "[ERROR] Could not write to hosts file. It may be locked by another process or protected. To block Windows Update servers manually, add the following line to your hosts file: $entry"
        }
    }
}
Write-Output "Windows Update servers blocked in hosts file."

# --- Block Windows Update Servers via Firewall ---
$updateIPs = @(
    "13.107.4.50", "13.107.5.88", "40.76.4.15", "40.76.4.167"
)
foreach ($ip in $updateIPs) {
    Try {
        New-NetFirewallRule -DisplayName "Block Windows Update $ip" -Direction Outbound -RemoteAddress $ip -Action Block -ErrorAction Stop
        Write-Output "Blocked Windows Update IP: $ip via firewall."
    } Catch {
        Write-Output "Failed to block Windows Update IP: $ip via firewall."
    }
}

# --- Disable Defender Periodic Scanning ---
Try {
    Set-MpPreference -DisablePeriodicScanning $true -ErrorAction Stop
    Write-Output "Defender periodic scanning disabled."
} Catch {
    Write-Output "Failed to disable Defender periodic scanning. This may be due to Tamper Protection, third-party antivirus, or OS restrictions."
}

Write-Output "Please manually reboot your system to apply all changes."

# Keep the window open
Read-Host -Prompt "Press ENTER to close this window"
