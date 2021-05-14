<#
.Synopsis
   Disables local administrators
.DESCRIPTION
   Gets the local admininistrators group members and disables local users that are members of the group
.EXAMPLE
   .\Disable-LocalAdmins.ps1
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
$LocalAdminGroup = try { Get-WMIObject -Class Win32_Group -Filter "LocalAccount=TRUE and SID='S-1-5-32-544'" -ErrorAction Stop } catch { $null }

if( $null -ne $LocalAdminGroup )
{
    $LocalAdmins = $LocalAdminGroup.GetRelated("Win32_UserAccount")
    if( $null -ne $LocalAdmins )
    {
        foreach( $User in $LocalAdmins )
        {
            $User.Disabled = $True
            $User.Put()
        }
    }
}