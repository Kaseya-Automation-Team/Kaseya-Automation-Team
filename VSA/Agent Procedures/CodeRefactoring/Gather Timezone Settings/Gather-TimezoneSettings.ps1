#This script collects information about UTC offset and time zone

$TimeZone = "Null"

$Offset = (Get-TimeZone|Select-Object -Property DisplayName).DisplayName

Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable TimeZone ""$Offset""") -Wait