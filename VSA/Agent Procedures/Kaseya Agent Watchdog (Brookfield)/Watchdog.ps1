function Check-ServiceStatus {
    Get-Service | Where-Object {$_.DisplayName -eq "Kaseya Agent"} | Select-Object -ExpandProperty Status
}

function Log-Event {
    param(        
        [Parameter(Mandatory=$true)][String]$Msg,
        [Parameter(Mandatory=$true)][Int]$Id,
        [Parameter(Mandatory=$true)][String]$Type
    )
    Write-EventLog –LogName Application –Source “Kaseya Agent Watchdog” –EntryType $Type –EventID $Id  –Message $Msg -Category 0
}

$SourceExists = [System.Diagnostics.EventLog]::SourceExists("Kaseya Agent Watchdog")

if ($SourceExists -eq $false) {
    New-EventLog –LogName Application –Source “Kaseya Agent Watchdog”
}

$ActiveConnection = $false
$ServiceStatus = Check-ServiceStatus

qwinsta | foreach {
    if ($_ -like "*rdp*"  -and $_ -like "*Active*") {
        $ActiveConnection = $true
    }
}

if ($ActiveConnection -eq $false) {
    

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

}