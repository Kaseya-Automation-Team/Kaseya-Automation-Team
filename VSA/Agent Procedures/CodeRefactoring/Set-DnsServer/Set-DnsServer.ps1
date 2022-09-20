<#
=================================================================================
Script Name:        Management: Set DNS Server.
Description:        Set DNS Server.
Lastest version:    2022-06-03
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
$ifList = Get-NetAdapter -physical | where status -eq 'Up' | select-object -ExpandProperty 'ifIndex'


#Please enter the DNS server address below
$primaryDns = 192.168.1.1
$secondaryDns = 192.168.1.1


ForEach($if in $ifList)
{
	$ifName = Get-NetAdapter -physical | where ifIndex -eq $if | select-object -ExpandProperty 'Name'
	Write-Output "Adapter ID:$if - Name: $ifName"
}

ForEach($if in $ifList)
{
	$ifName = Get-NetAdapter -physical | where ifIndex -eq $if | select-object -ExpandProperty 'Name'
	Write-Output "Setting Primary DNS Server to: $primaryDns on Adapter ID: $if - Name: $ifName"
	Write-Output "Setting Secondary DNS Server to: $secondaryDns on Adapter ID: $if - Name: $ifName"
	Set-DnsClientServerAddress -InterfaceIndex $if -ServerAddresses ("$primaryDns", "$secondaryDns")
    eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Setting Primary DNS Server to: $primaryDns on Adapter ID: $if - Name: $ifName" | Out-Null
    eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Setting secondary DNS Server to: $secondaryDns on Adapter ID: $if - Name: $ifName" | Out-Null
}