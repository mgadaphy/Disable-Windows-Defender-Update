# Request Admin Rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Output "Starting full disable of Windows Defender and Windows Update services..."

# Disable Tamper Protection via Registry
Try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -Value 0 -ErrorAction Stop
    Write-Output "Tamper Protection disabled successfully."
} Catch {
    Write-Output "Failed to disable Tamper Protection automatically. Manual disable may be required."
}

Start-Sleep -Seconds 2

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
        Write-Output "Failed to disable $protection."
    }
}

Start-Sleep -Seconds 2

# Stop Defender Service
Try {
    Stop-Service -Name WinDefend -Force -ErrorAction Stop
    Write-Output "Windows Defender service stopped."
} Catch {
    Write-Output "Failed to stop Windows Defender service."
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
        Write-Output "Failed to stop/disable $svc."
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
        Write-Output "Failed to disable scheduled task: $task"
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
        Add-Content -Path $hostsPath -Value $entry
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
    Write-Output "Failed to disable Defender periodic scanning."
}

Write-Output "Please manually reboot your system to apply all changes."

# Keep the window open
Read-Host -Prompt "Press ENTER to close this window"
