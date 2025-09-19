# Description: This script checks if the device is encrypted with BitLocker.
# Author: Lee Burridge (Intercity)
# Version: 1.0
# Created Date: 2025-02-06
# Updated Date: 2025-02-06

$Namespace = "Root\CIMv2\Security\MicrosoftVolumeEncryption"
if (Get-WmiObject -Namespace $Namespace -Class Win32_EncryptableVolume -ErrorAction SilentlyContinue) {
    exit 0
} else {
    exit 1
}
