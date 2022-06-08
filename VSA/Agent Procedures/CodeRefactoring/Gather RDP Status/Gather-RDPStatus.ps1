#This script checks if Windows Registry contains key which denies RDP connection, to understand if RDP connections are allowed

function CheckRDPStatus() {

    $RDPStatus = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue| Select-Object -Property fDenyTSConnections).fDenyTSConnections

    if ($RDPStatus -eq 0) {
        return "Enabled"
    } else {
        return "Disabled"
    }

}

CheckRDPStatus