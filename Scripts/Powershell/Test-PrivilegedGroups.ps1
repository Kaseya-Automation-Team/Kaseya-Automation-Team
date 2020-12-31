<#
.Synopsis
   Saves privileged domain groups' member discrepancy information to a file
.DESCRIPTION
   Iterates privileged AD groups and check if they contain only provided accounts. Log found discrepancies to a file.
.EXAMPLE
   Test-PrivilegedGroups -FileName 'deficient_groups.txt' -Path 'C:\TEMP' -AgentName '123456' -EligibleEnterpriseAdmins 'user1', 'user2' -EligibleSchemaAdmins 'user1', 'user2' -EligibleDomainAdmins 'user1', 'user2'
   Checks provided group members for discrepancies
.NOTES
   https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/security-identifiers-in-windows
   Run on a domain controller
   Version 0.1
   Author: Proserv Team - VS
#>
#region initialization
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    #list of eligible Enterprise Admins
    [parameter(Mandatory=$true)]
    [string[]]$EligibleEnterpriseAdmins,
    #list of eligible Schema Admins
    [parameter(Mandatory=$true)]
    [string[]]$EligibleSchemaAdmins,
    #list of eligible Domain Admins
    [parameter(Mandatory=$true)]
    [string[]]$EligibleDomainAdmins
 )

if ( $FileName -notmatch '\.txt$') { $FileName += '.txt' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

if (Test-Path $FileName) {
  Remove-Item -Path $FileName -Force -Confirm:$false
}

[string[]]$Message = @()

 [hashtable]$EligibleMembers = @{
"$((Get-ADDomain).DomainSID.Value)-519" = $EligibleEnterpriseAdmins
"$((Get-ADDomain).DomainSID.Value)-518" = $EligibleSchemaAdmins
"$((Get-ADDomain).DomainSID.Value)-512" = $EligibleDomainAdmins
}

$EligibleMembers.Keys | ForEach-Object {
    $ActualGroupMembers = Get-ADGroupMember -Identity $_ | Select-Object -ExpandProperty SamAccountName
    $ComparsionResult = Compare-Object -ReferenceObject $EligibleMembers.Item($_) -DifferenceObject $ActualGroupMembers
    if($null -ne $ComparsionResult)
    {
        [string]$TheGroup = Get-ADGroup -Identity $_ | Select-Object -ExpandProperty SamAccountName
        $Missing = ($ComparsionResult | Where-Object { '<=' -eq $_.SideIndicator } | Foreach-Object { $_.InputObject }) -join ', '
        $Added   = ($ComparsionResult | Where-Object { '=>' -eq $_.SideIndicator } | Foreach-Object { $_.InputObject }) -join ', '
        
        if ($null -ne $Missing) {$Message += "$TheGroup`: Members missing: $Missing"}
        if ($null -ne $Added)   {$Message += "$TheGroup`: Members added: $Added"}
    }
}
if (0 -lt $Message.Count)
{
    $Message -join "`n" | Out-File -FilePath $FileName -Encoding utf8 -Force
}