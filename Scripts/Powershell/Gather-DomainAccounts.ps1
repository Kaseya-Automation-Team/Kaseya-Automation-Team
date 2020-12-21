<#
.Synopsis
   Gathers domain users accounts on the computer.
.DESCRIPTION
   Gathers domain users accounts on the computers and saves information to a CSV-file
.EXAMPLE
   .\Gather-DomainAccounts.ps1 -AgentName '12345' -FileName 'domain_accounts.csv' -Path 'C:\TEMP'
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

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[string[]]$Props = @('Domain', 'Name', 'Status', 'Disabled')

[string]$Query = "SELECT $( $Props -join ',' ) FROM Win32_UserAccount WHERE LocalAccount='False'"

Get-WmiObject -Namespace root\cimv2 -Query $Query | Select-Object $Props | Select-Object -Property `
@{Name = 'Date'; Expression = {$currentDate }}, `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
@{Name = 'AgentGuid'; Expression = {$AgentName}}, `
* | Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation