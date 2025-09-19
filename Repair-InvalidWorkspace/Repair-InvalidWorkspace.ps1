# Check if the BitLocker WMI Namespace exists
$Namespace = "Root\CIMv2\Security\MicrosoftVolumeEncryption"
$CheckNamespace = Get-WmiObject -Namespace $Namespace -Class Win32_EncryptableVolume -ErrorAction SilentlyContinue

if ($CheckNamespace) {
    Write-Output "BitLocker WMI namespace exists. No action needed."
    exit 0
} else {
    Write-Output "BitLocker WMI namespace is missing or corrupted. Proceeding with fix..."
}

# Restart WMI Service
Write-Output "Restarting WMI Service..."
Restart-Service winmgmt -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# Rebuild WMI Repository
Write-Output "Rebuilding WMI Repository..."
Stop-Service winmgmt -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\System32\wbem\Repository" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service winmgmt -ErrorAction SilentlyContinue
Start-Sleep -Seconds 10
winmgmt /resetrepository | Out-Null

# Wait for Restart
Start-Sleep -Seconds 120

# Reinstall BitLocker (if necessary)
Write-Output "Checking if BitLocker is installed..."
$BitLockerFeature = Get-WindowsFeature -Name BitLocker | Select-Object -ExpandProperty Installed
if (-not $BitLockerFeature) {
    Write-Output "BitLocker is missing. Reinstalling..."
    dism /online /enable-feature /featurename:BitLocker | Out-Null
}

# Verify BitLocker Status
$BitLockerStatus = manage-bde -status 2>&1
Write-Output "BitLocker Status: $BitLockerStatus"

exit 0
