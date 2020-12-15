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

[string]$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[string[]]$Props = @('Caption', 'Version', 'BuildNumber', 'OSArchitecture')
Get-CimInstance Win32_OperatingSystem -Property $Props | Select-Object $Props | Select-Object -Property @{Name = 'Date'; Expression = {$currentDate }}, @{Name = 'AgentGuid'; Expression = {$AgentName}}, @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}} , *  `
| Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation