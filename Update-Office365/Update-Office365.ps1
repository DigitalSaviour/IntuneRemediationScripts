<#
.SYNOPSIS
    Force the update of Office 365.

.DESCRIPTION
    If Office 365 for Enterprise is installed, this script will force an update.

.PARAMETER
    A description of each parameter that the script or function takes.

.EXAMPLE
    Push through Intune

.NOTES
    Additional information about the script or function.

    * The transcript log file is stored in the Intune Management Extension log file folder.
    * This allows using the Collect Diagnostics option in Intune be able to download the log file.

.LINK
    Any links to related scripts or other resources.

.AUTHOR
    Lee Burridge (lburridge@centrality.com)

.DATE
    25/10/2024
#>

# Complete the $scriptname and $scriptver variables below - these will be used to populate the filename of the log
$scriptname = "Update-Office365"
$scriptver = "1.0"

Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$scriptname-$scriptver.log


# Define the path to the OfficeC2RClient executable, which is used to update Office
$OfficeC2RClientPath = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"

# Function to force an Office update
function Update-Office365 {
    if (Test-Path $OfficeC2RClientPath) {
        Write-Host "Forcing an update for Microsoft Office 365..."
        
        # Run the OfficeC2RClient.exe with the /update switch to force an update
        Start-Process -FilePath $OfficeC2RClientPath -ArgumentList "/update user displaylevel=false forceappshutdown=true" -NoNewWindow -Wait
        
        Write-Host "Office update process initiated."
    } else {
        Write-Host "Office Click-to-Run client not found. Please ensure Office 365 is installed."
    }
}

# Run the function
Update-Office365

Stop-Transcript