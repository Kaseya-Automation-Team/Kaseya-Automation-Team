$ifList = Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -ExpandProperty 'ifIndex'

if ($ifList -eq $null) {

    Write-Host "There are no active network adapters."

} else {

    ForEach($if in $ifList)
    {
	    Get-DnsClientServerAddress | Where-Object {($_.InterfaceIndex -eq $ifList) -and ($_.ServerAddresses -ne $null)} |Select-Object InterfaceAlias, ServerAddresses|Format-Table -HideTableHeaders
    }

}