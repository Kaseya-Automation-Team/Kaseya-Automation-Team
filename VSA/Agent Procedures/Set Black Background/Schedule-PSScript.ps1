param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ScheduledTaskAction,
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $TaskName
)

if ( $null -eq $(try {Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop} Catch {$null}) )
{
    $Trigger = New-ScheduledTaskTrigger -AtLogon
    $Principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users"
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $ScheduledTaskAction
    Register-ScheduledTask -TaskName 'SetBackgroundBlack' -Action $Action -Principal $Principal -Trigger $Trigger
}
