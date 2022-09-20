<#
=================================================================================
Script Name:        Software Management: Uninstall Microsoft OneDrive.
Description:        Uninstall Microsoft OneDrive.
Lastest version:    2022-05-04
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

[string[]]$UninstallStrings = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft OneDrive' } | Select-Object -ExpandProperty UninstallString

#region Loop through each profile on the machine
Foreach ($UserProfile in $UserProfiles)
{
    # Load User ntuser.dat if it's not already loaded
    [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile.SID)
    If ( -Not $IsProfileLoaded )
    {
        reg load "HKU\$($UserProfile.SID)" "$($UserProfile.UserHive)"
    }

    # Manipulate the registry
    $UninstallStrings += Get-ChildItem -Path $(Join-Path -Path "HKEY_USERS\$($UserProfile.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall") | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft OneDrive' } | Select-Object -ExpandProperty UninstallString

    # Unload NTuser.dat        
    If ( -Not $IsProfileLoaded )
    {
        [gc]::Collect()
        reg unload "HKU\$($UserProfile.SID)"
    }
}
#endregion Loop through each profile on the machine

if ($null -ne $UninstallStrings) {
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Microsoft OneDrive detected. Uninstalling", "Information", 200)
    Get-Process -Name 'OneDrive' | Stop-Process -Force -ErrorAction SilentlyContinue
    $UninstallStrings = $UninstallStrings | Select-Object -Unique
    foreach ( $UninstallString in $($UninstallStrings | Sort-Object) ) {
        [string] $FilePath = $($UninstallString -split '/')[0].Trim()
        [string] $ArgumentList = '/' + $($($UninstallString -split '/' | Select-Object -Skip 1 | ForEach-Object { $_.Trim() | Write-Output }) -join ' /')
        Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -Wait -PassThru -ErrorAction SilentlyContinue
    }
}