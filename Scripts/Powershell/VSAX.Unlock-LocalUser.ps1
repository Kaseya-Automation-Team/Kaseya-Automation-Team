# Inputs
$UserName = " "
$NewPassword = " "

$UserName = $UserName.Trim()
$NewPassword = $NewPassword.Trim()

$wmiQuery = "SELECT * FROM Win32_UserAccount WHERE Name = '$UserName'"
[array]$users = Get-WmiObject -Query $wmiQuery -Namespace "root\cimv2" | Where-Object { $_.LocalAccount -eq $True -and $_.Lockout -eq $True }

if (0 -lt $users.Count) {
    foreach ($user in $users) {
        $user.Lockout = $false
        $user.Put()

        if ( [string]::IsNullOrEmpty( $NewPassword ) ) {
            ([adsi]("WinNT://"+$user.caption).replace("\","/")).SetPassword($NewPassword)
        }
    }
}