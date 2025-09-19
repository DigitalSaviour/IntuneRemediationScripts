# Script to diagnose Windows Feature Update installation issues, including WindowsUpdate.log analysis

# Set output log file
$logFile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WindowsUpdateDiag_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp - $Message"
}

# Start logging
Write-Log "Starting Windows Feature Update Diagnostic"

# 1. Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "ERROR: Script not running as Administrator. Please run PowerShell as Administrator."
    exit
}

# 2. Check Disk Space
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
Write-Log "Free disk space on C: $freeSpaceGB GB"
if ($freeSpaceGB -lt 20) {
    Write-Log "WARNING: Low disk space. Feature updates require at least 20 GB free."
    Write-Log "REMEDIATION: Free up disk space by running 'Cleanmgr.exe' or deleting unnecessary files."
}

# 3. Check Windows Update Service Status
$wuService = Get-Service -Name wuauserv
Write-Log "Windows Update Service Status: $($wuService.Status)"
if ($wuService.Status -ne 'Running') {
    Write-Log "WARNING: Windows Update service is not running. Attempting to start..."
    try {
        Start-Service -Name wuauserv
        Write-Log "Windows Update service started successfully."
    } catch {
        Write-Log "ERROR: Failed to start Windows Update service: $_"
        Write-Log "REMEDIATION: Ensure dependent services (e.g., BITS, CryptSvc) are running. Run 'sc config wuauserv start=auto'."
    }
}

# 4. Check Windows Update History for Errors
Write-Log "Checking Windows Update History..."
$updateHistory = Get-WinEvent -LogName 'System' -MaxEvents 1000 -ErrorAction SilentlyContinue |
    Where-Object { $_.Id -eq 19 -and $_.ProviderName -eq 'Microsoft-Windows-WindowsUpdateClient' } |
    Select-Object -First 5
foreach ($event in $updateHistory) {
    $message = $event.Message
    if ($message -match "failed") {
        Write-Log "WARNING: Found failed update attempt: $message"
        Write-Log "REMEDIATION: Review error codes in message. Common fixes include resetting Windows Update components or running troubleshooter."
    }
}

# 5. Check for Pending Reboots
$pendingReboot = $false
if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) {
    $pendingReboot = $true
}
if (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) {
    $pendingReboot = $true
}
Write-Log "Pending Reboot Required: $pendingReboot"
if ($pendingReboot) {
    Write-Log "WARNING: A pending reboot may prevent updates."
    Write-Log "REMEDIATION: Restart the system using 'shutdown /r /t 0' and retry the update."
}

# 6. Check System Compatibility
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$osVersion = $os.Caption + " " + $os.Version
Write-Log "Current OS: $osVersion"
$cpu = Get-CimInstance -ClassName Win32_Processor
Write-Log "Processor: $($cpu.Name)"
$memoryGB = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Log "Total RAM: $memoryGB GB"
if ($memoryGB -lt 4) {
    Write-Log "WARNING: Insufficient RAM. Feature updates require at least 4 GB."
    Write-Log "REMEDIATION: Upgrade system RAM or ensure swap file is enabled."
}

# 7. Check TPM and Secure Boot (for Windows 11 compatibility)
$tpm = Get-Tpm -ErrorAction SilentlyContinue
if ($tpm) {
    Write-Log "TPM Present: $($tpm.TpmPresent)"
    Write-Log "TPM Ready: $($tpm.TpmReady)"
} else {
    Write-Log "WARNING: TPM not detected or not supported."
    Write-Log "REMEDIATION: Check BIOS/UEFI for TPM settings or confirm hardware compatibility for Windows 11."
}
$secureBoot = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
Write-Log "Secure Boot Enabled: $secureBoot"
if (-not $secureBoot) {
    Write-Log "WARNING: Secure Boot is disabled, which may be required for some updates (e.g., Windows 11)."
    Write-Log "REMEDIATION: Enable Secure Boot in BIOS/UEFI settings."
}

# 8. Check Windows Update Troubleshooter Results
Write-Log "Running Windows Update Troubleshooter..."
$troubleshooter = & "$env:SystemRoot\System32\msdt.exe" /id WindowsUpdateDiagnostic /quiet
Write-Log "Troubleshooter executed. Check Action Center for results or review $logFile."
Write-Log "REMEDIATION: Follow any troubleshooter prompts or review troubleshooter logs in Event Viewer."

# 9. Check for Corrupted System Files
Write-Log "Running System File Checker..."
$null = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -RedirectStandardOutput "$env:TEMP\sfc_output.txt"
$sfcResult = Get-Content -Path "$env:TEMP\sfc_output.txt"
if ($sfcResult -match "found corrupt files") {
    Write-Log "WARNING: Corrupted system files detected."
    Write-Log "REMEDIATION: Run 'DISM /Online /Cleanup-Image /RestoreHealth' followed by 'sfc /scannow' again."
} else {
    Write-Log "SFC scan completed. No issues detected."
}

# 10. Check Windows Update Components
Write-Log "Checking Windows Update Components..."
$wuComponents = Get-WmiObject -Class Win32_WinSAT -ErrorAction SilentlyContinue
if ($wuComponents) {
    Write-Log "Windows Update components appear intact."
} else {
    Write-Log "WARNING: Issue with Windows Update components."
    Write-Log "REMEDIATION: Reset Windows Update components by stopping services and clearing SoftwareDistribution folder (see below)."
}

