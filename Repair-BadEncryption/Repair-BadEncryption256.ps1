<#
.SYNOPSIS
    Script to remediate BitLocker encryption issues by decrypting and re-encrypting the specified volume.

.DESCRIPTION
    This script is designed to address issues with BitLocker encryption by first decrypting the specified volume and then re-encrypting it using Intune policies. 
    The script logs all actions and progress to a specified log file.

.PARAMETER $volume
    The drive letter of the volume to be decrypted and re-encrypted. Default is "C:".

.PARAMETER $logPath
    The path to the log file where script actions and progress will be recorded.

.FUNCTIONS
    Log-Message
        Logs a message with a timestamp to the log file.

    Check-BitLocker
        Checks if the specified volume is encrypted and, if so, decrypts it. Logs progress and errors.

    Fix-BitLocker
        Re-encrypts the specified volume using Intune policies. Removes existing key protectors, adds a recovery password protector, and backs up the recovery password to Azure Active Directory. Logs progress and errors.

.EXAMPLE
    .\Repair-BadEncryption256.ps1
    Runs the script to remediate BitLocker encryption issues on the C: drive.

.NOTES
    Author: Lee Burridge
    Version: 1.0
    Date: 4/2/2024

    Ensure that the script is run with administrative privileges.
    Modify the $volume variable if targeting a different drive.
#>
$scriptname = "Repair-BadEncryption"
$scriptver = "1.0"

$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$scriptname-$scriptver.log"

$volume = "C:"  # Change this if targeting a different drive

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Output $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

# Function to disable BitLocker
function Check-BitLocker {
    try {
        Log-Message "Starting decryption of drive $volume."
	
	if ((Get-BitLockerVolume -MountPoint $volume).EncryptionPercentage -eq 0) {
		Log-Message "Drive is already decrypted."
		return $true
	}

        Disable-BitLocker -MountPoint $volume
        Log-Message "Decryption command issued for drive $volume. Waiting for completion..."
        while ((Get-BitLockerVolume -MountPoint $volume).EncryptionPercentage -gt 0) {
            Start-Sleep -Seconds 30
            Log-Message "Decryption in progress... Current encryption percentage: $((Get-BitLockerVolume -MountPoint $volume).EncryptionPercentage)%."
            
            # Put this in every loop to make sure that it runs in certain scenarios
            # where it misses the first Disable-Bitlocker call
            Disable-BitLocker -MountPoint $volume
        }
        Log-Message "Drive $volume successfully decrypted."
        return $true
    } catch {
        Log-Message "Error during decryption: $_"
        return $false
    }
}


# Function to re-enable BitLocker
function Fix-BitLocker {
    try {
        Log-Message "Starting re-encryption of drive $volume with Intune policies."

	# Retrieve all key protectors for the specified volume
	$keyProtectors = Get-BitLockerVolume -MountPoint $volume | Select-Object -ExpandProperty KeyProtector

	# Loop through each key protector and remove it
	foreach ($keyProtector in $keyProtectors) {
    	try {
        	Remove-BitLockerKeyProtector -MountPoint $volume -KeyProtectorId $keyProtector.KeyProtectorId
        	Log-Message "Successfully removed key protector: $($keyProtector.KeyProtectorId)"
    	} catch {
        	Log-Message "Error removing key protector: $_"
    		}
	}
        # Modify the encryption method to match your Intune policy if needed
	#Add a recovery password protector to the C: drive
	Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector
        Enable-BitLocker -MountPoint $volume -EncryptionMethod XtsAes256 -UsedSpaceOnly -SkipHardwareTest -TpmProtector
        Log-Message "Re-encryption command issued for drive $volume. Waiting for completion..."
        while ((Get-BitLockerVolume -MountPoint $volume).EncryptionPercentage -lt 100) {
            Start-Sleep -Seconds 30
            Log-Message "Re-encryption in progress... Current encryption percentage: $((Get-BitLockerVolume -MountPoint $volume).EncryptionPercentage)%."
        }
        Log-Message "Drive $volume successfully re-encrypted."

        #Get the BitLocker volume object for the C: drive
        $BLV = Get-BitLockerVolume -MountPoint C:

        #Backup the recovery password protector to Azure Active Directory
        BackupToAAD-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId

        return $true
    } catch {
        Log-Message "Error during re-encryption: $_"
        return $false
    }
}

# Main Execution
Log-Message "BitLocker remediation script started."
if (Check-BitLocker) {
    Fix-BitLocker
} else {
    Log-Message "Failed to decrypt the drive. Aborting re-encryption process."
}

Log-Message "Remediation script execution completed."
