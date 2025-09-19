# Detection Script for BitLocker Status

# Complete the $scriptname and $scriptver variables below - these will be used to populate the filename of the log
$scriptname = "Detect-BadEncryption"
$scriptver = "1.0"

$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$scriptname-$scriptver.log"

$volume = "C:"  # Change this if targeting a different drive

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Output $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

# Function to check BitLocker status
function Check-BitLockerStatus {
    try {
        $status = Get-BitLockerVolume -MountPoint $volume
        if ($status.ProtectionStatus -eq "Off") {
            Log-Message "BitLocker is not enabled on drive $volume."
            return $false
        } elseif ($status.EncryptionPercentage -lt 100) {
            Log-Message "BitLocker encryption is incomplete on drive $volume. Current encryption percentage: $($status.EncryptionPercentage)%."
            return $false
        } elseif ($status.LockStatus -ne "Unlocked") {
            Log-Message "BitLocker drive $volume is locked and cannot be remediated."
            return $false
        } else {
            Log-Message "BitLocker is enabled and encryption is complete on drive $volume."
            return $true
        }
    } catch {
        Log-Message "Error checking BitLocker status: $_"
        return $false
    }
}

# Main Execution
Log-Message "BitLocker detection script started."
$bitLockerStatus = Check-BitLockerStatus

if ($bitLockerStatus) {
    Log-Message "No remediation needed; BitLocker encryption is healthy."
    exit 0  # Exit with success code
} else {
    Log-Message "Issues detected with BitLocker; remediation may be required."
    exit 1  # Exit with error code to indicate remediation is needed
}

Log-Message "Detection script execution completed."
