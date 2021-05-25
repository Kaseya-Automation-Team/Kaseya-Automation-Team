<#
.Synopsis
   Removes Dell dbutil_2_3.sys driver
.DESCRIPTION
   Removes Dell dbutil_2_3.sys driver
   https://www.dell.com/support/kbdoc/en-ca/000186019/dsa-2021-088-dell-client-platform-security-update-for-dell-driver-insufficient-access-control-vulnerability  
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$false)]
    [switch] $LogIt
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

function Clear-Folder {
[CmdletBinding()]
param (
    [parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $TheFolder,
    [parameter(Mandatory=$false)]
    [string] $TheFilter = 'dbutil_2_3.sys'
    )
    if(Test-Path -Path $TheFolder)
    {
        Get-ChildItem -Path $TheFolder -Recurse -Force -Filter $TheFilter -Verbose | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue -Verbose
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

        [string] $TempFolderPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Environment") -Name "TEMP" | Select-Object -ExpandProperty "TEMP"
        $RunningProcessProfilePath = $env:USERPROFILE

        $TempFolderPath.Replace($RunningProcessProfilePath, $UserProfilePath) | Clear-Folder

        [gc]::Collect()
        reg unload "HKU\$($_.SID)"
    }
# https://dl.dell.com/FOLDER07338430M/1/Dell-Security-Advisory-Update-DSA-2021-088_DF8CW_WIN_2.1.0_A02.EXE