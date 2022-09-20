<#
=================================================================================
Script Name:        Management: Create L2TP connection.
Description:        Creates VPN connection
Lastest version:    2022-07-29
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

#Name of the vpn connection
[string]$Name = ""

#Hostname of the server
[string]$Server = ""

#Preshared key
[string]$PresharedKey = ""

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

if ($Presharedkey) {
    
    try {
        Add-VpnConnection -Name $Name -ServerAddress $Server -TunnelType L2TP -EncryptionLevel $EncryptionLevel -L2tpPsk $Presharedkey -AllUserConnection -Force -ErrorAction Stop
        Write-Output "VPN connection $Name has been successfully created."
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "VPN connection $Name has been successfully created by VSA X script.", "Information", 200)
    } catch {
        Write-Output "Unable to create vpn connection."$_.Exception.Message
    }

} else {
    try {
        Add-VpnConnection -Name $Name -ServerAddress $Server -TunnelType L2TP -EncryptionLevel $EncryptionLevel -AllUserConnection -ErrorAction Stop
        Write-Output "VPN connection $Name has been successfully created."
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "VPN connection $Name has been successfully created by VSA X script.", "Information", 200)

    } catch {
        Write-Output "Unable to create vpn connection."$_.Exception.Message
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to create VPN connection.", "Error", 400)
    }
}