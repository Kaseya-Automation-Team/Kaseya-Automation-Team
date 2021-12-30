<#
.Synopsis
   Checks if services with given display names are stopped and makes attempt to start them if there are no active RDP connections.
.DESCRIPTION
   Checks if services with given display names are stopped and makes attempt to start them if there are no active RDP connections.
   Information on services' state is logged to the Kaseya Agent Watchdog log.
   Used by the "Kaseya Agent Watchdog for Brookfield" Agent Procedure
.EXAMPLE
   .\Watch-AgentService.ps1 -ServicesDisplayNames "Kaseya Agent", "Kaseya Agent Endpoint"
   .EXAMPLE
   .\Watch-AgentService.ps1 -ServicesDisplayNames "Kaseya Agent", "Kaseya Agent Endpoint" -LogIt
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true,
                Position=0)]
    [ValidateNotNull()] 
    [string[]] $ServicesDisplayNames
)
[string] $LogName = "Kaseya Agent Watchdog"
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


#Proceed if there are no active RDP sessions
if ( -not $ActiveConnection ) {
    #If a Kaseya Agent service is not running, start it
    $ServicesToWatch = Get-Service -DisplayName $ServicesDisplayNames
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