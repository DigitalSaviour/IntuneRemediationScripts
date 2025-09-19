# Detection script for retrieving Microsoft Office product key using ospp.vbs in Intune
try {
    # Path to ospp.vbs (common locations for Office installations)
    $osppPath = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Microsoft Office\Office16\ospp.vbs"
    if (-not (Test-Path $osppPath)) {
        $osppPath = Join-Path -Path $env:ProgramFiles -ChildPath "Microsoft Office\Office16\ospp.vbs"
    }

    # Verify ospp.vbs exists
    if (-not (Test-Path $osppPath)) {
        Write-Output "ospp.vbs not found in expected Office installation paths."
        exit 1
    }

    # Run ospp.vbs with cscript to get product key information
    $command = "cscript //NoLogo `"$osppPath`" /dstatus"
    $output = Invoke-Expression -Command $command

    # Parse output to extract the last 5 characters of the product key
    $productKey = $output | Select-String -Pattern "Last 5 characters of installed product key: (\w{5})"
    if ($productKey) {
        $keyFragment = $productKey.Matches.Groups[1].Value
        Write-Output "Office Product Key (Last 5 Characters): $keyFragment"
    } else {
        Write-Output "No Office product key found."
    }

    exit 0
}
catch {
    # Log error and exit with non-zero code for Intune to mark as failed
    Write-Output "Error retrieving Office product key: $($_.Exception.Message)"
    exit 1
}