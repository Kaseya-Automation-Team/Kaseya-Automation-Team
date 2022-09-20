<#
=================================================================================
Script Name:        Management: Enable Windows Firewall.
Description:        This script silently enables firewall on Windows machines.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Enable Windows Firewall
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True
Write-Host "Windows Firewall has been enabled"
eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Windows Firewall has been enabled" | Out-Null