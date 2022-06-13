$ValueToSet = 0

<#
If you enable this policy setting, administrators can interact with a user's Remote Desktop Services session based
on the option selected. Select the desired level of control and permission from the options list:

1. No remote control allowed: Disallows an administrator to use remote control or view a remote user session.
2. Full Control with user's permission: Allows the administrator to interact with the session, with the user's consent.
3. Full Control without user's permission: Allows the administrator to interact with the session, without the user's consent.
4. View Session with user's permission: Allows the administrator to watch the session of a remote user with the user's consent.
5. View Session without user's permission: Allows the administrator to watch the session of a remote user without the user's consent.

If you disable this policy setting, administrators can interact with a user's Remote Desktop Services session, with the user's consent.
#>

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\"

$CurrentValue = Get-ItemProperty -Path $Path | Select-Object -ExpandProperty Shadow -ErrorAction SilentlyContinue

if ($null -ne $CurrentValue) {
    Set-ItemProperty -Path $Path -Name Shadow -Value $ValueToSet
    Write-Host "Value has been successfully changed to $ValueToSet."

} else {
    Write-Host "Windows Registry value doesn't exist and will be created."
    New-ItemProperty -Path $Path -Name "Shadow" -Value $ValueToSet| Out-Null
    Write-Host "Value has been successfully changed to $ValueToSet."
}

#Make Event Log entry
[System.Diagnostics.EventLog]::WriteEntry("VSA X", "Windows Terminal Session shadow settings have been changed by VSA X script. New value is $ValueToSet.", "Information", 200)