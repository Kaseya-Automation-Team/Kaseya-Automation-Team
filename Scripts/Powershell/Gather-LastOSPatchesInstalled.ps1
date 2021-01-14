<#
.Synopsis
   Gather list of Top (3 by default) latest Windows updates and saves information to a csv-file
.DESCRIPTION
   Gather list of Top given number latest Windows updates and saves information as well as last boot time to a csv-file
.EXAMPLE
   .\Gather-LastOSPatchesInstalled.ps1 -FileName 'latest_os_patches.csv' -Path 'C:\TEMP' -AgentName '123456'
.EXAMPLE
    .\Gather-LastOSPatchesInstalled.ps1 -FileName 'latest_os_patches.csv' -Path 'C:\TEMP' -AgentName '123456' -Top 10
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
    [string]$Path,
    [parameter(Mandatory=$false)]
    [int]$Top = 3
 )

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

#[string] $LastBootUp = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f [System.Management.ManagementDateTimeConverter]::ToDateTime($(Get-WmiObject -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime))
[string] $LastBootUp = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f (Get-Date).AddMilliseconds( -([System.Environment]::TickCount) )

Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object HotFixID, InstalledOn -First $Top | Select-Object -Property `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
@{Name = 'AgentGuid'; Expression = {$AgentName}}, `
@{Name = 'PatchName'; Expression = {$_.HotFixID}}, `
@{Name = 'InstallData'; Expression = {"{0:MM'/'dd'/'yyyy}" -f $_.InstalledOn}}, `
@{Name = 'LastBootTime'; Expression = {$LastBootUp}} `
| Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation