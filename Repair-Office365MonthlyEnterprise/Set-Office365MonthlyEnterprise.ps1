# Title : Set-Office365MonthlyEnterprise.ps1
# Creation : 22/01/2024
# Author : Lee Burridge
# Description : This script will update the reg key to Monthly Enterprise update 
#   for Office 365 and then force an update. 

# Using transcript to log to IME folder for the overall script
Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Office365MonthlyEnterprise.log

# Force the office update branch to Monthly Enterprise in case it is set wrong.
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" -Name 'updatebranch' -value 'MonthlyEnterprise'
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" -Name 'enableautomaticupdates' -type binary -value 0x1

# Restart the Click To Run service in case it's in a failed state
Restart-Service "ClickToRunSvc"

# Run the update
cd 'C:\Program Files\Common Files\microsoft shared\ClickToRun'
Start-Process .\OfficeC2RClient.exe -ArgumentList "/update user"

Stop-Transcript

