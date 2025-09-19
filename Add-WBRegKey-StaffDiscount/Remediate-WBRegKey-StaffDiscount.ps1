$registryPath = "HKLM:\SOFTWARE\WOW6432Node\Positive\Office\InventoryEngineReports\Departmental Profit Control Report"
$name = "ExampleKeyStaffMealDiscountIds"
$value = "15,16"
$type = "DWORD"

try {
    if (!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    Set-ItemProperty -Path $registryPath -Name $name -Value $value -Type $type -Force | Out-Null
    Write-Output "Key set: $name = $value"
    Exit 0
} catch {
    Write-Error $_
    Exit 1
}