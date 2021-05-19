<#
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
    if(Test-Path -Path $TheFolder)
    {
        Get-ChildItem -Path $TheFolder -Recurse -Force | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}

#Clear the system temp folder
Get-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name "TEMP" | Select-Object -ExpandProperty "TEMP" | Clear-Folder

#Clear users' temp folders
[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        $UserProfilePath = $_.LocalPath

        reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"

        [string]$TempFolder = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Environment") -Name "TEMP" | Select-Object -ExpandProperty "TEMP"
        $RunningProcessProfilePath = $env:USERPROFILE

        $TempFolder.Replace($RunningProcessProfilePath, $UserProfilePath) | Clear-Folder

        [gc]::Collect()
        reg unload "HKU\$($_.SID)"
    }