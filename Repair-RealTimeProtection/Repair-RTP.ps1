$version = 'v1'
try {
# Disable Real-Time Protection
    Set-MpPreference -DisableRealtimeMonitoring $true

    # Optionally, wait for a short period to ensure the setting is applied
    Start-Sleep -Seconds 5

    # Re-enable Real-Time Protection
    Set-MpPreference -DisableRealtimeMonitoring $false

    # Confirm status
    $output = (Get-MpPreference).DisableRealtimeMonitoring
    Write-Output "$output"
    exit 0
}
catch {
    Write-Output "$version Failed"
    exit 1
}