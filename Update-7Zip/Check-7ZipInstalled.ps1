# Check if 7Zip is installed for use as remediation in Update-7Zip

$commonPaths = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )
    
foreach ($path in $commonPaths) {
    if (Test-Path -Path $path) {
        Write-Output "7-Zip is installed at $path"

        # 7-Zip is installed
        Exit 1
    }
}

# 7-Zip is not installed
Write-Output "7-Zip not detected"
Exit 0