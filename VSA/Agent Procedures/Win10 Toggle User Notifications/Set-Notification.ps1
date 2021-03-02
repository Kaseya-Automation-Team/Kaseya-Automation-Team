# Requires -Version 5.1 
<#
.Synopsis
   Switches User Notification Center On/Off on Windows 10 1709 & newer.
.DESCRIPTION
   Used by Agent Procedure
   Switches User Notification Center On/Off on Windows 10 1709 & newer.
.EXAMPLE
   .\Set-Notification.ps1 -Set On
.EXAMPLE
   .\Set-Notification.ps1 Off -LogIt 0
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    
[parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
                   [ValidateSet('On','Off')]
    [string] $Set,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 1
)

<#
.Synopsis
   Sets Registry parameter
#>
function Set-RegParam {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0)]
        [string] $RegPath,
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=1)]
        [string] $RegValue
    )
    
    begin {
        [string] $RegKey = Split-Path -Path Registry::$RegPath -Parent
        [string] $RegProperty = Split-Path -Path Registry::$RegPath -Leaf
    }
    
    process {
        if( -not (Test-Path -Path $RegPath) )
        {
            #Create key
            if( -not (Test-Path -Path $RegKey) )
            {
                try {
                    New-Item -Path $RegKey -Force  -ErrorAction Stop
                } catch { Write-Error $_.Exception.Message}
            }
            #Create property
            try {
                New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType DWord -Value $RegValue -Force  -ErrorAction Stop
            } catch { Write-Error $_.Exception.Message}
        }
        else
        {
            try {
                Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -ErrorAction Stop
            } catch {Write-Error $_.Exception.Message}
        }
    }
}


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

#region keys & values
#depending on the reistry key different values are used to enable/disable controlled property
[array] $RegParameters = @()

$RegParameters +=  New-Object PSObject -Property @{
ChildPath = 'Software\Policies\Microsoft\Windows\Explorer\DisableNotificationCenter'
On = 0
Off = 1
}
$RegParameters += New-Object PSObject -Property @{
ChildPath = 'Software\Microsoft\Windows\CurrentVersion\PushNotifications\ToastEnabled'
On = 1
Off = 0
}
#endregion keys & values

#region Change Machine hive
Write-Verbose -Message "Local Machine"
foreach($item in $RegParameters)
{
    [string] $RegPath = Join-Path -Path 'HKEY_LOCAL_MACHINE' -ChildPath $($item.ChildPath)
    $Value = $item | Select-Object -ExpandProperty $Set
    Set-RegParam -RegPath $RegPath -RegValue $Value
}

#endregion Change Machine hive

#region Change Users' Hives

#endregion Change Users' Hives
[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                    Select-Object  @{name="SID";expression={$_.PSChildName}}, 
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                    @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                    Where-Object {$_.SID -match $SIDPattern}

# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = Get-ChildItem Registry::HKEY_USERS | `
    Where-Object {$_.PSChildname -match $SIDPattern} | `
    Select-Object @{name="SID";expression={$_.PSChildName}}

[string[]] $HivesToLoad = $ProfileList.SID

#Excluding SIDs of currently logged on users
if ($null -ne $LoadedHives)
{
    # Get all users that are not currently logged
    $HivesToLoad = Compare-Object -ReferenceObject $ProfileList.SID -DifferenceObject $LoadedHives.SID | `
    Select-Object -ExpandProperty InputObject
}

# Loop through each profile on the machine
Foreach ($Profile in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    if ($Profile.SID -in $HivesToLoad)
    {
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)" | Out-Null
    }
 
    #####################################################################
    # Modifying a user`s hive of the registry
    "{0} {1}" -f "`tUser:", $($Profile.UserName) | Write-Verbose
    foreach($item in $RegParameters)
    {
        [string] $RegPath = Join-Path -Path "HKEY_USERS\$($Profile.SID)" -ChildPath $($item.ChildPath)
        $Value = $item | Select-Object -ExpandProperty $Set
        Set-RegParam -RegPath $RegPath -RegValue $Value
    }
    #####################################################################
 
    # Unload ntuser.dat        
    iF ($Profile.SID -in $HivesToLoad)
    {
        ### Garbage collection required before closing ntuser.dat ###
        [gc]::Collect()
        reg unload "HKU\$($Profile.SID)"
    }
}
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