# 11. Check for Update Blocks (Safeguard Holds)
Write-Log "Checking for Safeguard Holds..."
$regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
$deferFeature = Get-ItemProperty -Path $regPath -Name "DeferFeatureUpdatesPeriodInDays" -ErrorAction SilentlyContinue
if ($deferFeature -and $deferFeature.DeferFeatureUpdatesPeriodInDays -gt 0) {
    Write-Log "Feature Update Deferral: $($deferFeature.DeferFeatureUpdatesPeriodInDays) days"
    Write-Log "WARNING: Feature updates are deferred."
    Write-Log "REMEDIATION: Set 'DeferFeatureUpdatesPeriodInDays' to 0 in $regPath or disable deferral in Windows Update settings."
}

# 12. Analyze C:\Windows\WindowsUpdate.log
$wuLogPath = "C:\Windows\WindowsUpdate.log"
Write-Log "Analyzing WindowsUpdate.log..."
if (Test-Path $wuLogPath) {
    # Read last 500 lines for recent activity
    $logContent = Get-Content -Path $wuLogPath -Tail 500 -ErrorAction SilentlyContinue
    $errorPatterns = @(
        @{Pattern="0x800[0-9a-f]{4}"; Description="Windows Update Error Code"; Remediation="Look up error code on https://docs.microsoft.com/en-us/windows/deployment/update/windows-update-error-reference"},
        @{Pattern="failed to"; Description="General Failure"; Remediation="Check specific error details in log. Common fixes include resetting Windows Update components."},
        @{Pattern="download failed"; Description="Download Failure"; Remediation="Check internet connectivity. Reset Windows Update components."},
        @{Pattern="installation failed"; Description="Installation Failure"; Remediation="Run 'DISM /Online /Cleanup-Image /RestoreHealth' and retry update."},
        @{Pattern="safeguard hold"; Description="Safeguard Hold Detected"; Remediation="Check https://docs.microsoft.com/en-us/windows/release-health/ for known issues with your hardware/software."},
        @{Pattern="0xC190[0-9A-F]{4}"; Description="Feature Update Specific Error"; Remediation="Look up error code (e.g., 0xC1900101 for driver issues). Common fixes include updating drivers or removing conflicting software."}
    )

    foreach ($pattern in $errorPatterns) {
        $matches = $logContent | Where-Object { $_ -match $pattern.Pattern }
        if ($matches) {
            Write-Log "WARNING: Found $($pattern.Description) in WindowsUpdate.log:"
            foreach ($match in $matches) {
                Write-Log "  - $match"
            }
            Write-Log "REMEDIATION: $($pattern.Remediation)"
        }
    }

    # Check for specific common error codes
    $commonErrors.ConcurrentDictionary = @{
        "0x8007000D" = "Invalid data in update configuration. Run 'DISM /Online /Cleanup-Image /RestoreHealth'."
        "0x80070070" = "Insufficient disk space. Free up at least 20 GB on C: drive."
        "0xC1900101" = "Driver or software conflict. Update all drivers and remove third-party antivirus."
        "0x80070422" = "Windows Update service disabled. Ensure 'wuauserv' is running."
    }
    foreach ($errorCode in $commonErrors.Keys) {
        if ($logContent -match $errorCode) {
            Write-Log "WARNING: Found error $errorCode in WindowsUpdate.log."
            Write-Log "REMEDIATION: $($commonErrors[$errorCode])"
        }
    }
} else {
    Write-Log "ERROR: WindowsUpdate.log not found at $wuLogPath."
    Write-Log "REMEDIATION: Ensure logging is enabled. Run 'Get-WindowsUpdateLog' to generate a new log."
}

# 13. Offer to Reset Windows Update Components
Write-Log "Checking if Windows Update components reset is needed..."
$resetRecommended = $false
if ($logContent -match "0x800[0-9a-f]{4}" -or $wuComponents -eq $null -or $wuService.Status -ne 'Running') {
    $resetRecommended = $true
    Write-Log "WARNING: Issues detected that may require resetting Windows Update components."
    Write-Log "REMEDIATION: Run the following commands to reset Windows Update components:"
    Write-Log "  net stop wuauserv"
    Write-Log "  net stop cryptSvc"
    Write-Log "  net stop bits"
    Write-Log "  net stop msiserver"
    Write-Log "  ren C:\Windows\SoftwareDistribution SoftwareDistribution.old"
    Write-Log "  ren C:\Windows\System32\catroot2 catroot2.old"
    Write-Log "  net start wuauserv"
    Write-Log "  net start cryptSvc"
    Write-Log "  net start bits"
    Write-Log "  net start msiserver"
}

# End of Diagnostic
Write-Log "Diagnostic Complete. Review $logFile for details."
Write-Log "Summary of Recommended Actions:"
Write-Log "- Free up disk space if below 20 GB (run 'Cleanmgr.exe')."
Write-Log "- Restart system if pending reboot is detected ('shutdown /r /t 0')."
Write-Log "- Check Windows Update settings for deferrals or pauses."
Write-Log "- Run 'DISM /Online /Cleanup-Image /RestoreHealth' if SFC found issues."
Write-Log "- Reset Windows Update components if recommended above."
Write-Log "- Update drivers and remove conflicting software (e.g., third-party antivirus) for 0xC1900101 errors."
Write-Log "- Visit https://docs.microsoft.com/en-us/windows/deployment/update/windows-update-error-reference for specific error codes."
Write-Log "- Check https://support.microsoft.com for further assistance."

# Open log file
Invoke-Item $logFile