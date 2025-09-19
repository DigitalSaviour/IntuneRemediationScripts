# PowerShell script to reset Windows Update components and log output to a file
# Optimized for Intune deployment with WUfB

# Define the log file path
$logFile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\reset_wu.log"

# Ensure the log directory exists
$logDir = Split-Path -Path $logFile -Parent
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# Function to log messages with timestamp
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $logFile -Value $logEntry -ErrorAction Stop
    } catch {
        # Fallback to console output if logging fails
        Write-Output $logEntry
    }
}

# Start logging
Write-Log "Starting Windows Update reset process..."

# Function to stop a service with timeout
function Stop-ServiceWithTimeout {
    param (
        [string]$ServiceName
    )
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($service.Status -eq 'Running') {
            Write-Log "Stopping service $ServiceName..."
            Stop-Service -Name $ServiceName -Force -ErrorAction Stop
            $timeout = 30
            while ((Get-Service -Name $ServiceName).Status -ne 'Stopped' -and $timeout -gt 0) {
                Start-Sleep -Seconds 1
                $timeout--
            }
            if ((Get-Service -Name $ServiceName).Status -ne 'Stopped') {
                Write-Log "Failed to stop service $ServiceName within timeout." -Level "ERROR"
                return $false
            }
            Write-Log "Service $ServiceName stopped successfully."
            return $true
        } else {
            Write-Log "Service $ServiceName is already stopped."
            return $true
        }
    } catch {
        Write-Log "Error stopping service $ServiceName : $_" -Level "ERROR"
        return $false
    }
}

# Function to start a service
function Start-ServiceWithTimeout {
    param (
        [string]$ServiceName
    )
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($service.Status -ne 'Running') {
            Write-Log "Starting service $ServiceName..."
            Start-Service -Name $ServiceName -ErrorAction Stop
            Write-Log "Service $ServiceName started successfully."
            return $true
        } else {
            Write-Log "Service $ServiceName is already running."
            return $true
        }
    } catch {
        Write-Log "Error starting service $ServiceName : $_" -Level "ERROR"
        return $false
    }
}

# Stop Windows Update services
$services = @("wuauserv", "cryptSvc", "bits", "msiserver")
foreach ($service in $services) {
    if (-not (Stop-ServiceWithTimeout -ServiceName $service)) {
        Write-Log "Aborting due to failure to stop service $service." -Level "ERROR"
        exit 1
    }
}

# Clear BITS queue files
try {
    Write-Log "Clearing BITS job queue files..."
    Remove-Item -Path "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -Force -ErrorAction Stop
    Write-Log "BITS queue files cleared successfully."
} catch {
    Write-Log "Error clearing BITS queue files: $_" -Level "ERROR"
}

# Reset service security descriptors to defaults
try {
    Write-Log "Resetting BITS service security descriptor..."
    & sc.exe sdset bits "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" | Out-Null
    Write-Log "BITS security descriptor reset successfully."
} catch {
    Write-Log "Error resetting BITS security descriptor: $_" -Level "ERROR"
}

try {
    Write-Log "Resetting wuauserv service security descriptor..."
    & sc.exe sdset wuauserv "D:(A;;CCLCSWRPWPDTLOCRRC;;;AU)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)" | Out-Null
    Write-Log "wuauserv security descriptor reset successfully."
} catch {
    Write-Log "Error resetting wuauserv security descriptor: $_" -Level "ERROR"
}

# Rename update cache folders
$folders = @(
    @{Path="C:\Windows\SoftwareDistribution"; NewName="SoftwareDistribution.old"},
    @{Path="C:\Windows\System32\catroot2"; NewName="catroot2.old"}
)
foreach ($folder in $folders) {
    try {
        if (Test-Path -Path $folder.Path) {
            Write-Log "Renaming $($folder.Path) to $($folder.NewName)..."
            Rename-Item -Path $folder.Path -NewName $folder.NewName -Force -ErrorAction Stop
            Write-Log "Successfully renamed $($folder.Path)."
        } else {
            Write-Log "Folder $($folder.Path) does not exist, skipping rename."
        }
    } catch {
        Write-Log "Error renaming $($folder.Path): $_" -Level "ERROR"
        # Continue to allow partial success
    }
}

# Re-register Windows Update-related DLLs
$dlls = @(
    "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll",
    "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll",
    "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll",
    "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll",
    "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll",
    "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", "wups.dll", "wups2.dll",
    "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll", "wuwebv.dll"
)
foreach ($dll in $dlls) {
    try {
        Write-Log "Re-registering $dll..."
        & regsvr32.exe /s $dll | Out-Null
        Write-Log "$dll re-registered successfully."
    } catch {
        Write-Log "Error re-registering $dll : $_" -Level "WARNING"
    }
}

# Reset network configurations
try {
    Write-Log "Resetting Winsock..."
    & netsh winsock reset | Out-Null
    Write-Log "Winsock reset successfully."
} catch {
    Write-Log "Error resetting Winsock: $_" -Level "ERROR"
}

try {
    Write-Log "Resetting WinHTTP proxy..."
    & netsh winhttp reset proxy | Out-Null
    Write-Log "WinHTTP proxy reset successfully."
} catch {
    Write-Log "Error resetting WinHTTP proxy: $_" -Level "ERROR"
}

try {
    Write-Log "Flushing DNS cache..."
    & ipconfig /flushdns | Out-Null
    Write-Log "DNS cache flushed successfully."
} catch {
    Write-Log "Error flushing DNS: $_" -Level "ERROR"
}

