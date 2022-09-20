<#
=================================================================================
Script Name:        Software Management: Uninstall Firefox ESR.
Description:        Silently uninstalls Firefox ESR.
Lastest version:    2022-05-02
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

#region function Get-FirefoxInstalled
function Get-FirefoxInstalled {
    [OutputType([string[]])]
    [string[]]$UninstallKeys=@("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
    [string]$UserGUIDPattern="S-\d-\d+-(\d+-){1,14}\d+$"
    $null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
    $UninstallKeys += Get-ChildItem HKU: -ErrorAction SilentlyContinue | `
        Where-Object { $_.Name -match $UserGUIDPattern } | `
        ForEach-Object { "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall" }
    
    [string[]] $UninstallStrings = @()
    foreach ($UninstallKey in $UninstallKeys) {
        $UninstallStrings += Get-ChildItem -Path $UninstallKey -ErrorAction SilentlyContinue | `
            Where-Object {$_.GetValue("DisplayName") -match "Firefox"} | `
            Select-Object @{n="UninstallString"; e={$_.GetValue("UninstallString")}} | `
            Select-Object -ExpandProperty "UninstallString" 
    }# foreach ($UninstallKey in $UninstallKeys)
    Remove-PSDrive HKU
    return $UninstallStrings
}
#endregion function Get-FirefoxInstalled

$regexp = '(?<=\").+?(?=\")'

[string[]]$Found = $(Get-FirefoxInstalled)
if ( 0 -lt $Found.Count) {
    foreach ($RawString in $Found) {
        [string]$Uninstall=[regex]::Matches($RawString, $regexp).Value
        Start-Process $Uninstall -ArgumentList '/S' -Wait
    }
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "FirefoxESR successfully uninstalled", "Information", 200)
}