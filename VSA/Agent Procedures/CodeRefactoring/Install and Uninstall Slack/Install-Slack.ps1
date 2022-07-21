#This script installs Slack on the target machine

Function Get-InstallStatus {

    Return  (Get-Package | Where-Object {$_.Name -eq "Slack"} | Select-Object -Property Status).Status

}

# Source file location
$source64 = 'https://slack.com/ssb/download-win64'
$source32 = 'https://slack.com/ssb/download-win'

# Destination to save the file
$destination = "$env:TEMP\SlackSetup.exe"

$status = Get-InstallStatus

if ($Status -ne "Installed") {
     
     Write-Output "Slack is not installed on this computer and proceeding with the insallation steps!"

     #Check to see if windows is 64 bit or 32 bit
     if ($env:PROCESSOR_ARCHITECTURE -match "64") {

        $source = $source64
     }

     else {

        $source = $source32

     }

     #Download the file
     Invoke-WebRequest -Uri $source -OutFile $destination

     #Run the install command
     Start-Process -FilePath $destination -ArgumentList '-S'
     Start-Sleep -Seconds 20


     #Deleting the installer
     Remove-Item -Path $destination -Force

     #Check the install status again
     $status = Get-InstallStatus


    if ($Status -eq "Installed") {
        Write-Output "Installation has been successully completed"
        eventcreate /L Application /T INFORMATION /SO VSA X /ID 200 /D "Slack has been installed by VSA X agent!" | Out-Null
    } else {
        Write-Output "Installation could not be completed"
    }

 }

# If Slack is already installed, show the message and do nothing.
 else {

    Write-Output "Slack is already installed on this computer"
 }


