<#
    Install Microsoft OneDrive
#>
$Language = 'culture=en-us'

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

#Download the latest version of the OneDrive installer
[string]$BaseURL = 'https://go.microsoft.com/fwlink/p/?LinkID=2182910' #32-Bit version of OneDrive
if ([Environment]::Is64BitOperatingSystem ) {
    $BaseURL = 'https://go.microsoft.com/fwlink/p/?LinkID=844652'      #64-Bit version of OneDrive
}
$DownloadUrl = "$BaseURL&$Language"
$InstallerPath = "$env:TEMP\OneDriveSetup.exe"

Invoke-WebRequest $DownloadUrl -OutFile $InstallerPath

if (Test-Path -Path $InstallerPath ) {

    Unblock-File -Path $InstallerPath
    #region check if OneDrive already installed and uninstall it
    $OneDrivePkg = Get-Package | Where-Object {$_.Name -eq 'Microsoft OneDrive'} 
    if ( $null -ne $OneDrivePkg ) {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Microsoft OneDrive detected. Uninstalling", "Information", 200)
        Get-Process -Name 'OneDrive' | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Process $InstallerPath -Wait -ArgumentList '/uninstall /allusers' -PassThru
    }
    #endregion check if OneDrive already installed and uninstall it
    #Install
    Start-Process $InstallerPath -Wait -ArgumentList '/silent /allusers' -PassThru
    #Cleanup
    Remove-Item -Path $InstallerPath -Force -Confirm:$false
    #Double-check after installation
    $OneDrivePkg = Get-Package | Where-Object {$_.Name -eq 'Microsoft OneDrive'} 
    if ($null -ne $OneDrivePkg) {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Microsoft OneDrive successfully installed", "Information", 200)
    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to detect Microsoft OneDrive after installation", "Error", 400)
    }
} else {
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download distribution from $DownloadUrl to $InstallerPath", "Error", 400)
}