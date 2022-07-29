<#
.Synopsis
   Gathers Mapped Drive for all the computer's users.
   Version 0.1
   Author: Proserv Team - VS
#>

#Create VSA Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

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
[array] $Result = @()
Foreach ($Profile in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($Profile.SID)

    if ( -Not $IsProfileLoaded ) {
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)" | Out-Null
    }
 
    [string] $RegPath = Join-Path -Path "HKEY_USERS\$($Profile.SID)" -ChildPath "Network" -Verbose

    [array]$MappedDrives = @()
    $MappedDrives += Get-ChildItem -Path Registry::$RegPath -ErrorAction SilentlyContinue | Get-ItemProperty

    if (0 -lt $MappedDrives.Count) {
        $Results += $MappedDrives | Select-Object RemotePath, PSChildName, @{Name = 'UserName'; Expression= {$Profile.UserName}}
    }
 
    # Unload ntuser.dat        
    if ( -Not $IsProfileLoaded ) {
        ### Garbage collection required before closing ntuser.dat ###
        [gc]::Collect()
        reg unload "HKU\$($Profile.SID)" | Out-Null
    }
}

if (0 -lt $Results.Count) {
    [string]$Output = $Results | Select-Object UserName, @{Name = 'DriveLetter'; Expression= {$_.PSChildName}}, RemotePath | Out-String
    Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable MappedDrives ""$Output""") -Wait
}