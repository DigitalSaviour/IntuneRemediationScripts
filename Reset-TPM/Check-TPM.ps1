# Detection Script: Check TPM Readiness

try {
    # Get TPM status
    $tpm = Get-Tpm

    if ($tpm.TpmPresent -and $tpm.TpmReady) {
        Write-Output "TPM is present and ready for use."
        exit 0  # No issue
    } else {
        Write-Output "TPM is not ready for use or not present."
        exit 1  # Issue detected
    }
} catch {
    Write-Output "Error checking TPM: $_"
    exit 1  # Assume issue on error
}