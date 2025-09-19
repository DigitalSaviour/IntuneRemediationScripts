# Remediation Script: Provision and Optionally Clear TPM

# Function to log output (useful for Intune troubleshooting)
function Write-Log {
    param ([string]$Message)
    $logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Reset-TPM_Remediation_Log.txt"
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Output $Message
}

try {
    # Check if TPM is present
    $tpm = Get-Tpm
    if (-not $tpm.TpmPresent) {
        Write-Log "TPM not present. Cannot proceed."
        exit 1
    }

    # If not ready, initialize TPM
    if (-not $tpm.TpmReady) {
        Write-Log "TPM not ready. Attempting initialization."
        
        # Initialize TPM (allows clear and physical presence if needed; adjust flags as per policy)
        Initialize-Tpm -AllowClear -AllowPhysicalPresence | Out-Null
        
        # Re-check status post-init
        $tpm = Get-Tpm
        if ($tpm.TpmReady) {
            Write-Log "TPM successfully provisioned."
        } else {
            Write-Log "TPM initialization failed. Check Event Viewer (Microsoft-Windows-TPM) for details."
            exit 1
        }
    } else {
        Write-Log "TPM already ready. No initialization needed."
    }

    # Optional: Clear TPM after provisioning (uncomment if this is the goal, e.g., for reset)
    # Note: This requires the TPM to be ready and will prompt for reboot if ownership changes.
    # Suspend BitLocker first if enabled!
    Write-Log "Clearing TPM to reset ownership."
    Suspend-BitLocker -MountPoint "C:" -RebootCount 1 | Out-Null  # Suspend for one reboot
    Clear-Tpm | Out-Null
    Write-Log "TPM cleared successfully."

    # Force reboot if changes require it (comment out if Intune should handle reboot)
    Write-Log "Rebooting device to apply TPM changes."
    Restart-Computer -Force

    exit 0  # Success
} catch {
    Write-Log "Error during remediation: $_"
    exit 1  # Failure
}