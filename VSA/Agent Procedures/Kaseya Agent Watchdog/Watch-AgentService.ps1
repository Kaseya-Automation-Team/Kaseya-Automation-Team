## Kaseya Automation Team
## Used by the "Kaseya Agent Watchdog" Agent Procedure

#Get folder where script remains
$ScriptDir = Split-Path ($MyInvocation.MyCommand.Path) -Parent

#Get name of the script
$ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )

#Combine path to the log file
$Log = "$ScriptDir\$ScriptName.log"

#Implement logging with date/time
Function Log {
    param(
        [Parameter(Mandatory=$true)][String]$msg
    )
    $DateTime = Get-Date -Format "dd.mm.yyyy hh:mm:ss.ms"
    Add-Content $Log ($DateTime + " " + $msg)

    #Uncomment line below, if you also want log entries to be displayed under Procedure History log, not only recorded to log file
    #Write-Host $msg
}

#Check if Kaseya Agent service is present and identify it's Name (instead of Display Name)
$ServiceName = Get-Service -DisplayName 'Kaseya Agent' | Select-Object -ExpandProperty Name

#Get status of Kaseya Agent service
$isRunning = Get-Service -Name $ServiceName

if ($isRunning.Status -eq "Stopped") {
    #If status is stopped - restart
    Log("Service is not running, trying to restart")
    Restart-Service -Name $ServiceName
} else {
    if ($isRunning.Status -eq "Running") {
       #If status is running - do nothing
       Log("Service is already running - not restarting")
    }
    
}
