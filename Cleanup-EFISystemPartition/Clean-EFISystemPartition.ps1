# PowerShell script to clean up the EFI System Partition for Windows 11 24H2 upgrade
# Requires administrative privileges
#
# Written by: lee.burridge@intercity.technology (original), revised by Grok (xAI)
# Date: September 12, 2025
# Version: 1.0

# Set up logging
$LogFile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\EFICleanup.log"
$BackupDir = "C:\OSInst\EFIBackup"
$MinFreeSpaceMB = 50  # Minimum free space for Windows 11 24H2

function Write-Log {
    param($Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append
}

# Ensure backup directory exists
if (-not (Test-Path $BackupDir)) {
    New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
    Write-Log "Created backup directory: $BackupDir"
}

try {
    Write-Log "Starting EFI System Partition cleanup."

    # Identify the EFI System Partition
    $EFIPartition = Get-Partition | Where-Object { $_.Type -eq "System" }
    if (-not $EFIPartition) {
        Write-Log "ERROR: Could not identify EFI System Partition."
        exit 1
    }
    $DiskNumber = $EFIPartition.DiskNumber
    $PartitionNumber = $EFIPartition.PartitionNumber
    Write-Log "EFI System Partition found: Disk $DiskNumber, Partition $PartitionNumber"

    # Check partition details
    $PartitionDetails = Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber
    if (-not $PartitionDetails) {
        Write-Log "ERROR: Unable to retrieve details for EFI System Partition."
        exit 1
    }
    Write-Log "Partition details: Size $($PartitionDetails.Size / 1MB) MB, Type $($PartitionDetails.Type)"

    # Choose a drive letter (try Z, fall back to Y)
    $MountPoint = "Z"
    $FallbackMountPoint = "Y"
    if (Get-PSDrive -Name $MountPoint -ErrorAction SilentlyContinue) {
        Write-Log "WARNING: Drive letter $MountPoint is already in use. Trying $FallbackMountPoint."
        $MountPoint = $FallbackMountPoint
        if (Get-PSDrive -Name $MountPoint -ErrorAction SilentlyContinue) {
            Write-Log "ERROR: Fallback drive letter $MountPoint is also in use."
            exit 1
        }
    }

    # Mount the EFI partition
    $MountScript = @"
select disk $DiskNumber
select partition $PartitionNumber
assign letter=$MountPoint
"@
    New-Item -Path "C:\OSInst\BuildLogs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    $MountScript | Out-File -FilePath "C:\OSInst\BuildLogs\mount.txt" -Encoding ASCII
    $DiskPartResult = diskpart /s "C:\OSInst\BuildLogs\mount.txt"
    Write-Log "DiskPart mount result: $DiskPartResult"

    # Verify mount
    $RetryCount = 0
    $MaxRetries = 10
    $Drive = $null
    while ($RetryCount -lt $MaxRetries -and -not $Drive) {
        Start-Sleep -Seconds 3
        $Drive = Get-PSDrive -Name $MountPoint -ErrorAction SilentlyContinue
        $RetryCount++
        Write-Log "Retry $RetryCount/$MaxRetries: Checking for drive $MountPoint"
    }

    if (-not $Drive -or -not (Test-Path "$MountPoint`:\") -or -not (Test-Path "$MountPoint`:\EFI")) {
        Write-Log "ERROR: Failed to mount EFI partition or access $MountPoint`:\EFI. Drive found: $([bool]$Drive)"
        exit 1
    }
    Write-Log "Successfully mounted EFI partition to $MountPoint. Filesystem: $($Drive.Provider.Name)"

    # Calculate free space before cleanup
    $FreeSpaceBefore = $Drive.Free / 1MB
    Write-Log "Free space before cleanup: $FreeSpaceBefore MB"

    # Analyze space usage
    $EFIFiles = Get-ChildItem -Path "$MountPoint`:\EFI" -Recurse -ErrorAction SilentlyContinue
    $SpaceUsage = $EFIFiles | Measure-Object -Property Length -Sum
    Write-Log "Total space used by files in $MountPoint`:\EFI: $($SpaceUsage.Sum / 1MB) MB"

    # Backup critical EFI files
    $CriticalPaths = @("$MountPoint`:\EFI\Boot", "$MountPoint`:\EFI\Microsoft")
    foreach ($Path in $CriticalPaths) {
        if (Test-Path $Path) {
            $BackupPath = Join-Path $BackupDir (Split-Path $Path -Leaf)
            Copy-Item -Path $Path -Destination $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Backed up $Path to $BackupPath"
        }
    }

    # Define non-critical directories and files to remove (exclude Microsoft and Boot)
    $NonCriticalDirs = Get-ChildItem -Path "$MountPoint`:\EFI" -Directory | Where-Object {
        $_.Name -notmatch "Microsoft|Boot"
    }
    $NonCriticalFiles = Get-ChildItem -Path "$MountPoint`:\EFI" -Recurse -File -Include "*.log", "*.tmp", "*.old", "*.bak" -ErrorAction SilentlyContinue

    # Remove non-critical directories
    foreach ($Dir in $NonCriticalDirs) {
        try {
            Remove-Item -Path $Dir.FullName -Recurse -Force -ErrorAction Stop
            Write-Log "Removed non-critical directory: $($Dir.FullName)"
        } catch {
            Write-Log "WARNING: Failed to remove directory $($Dir.FullName): $_"
        }
    }

    # Remove non-critical files
    foreach ($File in $NonCriticalFiles) {
        try {
            Remove-Item -Path $File.FullName -Force -ErrorAction Stop
            Write-Log "Removed file: $($File.FullName)"
        } catch {
            Write-Log "WARNING: Failed to remove $($File.FullName): $_"
        }
    }

    # Remove empty directories
    Get-ChildItem -Path "$MountPoint`:\EFI" -Recurse -Directory | Where-Object {
        (Get-ChildItem -Path $_.FullName -Recurse -File).Count -eq 0
    } | ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Force -ErrorAction Stop
            Write-Log "Removed empty directory: $($_.FullName)"
        } catch {
            Write-Log "WARNING: Failed to remove empty directory $($_.FullName): $_"
        }
    }

    # Calculate free space after cleanup
    $DriveAfter = Get-PSDrive -Name $MountPoint -ErrorAction SilentlyContinue
    $FreeSpaceAfter = if ($DriveAfter) { $DriveAfter.Free / 1MB } else { $FreeSpaceBefore }
    Write-Log "Free space after cleanup: $FreeSpaceAfter MB"
    Write-Log "Space freed: $($FreeSpaceAfter - $FreeSpaceBefore) MB"

    # Unmount the EFI partition
    $UnmountScript = @"
select disk $DiskNumber
select partition $PartitionNumber
remove letter=$MountPoint
"@
    $UnmountScript | Out-File -FilePath "C:\OSInst\BuildLogs\unmount.txt" -Encoding ASCII
    diskpart /s "C:\OSInst\BuildLogs\unmount.txt" | Out-Null
    Write-Log "Unmounted EFI partition from $MountPoint"

    # Clean up temporary files
    Remove-Item -Path "C:\OSInst\BuildLogs\mount.txt" -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\OSInst\BuildLogs\unmount.txt" -ErrorAction SilentlyContinue

    # Verify sufficient free space
    if ($FreeSpaceAfter -lt $MinFreeSpaceMB) {
        Write-Log "WARNING: Free space ($FreeSpaceAfter MB) is below recommended $MinFreeSpaceMB MB for Windows 11 24H2 upgrade."
        exit 1
    } else {
        Write-Log "Sufficient free space ($FreeSpaceAfter MB) for Windows 11 24H2 upgrade."
    }

    Write-Log "EFI System Partition cleanup completed successfully."
    exit 0
} catch {
    Write-Log "ERROR: $_"
    exit 1
} finally {
    # Ensure partition is unmounted even on failure
    if (Get-PSDrive -Name $MountPoint -ErrorAction SilentlyContinue) {
        $UnmountScript | Out-File -FilePath "C:\OSInst\BuildLogs\unmount.txt" -Encoding ASCII
        diskpart /s "C:\OSInst\BuildLogs\unmount.txt" | Out-Null
        Write-Log "Unmounted EFI partition in finally block."
        Remove-Item -Path "C:\OSInst\BuildLogs\unmount.txt" -ErrorAction SilentlyContinue
    }
}