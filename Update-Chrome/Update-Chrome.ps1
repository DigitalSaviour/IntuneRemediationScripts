# Function to get the latest version of Chrome from Google's new API endpoint
function Get-LatestChromeVersion {
    $url = "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Windows&num=1"
    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing
        $latestVersion = $response[0].version
        return $latestVersion
    }
    catch {
        Write-Error "Failed to retrieve the latest Chrome version: $_"
        exit 1
    }
}

# Function to download and install Chrome
function Install-LatestChrome {
    $downloadUrl = "https://dl.google.com/tag/s/dl/chrome/install/latest/chrome_installer.exe"
    $installerPath = "$env:TEMP\chrome_installer.exe"

    # Download the latest installer
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

    # Install Chrome silently
    Start-Process -FilePath $installerPath -ArgumentList "/silent /install" -Wait

    # Clean up the installer
    Remove-Item -Path $installerPath -Force
}

# Get the installed version of Chrome
$installedVersion = (Get-ItemProperty -Path "C:\Program Files\Google\Chrome\Application\chrome.exe" -ErrorAction SilentlyContinue).VersionInfo.ProductVersion

# Get the latest version of Chrome
$latestVersion = Get-LatestChromeVersion

# Compare versions and install if outdated
if ($installedVersion -ne $latestVersion) {
    Write-Output "Updating Chrome to the latest version: $latestVersion"
    Install-LatestChrome
    Write-Output "Chrome has been updated."
} else {
    Write-Output "Chrome is already up to date."
}