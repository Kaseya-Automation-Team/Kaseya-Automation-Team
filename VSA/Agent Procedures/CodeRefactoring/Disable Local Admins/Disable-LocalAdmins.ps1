<#
=================================================================================
Script Name:        Management: Disable Local Admins
Description:        Disables local users’ accounts that are members of the local Administrators group.
Lastest version:    2022-04-14
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

(Get-WMIObject -Class Win32_Group -Filter "LocalAccount=TRUE and SID='S-1-5-32-544'").GetRelated(`
"Win32_Account", "Win32_GroupUser", "", "", "PartComponent", "GroupComponent", $false, $null) `
| ForEach-Object {
    $_.Disabled = $false
    $_.Put()
}
[System.Diagnostics.EventLog]::WriteEntry("VSA X", "Local members of the local Administrators group were disabled", "Information", 200)