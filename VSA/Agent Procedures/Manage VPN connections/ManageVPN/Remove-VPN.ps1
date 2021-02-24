## Kaseya Automation Team
## Used by the "Remove VPN Connection" Agent Procedure


param (
    [parameter(Mandatory=$true)]
    [string]$Name = ""
)

$Exists = Get-VpnConnection | Select-Object -Property Name|Where-Object {$_.Name -eq $Name}

if ($Exists) {
    try {
        Remove-VpnConnection -Name $Name -Force -ErrorAction Stop
        Write-Host "VPN connection $Name has been successfully removed."
    } catch {
        Write-Host "Unable to delete:"$_.Exception.Message
    }

} else {
    Write-Host "VPN connection $Name doesn't exist on this computer."
}