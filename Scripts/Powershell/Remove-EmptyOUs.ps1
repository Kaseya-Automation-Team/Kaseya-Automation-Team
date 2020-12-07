<#
.Synopsis
   Finds and removes empty OUs
.DESCRIPTION
   Finds empty OUs in AD and removes them
.EXAMPLE
   Remove-EmptyOUs  -FileName 'remove_OUs.txt' -Path 'C:\TEMP'
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>
param (
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path
 )

 if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

Import-Module ActiveDirectory

[array]$RemoveOUs = Get-ADOrganizationalUnit -Filter * | ForEach-Object {
	   if (-not (Get-ADObject -SearchBase $_ -SearchScope OneLevel -Filter * )) {
      		Write-Output $_
   	}
}

if (0 -lt $RemoveOUs.Length)
{
   $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
   [System.IO.File]::WriteAllLines($FileName,$(, "Empty OUs removed:" + $RemoveOUs.DistinguishedName), $Utf8NoBomEncoding)
   $RemoveOUs | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false -PassThru | Remove-ADOrganizationalUnit -Confirm:$false
}