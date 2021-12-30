## Kaseya Automation Team
## Used by the "Kaseya Agent Watchdog for Brookfield" Agent Procedure

#Check the state of Kaseya Agent Service
function Check-ServiceStatus {
    Get-Service | Where-Object {$_.DisplayName -eq "Kaseya Agent"} | Select-Object -ExpandProperty Status
}

#Log entries to Application log
function Log-Event {
    param(        
        [Parameter(Mandatory=$true)][String]$Msg,
        [Parameter(Mandatory=$true)][Int]$Id,
        [Parameter(Mandatory=$true)][String]$Type
    )
    Write-EventLog –LogName Application –Source “Kaseya Agent Watchdog” –EntryType $Type –EventID $Id  –Message $Msg -Category 0
}

#Check if log source alread exists
$SourceExists = [System.Diagnostics.EventLog]::SourceExists("Kaseya Agent Watchdog")

#If not, create a new one
if ($SourceExists -eq $false) {
    New-EventLog –LogName Application –Source "Kaseya Agent Watchdog"
}

#Define variables
$ActiveConnection = $false
$ServiceStatus = Check-ServiceStatus

#Check active RDP sessions
qwinsta | foreach {
    if ($_ -like "*rdp*"  -and $_ -like "*Active*") {
        $ActiveConnection = $true
    }
}

#If no active RDP sessions, then proceed
if ($ActiveConnection -eq $false) {
    
    #If Kaseya Agent service is not running, restart it
    if ($ServiceStatus -eq "Running") {
    
        Log-Event -Msg "Service is already running, not doing anything." -Id 1 -Type "Information"
    
        } else {

        Log-Event -Msg "Service is not running, restarting" -Id 2 -Type "Information"
        try {
            Start-Service -DisplayName "Kaseya Agent"
            Log-Event -Msg "Service has been started" -Id 3 -Type "Information"
        } catch {
            Log-Event -Msg "Unable to restart the service. Please check logs for details." -Id 10 -Type "Error"
            Log-Event -Msg "$_.Exception.Message" -Id 10 -Type "Error"
        }
    }

} else {
    Log-Event -Msg "Active RDP connection detected - not proceeding to restart." -Id 1 -Type "Information"
}