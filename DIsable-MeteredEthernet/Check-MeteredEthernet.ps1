# Get all network connections
$connections = Get-NetConnectionProfile

# Find the Ethernet connection
$ethernet = $connections | Where-Object { $_.InterfaceAlias -eq "Ethernet" }

# Use a try-catch block to handle potential errors
try {
    # Check if the Ethernet connection is set to metered
    if ($ethernet.MeteredNetwork -eq "True") {
        # Change the Ethernet connection to not use a metered connection
        #Set-NetConnectionProfile -InterfaceAlias "Ethernet" -MeteredNetwork $false
        Write-Output "Metered interface detected"
        Exit 1
    } else {
        Write-Output "No metered interfaces detected"
    }
} catch {
    Write-Output "An error occurred, but it was handled."
}

Exit 0