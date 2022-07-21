## This script silently uninstalls Google Drive from the computer

#Define varibles
$AppName = "Google Drive"

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
    return Get-RegistryRecords($AppName);
}

[System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName uninstall process has been initiated by VSA X script.", "Information", 200)

#If application is installed, continue with uninstall
If (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName was detected. Starting uninstall process.", "Information", 200)
    Write-Output "$AppName was detected. Starting uninstall process."

    $UninstallString = Test-IsInstalled|Select-Object -ExpandProperty UninstallString
    
    Start-Process -FilePath "$UninstallString" -ArgumentList "--silent --force_stop" -Wait

    Start-Sleep -s 10

    $Installed = Test-IsInstalled

    #Verify that application has been successfully uninstalled
    If ($null -eq $Installed) {

        Write-Output "$AppName has been succesfully removed from the target computer."
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName has been succesfully removed from the target computer.", "Information", 200)

    } else {

        Write-Output "$AppName couldn't be uninstalled from the target computer."
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName couldn't be uninstalled from the target computer.", "Error", 400)

    }

} else {
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName was not detected, aborting uninstall.", "Warning", 300)
    Write-Output "$AppName was not detected, aborting uninstall."
}

