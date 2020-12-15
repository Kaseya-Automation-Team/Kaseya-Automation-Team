<#
.Synopsis
   Gather list of Top (3 by default) latest updates and saves information to a csv-file
.DESCRIPTION
   Gather list of Top given number latest updates and saves information as well as last boot time to a csv-file
.EXAMPLE
   .\Gather-LastOSPatchesInstalled.ps1 -FileName 'biggestfolders.csv' -Path 'C:\TEMP' -AgentName '123456'
.EXAMPLE
    .\Gather-LastOSPatchesInstalled.ps1 -FileName 'biggestfolders.csv' -Path 'C:\TEMP' -AgentName '123456' -Top 10
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    [parameter(Mandatory=$false)]
    [int]$Top = 3
 )

[string] $LastBootUp = "{0:dd'/'MM'/'yyyy H:mm:ss}" -f (Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime)

Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object HotFixID, InstalledOn -First $Top | Select-Object -Property `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
@{Name = 'AgentGuid'; Expression = {$AgentName}}, `
@{Name = 'PatchName'; Expression = {$_.HotFixID}}, `
@{Name = 'InstallData'; Expression = {"{0:dd'/'MM'/'yyyy}" -f $_.InstalledOn}}, `
@{Name = 'LastBootTime'; Expression = {$LastBootUp}} `
| Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation