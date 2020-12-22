<#
.Synopsis
   Gathers time settings.
.DESCRIPTION
   Gathers time settings and saves information to a CSV-file
.EXAMPLE
   .\Gather-TimeZoneSettings.ps1 -AgentName '12345' -FileName 'timezone_settings.csv' -Path 'C:\TEMP'
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path
 )

[string]$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

#get NTP peers
$PeersNTP = $(w32tm.exe /query /peers) 

[string]$NTPServer = $(
    if ( $PeersNTP -match 'error')
    {
        'NTP not obtained'
    }
    else
    {
        [string]$regexp = '(Peer:\s+)(\S+)?$' # look for string that starts with 'Peer:'
        $PeersNTP | `
        Foreach-Object {[regex]::match( $_, $regexp ).Groups[2].Value} | `  # get server name in the matching string
        Where-Object { -not [string]::IsNullOrWhiteSpace($_)} | `   #get rid of empty lines
        Select-Object -Unique | Select-Object -First 1  #get the first server
    }
)

$OutputObject = New-Object PSObject -Property @{
AgentGuid = $AgentName
Hostname = $env:COMPUTERNAME
Date = $currentDate
Offset = $( [System.TimeZoneInfo]::Local.BaseUtcOffset ).ToString()
DST = $( [System.TimeZoneInfo]::Local.SupportsDaylightSavingTime ).ToString()
Server = $NTPServer
}
$OutputObject | Export-Csv -Path "FileSystem::$FileName" -Force -Encoding UTF8 -NoTypeInformation