## This script silently uninstalls Zoom from the computer

#Define varibles
$AppName = "Zoom"
$AppNameWithWildCard = "Zoom(*bit)"
$URL = "https://assets.zoom.us/docs/msi-templates/CleanZoom.zip"
$Destination = "$env:TEMP\CleanZoom.zip"

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
    return Get-RegistryRecords($AppNameWithWildCard);
}

#Delete installation file
function Start-Cleanup() {

    Write-Host "Removing uninstaller."
    Remove-Item -Path $Destination -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:TEMP\CleanZoom.exe" -ErrorAction SilentlyContinue
}

[System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName uninstall process has been initiated by VSA X script.", "Information", 200)

#If application is installed, continue with uninstall
If (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName was detected. Starting uninstall process.", "Information", 200)
    Write-Host "$AppName was detected. Starting uninstall process."

    Write-Host "Downloading $AppName uninstaller."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $URL -OutFile "$Destination"

    [System.IO.Compression.ZipFile]::ExtractToDirectory($Destination, "$env:TEMP")

    
    if (Test-Path -Path "$env:TEMP\CleanZoom.exe") {

        
        Start-Process -FilePath "$env:TEMP\CleanZoom.exe" -ArgumentList "/silent" -Wait
        Start-Sleep -s 10
        $Installed = Test-IsInstalled

        Start-Cleanup

    } else {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download $AppName uninstaller.", "Error", 400)
    }
  

    #Verify that application has been successfully uninstalled
    If ($null -eq $Installed) {

        Write-Host "$AppName has been succesfully removed from the target computer."
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName has been succesfully removed from the target computer.", "Information", 200)

    } else {

        Write-Host "$AppName couldn't be uninstalled from the target computer."
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName couldn't be uninstalled from the target computer.", "Error", 400)

    }

} else {
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName was not detected, aborting uninstall.", "Warning", 300)
    Write-Host "$AppName was not detected, aborting uninstall."
}

