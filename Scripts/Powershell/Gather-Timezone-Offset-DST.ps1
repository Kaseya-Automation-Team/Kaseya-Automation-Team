## Kaseya Automation Team
## Used by the "Gather Timezone Offset and DST settings" Agent Procedure
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)

$UTCOffset = Get-TimeZone|Select-Object -ExpandProperty BaseUTCOffset

$DSTstatus = Get-TimeZone|Select-Object -ExpandProperty SupportsDaylightSavingTime

$Output = New-Object psobject
Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName
Add-Member -InputObject $Output -MemberType NoteProperty -Name Offset -Value $UTCOffset
Add-Member -InputObject $Output -MemberType NoteProperty -Name DST -Value $DSTstatus

Export-Csv -InputObject $Output -Path $Path -NoTypeInformation