# Restart Windows Update services
foreach ($service in $services) {
    if (-not (Start-ServiceWithTimeout -ServiceName $service)) {
        Write-Log "Failed to start service $service, but continuing..." -Level "WARNING"
    }
}

# Clean WUfB/Intune-related registry keys
$regPaths = @(
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Action="Remove"},
    @{Path="HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings\PausedQualityDate"; Action="Remove"},
    @{Path="HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings\PausedFeatureDate"; Action="Remove"},
    @{Path="HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings\PausedQualityStatus"; Action="Set0"},
    @{Path="HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings\PausedFeatureStatus"; Action="Set0"},
    @{Path="HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update\DeferFeatureUpdatesPeriodInDays"; Action="Set0"},
    @{Path="HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update\PauseQualityUpdates"; Action="Set0"},
    @{Path="HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update\PauseFeatureUpdates"; Action="Set0"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowDeviceNameInTelemetry"; Action="Set1"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry_PolicyManager"; Action="Set1"},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser\GWX\GStatus"; Action="Set2"}
)
foreach ($reg in $regPaths) {
    try {
        if ($reg.Action -eq "Remove") {
            if (Test-Path $reg.Path) {
                Write-Log "Removing registry key: $($reg.Path)..."
                Remove-Item -Path $reg.Path -Recurse -Force -ErrorAction Stop
            }
        } elseif ($reg.Action -eq "Set0") {
            Write-Log "Setting registry value to 0: $($reg.Path)..."
            Set-ItemProperty -Path (Split-Path $reg.Path) -Name (Split-Path $reg.Path -Leaf) -Value 0 -Type DWord -Force -ErrorAction Stop
        } elseif ($reg.Action -eq "Set1") {
            Write-Log "Setting registry value to 1: $($reg.Path)..."
            Set-ItemProperty -Path (Split-Path $reg.Path) -Name (Split-Path $reg.Path -Leaf) -Value 1 -Type DWord -Force -ErrorAction Stop
        } elseif ($reg.Action -eq "Set2") {
            Write-Log "Setting registry value to 2: $($reg.Path)..."
            Set-ItemProperty -Path (Split-Path $reg.Path) -Name (Split-Path $reg.Path -Leaf) -Value 2 -Type DWord -Force -ErrorAction Stop
        }
        Write-Log "Registry operation successful for $($reg.Path)."
    } catch {
        Write-Log "Error on registry key $($reg.Path): $_" -Level "WARNING"
    }
}

# Run System File Checker (SFC)
try {
    Write-Log "Running System File Checker (SFC)..."
    $sfcOutput = & sfc /scannow 2>&1
    Write-Log "SFC output: $sfcOutput"
} catch {
    Write-Log "Error running SFC: $_" -Level "ERROR"
}

# Run DISM commands
$dismCommands = @(
    @{Command="DISM /Online /Cleanup-Image /CheckHealth"; Description="DISM CheckHealth"},
    @{Command="DISM.exe /Online /Cleanup-Image /ScanHealth"; Description="DISM ScanHealth"},
    @{Command="DISM.exe /Online /Cleanup-Image /RestoreHealth"; Description="DISM RestoreHealth"}
)
foreach ($dism in $dismCommands) {
    try {
        Write-Log "Running $($dism.Description)..."
        $dismOutput = Invoke-Expression $dism.Command 2>&1
        Write-Log "$($dism.Description) output: $dismOutput"
    } catch {
        Write-Log "Error running $($dism.Description): $_" -Level "ERROR"
    }
}

# Force Windows Update scan
try {
    Write-Log "Forcing Windows Update scan..."
    & USOClient.exe StartInteractiveScan 2>&1 | Out-Null
    Write-Log "Update scan triggered successfully."
} catch {
    Write-Log "Error triggering update scan: $_" -Level "ERROR"
}

# Trigger Intune policy sync to reapply WUfB settings
try {
    Write-Log "Triggering Intune policy sync..."
    $namespace = "root\cimv2\mdm\dmmap"
    $class = "MDM_RemoteDeviceManagement"
    $method = "TriggerSync"
    Invoke-WmiMethod -Namespace $namespace -Class $class -Name $method -ErrorAction Stop | Out-Null
    Write-Log "Intune policy sync triggered successfully."
} catch {
    Write-Log "Error triggering Intune sync: $_" -Level "WARNING"
}

# Verify WUfB policy reapplication
try {
    Write-Log "Verifying WUfB policy reapplication..."
    $wuPolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue
    if ($wuPolicy) {
        Write-Log "WUfB policies detected: $($wuPolicy | Out-String)"
    } else {
        Write-Log "No WUfB policies found in registry yet. Awaiting Intune sync." -Level "WARNING"
    }
} catch {
    Write-Log "Error verifying WUfB policies: $_" -Level "WARNING"
}

# Optional: Schedule a reboot (e.g., in 5 minutes) for full effect
try {
    Write-Log "Scheduling optional reboot in 5 minutes (cancel with 'shutdown /a')..."
    & shutdown.exe /r /f /t 300 /c "Rebooting to complete Windows Update reset and reapply Intune WUfB settings. Save your work or cancel with 'shutdown /a'." | Out-Null
    Write-Log "Reboot scheduled. WUfB settings will be reapplied by Intune post-reboot or next sync."
} catch {
    Write-Log "Error scheduling reboot: $_" -Level "WARNING"
    Write-Log "Manual reboot recommended to ensure WUfB settings are reapplied."
}

# End logging
Write-Log "Windows Update reset process completed."

# Exit with success code
exit 0