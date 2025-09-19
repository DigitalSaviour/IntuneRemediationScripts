# Detection script for Intune
$ClassicTeamsPath = "C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe"
$NewTeamsApp = Get-AppxPackage -Name "MicrosoftTeams"

# Check if Classic Teams exists
if (Test-Path -Path $ClassicTeamsPath) {
    Write-Output "Classic Teams is installed."
    exit 1
}

# Check if New Teams is installed
if ($NewTeamsApp -eq $null) {
    Write-Output "New Teams is not installed."
    exit 1
}

# If New Teams is installed, check for version (example version check, adjust as needed)
$versionToCompare = [version]"24010.3002.2730.5461"  # Example version, update as necessary
if ($NewTeamsApp.Version -lt $versionToCompare) {
    Write-Output "New Teams is installed but outdated."
    exit 1
}

Write-Output "New Teams is up to date and Classic Teams is not present."
exit 0