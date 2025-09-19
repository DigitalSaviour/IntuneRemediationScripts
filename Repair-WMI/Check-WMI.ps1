# Title : Check-WMI.ps1
# Creation : 11/01/2024
# Author : Lee Burridge
# Description : This script checks to see if WMI needs rebuilding

# Test the WMI repository for consistency

Try {
    $repositoryStatus = (get-service winmgmt | select Status)

    if ($repositoryStatus.Status -eq "Running") {
        Write-Output "WMI repository is consistent."
        Exit 0
    } else {
        Write-Output "WMI repository is inconsistent and may need rebuilding."
        Exit 1
    }
}

Catch {
    Write-Warning "Error encountered"
    Exit 1
}
