## Kaseya Automation Team
## Used by the "Gather Timezone Offset and DST settings" Agent Procedure
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)

$NTPStatus = w32tm.exe /query /peers

$UTCOffset = Get-TimeZone|Select-Object -ExpandProperty BaseUTCOffset

$DSTstatus = Get-TimeZone|Select-Object -ExpandProperty SupportsDaylightSavingTime

$Output = New-Object psobject

Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName

if ($NTPStatus -like "*has not been started*") {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name Server -Value "NULL"
} else {
    $NTPServer = $NTPStatus|Select-String -Pattern 'Peer:' | Select-Object -First 1 | Foreach {$_.Line.Split(': ')[2].Split(',')[0];}
    Add-Member -InputObject $Output -MemberType NoteProperty -Name Server -Value $NTPServer
}

Add-Member -InputObject $Output -MemberType NoteProperty -Name Offset -Value $UTCOffset
Add-Member -InputObject $Output -MemberType NoteProperty -Name DST -Value $DSTstatus

Export-Csv -InputObject $Output -Path $Path -NoTypeInformation