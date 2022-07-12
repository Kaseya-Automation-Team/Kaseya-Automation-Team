## This script downloads and silently installs latest version of Dropbox Offline installer from the official website

#Define variables
$AppName = "Audacity"
$AppFullName = "Audacity*"
$URL = "https://dl2.boxcloud.com/d/1/b1!qAMdcJr9Cn448sQH3FjIV9iFu7X7RhDOWYLXki3RLLJ4yOIFvq7yh19udO6-3cxWEBmz3-FE1mNMPDXmw7b815Ie8MELGg4-hSjbXNFP1w-HxBcALdg-xpotOkiFsSexawA5SDwP1AMJ5W_A3r4ofDrZ1O9nM0TrfPuq7rGNtAg7-eV0nWsS_FwO9idu116T9ieCEVd36hTkxw5KkN_xaGb1b20IDhqBu0TQscaAl1OBgIqxCwAJaKjfpYpuzTO7BklHOSlLVSFwX1Mmvpx_T6W2cwpHZ6WfMTUBdNvlY9xWjnnW6s5bZJlf298DnRg2dZjH18kka1cXAguksOWrtXFA3E4YO5o3Rk-qQAHPhV9T1w4i3jJ6HDu7OMkOSoi7eFxVUZCgFQXlSJbxWu9hmSg5qfmoxxkWrnqEU7394Br-HXcWibwBnA4-axtWsUvLmmmP2rFjIFXwvJgFuv7RZwXjKrRajc2MK6SQ25ix9UF4lG0iN8WtNNkJcSyOMaeyg8kfvUwWr5wxjsElfg17uc-i7uW3jesyQRBDT5uTsXYING8_Fc5ukMDq1vXauJ3B8nfYdYVFySEnkUDk2KNji9qXCn6OQMG5ET9S_IqC3J7n-vCKaHr0JZoeJVF4BqXSJlTQCPWbjDZkaJKloLuRC1vi4nq1hGLHtrNSMlNi5ELomO5tt2z1Ldk8fKVUL8Flp9WGAAb3KE3-EDu20clQaJglBU5lCIda20fG10goMSpD3JTt6roCBU47J5Cwcof0EYigJmVAOy521oZnkFQP0G5cZS0dMcF-3HbveRNv3vjRGHqIZGcc0iQjy0ekU5XsdBDFMI3dEzgdknhUiu0f2tUxezhMSbNeIUsoUH83Ng3_6MO7i4FvKwbXtDF9ACNo3n9j-J9vYAR3YGQI85FPXr3sBjbTDoy80nW8G2oh0uVYw5yt4XfNY0bxV8BbzkyJ7R3OCkJcMLbjDIFGCiTdI0QrjYSDmiYl_hJE4YkIj2Bv0fYy9w4J85r2CB7-CLnSyKYcYEIzJi-z50RPqDy0LANBwhpR25r_z7JtsfG6Qq3AGKcMj1XteYkWGLJSWDqkMHpckYCqWNS3UmDAEp34bFEeSsH7ET5ZyhOYz6cP4n7rMenr1duz6_YjMrBpTQsFFfznEJts5RwoMw-ki6JQPf7lzuE-JHoX-9uylFMbBH3xRvpBD_35R22AsrzM9dWZB4IyyqNYsTGXIaWPaYQzLJf5mSCrgH1XbUxdAl8BPm2YWkjho6VE_xdT52a4rGF3AgPqzwcWlbRa-9cWbkxy9VO1YQ../download"
$Destination = "$env:TEMP\audacity.exe"

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

function Get-RegistryRecords {
    Param($productDisplayNameWithWildcards)

    $machine_key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $machine_key6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

    return Get-ItemProperty -Path @($machine_key, $machine_key6432) -ErrorAction SilentlyContinue |
           Where-Object {
              $_.DisplayName -like $productDisplayNameWithWildcards
           } | Sort-Object -Property @{Expression = {$_.DisplayVersion}; Descending = $True} | Select-Object -First 1
}


#Lookup related records in Windows Registry to check if application is already installed
function Test-IsInstalled(){
    return Get-RegistryRecords($AppFullName);
}

#Start download
function Get-Installer($URL) {

    Write-Host "Downloading $AppName installer."
	$ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $URL -OutFile "$Destination"

    if (Test-Path -Path $Destination) {

        Start-Install
    } else {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download $AppName installation file.", "Error", 400)
    }
}

#Execute installer
function Start-Install() {

    Write-Host "Starting $AppName installation."
    Start-Process -FilePath $Destination -ArgumentList "/VERYSILENT /NORESTART" -Wait
}

#Delete installation file
function Start-Cleanup() {

    Write-Host "Removing installation files."
    Remove-Item -Path $Destination -ErrorAction SilentlyContinue
}

#If application is not installed yet, continue with installation
if (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName is already installed on the target computer, not proceeding with installation.", "Warning", 300)
    Write-Host "$AppName is already installed on the target computer, not proceeding with installation."

    break

} else {
    
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName installation process has been initiated by VSA X script", "Information", 200)

    Get-Installer($URL)
    Start-Cleanup
    
    Start-Sleep -s 10

    $Installed = Test-IsInstalled

    #Verify that application has been successfully installed
    if ($null -eq $Installed) {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Couldn't install $AppName on the target computer.", "Error", 400)
        Write-Host "Couldn't install $AppName on the target computer."

    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName has been successfully installed.", "Information", 200)
        Write-Host "$AppName has been successfully installed."
    }
}