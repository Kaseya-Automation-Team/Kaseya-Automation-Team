<#
.Synopsis
   Uninstall program
.DESCRIPTION
   Uninstall Python for all users
.EXAMPLE
   .\Uninstall-Python.ps1
.NOTES
   Version 1.0
   Author: Proserv Team - SM
#>

#region Change Users' Hives
[string] $SIDPattern = '^S-1-5-21-(\d+-?){4}$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'
[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                    Select-Object  @{name="SID";expression={$_.PSChildName}}, 
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                    @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                    Where-Object {$_.SID -match $SIDPattern}
# Loop through each profile on the machine
Foreach ($Profile in $ProfileList)
{
    # Load User ntuser.dat if it's not already loaded
    [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($Profile.SID)
    if ( -Not $IsProfileLoaded )
    {
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)"
    }
 
    #####################################################################
    # Modifying a user`s hive of the registry
    "{0} {1}" -f "`tUser:", $($Profile.UserName) | Write-Verbose
    $UninstallCommand = Get-ItemProperty Registry::"HKEY_USERS\$($Profile.SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -match "^Python"} | Select-Object -ExpandProperty QuietUninstallString
    if ($null -ne $UninstallCommand)
    {
        Write-Debug $UninstallCommand
        #Also execute the command here
        $UninstallCommand = $UninstallCommand.Split('/')
        $FinalCmd = ($UninstallCommand.Split('/'))[0] -replace '"', ''
        & $FinalCmd /uninstall /quiet

    }
    #####################################################################
 
    # Unload ntuser.dat        
    iF ( -Not $IsProfileLoaded )
    {
        ### Garbage collection required before closing ntuser.dat ###
        [gc]::Collect()
        reg unload "HKU\$($Profile.SID)"
    }
}
#endregion Change Users' Hives