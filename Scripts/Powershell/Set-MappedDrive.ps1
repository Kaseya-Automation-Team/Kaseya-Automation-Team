# Requires -Version 5.1 
<#
.Synopsis
  Creates/updates Mapped drive
.DESCRIPTION
   Creates or updates network drive for all the computer's users
   Used by Agent Procedure
.EXAMPLE
   .\Set-MappedDrive.ps1 -UNCPath '\\Server\Share' -DriveLetter 'X' -UpdateMapping 1
.EXAMPLE
   .\Set-MappedDrive.ps1 -UNCPath '\\Server\Share' -DriveLetter 'X' -LogIt 0
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
    [ValidatePattern( '^\\\\[\w\-.]+\\[\w\-.\$]*$' )]
    [string] $UNCPath,
    [parameter(Mandatory=$true, 
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true, 
    ValueFromRemainingArguments=$false, 
    Position=1)]
    [ValidatePattern( '[h-zH-Z]' )]
    [string] $DriveLetter,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 1,
    [parameter(Mandatory=$false)]
    [int] $UpdateMapping = 0
)

#region function Set-RegParam
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
        [AllowEmptyString()]
        [string] $RegValue,
        [parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=2)]
        [ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'None', 'QWord', 'String', 'Unknown')]
        [string] $ValueType = 'DWord',
        [parameter(Mandatory=$false, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                ValueFromRemainingArguments=$false, 
                Position=3)]
        [int] $UpdateExisting = 0
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
                    New-Item -Path $RegKey -Force -Verbose -ErrorAction Stop
                } catch { Write-Error $_.Exception.Message}
            }
            #Create property
            try {
                New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
            } catch { Write-Error $_.Exception.Message}
        }
        else
        {
            #Assign value to the property
            if( 1 -eq $UpdateExisting)
            {
                try {
                        Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch {Write-Error $_.Exception.Message}
            }
        }
    }
}
#endregion function Set-RegParam

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

#region define Registry Settings
[array] $RegParameters = @(
    [PSCustomObject] @{ChildPath = "Network\$DriveLetter\RemotePath"; Value = $UNCPath; Type = 'String'},
    [PSCustomObject] @{ChildPath = "Network\$DriveLetter\UserName"; Value = ""; Type = 'String'},
    [PSCustomObject] @{ChildPath = "Network\$DriveLetter\ProviderName"; Value = 'Microsoft Windows Network'; Type = 'String'},
    [PSCustomObject] @{ChildPath = "Network\$DriveLetter\ProviderType"; Value = '0x002000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "Network\$DriveLetter\ConnectionType"; Value = '0x000001'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "Network\$DriveLetter\ConnectFlags"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "Network\$DriveLetter\DeferFlag"; Value = '0x000004'; Type = 'DWord'}
    [PSCustomObject] @{ChildPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\$($UNCPath.Replace('\', '#'))"; Value = ""; Type = 'String'}
)
#endregion define Registry Settings


#region Change Users' Hives
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

# Get all users that are not currently logged
$HivesToLoad = Compare-Object -ReferenceObject $ProfileList.SID -DifferenceObject $LoadedHives.SID | `
    Select-Object -ExpandProperty InputObject

# Loop through each profile on the machine
Foreach ($Profile in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    if ( $Profile.SID -in $HivesToLoad )
    {
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)"
    }
 
    #####################################################################
    # Modifying a user`s hive of the registry
    "{0} {1}" -f "`tUser:", $($Profile.UserName) | Write-Verbose
    foreach($item in $RegParameters)
    {
        [string] $RegPath = Join-Path -Path "HKEY_USERS\$($Profile.SID)" -ChildPath $($item.ChildPath) -Verbose
        Set-RegParam -RegPath $RegPath -RegValue $($item.Value) -ValueType $($item.Type)
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
#endregion Change Users' Hives

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