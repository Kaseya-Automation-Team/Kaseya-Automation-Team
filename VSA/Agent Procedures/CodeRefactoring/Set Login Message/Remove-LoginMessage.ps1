#Registry path to Windows Update settings
$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"

Remove-ItemProperty -Path $Path -Name "legalnoticecaption" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $Path -Name "legalnoticetext" -ErrorAction SilentlyContinue

Write-Host "Login message has been removed by VSA X script."
eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Login message has been removed by VSA X script." | Out-Null