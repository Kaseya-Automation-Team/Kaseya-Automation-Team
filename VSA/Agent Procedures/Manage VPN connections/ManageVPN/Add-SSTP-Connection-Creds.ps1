## Kaseya Automation Team
## Used by the "Gather Log Detais" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$Name = "",
    [parameter(Mandatory=$true)]
    [string]$Server = "",
    [parameter(Mandatory=$true)]
    [string]$EncryptionLevel = "",
    [parameter(Mandatory=$true)]
    [string]$Username = "",
    [parameter(Mandatory=$true)]
    [string]$Password = "",
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
 )

#Get folder where this script remains
$ScriptDir = Split-Path ($MyInvocation.MyCommand.Path) -Parent

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $LogFile = "$ScriptDir\Add-SSTPConnection-Creds.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"
Write-Debug ($Name|Out-String)
Write-Debug ($Server|Out-String)
Write-Debug ($EncryptionLevel|Out-String)

if (($EncryptionLevel -eq "Required") -or ($EncryptionLevel -eq "NoEncryption") -or ($EncryptionLevel -eq "Optional") -or ($EncryptionLevel -eq "Maximum")) {
} else {
    Write-Host "Specified encryption level $EncryptionLevel is not supported."
    Break
}


try {
    Add-VpnConnection -Name $Name -ServerAddress $Server -TunnelType SSTP -EncryptionLevel $EncryptionLevel -ErrorAction Stop
    Write-Host "VPN connection $Name has been successfully created."
} catch {
    Write-Host "Unable to create vpn connection."$_.Exception.Message
}

try {
    Install-Module -Name VPNCredentialsHelper -Force
    Set-VpnConnectionUsernamePassword -connectionname $Name -username $Username -password $Password -domain '' | Out-Null
    (Get-Content -Path $env:USERPROFILE\AppData\Roaming\Microsoft\Network\Connections\Pbk\rasphone.pbk) -replace 'CacheCredentials=0','CacheCredentials=1' | Set-Content -Path $env:USERPROFILE\AppData\Roaming\Microsoft\Network\Connections\Pbk\rasphone.pbk
    Write-Host "Credentials for VPN connection have been set."
} catch {
    Write-Host "Unable to set credentials for VPN connection."$_.Exception.Message
}

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}