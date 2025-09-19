<#
.SYNOPSIS
    Gets Windows activation status

.DESCRIPTION
    Simple script to get the status of Windows activation.

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
    Lee Burridge (lburridge@centrality.com)

.DATE
    25th April 2024
#>

try {
# Insert code here
    $ospp = Get-WmiObject -Query 'select * from SoftwareLicensingProduct where (PartialProductKey is not null) and (LicenseStatus = 1)'
    if ($ospp -ne $null) {
        Write-Output "Windows is activated."
        Exit 0
    } else {
        Write-Output "Windows is not activated."
        Exit 1
    }

}

catch {
    write-output "An Error occured"
}

