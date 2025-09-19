# Complete the $scriptname and $scriptver variables below - these will be used to populate the filename of the log
$scriptname = "ForceUpdate-Chrome"
$scriptver = "2.1"

Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$scriptname-$scriptver.log

# Function to force update Google Chrome
function Force-UpdateChrome {
    param (
        [string]$chromeBitVersion
    )

    # Determine paths based on bit version
    if ($chromeBitVersion -eq "64") {
        $googleUpdatePath = "${env:ProgramFiles}\Google\Update\GoogleUpdate.exe"
        $chromePath = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
    } else {
        $googleUpdatePath = "${env:ProgramFiles(x86)}\Google\Update\GoogleUpdate.exe"
        $chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
    } 

    # Stop any running instances of Chrome
    $chromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    if ($chromeProcesses) {
        Write-Host "Stopping running Chrome processes..."
        try {
            Stop-Process -Name "chrome" -Force
        } catch {
            Write-Host "Failed to stop Chrome processes: $_"
        }
    }

    # Trigger Chrome update
    if (-Not (Test-Path $googleUpdatePath)) {
        Write-Host "$chromeBitVersion-bit Google Update tool not found. Is Chrome installed?"
        return
    }

    Write-Host "Forcing $chromeBitVersion-bit Chrome update..."
    Start-Process $googleUpdatePath -ArgumentList "/ua" -Wait -PassThru | Out-File C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GoogleUpdate.log

    # Optional: Restart Chrome after update
    if (Test-Path $chromePath) {
        Write-Host "Restarting $chromeBitVersion-bit Chrome..."
        Start-Process $chromePath
    } else {
        Write-Host "$chromeBitVersion-bit Chrome was not found in the expected location."
    }

    Write-Host "$chromeBitVersion-bit Chrome update process completed."
}

# Function to check Chrome version and compare with target
function Check-ChromeVersion {
    param (
        [string]$chromePath,
        [string]$targetVersion
    )

    if (-Not (Test-Path $chromePath)) {
        Write-Host "Chrome is not installed at $chromePath"
        return $false
    }

    # Get the installed Chrome version
    $installedVersion = (Get-Item $chromePath).VersionInfo.ProductVersion
    Write-Host "Installed Chrome Version: $installedVersion at $chromePath"

    # Compare the installed version with the target version
    if ($installedVersion -ge $targetVersion) {
        Write-Host "Chrome has been updated to the target version ($targetVersion) or higher. $chromePath"
        return $true
    } else {
        Write-Host "Chrome is still at an older version. Waiting for update to complete... $chromePath"
        return $false
    }
}

try {
    # Update 64-bit Chrome
    Force-UpdateChrome -chromeBitVersion "64"
    
    # Update 32-bit Chrome
    Force-UpdateChrome -chromeBitVersion "32"
    
    # Target version to check for
    $targetVersion = "128.0.6613.85"  # Example version, change to desired version
    
    # Path to 64-bit Chrome
    $chromePath64 = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
    # Path to 32-bit Chrome
    $chromePath32 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
   
    # Version check loop
    $maxRetries = 10
    $retryCount = 0
    $versionUpdated = $false

    while (-not $versionUpdated -and $retryCount -lt $maxRetries) {
        Write-Host "Checking if Chrome is updated to version $targetVersion (Attempt $($retryCount+1))..."

        # Check both 64-bit and 32-bit Chrome versions
        $chrome64Updated = Check-ChromeVersion -chromePath $chromePath64 -targetVersion $targetVersion
        $chrome32Updated = Check-ChromeVersion -chromePath $chromePath32 -targetVersion $targetVersion
 
        if ($chrome64Updated -or $chrome32Updated) {
            $versionUpdated = $true
        } else {
            # Wait 30 seconds before rechecking
            Start-Sleep -Seconds 30
            $retryCount++
        }
    }

    if ($versionUpdated) {
        Write-Output "Success: Chrome has been updated to the required version."
    } else {
        Write-Output "Failed: Chrome did not reach the required version within the retry limit."
    }
}
catch {
    Write-Output "An error occurred: $_"
}

Stop-Transcript
