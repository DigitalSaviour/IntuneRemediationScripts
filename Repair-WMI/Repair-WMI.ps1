# Title : Repair-WMI.ps1
# Creation : 11/01/2024
# Modified : 17/01/2025
# Author : Lee Burridge
# Description : This script repairs the WMI repository and re-registers WMI-related DLLs.

# Using transcript to log to IME folder for the overall script
Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Repair-WMI.log


# Set VSS to demand start 
Set-Service -Name vss -StartupType Manual
Set-Service -Name SMPHost -StartupType Manual

Stop-Service -Name SMPHost
Stop-Service -Name vss

# Stop the WMI Service
Stop-Service -Name Winmgmt -Force

# Rename the repository folder
Rename-Item -Path "C:\WINDOWS\system32\wbem\Repository" -NewName "Repository.old"

# Re-register all the dlls
Get-ChildItem -Path "C:\WINDOWS\system32\wbem" -Filter "*.dll" -Recurse | ForEach-Object {
    Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s $($_.FullName)" -Wait -NoNewWindow
}

# Set the WMI Service type back to Automatic and restart WMI Service
Set-Service -Name Winmgmt -StartupType Automatic
Start-Service -Name Winmgmt

# Change to the root of the C drive
Set-Location -Path "C:\"

# Recompile the MOFs for 2012 Clustered servers
Get-ChildItem -Path "C:\" -Filter "*.mof","*.mfl" -Recurse | Where-Object { $_.FullName -notmatch "uninstall" } | ForEach-Object {
    Start-Process -FilePath "mofcomp.exe" -ArgumentList "$($_.FullName)" -Wait -NoNewWindow
}

# Restart WMI service
Restart-Service -Name Winmgmt

Stop-Transcript
