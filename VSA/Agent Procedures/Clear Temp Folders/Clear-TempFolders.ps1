﻿<#
.Synopsis
   Clears the Temp folders.
.DESCRIPTION
   Clears the Temp folders. Used by Agent Procedure
.EXAMPLE
   .\Clear-TempFolders.ps1
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>


function Clear-Folder {
[CmdletBinding()]
param (
    [parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $TheFolder)
    if(Test-Path -Path $TheFolder) {
        Get-ChildItem -Path $TheFolder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}

#Clear the system temp folder
Get-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name "TEMP" | Select-Object -ExpandProperty "TEMP" | Clear-Folder

#Clear users' temp folders
[string] $SIDPattern = 'S-1-5-21-(\d+-?){4}$'
Get-CimInstance Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
ForEach-Object {
    $UserProfilePath = $_.LocalPath

    [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($_.SID)
    If ( -Not $IsProfileLoaded ) {
        reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"
    }

    [string] $TempFolderPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Environment") -Name "TEMP" | Select-Object -ExpandProperty "TEMP"
    $RunningProcessProfilePath = $env:USERPROFILE

    $TempFolderPath.Replace($RunningProcessProfilePath, $UserProfilePath) | Clear-Folder

    [gc]::Collect()
    If ( -Not $IsProfileLoaded ) {
        (reg unload "HKU\$($_.SID)" ) 2> $null
    }
}