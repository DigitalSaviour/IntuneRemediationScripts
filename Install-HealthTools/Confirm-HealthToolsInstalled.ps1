# Detection Script: Check if Microsoft Update Health Tools is installed
# Author: Lee Burridge
# Date: 27th May 2025
# Version: 1.0

try {
    # Check 64-bit registry path
    $app = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*Microsoft Update Health Tools*" }

    # Check 32-bit registry path on 64-bit systems
    if (-not $app) {
        $app = Get-ItemProperty -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*Microsoft Update Health Tools*" }
    }

    if ($app) {
        Write-Output "Detected: Microsoft Update Health Tools is installed."
        exit 0
    } else {
        Write-Output "Not Detected: Microsoft Update Health Tools is not installed."
        exit 1
    }
}
catch {
    Write-Output "Detection error: $_"
    exit 1
}
