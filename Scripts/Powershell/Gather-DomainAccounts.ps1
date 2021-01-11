<#
.Synopsis
   Gathers domain users accounts that have logged on the computer.
.DESCRIPTION
   Gathers domain users accounts that have logged on the computer and saves information to a CSV-file.
   The information of domain accounts that have logged on the computercan be obtained form Security Event Log, 
   Users' profile folder and from 
   HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList registry key.
   However, the event log can be overwritten and the user profile folder can be deleted.
   Therefore, the registry is used.
   krbtgt account: https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/active-directory-accounts#sec-krbtgt
.EXAMPLE
   .\Gather-DomainAccounts.ps1 -AgentName '12345' -FileName 'domain_accounts.csv' -Path 'C:\TEMP'
.NOTES
   Version 0.2.2
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [string] $AgentName,
    [parameter(Mandatory=$true)]
    [string] $FileName,
    [parameter(Mandatory=$true)]
    [string] $Path
)

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[string[]] $DomainAccountSIDs = @()
[array] $DomainUsers = @()

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain() | Select-Object -ExpandProperty Name

if ( $null -ne $Domain )
{
   # under ProfileList key there are subkeys for each user in the system. 
   [string] $RegKeyPath = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
   [string] $Domain  = $SystemObject | Select-Object -ExpandProperty Domain
   [string] $krbtgtSID = (New-Object Security.Principal.NTAccount "$Domain\krbtgt").Translate([Security.Principal.SecurityIdentifier]).Value
   #[string] $krbtgtSID = try {Get-WmiObject -Class Win32_UserAccount -Filter "Name='krbtgt' AND LocalAccount='False'" -ComputerName $env:COMPUTERNAME -ErrorAction Stop | Select-Object -ExpandProperty SID } catch {$null}
   if ( -not [string]::IsNullOrEmpty($krbtgtSID) )
   {
       [string] $DomainSID = $krbtgtSID.SubString( 0, $krbtgtSID.LastIndexOf('-') )
       #lookup for the domain profiles' SIDs
       $DomainAccountSIDs = try {(Get-ChildItem -Name Registry::$RegKeyPath -ErrorAction Stop).PSChildName | Where-Object {$_ -match $DomainSID} } catch {$null}
       if ($null -ne $DomainAccountSIDs)
       {
           Foreach ($SID in $DomainAccountSIDs )
           {
                $Account = New-Object Security.Principal.SecurityIdentifier("$SID")
                $NetbiosName = $Account.Translate([Security.Principal.NTAccount]) | Select-Object -ExpandProperty Value
                $UserBySID = New-Object PSObject -Property @{
                    Domain = $Domain
                    SID = $SID
                    Name = ($NetbiosName -split '\\')[-1]
                }

              #$UserBySID = try {Get-WmiObject -ClassName Win32_UserAccount -Filter "SID like '$SID'" -ComputerName $env:COMPUTERNAME -ErrorAction Stop `
              #   | Select-Object -Property 'Domain', 'Name', 'Status', 'Disabled', 'SID'} catch {$null} 
              if ($null -ne $UserBySID) {$DomainUsers += $UserBySID}
           }
       }
   }
}

$DomainUsers | Select-Object -Property `
   @{Name = 'Date'; Expression = {$currentDate }}, `
   @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
   @{Name = 'AgentGuid'; Expression = {$AgentName}}, `
* | Export-Csv -Path "FileSystem::$FileName" -Force -Encoding UTF8 -NoTypeInformation