<#
    Install Firefox ESR
#>

$Language = 'lang=en-US'
$BaseURL = 'https://download.mozilla.org/?product=firefox-esr-msi-latest-ssl'

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

[Int]$Detected = $(Get-FirefoxInstalled).Count

if ( 0 -eq $Detected ) {

    if ([Environment]::Is64BitOperatingSystem ) {
        $Bitness = 'os=win64'
    } else {
        $Bitness = 'os=win'
    }

    $DownloadUrl = "$BaseURL&$Bitness&$Language"
    $MSIPath = "$env:TEMP\FirefoxESR.msi"
    Invoke-WebRequest $DownloadUrl -OutFile $MSIPath
    if (Test-Path -Path $MSIPath ) {
        #Install
        Start-Process $MSIPath -ArgumentList '/quiet' -Wait
        #Cleanup
        Remove-Item -Path $MSIPath -Force -Confirm:$false
    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download distribution from $DownloadUrl to $MSIPath", "Error", 400)
    }
    #Double-check after installation
    if ( 0 -lt $(Get-FirefoxInstalled).Count ) {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "FirefoxESR successfully installed", "Information", 200)
    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to detect FirefoxESR after installation", "Error", 400)
    }
} else { # if ( 0 -eq $Detected )
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Firefox already installed count: $Detected", "Information", 200)
}# if ( 0 -eq $Detected )