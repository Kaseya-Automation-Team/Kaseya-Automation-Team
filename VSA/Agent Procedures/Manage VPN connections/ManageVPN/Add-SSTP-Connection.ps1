## Kaseya Automation Team
## Used by the "Gather Log Detais" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$Name = "",
    [parameter(Mandatory=$true)]
    [string]$Server = "",
    [parameter(Mandatory=$true)]
    [string]$EncryptionLevel = "",
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
    $LogFile = "$ScriptDir\Add-SSTPConnection.log"
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
    Add-VpnConnection -Name $Name -ServerAddress $Server -TunnelType SSTP -EncryptionLevel $EncryptionLevel -AllUserConnection -ErrorAction Stop
    Write-Host "VPN connection $Name has been successfully created."
} catch {
    Write-Host "Unable to create vpn connection."$_.Exception.Message
}

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}