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
.EXAMPLE
   .\Gather-DomainAccounts.ps1 -AgentName '12345' -FileName 'domain_accounts.csv' -Path 'C:\TEMP' -LogIt 1
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
    [string] $Path,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[string[]] $DomainAccountSIDs = @()
[array] $DomainUsers = @()

[string]$Domain = try {
    [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain() | Select-Object -ExpandProperty Name
}
catch
{
    $_.Exception.Message
}

if ( $Domain -notmatch 'Exception' )
{
    # under the ProfileList key there are subkeys for each user in the system. 
    [string] $RegKeyPath = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

    #The krbtgt user exists in every domain. It cannot be renamed
    [string] $krbtgtSID = try { (New-Object Security.Principal.NTAccount "$Domain\krbtgt").Translate([Security.Principal.SecurityIdentifier]).Value } catch {$null}
    if ( -not [string]::IsNullOrEmpty($krbtgtSID) )
    {
        [string] $DomainSID = $krbtgtSID.SubString( 0, $krbtgtSID.LastIndexOf('-') )

        #scan the registry for the domain profiles' SIDs
        $DomainAccountSIDs = try {
            (Get-ChildItem -Name Registry::$RegKeyPath -ErrorAction Stop).PSChildName | Where-Object {$_ -match $DomainSID}
        }
        catch {$null}
        
        if ( 0 -ne $DomainAccountSIDs.Length )
        {
            Foreach ( $SID in $DomainAccountSIDs )
            {
                $Account = New-Object Security.Principal.SecurityIdentifier("$SID")
                $NetbiosName = $Account.Translate([Security.Principal.NTAccount]) | Select-Object -ExpandProperty Value
                $UserBySID = New-Object PSObject -Property @{
                    Domain = $Domain
                    SID = $SID
                    Name = ($NetbiosName -split '\\')[-1]
                }
            
                if ($null -ne $UserBySID) {$DomainUsers += $UserBySID}
            }
        }
    }
}

#Gather empty user if no domain users found
if (0 -eq $DomainUsers.Length )
{
    $EmptyUser = New-Object PSObject -Property @{
                    Domain = $Domain;
                    SID = 'NULL'
                    Name = 'NULL'
                }

    $DomainUsers += $EmptyUser
}

$DomainUsers | Select-Object -Property `
    @{Name = 'Date'; Expression = {$currentDate }}, `
    @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
    @{Name = 'AgentGuid'; Expression = {$AgentName}}, `
* | Export-Csv -Path "FileSystem::$FileName" -Force -Encoding UTF8 -NoTypeInformation

#region check/stop transcript
if (1 -eq $LogIt)
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript