<#
.Synopsis
   Gathers computers that are inactive for given amount of days.
   Based on the the lastLogonDate AD attribute since it is replicated to all the domain controllers while the LastLogon attribute is not replicated.
.DESCRIPTION
   Finds inactive computers in AD and saves information to file
.EXAMPLE
   Gather-InactiveComputers -AgentName '12345' -FileName 'inactive_computers.txt' -Path 'C:\TEMP' -Days 63
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
    [parameter(Mandatory=$true)]
    [uint16]$Days
 )

[string]$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

Import-Module ActiveDirectory
$Older = [datetime]::Today.AddDays(-($Days))

$InactiveComputers = Get-ADComputer -Filter {( LastLogonDate -lt $Older ) -and (Enabled -eq $true)} -Properties LastLogonDate | Select-Object DistinguishedName, LastLogonDate

if (0 -lt $InactiveComputers.Length)
{
 $InactiveComputers | Select-Object -Property @{Name = 'AgentGuid'; Expression = {$AgentName}}, @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}} , @{Name = 'Date'; Expression = {$currentDate}}, * `
 | Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation
}