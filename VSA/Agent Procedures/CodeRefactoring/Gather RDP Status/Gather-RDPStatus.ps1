<#
=================================================================================
Script Name:        Audit: Security: Gather RDP Status.
Description:        Checks if Windows Registry contains key which denies RDP connection, to understand if RDP connections are allowed.
Lastest version:    2022-06-09
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

# Outputs
$RDPStatus = "Null"

function CheckRDPStatus() {

    $CurrentRDPStatus = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue| Select-Object -Property fDenyTSConnections).fDenyTSConnections

    if ($CurrentRDPStatus -eq 0) {
        return "Enabled"
    } else {
        return "Disabled"
    }

}

Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable RDPStatus ""CheckRDPStatus""") -Wait