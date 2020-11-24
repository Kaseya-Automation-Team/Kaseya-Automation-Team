<#
.Synopsis
   Finds and removes empty OUs
.DESCRIPTION
   Finds empty OUs in AD and removes them
.EXAMPLE
   Remove-EmptyOUs
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>

Import-Module ActiveDirectory

Get-ADOrganizationalUnit -Filter * | ForEach-Object {
	   if (-not (Get-ADObject -SearchBase $_ -SearchScope OneLevel -Filter * )) {
      		Write-Output $_
   	}
} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false -PassThru | Remove-ADOrganizationalUnit -Confirm:$false