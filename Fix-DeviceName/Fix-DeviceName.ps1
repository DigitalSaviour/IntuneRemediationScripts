# Requires running as Administrator

# Set the prefix for the device name
$prefix = "CCTCBC-" # Custom prefix for the device name

# Ensure the script is run with elevated privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script must be run as an Administrator."
    exit 1
}

try {
    # Get the device's serial number
    $serialNumber = (Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber).Trim()

    if (-not $serialNumber) {
        Write-Error "Could not retrieve the serial number."
        exit 1
    }

    # Remove any invalid characters (Windows device names can't contain certain characters)
    $serialNumber = $serialNumber -replace '-', ''

    # Define the new device name
    $newName = "$serialNumber"

    # Check if the name meets Windows naming requirements (max 15 characters, no special chars)
    if ($newName.Length -gt 15) {
        Write-Warning "Generated name '$newName' exceeds 15 characters. Trimming from the beginning to 15 characters."
        $newName = $newName.Substring($newName.Length - 8, 8)
	$newName = "$prefix-$newName"
    }



    # Get current device name
    $currentName = $env:COMPUTERNAME

    if ($currentName -eq $newName) {
        Write-Output "Device is already named '$newName'. No changes needed."
        exit 0
    } else {
	Write-Output "Device name has been changed to '$currentName' but should be '$newName'."
    }

    # Rename the computer
    Write-Output "Renaming device from '$currentName' to '$newName'..."
    Rename-Computer -NewName $newName -Force -ErrorAction Stop

    Write-Output "Device successfully renamed to '$newName'. A restart is required for the change to take effect."
    
    # Prompt for restart
    $restart = Read-Host "Would you like to restart now to apply the name change? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Output "Restarting device..."
        Restart-Computer -Force
    } else {
        Write-Output "Please restart the device manually to apply the name change."
    }

} catch {
    Write-Error "An error occurred while renaming the device: $_"
    exit 1
}