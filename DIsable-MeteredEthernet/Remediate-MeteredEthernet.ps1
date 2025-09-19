# Complete the $scriptname and $scriptver variables below - these will be used to populate the filename of the log
$scriptname = "Remediate-MeteredEthernet"
$scriptver = "1.1"

Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$scriptname-$scriptver.log

try {
    # Get all network connections
    $connections = Get-NetConnectionProfile

    # Loop through each connection
    foreach ($connection in $connections) {
        # Check if the connection is Ethernet
        if ($connection.InterfaceAlias -like "*Ethernet*") {
            # Check if the connection is metered
            if ($connection.MeteredNetwork -eq "True") {
                # Change the Ethernet connection to not use a metered connection
                Set-NetConnectionProfile -InterfaceAlias $connection.InterfaceAlias -MeteredNetwork $false
                Write-Output "The Ethernet connection '$($connection.InterfaceAlias)' is now set to not use a metered connection."
            } else {
                Write-Output "The Ethernet connection '$($connection.InterfaceAlias)' is already set to not use a metered connection."
            }
        }
    }
} catch {
    Write-Warning "An error occurred: $_"
} finally {
    Stop-Transcript
}