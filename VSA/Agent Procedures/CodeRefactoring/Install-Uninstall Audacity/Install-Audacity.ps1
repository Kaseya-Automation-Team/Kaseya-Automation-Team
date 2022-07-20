## This script downloads and silently installs Audacity 2.2.2
param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()] 
    [string] $URL
)
if ($URL -eq 'Test') {
    $URL = 'https://dl2.boxcloud.com/d/1/b1!RnvYpWqIOVTo7IGGz8oFznWZ264r6CO4GN7aJV03oX4QeuM_9Zb1m-3GLbKfoc2vdgkMD4V_kPPHhmz5-PpEZIlF6CHppuBuP4Ik_FKtEfPgLTCdWu8nW6X6CHpcOwUippowmFmcChS-UCrr1CHcSlqth9a2fU8IzVAbrDRIxgugyR2IsZ1MH_roYWivzdE2xFg00YcRMCvjK2gKgkh99A1TVPupZvfie58-exrA3oZa16bVceAyu3ruxmNpQ80UIe2zVDY0Fq3t7Il5X_C7NsH740k-cs0yPB8S_IEd1r3zz1jJsoNhlnmQd1JQUt_01JVnkhSBDqhHlD7dNxwTrnovE8sbF8DesX-jDx1yf_yVw6tmU393XgQPuvwqrEpmX9xs9EZIHAQRFzVYypGGcZEf_UWyrIlN3r4PKk1974o6YUsbkAtVMaUgJlCRLYCOYtwKfxSvIeVZTmasqRH5arIAJV48_KpRl1pw2SnFPUEt9YsHwtiqLxELkJHvR_M9YsN7MVmwOcnERYZu8E3ag6MAs4Ud9VsfC7cdHZ7Pp9jVAHHhdzSL6WFgqSoEXLweB8NzminetGf2YKkCiDxnDddfm7CkvpAN0xjy-j-DjGul2OJvebeQYrM-P95kwhZEP7Aniiz4ot40Nu20HhgURrPCkr1vWqJkk29OShugrlXI1qE3trABFvum7rvheepnLh0X64Fkl2FTvgub_npQWekWiaule0tihdqbt_m24Du28k7B68r0HcHNucs0_cXCzc5L2D_YoPf6AUHQoDN0_qZNXcQM50D1dJS59jEwkCV04GZ7PB_T3mE8vlKF07tktob9DXncRRr098DVhKDNYR2FjZJRvCZnutH_dsGZgV8BvBRs2wW6gFsZRVqfrn84fC6aeNyBtWtb9c2lQsZZ4fWV7FbgHIQE3Qi8wH5LcxeKMquHrjRU9sXzhjaX4b8503ntcDYcfKKJWnZHf2JjBzsIYDohgWiX93QzMAQ9CHa3N5pGiqBMEY3vC5Kj9VHEy4nGhDa0558Gz1R-VwAkf6rev6aaL9VjCSSWMrmwXqEjx4T2Tln9zf2XHde49HaYvHOrGxqYx_9bG2D4R8BiaRo3rzozWamGNFrHx5jjPNdpP39d5oU9NiQ2thCKM8kcgAoAiZ0OQzC6eraQawC3zBFZwVliwIwHpP-T-h779w-xDDMOrhQAscTUlZvSNF4KMncjPCPLL6muknUZ7D9UtSD_JHYHkrIKIBfwP_DoDcVRtT4Pd-p2eqK3qc4yaXJ2nPNKT_GGXkpf/download'
}

#Define variables
$AppName = "Audacity"
$AppFullName = "Audacity*"
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

    Write-Output "Downloading $AppName installer."
	$ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $URL -OutFile $Destination

    if (Test-Path -Path $Destination) {
        Start-Install
    } else {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download $AppName installation file.", "Error", 400)
    }
}

#Execute installer
function Start-Install() {

    Write-Output "Starting $AppName installation."
    Start-Process -FilePath $Destination -ArgumentList "/VERYSILENT /NORESTART" -Wait
}

#Delete installation file
function Start-Cleanup() {

    Write-Output "Removing installation files."
    Remove-Item -Path $Destination -ErrorAction SilentlyContinue
}

#If application is not installed yet, continue with installation
if (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName is already installed on the target computer, not proceeding with installation.", "Warning", 300)
    Write-Output "$AppName is already installed on the target computer, not proceeding with installation."

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
        Write-Output "Couldn't install $AppName on the target computer."

    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName has been successfully installed.", "Information", 200)
        Write-Output "$AppName has been successfully installed."
    }
}