# Function to check Office 365 version
$OfficeKey = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

if (Test-Path $OfficeKey) {
    $OfficeVersion = Get-ItemProperty -Path $OfficeKey -Name VersionToReport
    Write-Host "Installed Office 365 Version: $($OfficeVersion.VersionToReport)"
    Exit 1
} else {
    Write-Host "Office 365 is not installed on this machine or not installed via Click-to-Run."
    Exit 0
}

