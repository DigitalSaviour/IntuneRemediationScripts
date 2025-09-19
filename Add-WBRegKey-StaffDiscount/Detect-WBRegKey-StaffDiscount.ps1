$registryPath = "HKLM:\SOFTWARE\WOW6432Node\Positive\Office\InventoryEngineReports\Departmental Profit Control Report"
$name = "ExampleKeyStaffMealDiscountIds"
$value = "15,16"

try {
    $currentValue = Get-ItemProperty -Path $registryPath -Name $name -ErrorAction Stop | Select-Object -ExpandProperty $name
    if ($currentValue -eq $value) {
        Write-Output "Compliant"
        Exit 0
    } else {
        Write-Warning "Not Compliant"
        Exit 1
    }
} catch {
    Write-Warning "Not Compliant"
    Exit 1
}