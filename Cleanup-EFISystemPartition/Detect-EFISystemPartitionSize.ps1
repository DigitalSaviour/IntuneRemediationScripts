# Dynamically find EFI partition (assumes GPT disk, System type)
$efiPartition = Get-Partition | Where-Object { $_.Type -eq 'System' }
if (-not $efiPartition) {
    Write-Output "EFI partition not found."
    exit 0  # No remediation if no EFI
}

$driveLetter = 'Y'
$fontsPath = "$($driveLetter):\EFI\Microsoft\Boot\Fonts"

# Create diskpart script to mount EFI
$diskpartScript = @"
select disk $($efiPartition.DiskNumber)
select partition $($efiPartition.PartitionNumber)
assign letter=$driveLetter
exit
"@

$scriptPath = "$env:TEMP\dp_detect.txt"
$diskpartScript | Set-Content -Path $scriptPath -Encoding ASCII

try {
    Start-Process -FilePath "diskpart.exe" -ArgumentList "/s `"$scriptPath`"" -Wait -NoNewWindow -ErrorAction Stop
    Start-Sleep -Seconds 2
} catch {
    Write-Output "Failed to mount EFI: $($_.Exception.Message)"
    exit 0
}

# Check for font files
try {
    if (Test-Path $fontsPath) {
        $fontFiles = Get-ChildItem $fontsPath -File -ErrorAction Stop
        if ($fontFiles) {
            Write-Output "Font files exist. Remediation needed."
            exit 1
        } else {
            Write-Output "No font files found. No remediation needed."
            exit 0
        }
    } else {
        Write-Output "Fonts path does not exist. No remediation needed."
        exit 0
    }
} catch {
    Write-Output "Error checking fonts: $($_.Exception.Message)"
    exit 0
} finally {
# Unmount regardless
$unmountScript = @"
select disk $($efiPartition.DiskNumber)
select partition $($efiPartition.PartitionNumber)
remove letter=$driveLetter
exit
"@

    $unmountPath = "$env:TEMP\dp_unmount.txt"
    $unmountScript | Set-Content -Path $unmountPath -Encoding ASCII
    Start-Process -FilePath "diskpart.exe" -ArgumentList "/s `"$unmountPath`"" -Wait -NoNewWindow
}