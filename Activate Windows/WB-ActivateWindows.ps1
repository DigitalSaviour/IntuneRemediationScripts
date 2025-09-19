# Push a Windows product code when it hasn't activated by itself. The code below 
# is one used for Connect devices

# Author : Lee Burridge 
# Date   : 04/09/2024

# Define the log file location
$logFile = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Activate-Windows.log"

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

# Install the product key
Write-Log "Installing product key..."
Invoke-Expression "cscript /nologo c:\windows\system32\slmgr.vbs /ipk PW9RJ-PBN3P-QKQR4-6RBHH-7QWWR"

# Activate Windows
Write-Log "Activating Windows..."
Invoke-Expression "cscript /nologo c:\windows\system32\slmgr.vbs /ato"

# Pause for a few seconds to ensure the activation process completes
Start-Sleep -Seconds 10

# Check the activation status
Write-Log "Checking activation status..."
$licenseStatus = (Invoke-Expression "cscript /nologo c:\windows\system32\ slmgr.vbs /dli" | Select-String "License Status").ToString()

# Determine if Windows is activated
if ($licenseStatus -like "*Licensed*") {
    Write-Log "Windows is activated successfully."
} else {
    Write-Log "Windows activation failed. Status: $licenseStatus"
}

Invoke-Expression "cscript /nologo c:\windows\system32\slmgr.vbs /xpr"

# Log the completion time
Write-Log "Activation check complete."
