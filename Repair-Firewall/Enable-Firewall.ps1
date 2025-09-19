<#
.SYNOPSIS
    A brief description of what the script or function does.

.DESCRIPTION
    A detailed description of the script or function.

.PARAMETER
    A description of each parameter that the script or function takes.

.EXAMPLE
    An example of how to use the script or function.

.NOTES
    Additional information about the script or function.

    * The transcript log file is stored in the Intune Management Extension log file folder.
    * This allows using the Collect Diagnostics option in Intune be able to download the log file.

.LINK
    Any links to related scripts or other resources.

.AUTHOR
    Your name or the name of the person who wrote the script.

.DATE
    The date the script was written or last updated.
#>

# Complete the $scriptname and $scriptver variables below - these will be used to populate the filename of the log
$scriptname = ""
$scriptver = ""

Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$scriptname-$scriptver.log

# Check and enable Windows Firewall on all network profiles (Domain, Private, Public)

# Define a function to enable the firewall for a specific profile
function Enable-Firewall {
    param (
        [string]$Profile
    )
    
    # Check if the firewall is enabled for the profile
    $firewallStatus = (Get-NetFirewallProfile -Profile $Profile).Enabled
    if ($firewallStatus -eq "False") {
        # Enable the firewall for the profile
        Set-NetFirewallProfile -Profile $Profile -Enabled True
        Write-Output "Firewall enabled for $Profile profile."
    } else {
        Write-Output "Firewall already enabled for $Profile profile."
    }
}

# Enable firewall for Domain, Private, and Public profiles
Enable-Firewall -Profile "Domain"
Enable-Firewall -Profile "Private"
Enable-Firewall -Profile "Public"

# Check the status after enforcing to log results
$firewallStatusAfter = Get-NetFirewallProfile | Select-Object Name, Enabled
Write-Output "Firewall status after enforcement:"
$firewallStatusAfter | ForEach-Object { Write-Output "$($_.Name): $($_.Enabled)" }

Stop-Transcript