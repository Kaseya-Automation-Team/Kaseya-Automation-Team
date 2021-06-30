## Kaseya Automation Team
## Used by the "Install Unifi Controller" Agent Procedure

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

        $TaskAction = New-ScheduledTaskAction -Execute "$Path\OneDriveSetup.exe" -Argument "/silent /allusers"

        $Repeat = (New-TimeSpan -Minutes 10)

        $RunAt = (Get-Date).Date.AddHours(2)

        $TaskTrigger = New-ScheduledTaskTrigger -Once -At $RunAt

        Register-ScheduledTask -TaskName "InstallOneDrive" -User $User -RunLevel Highest -Action $TaskAction -Trigger $TaskTrigger -Description "Start OneDrive installer" -ErrorAction Stop

        $TaskExists = Get-ScheduledTask -TaskName "InstallOneDrive" -ErrorAction SilentlyContinue

        if ($TaskExists) {
            Write-Host "Installation task has been successfully created."
        }

    } catch {
        #Handle errors
        Write-Host "Unable to create task."
        Write-Host $_.Exception.Message
    }
}

if ($Run) {
    Start-ScheduledTask -TaskName "InstallOneDrive"

    $timeout = 360 ##  seconds

    $timer =  [Diagnostics.Stopwatch]::StartNew()

    while (((Get-ScheduledTask -TaskName "InstallOneDrive").State -ne  "Ready") -and  ($timer.Elapsed.TotalSeconds -lt $timeout)) {    

      Start-Sleep -Seconds  3

    }

    $timer.Stop()

    Unregister-ScheduledTask -TaskName "InstallOneDrive" -Confirm:$false

    $Status = (Get-Package | Where-Object {$_.Name -eq "Ubiquiti UniFi (remove only)"} | Select-Object -Property Status).Status

    if ($Status -eq "Installed") {
        Write-Host "Installation has been successully completed"
    } else {
        Write-Host "Installation could not be completed"
    }

}