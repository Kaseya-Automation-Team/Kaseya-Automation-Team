<#
.Synopsis
   Finds all the domain administrators and saves them to a CSV file
.DESCRIPTION
   Finds all the objects of the users type that are included in the the Domain Admins group either directly or through nested group membership. Saves found administrators to a CSV file
.EXAMPLE
   Get-ADDomainAdmins
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
    [int]$Top = 10
 )


[string]$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

Import-Module ActiveDirectory

function Get-ADGroupAllMembers {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='ADGroupName')]
        [string]$ADGroupName,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='ADGroup')]
        [Microsoft.ActiveDirectory.Management.ADPrincipal]$ADGroup,

        [Parameter(DontShow)]
        [System.Collections.ArrayList]$AllGroups = [System.Collections.ArrayList]@(),

        [Parameter(DontShow)]
        [System.Collections.ArrayList]$CheckedGroups = [System.Collections.ArrayList]@(),

        [Parameter(DontShow)]
        [System.Collections.ArrayList]$AllGroupMembers = [System.Collections.ArrayList]@()
    )

    if ($ADGroupName)
    {
        try {
            $ADGroup = Get-ADGroup -Identity $ADGroupName -ErrorAction Stop
            $ADGroupName = $null
        }
        catch {
            Write-Error $_.Exception.Message
            break
        }
    }

    $GroupMembers = $ADGroup | Get-ADGroupMember
    $Users = $GroupMembers | Where-Object objectClass -eq "user" | Get-ADUser -properties Enabled

    $Users | ForEach-Object {
        $User = $_ | Select-Object Name, GivenName, Surname, DistinguishedName, SAMAccountName, Enabled, SID
        $AllGroupMembers.Add($User) | Out-Null
    }

    $CurrentGroupSID = $ADGroup.SID.Value
    $CheckedGroups.Add($CurrentGroupSID) | Out-Null
    $AllGroups.Remove($ADGroup) | Out-Null

    $Groups = $GroupMembers | Where-Object objectClass -eq "group"
    foreach ($Group in $Groups)
    {
        if ($Group.SID.Value -notin $CheckedGroups)
        {
            $AllGroups.Add($Group) | Out-Null
        }
    }
    
    if (0 -lt $AllGroups.Count)
    {
        [hashtable]$GetADGroupAllMembers = @{
        ADGroup = $AllGroups[0]
        AllGroupMembers = $AllGroupMembers
        CheckedGroups = $CheckedGroups
        AllGroups = $AllGroups
        }

        Get-ADGroupAllMembers @GetADGroupAllMembers

    }
    else
    {
        Write-Output $AllGroupMembers | Sort-Object -Property SID -Unique
    }
}
#Get Domain Admins by well-known SID to avoid issues with international/renamed groups
Get-ADGroupAllMembers -ADGroup $(Get-ADGroup -Identity "$((Get-ADDomain).DomainSID.Value)-512") `
 | Select-Object -Property @{Name = 'AgentGuid'; Expression = {$AgentName}}, @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}} , @{Name = 'Date'; Expression = {$currentDate}}, * `
 | Export-Csv -Path "FileSystem::$FileName" -Append -Encoding UTF8 -NoTypeInformation