# PowerShell detection script for Windows Update issues
# Designed for Intune Proactive Remediation on WUfB-managed devices

# Define the log file path (same as remediation script)
$logFile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\reset_wu.log"
$logFile = "C:\temp\reset_wu.log"

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
Write-Log "Starting Windows Update issue detection..."

# Initialize issue detection flag
$issuesDetected = $false



# 2. Verify critical Windows Update services
$services = @(
    @{Name="wuauserv"; ExpectedStartup="Manual"},
    @{Name="bits"; ExpectedStartup="Manual"},
    @{Name="cryptSvc"; ExpectedStartup="Automatic"},
    @{Name="msiserver"; ExpectedStartup="Manual"}
)
foreach ($svc in $services) {
    try {
        $serviceStatus = Get-Service -Name $svc.Name -ErrorAction Stop
        if ($serviceStatus.StartType -eq "Disabled") {
            Write-Log "Service $($svc.Name) is disabled. Issue detected." -Level "WARNING"
            $issuesDetected = $true
        } else {
            Write-Log "Service $($svc.Name) startup type is $($serviceStatus.StartType) (expected: $($svc.ExpectedStartup))."
        }
    } catch {
        Write-Log "Error checking service $($svc.Name): $_" -Level "ERROR"
        $issuesDetected = $true
    }
}

# 3. Check cache folders (SoftwareDistribution and catroot2)
$folders = @("C:\Windows\SoftwareDistribution", "C:\Windows\System32\catroot2")
foreach ($folder in $folders) {
    try {
        if (Test-Path -Path $folder) {
            $folderSize = (Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
            $sizeThresholdMB = 500 # Flag if folder > 500 MB
            if ($folderSize -gt $sizeThresholdMB) {
                Write-Log "Folder $folder size is $folderSize MB, exceeds threshold ($sizeThresholdMB MB). Issue detected." -Level "WARNING"
                $issuesDetected = $true
            } else {
                Write-Log "Folder $folder size is $folderSize MB, within threshold."
            }
        } else {
            Write-Log "Folder $folder does not exist. Issue detected." -Level "WARNING"
            $issuesDetected = $true
        }
    } catch {
        Write-Log "Error checking folder $folder : $_" -Level "ERROR"
        $issuesDetected = $true
    }
}

# 4. Check for WUfB policy conflicts (e.g., paused updates)
$regPaths = @(
    @{Path="HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings\PausedQualityStatus"; ExpectedValue=0},
    @{Path="HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings\PausedFeatureStatus"; ExpectedValue=0},
    @{Path="HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update\PauseQualityUpdates"; ExpectedValue=0},
    @{Path="HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update\PauseFeatureUpdates"; ExpectedValue=0}
)
foreach ($reg in $regPaths) {
    try {
        $value = Get-ItemProperty -Path (Split-Path $reg.Path) -Name (Split-Path $reg.Path -Leaf) -ErrorAction SilentlyContinue
        if ($value -and $value.(Split-Path $reg.Path -Leaf) -ne $reg.ExpectedValue) {
            Write-Log "WUfB policy conflict at $($reg.Path): Value is $($value.(Split-Path $reg.Path -Leaf)), expected $($reg.ExpectedValue). Issue detected." -Level "WARNING"
            $issuesDetected = $true
        } else {
            Write-Log "WUfB policy at $($reg.Path) is compliant or not set."
        }
    } catch {
        Write-Log "Error checking registry key $($reg.Path): $_" -Level "WARNING"
        $issuesDetected = $true
    }
}

# Log final detection result
if ($issuesDetected) {
    Write-Log "Windows Update issues detected. Remediation required." -Level "WARNING"
    exit 1 # Signal Intune to run remediation script
} else {
    Write-Log "No Windows Update issues detected."
    exit 0 # No remediation needed
}