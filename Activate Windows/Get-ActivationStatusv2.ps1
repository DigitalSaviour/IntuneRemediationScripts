<#
.SYNOPSIS
    Detects if Windows is activated.

.DESCRIPTION
    This script runs the slmgr.vbs /xpr command to check Windows activation status.
    If the output indicates that Windows is "permanently activated", the script
    exits with code 0 (indicating compliance). If activation is not confirmed,
    the script exits with code 1, which can trigger remediation via Intune.

.NOTES
    - Ensure the script is run with administrative privileges.
    - Adjust text matching if your environment displays a different activation string.
#>

function Get-SlmgrOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Arguments
    )
    # Run slmgr.vbs using cscript.exe and capture output
    $output = & cscript.exe //Nologo "$env:windir\system32\slmgr.vbs" $Arguments 2>&1 | Out-String
    return $output
}

# Check current activation status
Write-Host "Checking Windows activation status..."
$activationOutput = Get-SlmgrOutput -Arguments "/xpr"
Write-Host $activationOutput

# Determine activation status.
# This check looks for the phrase "permanently activated" in the output.
if ($activationOutput -match "permanently activated") {
    Write-Host "OK - Device is activated."
    exit 0
}
else {
    Write-Host "ISSUE - Device is not activated."
    exit 1
}
