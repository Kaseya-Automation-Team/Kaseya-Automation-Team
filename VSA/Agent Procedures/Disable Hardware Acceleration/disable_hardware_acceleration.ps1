# Get each user profile SID and Path to the profile
$UserProfiles = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Where {$_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } | Select-Object @{Name="SID"; Expression={$_.PSChildName}}, @{Name="UserHive";Expression={"$($_.ProfileImagePath)\NTuser.dat"}}

# Loop through each profile on the machine</p>
Foreach ($UserProfile in $UserProfiles) {
    # Load User ntuser.dat if it's not already loaded
    If (($ProfileWasLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile.SID)) -eq $false) {
        Start-Process -FilePath "CMD.EXE" -ArgumentList "/C REG.EXE LOAD HKU\$($UserProfile.SID) $($UserProfile.UserHive)" -Wait -WindowStyle Hidden
    }

    # Manipulate the registry
    $key = "Registry::HKEY_USERS\$($UserProfile.SID)\Software\Microsoft\Office\16.0\Common\Graphics"
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name "DisableHardwareAcceleration" -Value 0x00000001 -PropertyType DWORD -Force | Out-Null
 
    $key = "$key\UserInfo"
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -Path $key -Name "LoginName" -Value "$($ENV:USERDOMAIN)\$($ENV:USERNAME)" -PropertyType STRING -Force | Out-Null

    # Unload NTuser.dat        
    If ($ProfileWasLoaded -eq $false) {
        [gc]::Collect()
        Start-Sleep 1
        Start-Process -FilePath "CMD.EXE" -ArgumentList "/C REG.EXE UNLOAD HKU\$($UserProfile.SID)" -Wait -WindowStyle Hidden| Out-Null
    }
}