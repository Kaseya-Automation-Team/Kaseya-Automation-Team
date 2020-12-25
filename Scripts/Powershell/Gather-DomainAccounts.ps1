<#
.Synopsis
   Gathers domain users accounts that have logged on the computer.
.DESCRIPTION
   Gathers domain users accounts that have logged on the computer and saves information to a CSV-file.
   The information of domain accounts that have logged on the computercan be obtained form Security Event Log, 
   Users' profile folder and from 
   HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList registry key.
   However, the event log can be overwritten and the user profile folder can be deleted.
   Therefore, the registry is used
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

$SystemObject = Get-WmiObject -Class Win32_ComputerSystem
[string[]]$DomainAccountSIDs = @()
[array]$DomainUsers = @()

if ( $SystemObject.partofdomain)
{
    [string]$RegKeyPath = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

    [string] $Domain  = $SystemObject | Select -Expand Domain
    [string] $krbtgtSID = (New-Object Security.Principal.NTAccount $domain\krbtgt).Translate([Security.Principal.SecurityIdentifier]).Value
    $DomainSID = $krbtgtSID.SubString(0, $krbtgtSID.LastIndexOf('-'))
    
    $DomainAccountSIDs = (Get-ChildItem Registry::$RegKeyPath).PSChildName | Where-Object {$_ -match $DomainSID}
    Foreach ($SID in $DomainAccountSIDs )
    {
        $DomainUsers += $( 
        try {Get-CimInstance -ClassName Win32_UserAccount -Filter "SID like '$SID'" -ComputerName $SystemObject.Name -ErrorAction Stop `
        | Select-Object -Property 'Domain', 'Name', 'Status', 'Disabled', 'SID'} catch {$null} 
        )
    }
}
$DomainUsers | Select-Object -Property `
@{Name = 'Date'; Expression = {$currentDate }}, `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
@{Name = 'AgentGuid'; Expression = {$AgentName}}, `
* | Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation