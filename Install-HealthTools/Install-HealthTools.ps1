# Remediation Script: Download and install Microsoft Update Health Tools
# This script downloads the Microsoft Update Health Tools package, extracts it, and installs the appropriate MSI based on the Windows version and architecture.
# The $DownloadUrl is set to the official Microsoft download link for Update Health Tools and may need to be updated if the link changes.

# Author: Lee Burridge
# Date: 27th May 2025
# Version: 1.0
# Usage: Run this script with administrative privileges to install the Microsoft Update Health Tools.

try {
    # Define variables
    $DownloadUrl = "https://download.microsoft.com/download/d/7/e/d7e9fd79-e6fe-4036-85df-c60254f50d90/Expedite_packages.zip" # Microsoft Download Center URL for Update Health Tools
    $DownloadPath = "$env:TEMP\UpdateHealthTools.zip"
    $ExtractPath = "$env:TEMP\UpdateHealthTools"
    $LogPath = "$env:TEMP\UpdateHealthTools_Install.log"

    # Verify the download URL accessibility
    Write-Output "Checking download URL availability..."
    $UrlStatus = Invoke-WebRequest -Uri $DownloadUrl -Method Head -UseBasicParsing -ErrorAction SilentlyContinue
    if ($UrlStatus.StatusCode -ne 200) {
        Write-Output "Error: Download URL is not accessible. Please visit https://www.microsoft.com/en-us/download/details.aspx?id=103324 to download the Update Health Tools package manually."
        exit 1
    }

    # Download the ZIP package
    Write-Output "Downloading Microsoft Update Health Tools..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath

    # Create extraction directory if it doesn't exist
    if (-not (Test-Path $ExtractPath)) {
        New-Item -ItemType Directory -Path $ExtractPath | Out-Null
    }

    # Extract the ZIP file
    Write-Output "Extracting ZIP package..."
    Expand-Archive -Path $DownloadPath -DestinationPath $ExtractPath -Force

    # Determine Windows version to select the correct MSI
    $OSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
    $MsiFile = $null

    # Map Windows versions to folder names in the ZIP (based on Microsoft naming conventions)
    $VersionMap = @{
        "10.0.19041" = "Windows 10" # Windows 10 2004, 20H2, 21H1, 21H2
        "10.0.19042" = "Windows 10"
        "10.0.19043" = "Windows 10"
        "10.0.19044" = "Windows 10"
        "10.0.19045" = "Windows 10"
        "10.0.22000" = "Windows 11 21H2" # Windows 11 21H2
        "10.0.22621" = "Windows 11 22H2+" # Windows 11 22H2
        "10.0.26100" = "Windows 11 22H2+" # Windows 11 23H2
        "10.0.22631" = "Windows 11 22H2+" # Windows 11 23H2
    }

    $VersionFolder = $VersionMap.Keys | Where-Object { $OSVersion -like "$_*" } | ForEach-Object { $VersionMap[$_] }
    if (-not $VersionFolder) {
        Write-Output "Error: Unsupported Windows version ($OSVersion). Please verify manually."
        exit 1
    }

    $MsiPath = Join-Path -Path $ExtractPath -ChildPath "Expedite_packages\$VersionFolder\UpdHealthTools.msi"

    if (-not (Test-Path $MsiPath)) {
        Write-Output "Error: MSI file not found for $VersionFolder. Please verify the ZIP contents at $ExtractPath."
        exit 1
    }

    # Install the MSI silently
    Write-Output "Installing Microsoft Update Health Tools from $MsiPath..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$MsiPath`" /quiet /norestart /log `"$LogPath`"" -Wait

    # Verify installation
    $AppCheck = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Microsoft Update Health Tools*" }
    if ($AppCheck) {
        Write-Output "Microsoft Update Health Tools installed successfully."
        Remove-Item -Path $DownloadPath -Force # Clean up the ZIP
        Remove-Item -Path $ExtractPath -Recurse -Force # Clean up extracted files
        exit 0
    } else {
        Write-Output "Installation failed. Check $LogPath for details."
        exit 1
    }
}
catch {
    Write-Output "Error occurred: $_"
    exit 1
}