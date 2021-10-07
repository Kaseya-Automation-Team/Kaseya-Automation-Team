
$ZoomInstalledHKLM = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse | Get-ItemProperty | Where-Object {$_.Publisher -like "Zoom*" } | Select-Object -ExpandProperty UninstallString

if ($ZoomInstalledHKLM) {
    
    $ZoomInstalledHKLM | Out-File C:\Kworking\ZoomString.txt }