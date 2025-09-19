# Push a Windows product code when it hasn't activated by itself. The code below 
# is one used for Connect devices

# Only use this for SBS as it is the Education activation key

# Author : Lee Burridge 
# Date   : 03/02/2025

# Define the log file location
$logFile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Activate-SBS-Windows.log"

# Function to write output to both console and log file
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = "$timestamp - $message"
    Write-Output $fullMessage
    Add-Content -Path $logFile -Value $fullMessage
}

# Clear the log file before starting (optional)
Clear-Content $logFile -ErrorAction SilentlyContinue

# Log the start of the activation process
Write-Log "Starting Windows activation..."

# Define the product key
$key="JKNMX-3WD9G-PGD9V-4DHGT-PDMMQ"

# Activate Windows
(Get-WmiObject -query 'select * from SoftwareLicensingService').InstallProductKey($key)
(Get-WmiObject -query 'select * from SoftwareLicensingService').RefreshLicenseStatus()
(Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey

cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /dli

Write-Log "Windows activated completed"

# End of script