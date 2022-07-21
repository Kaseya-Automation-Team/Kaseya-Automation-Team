#This script Un-installs Slack on the target machine

Function Get-InstallStatus {

Return  (Get-Package | Where-Object {$_.Name -eq "Slack"} | Select-Object -Property Status).Status

}

$status = Get-InstallStatus

If($status -ne "Installed") {
    Write-Output "Slack is not installed on this computer yet!"
}

Else {
    Write-Output "Slack is installed on this computer, proceeding with the uninstall steps!"
        
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
        
        $UninstallCommand = Get-ItemProperty Registry::"HKEY_USERS\$($Profile.SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -match "^slack"} | Select-Object -ExpandProperty QuietUninstallString
        
        if ($null -ne $UninstallCommand)
        {
            $UninstallCommand = $UninstallCommand.Split(' ')
            $FinalCmd = ($UninstallCommand.Split('/'))[0] -replace '"', ''
            & $FinalCmd /uninstall /s
            Start-Sleep -Seconds 20


            $status = Get-InstallStatus

            If($status -ne "Installed") {
                Write-Output "Uninstall is completed!"
                eventcreate /L Application /T INFORMATION /SO VSA X /ID 200 /D "Slack uninstall has been completed!" | Out-Null
            }

            Else {
                Write-Output "Slack couldn't be uninstalled!"
            }
     }

 }

 }