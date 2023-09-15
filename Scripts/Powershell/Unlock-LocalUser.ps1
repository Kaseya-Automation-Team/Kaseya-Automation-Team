param (
[parameter(Mandatory=$true, 
        ParameterSetName = 'Reset')]
[parameter(Mandatory=$true, 
        ParameterSetName = 'Unlock')]
[ValidateNotNullOrEmpty()]
    [string]$Username,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Reset')]
    [switch]$ResetPassword,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Reset')]
[ValidateNotNullOrEmpty()]
    [string]$NewPassword
)

$wmiQuery = "SELECT * FROM Win32_UserAccount WHERE Name = '$Username'"
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