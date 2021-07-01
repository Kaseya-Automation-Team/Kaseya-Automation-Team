## Kaseya Automation Team
## Used by the "Install/Uninstall Microsoft OneDrive" Agent Procedure

param (
    [parameter(Mandatory=$true)]
	[string]$Path = "",
    [parameter(Mandatory=$true)]
	[string]$User = "",
    [switch]$Install = $false,
    [switch]$Run = $false
)

if ($Install) {

    try {

        $TaskAction = New-ScheduledTaskAction -Execute "$Path" -Argument "/uninstall"

        $Repeat = (New-TimeSpan -Minutes 10)

        $RunAt = (Get-Date).Date.AddHours(2)

        $TaskTrigger = New-ScheduledTaskTrigger -Once -At $RunAt

        Register-ScheduledTask -TaskName "UninstallOneDrive" -User $User -RunLevel Highest -Action $TaskAction -Trigger $TaskTrigger -Description "Start OneDrive uninstaller" -ErrorAction Stop

        $TaskExists = Get-ScheduledTask -TaskName "UninstallOneDrive" -ErrorAction SilentlyContinue

        if ($TaskExists) {
            Write-Host "Uninstall task has been successfully created."
        }

    } catch {
        #Handle errors
        Write-Host "Unable to create task."
        Write-Host $_.Exception.Message
    }
}

if ($Run) {
    Start-ScheduledTask -TaskName "UninstallOneDrive"

    $timeout = 360 ##  seconds

    $timer =  [Diagnostics.Stopwatch]::StartNew()

    while (((Get-ScheduledTask -TaskName "UninstallOneDrive").State -ne  "Ready") -and  ($timer.Elapsed.TotalSeconds -lt $timeout)) {    

      Start-Sleep -Seconds  3

    }

    $timer.Stop()

    Unregister-ScheduledTask -TaskName "UninstallOneDrive" -Confirm:$false

    $Status = (Get-Package | Where-Object {$_.Name -eq "Microsoft OneDrive"} | Select-Object -Property Status).Status

    if ($Status -eq "Installed") {
        Write-Host "Installation has been successully completed"
    } else {
        Write-Host "Installation could not be completed"
    }

}