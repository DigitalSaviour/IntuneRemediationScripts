# Remediation script for Intune

# Function to uninstall old Teams
function Uninstall-ClassicTeams {
    $classicTeamsProcesses = Get-Process -Name Teams -ErrorAction SilentlyContinue
    if ($classicTeamsProcesses) {
        $classicTeamsProcesses | Stop-Process -Force
    }

    $classicTeamsInstaller = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "Microsoft Teams*" }
    if ($classicTeamsInstaller) {
        $classicTeamsInstaller.Uninstall()
    }

    # Remove Teams folder if exists
    $teamsFolder = "C:\Program Files (x86)\Microsoft\Teams"
    if (Test-Path $teamsFolder) {
        Remove-Item $teamsFolder -Recurse -Force
    }
    $classicTeamsMWI = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse | Get-ItemProperty | Where-Object { $_.DisplayName -match "Teams Machine-Wide Installer" }

    if ($classicTeamsMWI) {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($classicTeamsMWI.PSChildName) /quiet /norestart" -Wait -NoNewWindow
    }

    # Uninstall Classic Teams for all users
    Get-AppxPackage "Microsoft.Teams" -AllUsers | Remove-AppxPackage
}

# Function to install New Teams
function Install-NewTeams {
    # Download the Teams Bootstrapper (adjust URL as per latest version)
    $teamsBootstrapperUrl = "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409"
    $installerPath = "$env:TEMP\TeamsBootstrapper.exe"
    
    Invoke-WebRequest -Uri $teamsBootstrapperUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "-p" -Wait -NoNewWindow
    Remove-Item $installerPath
}

# Main Execution
Uninstall-ClassicTeams
Install-NewTeams

Write-Output "Remediation completed."