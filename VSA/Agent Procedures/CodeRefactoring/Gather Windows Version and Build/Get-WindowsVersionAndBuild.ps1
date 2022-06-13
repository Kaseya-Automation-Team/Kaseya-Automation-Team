#This script requires custom field WindowsVersion to be created and assigned to the machine before execution

# Outputs
$WindowsVersion = "Null"
$ProductName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName 
$Build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
$DisplayBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion

$WindowsVersion = "$ProductName, $DisplayBuild ($Build)"

Start-Process -FilePath "$env:PWY_HOME\CLI.exe" -ArgumentList ("setVariable WindowsVersion ""$WindowsVersion""") -Wait