# Requires -Version 5.1 
<#
.Synopsis
   Updates Internet Zone Security Settings
.DESCRIPTION
   Updates Internet Zone Security Settings for all users that are not currently logged on
.EXAMPLE
   .\Set-InternetZoneParams.ps1 -RegKeyPath 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2'
.EXAMPLE
   .\Set-InternetZoneParams.ps1 -RegKeyPath 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2' -LogIt
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()] 
    [string] $RegKeyPath,
    [parameter(Mandatory=$false)]
    [Switch] $LogIt
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
        [parameter(Mandatory=$false)]
        [Switch] $UpdateExisting
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
            if( $UpdateExisting )
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

#region define Registry Settings for the Internet Zone
[string] $RegKeyPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2'

[array] $RegParameters = @(
    [PSCustomObject] @{ChildPath = "$regKeyPath"; Value = ''; Type = 'String'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2001"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2004"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\DisplayName"; Value = 'Trusted sites'; Type = 'String'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\PMDisplayName"; Value = 'Trusted sites [Protected Mode]'; Type = 'String'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\Description"; Value = 'This zone contains websites that you trust not to damage your computer or data.'; Type = 'String'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\Icon"; Value = 'inetcpl.cpl#00004480'; Type = 'String'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\LowIcon"; Value = 'inetcpl.cpl#005424'; Type = 'String'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\CurrentLevel"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\Flags"; Value = '0x000047'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1200"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1400"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1001"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1004"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1201"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1206"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1207"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1208"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1209"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\120A"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\120C"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1402"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1405"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1406"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1407"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1408"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1409"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\140A"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\140C"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1601"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1604"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1605"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1606"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1607"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1608"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1609"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\160A"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\160B"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1802"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1803"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1804"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1809"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1812"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1A00"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1A02"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1A03"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1A04"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1A05"; Value = '0x000001'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1A06"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1A10"; Value = '0x000001'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1C00"; Value = '0x010000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2000"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2005"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2007"; Value = '0x010000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2100"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2101"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2102"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2103"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2104"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2105"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2106"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2107"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2108"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2200"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2201"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2300"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2301"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2302"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2400"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2401"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2402"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2600"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2700"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2701"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2702"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2703"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2704"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2708"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2709"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\270B"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\270C"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\270D"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\1806"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2500"; Value = '0x000003'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\2707"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\120B"; Value = '0x000000'; Type = 'DWord'},
    [PSCustomObject] @{ChildPath = "$regKeyPath\140D"; Value = '0x000000'; Type = 'DWord'}
)
#endregion define Registry Settings for the Internet Zone

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

[string[]] $HivesToLoad = $ProfileList.SID

#Excluding SIDs of currently logged on users
if ($null -ne $LoadedHives)
{
    # Get all users that are not currently logged
    $HivesToLoad = Compare-Object -ReferenceObject $ProfileList.SID -DifferenceObject $LoadedHives.SID | `
                    Select-Object -ExpandProperty InputObject
    #Write logged on users to Debug stream
    [string[]] $LoggedOnUsers = @('Currently logged on users')
    $LoggedOnUsers += $LoadedHives.SID | ForEach-Object { $Account = New-Object Security.Principal.SecurityIdentifier("$_");
                                Write-Output "{$_} [$(  try { $Account.Translate([Security.Principal.NTAccount]) | Select-Object -ExpandProperty Value } catch { $_.Exception.Message } )]"
                                }
    $LoggedOnUsers | Write-Debug
}

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
        Write-Debug "Set-RegParam -RegPath $RegPath -RegValue $($item.Value) -ValueType $($item.Type)"
        Set-RegParam -RegPath $RegPath -RegValue $($item.Value) -ValueType $($item.Type) -UpdateExisting
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
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript
