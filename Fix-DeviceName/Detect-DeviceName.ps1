# Detection Script: Check for Device Name Compliance
# Purpose: Detects if the device name matches the expected format (CCTCBC-<trimmed serial number>)
# Intune Exit Codes: 0 (compliant, no remediation needed), 1 (non-compliant, remediation needed)

try {
    # Set the prefix for the device name (must match remediation script)
    $prefix = "CCTCBC-"

    # Get the device's serial number
    $serialNumber = (Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber).Trim()

    if (-not $serialNumber) {
        Write-Error "Could not retrieve the serial number."
        exit 1
    }

    # Remove any invalid characters (matching remediation script logic)
    $serialNumber = $serialNumber -replace '-', ''

    # Define the expected device name
    $expectedName = "$serialNumber"

    # Check if the name meets Windows naming requirements (max 15 characters)
    # Removed the 15 character limit check as per the request
    # If the name exceeds 15 characters, it will be trimmed to the last 8 (Dell devices typically have 7-8 character serial numbers)
    #if ($expectedName.Length -gt 15) {
    #    Write-Output "Generated name '$expectedName' exceeds 15 characters. Trimming to last 8 characters."
        $expectedName = $expectedName.Substring($expectedName.Length - 8, 8)
        $expectedName = $prefix+$expectedName
    #}

    # Get current device name
    $currentName = $env:COMPUTERNAME

    # Log for debugging
    Write-Output "Expected Device Name: $expectedName"
    Write-Output "Current Device Name: $currentName"

    # Compare current name with expected name
    if ($currentName -eq $expectedName) {
        Write-Output "Device name is compliant."
        exit 0  # Compliant, no remediation needed
    } else {
        Write-Output "Device name '$currentName' does not match expected name '$expectedName'. Remediation required."
        exit 1  # Non-compliant, trigger remediation
    }
}
catch {
    Write-Error "Error checking device name: $_"
    exit 1  # Exit with error to trigger remediation or flag issue
}