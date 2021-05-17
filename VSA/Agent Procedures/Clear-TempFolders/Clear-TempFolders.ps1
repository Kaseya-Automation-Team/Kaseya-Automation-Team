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
Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | ForEach-Object `
    {
        $ProfilePath = $_.LocalPath
        reg load "HKU\$($_.SID)" "$ProfilePath\ntuser.dat"

        <#Usually the user's TEMP folder refers to the USERPROFILE system variable. Runtime substitutes the variable with the current process's USERPROFILE value.
        Thus, a registry value that contains %USERPROFILE% system variable has to be modyfied by replacing process's USERPROFILE value by corect profile's owner path.
        #>
        [string]$TempPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Environment") -Name "TEMP" | Select-Object -ExpandProperty "TEMP"
        $RunningProcessProfile = $env:USERPROFILE

        $TempPath.Replace($RunningProcessProfile, $ProfilePath) | Clear-Folder

        [gc]::Collect()
        reg unload "HKU\$($_.SID)"
    }