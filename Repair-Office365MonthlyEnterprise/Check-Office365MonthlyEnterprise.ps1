# Title : Check-Office365MonthlyEnterprise.ps1
# Creation : 22/01/2024
# Author : Lee Burridge
# Description : Checks a device to make sure the update branch has been set 

# Using transcript to log to IME folder for the overall script
Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Check-Office365MonthlyEnterprise.log

$item = get-itempropertyvalue 'HKLM:\Software\Policies\Microsoft\office\16.0\common\officeupdate' 'updatebranch'

if ($item -eq 'MonthlyEnterprise') {
	Write-Output "Compliant"
	Stop-Transcript

	Exit 0
} else {
	Write-Warning "Not Compliant"
	Stop-Transcript

	Exit 1
}
