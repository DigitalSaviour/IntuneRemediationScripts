# Check if the Windows Defender service is running
$service = Get-Service -Name "WinDefend"
if ($service.Status -ne "Running") {
    # Return non-zero exit code if the service is not running
    exit 1
}

# Check if the definitions are up to date
$status = Get-MpComputerStatus

# Check if the definitions are up to date
if ($status.AntivirusSignatureAge -gt 1) {
    Write-Output "The definitions are out of date."
    exit 1
} else {
    Write-Output "The definitions are up to date."
}


# Return zero exit code if the definitions are up to date
exit 0