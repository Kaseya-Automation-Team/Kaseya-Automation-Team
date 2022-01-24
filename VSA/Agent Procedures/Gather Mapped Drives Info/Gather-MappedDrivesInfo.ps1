<#
.Synopsis
   Gathers Mapped Drive for all the computer's users.
.DESCRIPTION
   Gathers Mapped Drive for all the computer's users and saves information to a CSV-file.
   Used by the "Gather Mapped Drives Info" Agent Procedure
.EXAMPLE
   .\Gather-MappedDrivesInfo.ps1 -AgentName '12345' -OutputFilePath 'local_accounts.csv' -Path 'C:\TEMP'
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,

    [parameter(Mandatory=$true)]
	[string]$OutputFilePath,

    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$Path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}

if ( $OutputFilePath -notmatch '\.csv$') { $OutputFilePath += '.csv' }

#Write-Debug "Script execution started"


#Create array where all objects for export will be storred
[array]$Results = @()

#region Get Users' Hives
[string] $SIDPattern = 'S-1-5-21-(\d+-?){4}$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                    Select-Object  @{name="SID";expression={$_.PSChildName}}, 
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                    @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                    Where-Object {$_.SID -match $SIDPattern}
# Loop through each profile on the machine
Foreach ($Profile in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($Profile.SID)

    if ( -Not $IsProfileLoaded )
    {
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)" | Out-Null
    }
 
    [string] $RegPath = Join-Path -Path "HKEY_USERS\$($Profile.SID)" -ChildPath "Network" -Verbose

    [array]$MappedDrives = Get-ChildItem -Path Registry::$RegPath -ErrorAction SilentlyContinue | Get-ItemProperty

    if (0 -lt $MappedDrives.Count) {
        $MappedDrives | Select-Object @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, @{Name = 'UserName'; Expression= {$Profile.UserName}}, `
                                      @{Name = 'DriveLetter'; Expression= {$_.PSChildName}}, RemotePath, ProviderName | ForEach-Object { $Results += $_ }
    }
 
    # Unload ntuser.dat        
    if ( -Not $IsProfileLoaded )
    {
        ### Garbage collection required before closing ntuser.dat ###
        [gc]::Collect()
        reg unload "HKU\$($Profile.SID)" | Out-Null
    }
}
#endregion Get Users' Hives


#Export results to csv file

try { $Results | Export-Csv -Path "FileSystem::$OutputFilePath" -Encoding UTF8 -NoTypeInformation -Force -ErrorAction Stop } catch { $_.Exception.Message }

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}