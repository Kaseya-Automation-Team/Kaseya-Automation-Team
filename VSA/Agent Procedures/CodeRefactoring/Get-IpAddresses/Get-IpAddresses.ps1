<#
=================================================================================
Script Name:        Audit: Get-IpAddresses.
Description:        This script allows fetch information about IP addresses on all connected network adapters.
Lastest version:    2022-06-03
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
$Results = @(); 

$LocalIP = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress

Get-NetIPInterface -AddressFamily IPv4| Where-Object -Property ConnectionState -eq 'Connected'| foreach {$ifIndex = $_.ifIndex; $ipAddress = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {($_.ifIndex -eq $ifIndex) -and ($_.ifIndex -ne 1) -and $_.IPAddress -ne $LocalIP} | Select-Object -ExpandProperty IPAddress; $Results += $ipAddress}; $Results -join ', '

eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "$Results is/are the Ip Address(es) of ALL the network devices" | Out-Null