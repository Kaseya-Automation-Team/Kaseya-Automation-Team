#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}
Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True AND Disabled=False AND PasswordExpires=False" -Property PasswordExpires | ForEach-Object {$_.PasswordExpires=$true; $_.Put()}
[System.Diagnostics.EventLog]::WriteEntry("VSA X", 'The "Password never expires" property disabled for all local users', "Information", 200)