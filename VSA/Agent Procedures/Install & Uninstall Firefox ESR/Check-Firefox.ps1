<#
.Synopsis
   Detects and/or removes Mozilla Firefox
.DESCRIPTION
   Detects Firefox by scanning registry for Firefox-related uninstall strings. Removes Firefox if the RemoveDetected switch is used. 
.NOTES
   Version 0.1
   Author: Proserv Team - VS
.PARAMETER(s)
    None
.EXAMPLE
   .\Check-Firefox
.EXAMPLE
   .\Check-Firefox -RemoveDetected
.EXAMPLE
   .\Check-Firefox -LogIt 1
#>

param (
    [parameter(Mandatory=$false)]
    [Switch]$RemoveDetected,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
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

#Get all the registry keys related to Firefox
[string[]] $UninstallKeys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
$UninstallKeys += Get-ChildItem HKU: -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | ForEach-Object { "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall" }

[string[]] $UninstallStrings = @()
foreach ($UninstallKey in $UninstallKeys) {
    $UninstallStrings += Get-ChildItem -Path $UninstallKey -ErrorAction SilentlyContinue | Where-Object {$_.GetValue('DisplayName') -match 'Firefox'} | 
    Select-Object  @{n='UninstallString'; e={$_.GetValue('UninstallString')}} | Select-Object -ExpandProperty 'UninstallString'
}

Remove-PSDrive HKU

if (0 -lt $UninstallStrings.Count)
{
    if ( $RemoveDetected)
    {
        [string] $SilentKey = "/S"
        foreach ($RawString in $UninstallStrings)
        {
            [string] $Uninstall = [regex]::Matches($RawString, '(?<=\").+?(?=\")').Value
            & "$Uninstall" $SilentKey
        }
    }
}
Write-Output $($UninstallStrings.Count)

#region check/stop transcript
if ( 1 -eq $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript