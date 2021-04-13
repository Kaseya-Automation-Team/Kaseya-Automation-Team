<#
.Synopsis
   Backs up & clears Event Logs
.DESCRIPTION
   Gets non-empty event Logs, backs up & clears those logs
.NOTES
   Version 0.1
   Author: Proserv Team - VS
.PARAMETER(s)
    None
.EXAMPLE
   .\Archive-Events
.EXAMPLE
   .\Archive-Events -AgentName 12345 -ArchivePath 'C:\archive'
.EXAMPLE
   .\Check-Firefox -LogIt 1
#>

param (
    [parameter(Mandatory=$true)]
    [string] $AgentName,
    [parameter(Mandatory=$true)]
    [string] $ArchivePath,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

[string] $DateFormat = "{0:MM'-'dd'-'yyyy'-'H'h'mm'm'ss's'}"

$NonEmptyLogs = try {Get-WmiObject -Query 'SELECT * FROM Win32_NTEventLogFile WHERE NumberOfRecords > 0' -ErrorAction Stop} Catch {"WMI Query Error: $($_.Exception.Message)"}
if ($NonEmptyLogs -notmatch 'Error')
{
    $ResultArray = @()
    Foreach ($Log in $NonEmptyLogs)
    {
        $Path = Join-Path -Path $ArchivePath -ChildPath "$env:COMPUTERNAME $($Log.LogfileName) $($DateFormat -f (Get-Date)).evt"
        $BackupResult = ($Log.BackupEventLog($Path)).ReturnValue
        if(0 -eq $BackupResult)
        {
            $ResultArray += "Event log $($Log.LogfileName) backed up to $Path."
            $ClearResult = ($Log.ClearEventLog()).ReturnValue
            if(0 -eq $ClearResult)
            {
                $ResultArray += "Event log $($Log.LogfileName) cleared."
            }
            else
            {
                $ResultArray += "Unable to clear event log $($Log.LogfileName). Clear Error was $ClearResult."
            }
        }
        else
        { 
            $ResultArray += "Unable to clear event log $($Log.LogfileName) because backup failed. Backup Error was $BackupResult."
        }
    }
    $Result = $ResultArray -join "`n"
}
else
{
    $Result = $NonEmptyLogs
}
Write-Output $Result

#region check/stop transcript
if ( 1 -eq $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript