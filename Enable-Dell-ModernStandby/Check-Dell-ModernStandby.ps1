# Check if Modern Standby (S0 Low Power Idle) is enabled

function Check-ModernStandby {
    # Run the powercfg command and capture the output
    $output = powercfg /a

    # Check if "Standby (S0 Low Power Idle)" is listed in the output
    if ($output -match "Standby \(S0 Low Power Idle\)") {
        return $true
    } else {
        return $false
    }
}

# Main script logic
if (Check-ModernStandby) {
    Write-Output "Modern Standby (S0 Low Power Idle) is enabled."
    exit 0  # Exit code 0 indicates success
} else {
    Write-Output "Modern Standby (S0 Low Power Idle) is not enabled."
    exit 1  # Exit code 1 indicates failure
}
