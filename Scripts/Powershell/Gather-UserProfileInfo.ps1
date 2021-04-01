<#
.Synopsis
   Gathers users' profiles information on the computer.
.DESCRIPTION
   Used by Agent Procedure
   Gathers users' profiles information on the computer and saves information to a CSV-file.
.EXAMPLE
   .\Gather-UserProfileInfo.ps1 -AgentName '12345' -OutputFilePath 'C:\TEMP\profiles_info.csv'
.EXAMPLE
   .\Gather-UserProfileInfo.ps1 -AgentName '12345' -OutputFilePath 'C:\TEMP\profiles_info.csv' -LogIt 0
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [string] $AgentName,
    [parameter(Mandatory=$true)]
    [string] $OutputFilePath,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 1
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

[string] $DateFormat = "{0:MM'/'dd'/'yyyy H:mm:ss}"
[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
            Select-Object  @{name="UserSID";expression={$_.PSChildName}}, 
            @{name="Profile location";expression={$_.ProfileImagePath}},
            @{name="Profile size, KB";expression={$null}},
            @{name="Last modified";expression={$null}} `
                | Where-Object {$_.UserSID -match $SIDPattern}

Foreach ( $Profile in $ProfileList )
{
    $Profile.'Profile size, KB' = [math]::Round( 
            $( Get-ChildItem -Path $Profile.'Profile location' -Recurse `
            | Measure-Object -Sum Length `
            | Select-Object -ExpandProperty Sum ) / 1KB 
        )

    $Profile.'Last modified'  = $DateFormat -f (Get-WmiObject -Query "Select LastUseTime From Win32_UserProfile Where SID = '$($Profile.UserSID)'" `
            | ForEach-Object {$_.ConvertToDateTime($_.LastUseTime)})

    #Try to resolve user name. Return SID if the name can not be resolved
    $Account = New-Object Security.Principal.SecurityIdentifier($Profile.UserSID)
    $UserBySID  = $(  try { $Account.Translate([Security.Principal.NTAccount]) `
            | Select-Object -ExpandProperty Value } catch { $_.Exception.Message } )
    if ( $UserBySID -notmatch 'Exception' ) { $Profile.UserSID = $UserBySID }
}

$ProfileList | Select-Object -Property `
    @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}},
    @{Name = 'AgentGuid'; Expression = {$AgentName}},
    @{Name = 'Account'; Expression = {$_.UserSID}},
    'Profile location',
    'Profile size, KB',
    'Last modified' | Sort-Object 'Profile size, KB' -Descending `
            | Export-Csv -Path "FileSystem::$OutputFilePath" -Force -Encoding UTF8 -NoTypeInformation

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