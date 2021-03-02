# Requires -Version 5.1 
<#
.Synopsis
  Removes existing drive
.DESCRIPTION
    Removes mapped drive if exists combination of provided drive letter & share path
.EXAMPLE
   .\Remove-MappedDrive.ps1 -UNCPath '\\Server\Share' -DriveLetter 'X'
.EXAMPLE
   .\Remove-MappedDrive.ps1 -UNCPath '\\Server\Share' -DriveLetter 'X' -LogIt 0
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

    [string] $RegPath = Join-Path -Path "HKEY_USERS\$($Profile.SID)" -ChildPath $("Network\$DriveLetter") -Verbose
        
    if( Test-Path -Path Registry::$RegPath )
    {
        $MappedPath = Try { Get-ItemPropertyValue -Path Registry::$RegPath -Name 'RemotePath' -ErrorAction Stop } 
                    Catch { $null }

        #If the drive letter is mapped to the '\\Server\Share'
        If( $UNCPath -eq $MappedPath )
        {
            #Remove the drive
            Remove-Item -Path Registry::$RegPath -Verbose -Force -Confirm:$false

            #Remove mapping entry as well
            $RegPath = Join-Path -Path "HKEY_USERS\$($Profile.SID)" -ChildPath $("SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\$($UNCPath.Replace('\', '#'))")
            if( Test-Path -Path Registry::$RegPath )
            {
                Remove-Item -Path Registry::$RegPath -Verbose -Force -Confirm:$false
            }
        }
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