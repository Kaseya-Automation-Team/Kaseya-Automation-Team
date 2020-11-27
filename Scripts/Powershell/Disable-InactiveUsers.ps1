<#
.Synopsis
   Finds and disables users that are inactive for (30) days.
   Based on the the LastLogonDate AD attribute since it is replicated to all the domain controllers while the LastLogon attribute is not replicated.
.DESCRIPTION
   Finds inactive users in AD and removes them
.EXAMPLE
   Disable-InactiveUsers  -FileName 'inactive_users.txt' -Path 'C:\TEMP' -Days 63
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>
param (
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    [parameter(Mandatory=$true)]
    [uint16]$Days
 )

 if(0 -eq $days ){$Days=30} #

 if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[datetime]$Older = (Get-Date).AddDays(-$Days)

Import-Module ActiveDirectory
[hashtable] $paramhash = @{
    Filter = "(LastLogonDate -lt '$Older') -and (Enabled -eq '$true')"
    Properties = 'LastLogonDate'
}

[array]$SelectProps = @('DistinguishedName', 'LastLogonDate')
[array]$InactiveUsers = Get-Aduser @paramhash | Select-Object $SelectProps

if (0 -lt $InactiveUsers.Length)
{
   $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
   [System.IO.File]::WriteAllLines($FileName,$(, "Inactive for $Days days users were disabled:" + $InactiveUsers.DistinguishedName), $Utf8NoBomEncoding)
   $InactiveUsers | ForEach-Object { Set-User $_.DistinguishedName -Enabled $false }
}