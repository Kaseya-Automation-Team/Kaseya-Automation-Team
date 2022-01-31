$ifList = Get-NetAdapter -physical | where status -eq 'Up' | select-object -ExpandProperty 'ifIndex'

ForEach($if in $ifList)
{
	Get-DnsClientServerAddress | Where-Object {($_.InterfaceIndex -eq $iflist) -and ($_.ServerAddresses -ne $null)} |Select-Object InterfaceAlias, ServerAddresses | Out-File -FilePath C:\temp\DnsEntries.txt
}

