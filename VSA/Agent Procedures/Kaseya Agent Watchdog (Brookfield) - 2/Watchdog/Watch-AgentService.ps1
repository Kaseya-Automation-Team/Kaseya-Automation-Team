## Kaseya Automation Team
## Used by the "Kaseya Agent Watchdog for Brookfield" Agent Procedure[string]$LogName = "Kaseya Agent Watchdog"

if ( -not [System.Diagnostics.EventLog]::SourceExists($LogName) ) { 
    New-EventLog -LogName Application -Source $LogName
}

#Define variables
[bool]$ActiveConnection = $false

#Check active RDP sessions
qwinsta | ForEach-Object {
    if ($_ -like "*rdp*" -and $_ -like "*Active*") {
        $ActiveConnection = $true
    }
}

#Information to log
[hashtable]$EventData = @{
            LogName   = 'Application'
            Source    = 'Kaseya Agent Watchdog'
            Category  = 0
            EventID   = 0
            EntryType = 'Information'
            Message   = 'Kaseya Agent Watchdog'
        }

#Rename service if old names found
[string]$OldName = "Kaseya Agent*"
[string]$NewName = "STCST976705554315707"
$ServicesToWatch = Get-Service -DisplayName $OldName
if (0 -lt $ServicesToWatch.Count) {
    Foreach ($Service in $ServicesToWatch) {
        $OldDisplayName = $Service.DisplayName
        $NewDisplayName = $OldDisplayName -replace $OldName, $NewName
        Set-Service -Name $Service.Name -DisplayName $NewDisplayName
        $EventData.Message = "Display name of the service $($Service.Name) changed from  $OldDisplayName to $NewDisplayName"
        Write-EventLog @EventData
    }
}

#Proceed if there are no active RDP sessions
if ( -not $ActiveConnection ) {
    
    #If a Kaseya Agent service is not running, start it
    $ServicesToWatch = Get-Service -DisplayName "$NewName*"
    Foreach ($Service in $ServicesToWatch) {
        switch ( $Service.Status ) {
            'Stopped' {
                $EventData.EventID = 2
                $EventData.EntryType = 'Information'
                $EventData.Message = "The service $($Service.DisplayName) is stopped. Attempt to start"
                Write-EventLog @EventData
                try {
                    Start-Service $Service
                    $EventData.EntryType = 'Information'
                    $EventData.EventID = 3
                    $EventData.Message = "The service $($Service.DisplayName) has been started."
                    Write-EventLog @EventData
                } catch {
                    $EventData.EventID   = 10
                    $EventData.EntryType = 'Error'
                    $EventData.Message   = "Could not start the service $($Service.DisplayName). Please check logs for details."
                    Write-EventLog @EventData
                    $EventData.Message = "$_.Exception.Message"
                    Write-EventLog @EventData
                }
            }
            'Running' {
                $EventData.EntryType = 'Information'
                $EventData.EventID = 1
                $EventData.Message = "Service $($Service.DisplayName) is running. No action required"
                Write-EventLog @EventData
            }
            default {
                $EventData.EntryType = 'Information'
                $EventData.EventID = 4
                $EventData.Message = "The service $($Service.DisplayName) status is $($Service.Status)"
                Write-EventLog @EventData
            }
        }
    }
}