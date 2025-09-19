# Function to get the latest version of Chrome from Google's new API endpoint
function Get-LatestChromeVersion {
    $url = "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Windows&num=1"
    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing
        $latestVersion = $response[0].version
        return [System.Version]$latestVersion
    }
    catch {
        Write-Error "Failed to retrieve the latest Chrome version: $_"
        return $null
    }
}

# Get the installed version of Chrome
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$installedVersion = $null
if (Test-Path $chromePath) {
    $installedVersion = [System.Version](Get-ItemProperty -Path $chromePath -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
}

# Check if Chrome is installed
if (-not $installedVersion) {
    Write-Output "Chrome is not installed at the expected path."
    exit 0
}

# Get the latest version of Chrome
$latestVersion = Get-LatestChromeVersion
if (-not $latestVersion) {
    exit 1
}

# Compare versions
if ($installedVersion -ge $latestVersion) {
    Write-Output "Chrome is up to date. Installed version: $installedVersion, Latest version: $latestVersion"
    exit 0
} else {
    Write-Output "Chrome is outdated. Installed version: $installedVersion, Latest version: $latestVersion"
    exit 1
}