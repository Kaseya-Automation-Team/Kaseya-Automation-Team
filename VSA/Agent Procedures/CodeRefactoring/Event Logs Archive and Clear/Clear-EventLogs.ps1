<#
=================================================================================
Script Name:        Management: Event Logs Archive And Clear.
Description:        Archives and Clears non-empty Windows Event Logs.
Lastest version:    2022-04-19
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

#Path to store backed up Logs. Provide custom path if needed
$ArchivePath = "$env:SystemRoot\system32\winevt\Logs" 

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}
[string[]]$NonEmptyLogs = @()
$NonEmptyLogs += try {
    Get-WmiObject -Query 'SELECT LogfileName FROM Win32_NTEventLogFile WHERE NumberOfRecords > 0' -ErrorAction Stop `
        | Select-Object -ExpandProperty LogfileName
} Catch {$null}

if ( 0 -lt $NonEmptyLogs.Count) {
    Foreach ($LogName in $NonEmptyLogs) {
        $Log = Get-WmiObject -Query "SELECT * FROM Win32_NTEventLogFile WHERE LogfileName = '$LogName'"
        $BackupFileName = "Archived-$($Log.LogfileName)-$("{0:MM'-'dd'-'yyyy'-'H'h'mm'm'ss's'}" -f (Get-Date))"
        $Path = Join-Path -Path $ArchivePath -ChildPath "$BackupFileName.evtx"
        $BackupResult = ($Log.BackupEventLog($Path)).ReturnValue
        if(0 -eq $BackupResult) {
            [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Event log $($Log.LogfileName) backed up.", "Information", 200)
            $ClearResult = ($Log.ClearEventLog()).ReturnValue
                if(0 -eq $ClearResult) {
                    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Event log $($Log.LogfileName) cleared.", "Information", 200)
                    Compress-Archive -Path $Path -DestinationPath $(Join-Path -Path $ArchivePath -ChildPath "$BackupFileName.zip") -Force
                    Remove-Item -Path $Path -Force -Confirm:$false
                } else {
                    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$($Log.LogfileName) Log clear failed with error [$ClearResult].", "Error", 400)
                }
        } else {
            [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$($Log.LogfileName) Log backup failed with error [$BackupResult]. Not cleared", "Error", 400)
        }
    }
}