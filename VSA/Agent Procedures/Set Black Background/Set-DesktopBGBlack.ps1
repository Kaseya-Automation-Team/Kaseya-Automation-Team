[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        $UserProfilePath = $_.LocalPath

        reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"

        Set-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Desktop") -Name "Wallpaper" -Value ''
        Set-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Control Panel\Colors") -Name "Background" -Value '0 0 0'
        
        & RUNDLL32.EXE user32.dll, UpdatePerUserSystemParameters
        [gc]::Collect()
        reg unload "HKU\$($_.SID)"
    }