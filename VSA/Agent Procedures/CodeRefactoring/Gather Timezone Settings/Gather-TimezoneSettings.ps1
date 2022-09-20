<#
=================================================================================
Script Name:        Audit: Gather Timezone Settings.
Description:        Gather Timezone Settings. Collects information about UTC offset and time zone
Lastest version:    2022-06-09
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

$TimeZone = "Null"

$Offset = (Get-TimeZone|Select-Object -Property DisplayName).DisplayName

Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable TimeZone ""$Offset""") -Wait