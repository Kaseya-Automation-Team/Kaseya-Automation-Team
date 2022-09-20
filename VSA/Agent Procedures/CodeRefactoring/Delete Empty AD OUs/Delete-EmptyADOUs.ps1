<#
=================================================================================
Script Name:        Management: Delete Empty AD OUs.
Description:        Gathers and deletes Empty AD OUs. Should be executed on a Domain Controller.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

Import-Module ActiveDirectory

#Collect the OUs that have no members
[array]$RemoveOUs = Get-ADOrganizationalUnit -Filter * | ForEach-Object {
	   if (-not (Get-ADObject -SearchBase $_ -SearchScope OneLevel -Filter * )) {
      		Write-Output $_
   	}
}
#Remove the collect the OUs
if (0 -lt $RemoveOUs.Length)
{
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Removing Empty OUs:`n$($RemoveOUs | Select-Object -ExpandProperty DistinguishedName | Out-String)", "Information", 200)
    $RemoveOUs | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false -PassThru | Remove-ADOrganizationalUnit -Confirm:$false
}