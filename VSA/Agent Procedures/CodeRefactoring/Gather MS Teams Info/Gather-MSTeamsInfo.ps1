<#
=================================================================================
Script Name:        Audit: Gather MS Teams Info.
Description:        Gather MS Teams Info for all the computer's users.
Lastest version:    2022-07-29
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Create VSA Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
            Select-Object  @{name='User';expression={$_.PSChildName}}, 
            ProfileImagePath `
                | Where-Object {$_.User -match $SIDPattern}

[array] $TeamsInfo = @()

Foreach ( $Profile in $ProfileList )
{
    #Try to resolve user name. Return SID if the name can not be resolved
    $Account = New-Object Security.Principal.SecurityIdentifier($Profile.User)
    $UserBySID  = $(  try { $Account.Translate([Security.Principal.NTAccount]) `
            | Select-Object -ExpandProperty Value
            } catch {
                $_.Exception.Message
            } )
    if ( $UserBySID -notmatch 'Exception' ) {
        $Profile.User = $UserBySID
    }
    $TeamsPath = Join-Path -Path $Profile.ProfileImagePath -ChildPath "AppData\Roaming\Microsoft\Teams\settings.json"
    if (Test-Path -Path $TeamsPath) {
        $TeamsInfo += Get-Content -Path $TeamsPath | ConvertFrom-Json | Select-Object @{name='User';expression={$Profile.User}}, Version, Ring, Environment
    }
}
$TeamsInfo | Out-String | Write-Output