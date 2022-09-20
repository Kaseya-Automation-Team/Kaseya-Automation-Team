<#
=================================================================================
Script Name:        Management: Disable Windows Firewall.
Description:        This script silently disables firewall on Windows machines.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Disable Windows Firewall
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
Write-Host "Windows Firewall has been disabled"
eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Windows Firewall has been disabled" | Out-Null