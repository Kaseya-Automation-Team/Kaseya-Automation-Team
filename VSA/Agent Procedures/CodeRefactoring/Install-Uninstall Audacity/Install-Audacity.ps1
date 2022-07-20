## This script downloads and silently installs Audacity 2.2.2
param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()] 
    [string] $URL
)
if ($URL -eq 'Test') {
    $URL = 'https://dl2.boxcloud.com/d/1/b1!ktrIiwiJsP6xDlUQ8Mmr2aCB-BPwWleHL14geoKYeKpMxqeeSBcX7evu954p9n0iSlfD_mp6vB69x-MyC2dPqpC_zlFRyeJHmXVKvJ9tQviphzU6soO0sLefLjWAVXtrMh1fgPkwOf5foV87DE5fE5kxh14aVIZ3Mn6_HydCdZb2Am_TNQzUu-4ClBMgX8oGP7ef3QpemaD4LaBQHViQTpVNJ4QYrVB_ZaxAnsLnopTAq4fJWMwGgWg0c5w_GotrPcM7b9IcV1Y09Y_nBfoumH94It8OyfD3yJuLWcBB7ubkrm1bGUoW4qqdWfx5_n9BCDSPRNuzvxq_uXeWMc5QxyFqOj9BIeyTpQoEXZv9oslkYBTCRbsYMX_iw7F1me6jmWmIf4oP38E0XaNFfncQglQRu4sBKj-R7SHb7NVgtGWtj-OyTPZJj_UVr0CF-dUBq5c7-VihcNzLWEKexE-Hr3RFIMHyRxN7SJOhiCi7qreetoHZiXtVGxiCJA4MdaBkhxSElVMibexgO7uMaNJP8RJ4NsnBe3X2MWusAF-CR-UVd4vUGpA8m7gvWuBPD-f1gmMWN4RbEYxDjVQBmpxrm8rwkY49Evga6YXQ7zm2oy05wgBjx4HNaE3hrs9ZQOx4LJ0JIb4R1E6MCeCf_xL1kIJUU0bM_c_cwSY4J7dWxRjCOmi2VfjjjZUvTLV6cMqJiABuchhLQawHLXT_a1LhoNLqry4IKYi-c7ChqI1zZUlTGq2jR3exlqbtC-_ZQdOBFqBl3IvKhlnM1oEZ6bcdnZ8FyUwF6qBhRBAix7OgjwmCSx1N9EfgQDkCphdU78IJQx1PkeyPdPjhGeKcQ8iNVZ24FeHjoMTDluMQ9_YYzppPRobgUHndPnMEoa4D9jxrI1Od9hP7_tCsWtLRkvxDacOLnFQDOALmzeM8QQG-D-tGbSsNqtniRsgo-XZ1-vB7_MFbHNkdOrttohtEJqPb6mbIaq399VOytqtdGYHoAMsDJY-HwurCt7LUBTNvtUcTmTUchAuFU6ymn7eAcErS58YmsW_ZKiw1qzDMuGjH-YfPV1sGiBi4S16NK8TQ3F2nhgf694d80UgflyEKP14qmBHCWHd_DC8hJz2wVhAArKMrq7BXp2CcfOZvRp-YTH5N9bSUu25K8DjUSEhbqjiFcTsffvVp2scGwkV527-EqRyTIVkgf7gw0LKq2V0MyAWO7MlKrQO-uqV7Qcc1XAGT_JhH6u2obivVVEQvBy_-bJ8edbabCZLxgMi3p9Wl12PKzpRbcGCUIlLdVQ3RP0UqRKAv/download'
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