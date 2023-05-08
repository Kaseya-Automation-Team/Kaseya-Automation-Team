#test for and uninstall Pulse Secure 5.3
if ((Test-Path "C:\Program Files (x86)\Pulse Secure\Pulse\PulseUninstall.exe" -PathType Leaf) -eq "true"){
    stop-process -name Pulse -Force
    stop-process -name PulseSecureService -Force
    cd "C:\Program Files (x86)\Pulse Secure\Pulse"
	.\PulseUninstall.exe /silent=1
    Write-Output "PulseUninstall.exe was Executed"
    Start-Sleep 240
    }
else {Write-Output "PulseUninstall.exe does not exist."}

#geting all user profiles
$users = Get-ChildItem "C:\Users" -Directory

#Loop through each user profile and uninstall Pulse Secure Setup Client
foreach($user in $users) 
{
    if ((Test-Path "C:\Users\$user\AppData\Roaming\Pulse Secure\Setup Client\uninstall.exe" -PathType Leaf) -eq "true"){
        cd "C:\Users\$user\AppData\Roaming\Pulse Secure\Setup Client\"
        .\pulsesetupclient.exe -stop
        .\uninstall.exe /silent=1
        Start-Sleep 30
        Stop-Process -name "Au_" -Force
        Write-Output "uninstall.exe Executed for $user"
        }
    else {Write-Output "$user does not have uninstall.exe"}
    }

#check for and uninstall Pulse Secure Setup Client x64
if ((Test-Path "C:\WINDOWS\Downloaded Program Files\PulseSetupClientCtrlUninstaller64.exe" -PathType Leaf) -eq "true"){
    cd "C:\WINDOWS\Downloaded Program Files\"
    .\PulseSetupClientCtrlUninstaller64.exe /silent=1
    Start-Sleep 15
    Stop-Process -name "Au_" -Force
    Write-Output "PulseSetupClientUninstaller64.exe Executed"
    }
else { Write-Output "PulseSetupClientCtrlUninstaller64.exe does not exist"}

#check for and uninstall Pulse Secure Setup Client x86
if ((Test-Path "C:\WINDOWS\Downloaded Program Files\PulseSetupClientCtrlUninstaller.exe" -PathType Leaf) -eq "true"){
    cd "C:\WINDOWS\Downloaded Program Files\"
    .\PulseSetupClientCtrlUninstaller.exe /silent=1
    Start-Sleep 15
    Stop-Process -name "Au_" -Force
    Write-Output "PulseSetupVlientUninstaller.exe Executed"
    }
else {Write-Output "PulseSetupClientCtrlUninstaller.exe does not exist"}

#check if the Pulse Secure WmiObject still shows as installed and uninstall as needed
$Pulse = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Pulse Secure"} | Select-Object -Property Name
if ($Pulse.name -eq "Pulse Secure"){
    $MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Pulse Secure"}
    $MyApp.Uninstall()
    Write-Output "Pulse Secure has been completely uninstalled!"#this output means Pulse needed this extra step to be completely uninstalled
    }
Else {Write-Output "Pulse Secure is not present to be uninstalled!"}#this output means Pulse did not need this extra step to be completely uninstalled

#use get-package to make sure pulse secure installer service isnt lingering
$PulsePack = Get-Package -Provider Programs -IncludeWindowsInstaller | Where-Object{$_.Name -eq "Pulse Secure installer service"} | Select-Object -Property Name
if ($PulsePack.name -eq "Pulse Secure installer service"){
    Uninstall-Package -Name "Pulse Secure installer service" -force | Out-Null
    Write-Output "Pulse Secure installer service Package removed!"#this output means Pulse needed this extra step to be completely uninstalled
    }
Else {Write-Output "Pulse Secure installer service Package NOT installed"}#this output means Pulse did not need this extra step to be completely uninstalled

#check if get-package still shows pulse as installed and uninstall-package is=f it does.
$PulsePack2 = Get-Package -Provider Programs -IncludeWindowsInstaller | Where-Object{$_.Name -eq "Pulse Secure"} | Select-Object -Property Name
if ($PulsePack.name -eq "Pulse Secure"){
    Uninstall-Package -Name "Pulse Secure" -force | Out-Null
    Write-Output "Pulse Secure Package Uninstalled!"#this output means Pulse needed this extra step to be completely uninstalled
    }
Else {Write-Output "Pulse Secure Package NOT installed"}#this output means Pulse did not need this extra step to be completely uninstalled
