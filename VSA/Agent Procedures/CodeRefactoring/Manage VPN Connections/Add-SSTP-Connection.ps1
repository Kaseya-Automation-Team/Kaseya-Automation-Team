<#
.Synopsis
   Creates vpn connection
.DESCRIPTION
   This script is dedicated to create SSTP connection without setting credentials for the VPN connection
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

#Name of the vpn connection
[string]$Name = ""

#Hostname of the server
[string]$Server = ""

#Encryption level - NoEncryption, Optional, Required
[string]$EncryptionLevel = ""

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

Write-Output "Script execution started"

if (($EncryptionLevel -eq "Required") -or ($EncryptionLevel -eq "NoEncryption") -or ($EncryptionLevel -eq "Optional") -or ($EncryptionLevel -eq "Maximum")) {
} else {
    Write-Output "Specified encryption level $EncryptionLevel is not supported."
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to create VPN connection - Specified encryption level $EncryptionLevel is not supported.", "Error", 400)
    Break
}
  
try {
    Add-VpnConnection -Name $Name -ServerAddress $Server -TunnelType SSTP -EncryptionLevel $EncryptionLevel -AllUserConnection -Force -ErrorAction Stop
    Write-Output "VPN connection $Name has been successfully created."
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "VPN connection $Name has been successfully created by VSA X script.", "Information", 200)
} catch {
    Write-Output "Unable to create vpn connection."$_.Exception.Message
}