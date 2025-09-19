# Manually define the latest known stable version of Chrome
$latestVersion = New-Object Version ("132.0.6834.111")  # Update this version number manually as needed

# Define the path to where Chrome is usually installed for a system-wide install
$chromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

# Initialize variable to hold the installed Chrome version
$installedVersion = $null

# Check all known paths for Chrome and get the version information
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $installedVersion = (Get-Item $path).VersionInfo.ProductVersion
        $installedVersion = New-Object Version ($installedVersion)
        break
    }
}

if (-not $installedVersion) {
    Write-Output "Google Chrome is not installed or the version information could not be retrieved."
    exit 0
}

# Compare the installed version with the manually defined latest version
if ($installedVersion -gt $latestVersion) {
    Write-Output "Google Chrome is up to date. Installed version: $installedVersion."
    exit 0
} else {
    Write-Output "Google Chrome is NOT up to date. Installed version: $installedVersion. Latest version: $latestVersion."
    exit 1
}
