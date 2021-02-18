$ifList = Get-NetAdapter -physical | where status -eq 'Up' | select-object -ExpandProperty 'ifIndex'

$primaryDns = $args[0]
$secondaryDns = $args[1]

echo "Requested Primary DNS Server: $primaryDns"
echo "Requested Secondary DNS Server: $secondaryDns"

echo "Active Physical Adapters Found:"
ForEach($if in $ifList)
{
	$ifName = Get-NetAdapter -physical | where ifIndex -eq $if | select-object -ExpandProperty 'Name'
	echo "Adapter ID:$if - Name: $ifName"
}

ForEach($if in $ifList)
{
	$ifName = Get-NetAdapter -physical | where ifIndex -eq $if | select-object -ExpandProperty 'Name'
	echo "Setting Primary DNS Server to: $primaryDns on Adapter ID: $if - Name: $ifName"
	echo "Setting Secondary DNS Server to: $secondaryDns on Adapter ID: $if - Name: $ifName"
	Set-DnsClientServerAddress -InterfaceIndex $if -ServerAddresses ("$primaryDns", "$secondaryDns")
}


