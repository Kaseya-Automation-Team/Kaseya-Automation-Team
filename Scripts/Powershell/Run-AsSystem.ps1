<#
.Synopsis
   Creates and runs as a system the script provided
.DESCRIPTION
   The scheduled task is created and launched in order to run provided script as the local system
.EXAMPLE
   .\Run-AsSystem -ScheduledScriptName 'Wipe-TheSystem.ps1'
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string]$ScheduledScriptName
 )
[string]$TaskName = "Schedule $(Split-Path $ScheduledScriptName -leaf)"

$ScheduledTaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
$SettingsSet = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd
$ScheduledTaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date)

$ScheduledTaskActionParams = @{
    Execute = "PowerShell.exe" 
    Argument = "-NoProfile -ExecutionPolicy Bypass -NonInteractive -Command $ScheduledScriptName"
}
$ScheduledTaskAction = New-ScheduledTaskAction @ScheduledTaskActionParams

Register-ScheduledTask -Force -Principal $ScheduledTaskPrincipal -Trigger $ScheduledTaskTrigger -TaskName $TaskName -Action $ScheduledTaskAction -Settings $SettingsSet

Start-ScheduledTask -TaskName $TaskName