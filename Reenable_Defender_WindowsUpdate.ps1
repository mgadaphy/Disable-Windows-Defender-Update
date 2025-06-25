# Re-enable Windows Defender and Windows Update on Windows 11
# Run this script as Administrator

Write-Output "Starting re-enablement of Windows Defender and Windows Update services..."

# Remove Group Policy/Registry blocks for Defender
Try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
    Write-Output "Removed DisableAntiSpyware registry key."
} Catch {}
Try {
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -ErrorAction SilentlyContinue
    Write-Output "Removed Real-Time Protection registry keys."
} Catch {}

# Remove Windows Update Group Policy keys
Try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -ErrorAction SilentlyContinue
    Write-Output "Removed Windows Update Group Policy registry keys."
} Catch {}

# Restore Tamper Protection registry value (set to 5 = On)
Try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -Value 5 -ErrorAction SilentlyContinue
    Write-Output "Restored Tamper Protection registry value."
} Catch {}

# Restore Defender settings via WMI (if available)
Try {
    $namespace = "root\Microsoft\Windows\Defender"
    $class = Get-WmiObject -Namespace $namespace -List | Where-Object { $_.Name -eq "MSFT_MpPreference" }
    if ($class) {
        $mp = Get-WmiObject -Namespace $namespace -Class MSFT_MpPreference
        $mp.DisableRealtimeMonitoring = $false
        $mp.Put() | Out-Null
        Write-Output "WMI: DisableRealtimeMonitoring set to false."
    }
} Catch {
    Write-Output "Failed to restore DisableRealtimeMonitoring via WMI."
}

# Re-enable Defender and Update services
$services = @(
    "WinDefend",
    "wuauserv",
    "WaaSMedicSvc",
    "UsoSvc",
    "BITS",
    "WdNisSvc",
    "sedsvc"
)
foreach ($svc in $services) {
    Try {
        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Output "$svc service set to Automatic and started."
    } Catch {
        Write-Output "Failed to re-enable $svc."
    }
}

# Re-enable scheduled tasks
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
        Enable-ScheduledTask -TaskPath ([System.IO.Path]::GetDirectoryName($task)) -TaskName ([System.IO.Path]::GetFileName($task)) -ErrorAction SilentlyContinue
        Write-Output "Enabled scheduled task: $task"
    } Catch {
        Write-Output "Failed to enable scheduled task: $task"
    }
}

# Remove Windows Update blocks from hosts file
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$updateHosts = @(
    "windowsupdate.microsoft.com",
    "update.microsoft.com",
    "download.windowsupdate.com",
    "wustat.windows.com"
)
Try {
    $hostsContent = Get-Content -Path $hostsPath -ErrorAction Stop
    $filtered = $hostsContent | Where-Object { $line = $_; -not ($updateHosts | ForEach-Object { $line -match $_ }) }
    Set-Content -Path $hostsPath -Value $filtered -ErrorAction Stop
    Write-Output "Removed Windows Update blocks from hosts file."
} Catch {
    Write-Output "Could not edit hosts file. You may need to remove update blocks manually."
}

# Remove firewall rules blocking Windows Update
$updateIPs = @(
    "13.107.4.50", "13.107.5.88", "40.76.4.15", "40.76.4.167"
)
foreach ($ip in $updateIPs) {
    Try {
        Get-NetFirewallRule -DisplayName "Block Windows Update $ip" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
        Write-Output "Removed firewall rule blocking $ip."
    } Catch {}
}

Write-Output "All operations completed. Please reboot your system."
Read-Host -Prompt "Press ENTER to close this window" 