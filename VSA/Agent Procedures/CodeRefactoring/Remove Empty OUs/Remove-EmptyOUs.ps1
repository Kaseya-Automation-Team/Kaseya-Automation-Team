<#
.Synopsis
   Finds and removes all empty OUs in the Active Directory
#>

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

#The script must be executed on a Domain Controller
if (2 -ne $(Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty ProductType) ) {
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", " $env:COMPUTERNAME is not a Domain Controller", "Error", 400)    
} else {
    Import-Module ActiveDirectory

    [array]$RemoveOUs = Get-ADOrganizationalUnit -Filter * | ForEach-Object {
	       if ( -not (Get-ADObject -SearchBase $_ -SearchScope OneLevel -Filter * )) {
      		    Write-Output $_
   	    }
    }

    if (0 -lt $RemoveOUs.Length)
    {
       $RemoveOUs | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false -PassThru | Remove-ADOrganizationalUnit -Confirm:$false
       [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Empty OUs removed: $( $($RemoveOUs | Select-Object -ExpandProperty DistinguishedName) -join '; ' )", "Information", 200)
    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "No Empty OU found ", "Information", 200)
    }
}
