<#
=================================================================================
Script Name:        Management: Clear Temp folders.
Description:        Clear Temp folders.
Lastest version:    2022-08-31
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
function Clear-Folder {
[CmdletBinding()]
param (
    [parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $TheFolder)
    if(Test-Path -Path $TheFolder) {
        Get-ChildItem -Path $TheFolder -Recurse -Force | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
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
    if ( -Not $IsProfileLoaded ) {
        reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"
    }

    [string] $TempFolderPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Environment") -Name "TEMP" | Select-Object -ExpandProperty "TEMP"

    $TempFolderPath.Replace("$env:USERPROFILE", $UserProfilePath) | Clear-Folder

    [gc]::Collect()
    if ( -Not $IsProfileLoaded ) {
        reg unload "HKU\$($_.SID)"
    }
}