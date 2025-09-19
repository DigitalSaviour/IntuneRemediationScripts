# Check if the Windows Defender service is running
$service = Get-Service -Name "WinDefend"
if ($service.Status -ne "Running") {
    # Start the service if it's not running
    Start-Service -Name "WinDefend"
}

# Update the Windows Defender definitions
Update-MpSignature
