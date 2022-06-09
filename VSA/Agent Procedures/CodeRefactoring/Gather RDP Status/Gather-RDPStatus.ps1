#This script checks if Windows Registry contains key which denies RDP connection, to understand if RDP connections are allowed

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