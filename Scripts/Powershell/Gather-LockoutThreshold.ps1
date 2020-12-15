## Kaseya Automation Team
## Used by the "Gather Account Lockout Threshold" Agent Procedure
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)


$Output = New-Object psobject

Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName

#Store path to temp directory into custom variable
$Temp = $env:TEMP

#If computer is NOT part of domain, export current security policies into file
secedit.exe /export /cfg $Temp\secpol.cfg /quiet

#Gather value of account lockout threshold
$LockoutThreshold = Get-Content $Temp\secpol.cfg | Select-String -Pattern "LockoutBadCount = [0-9]+"
$LockoutThreshold =  $LockoutThreshold.Line.Split(" = ")[3]

#Clean up
Remove-Item -force $Temp\secpol.cfg -confirm:$false
Add-Member -InputObject $Output -MemberType NoteProperty -Name AccountLockoutThreshold -Value $LockoutThreshold

Export-Csv -InputObject $Output -Path $Path -NoTypeInformation