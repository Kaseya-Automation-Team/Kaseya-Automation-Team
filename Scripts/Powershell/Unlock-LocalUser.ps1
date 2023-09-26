<#
.Synopsis
    Unlocks local user account.
.DESCRIPTION
    Unlocks local user accounts by resetting passwords or disabling lockouts.
.PARAMETER UserName
    The user name to unlock.
.PARAMETER ResetPassword
    (Optional) unlock account by resetting password.
.PARAMETER NewPassword
    A new password. Must meet length and complexety requirements
.EXAMPLE
    .\Unlock-LocalUser -UserName myuser
.EXAMPLE
    .\Unlock-LocalUser -UserName myuser -ResetPassword NewP@ssword
.NOTES
    Version 0.1
    Requires:
        Proper permissions to manage local accounts and execute the script.
   
    Author: Proserv Team - VS
#>
param (
[parameter(Mandatory=$true, 
        ParameterSetName = 'Reset')]
[parameter(Mandatory=$true, 
        ParameterSetName = 'Unlock')]
[ValidateNotNullOrEmpty()]
    [string]$UserName,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Reset')]
    [switch]$ResetPassword,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Reset')]
[ValidateNotNullOrEmpty()]
    [string]$NewPassword
)

$wmiQuery = "SELECT * FROM Win32_UserAccount WHERE Name = '$UserName'"
[array]$users = Get-WmiObject -Query $wmiQuery -Namespace "root\cimv2" | Where-Object { $_.LocalAccount -eq $True -and $_.Lockout -eq $True }

if (0 -lt $users.Count) {
    foreach ($user in $users) {
        $user.Lockout = $false
        $user.Put()
        if ( $ResetPassword ) {
            ([adsi]("WinNT://"+$user.caption).replace("\","/")).SetPassword($NewPassword)
        }
    }
}