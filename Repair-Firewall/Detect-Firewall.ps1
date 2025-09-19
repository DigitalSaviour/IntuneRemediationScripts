# Script to check firewall status across all network profiles
# Returns 0 if the firewall is enabled for all profiles (Domain, Private, and Public)
# Returns 1 if any profile has the firewall disabled

# Check the firewall status for each network profile
$firewallStatus = Get-NetFirewallProfile | Select-Object -Property Name, Enabled

# Initialize a variable to track firewall compliance
$firewallEnabled = $true

foreach ($profile in $firewallStatus) {
    if (-not $profile.Enabled) {
        # If any profile has the firewall disabled, set $firewallEnabled to false
        $firewallEnabled = $false
    }
}

# Exit with appropriate code
if ($firewallEnabled) {
    # Firewall is enabled on all profiles
    Write-Output "Firewall is enabled on all profiles."
    exit 0  # Success
} else {
    # Firewall is disabled on one or more profiles
    Write-Output "Firewall is not enabled on all profiles."
    exit 1  # Failure
}
