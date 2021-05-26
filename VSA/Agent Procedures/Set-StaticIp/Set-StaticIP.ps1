$connectedIndexes = Get-NetAdapter -physical | Where-Object {$_.MediaConnectionState -EQ 'Connected'} | Select-Object -ExpandProperty ifIndex
Foreach ($connectedIndex in $connectedIndexes)
{
   [hashtable] $adapterParameters = @{AddressFamily = 'IPv4'}

   [string] $IPAddress = Get-NetIPConfiguration -interfaceIndex $connectedIndex -Detailed | Select-Object -ExpandProperty IPv4Address | Select-Object -ExpandProperty IPAddress
   if (-not [string]::IsNullOrEmpty($IPAddress)) {$adapterParameters.Add('IPAddress', $IPAddress)}

   [string] $DefaultGateway = Get-NetIPConfiguration -interfaceIndex $connectedIndex -Detailed | Select-Object -ExpandProperty IPv4DefaultGateway | Select-Object -ExpandProperty nexthop
   if (-not [string]::IsNullOrEmpty($DefaultGateway)) {$adapterParameters.Add('DefaultGateway', $DefaultGateway)}

   [string] $PrefixLength = Get-NetIPAddress -InterfaceIndex $connectedIndex -AddressFamily IPv4 | Select-Object -ExpandProperty PrefixLength
   if (-not [string]::IsNullOrEmpty($PrefixLength)) {$adapterParameters.Add('PrefixLength', $PrefixLength)}

   [string] $InterfaceAlias = Get-NetIPAddress -InterfaceIndex $connectedIndex -AddressFamily IPv4 | Select-Object -ExpandProperty InterfaceAlias
   if (-not [string]::IsNullOrEmpty($InterfaceAlias)) {$adapterParameters.Add('InterfaceAlias', $InterfaceAlias)}

   [string[]] $DNSServers = Get-NetIPConfiguration -interfaceIndex $connectedIndex -Detailed | Select-Object -ExpandProperty DNSServer | Where-Object {$_.AddressFamily -eq "2"} | Select-Object -ExpandProperty ServerAddresses

   if (-not [string]::IsNullOrEmpty($IPAddress))
   {
        Remove-NetIPAddress -InterfaceIndex $connectedIndex -Confirm:$false
        if (-not [string]::IsNullOrEmpty($DefaultGateway))
        {
            Remove-NetRoute -InterfaceIndex $connectedIndex -Confirm:$false
        }
   }  
    
   New-NetIPAddress @adapterParameters

   if($DNSServers.Count -gt 0)
   {
        Set-DnsClientServerAddress -InterfaceIndex $connectedIndex -ServerAddresses $adapterParameters.DNSServers
   }
   Set-NetIPInterface -InterFaceIndex $connectedIndex -Dhcp disabled
}