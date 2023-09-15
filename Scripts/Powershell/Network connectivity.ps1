# Release IP
ipconfig /release

# Renew IP
ipconfig /renew

# Run Network Diagnostics
msdt.exe /id NetworkDiagnosticsNetworkAdapter

# Get the network adapter
$adapter = Get-NetAdapter | ? {$_.Status -eq 'up'}

# Disable the network adapter
Disable-NetAdapter -Name $adapter.Name -Confirm:$false

# Enable the network adapter
Enable-NetAdapter -Name $adapter.Name -Confirm:$false
