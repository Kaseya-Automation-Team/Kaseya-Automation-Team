# Requires -Version 5.1 
<#
.Synopsis
  Checks if the computer has rebooted in the last one minute, if not, it will reboot the system!
.DESCRIPTION
  Checks if the computer has rebooted in the last one minute, if not, it will reboot the system!
.EXAMPLE
   .\RebootPc.ps1
.NOTES
   Version 0.1
   Author: Automation Team - SM
#>

$BootDate = Get-CimInstance -ClassName win32_operatingsystem | select -ExpandProperty lastbootuptime      #Last reboot time

$Today      = Get-Date      #Current date and time
$ReportDate = $Today.AddMinutes( -1 )   #Adding last one minute to the current time.

if ( $ReportDate -gt $BootDate ){

    powershell -WindowStyle hidden -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Your computer hasnt been rebooted since $BootDate, hence rebooting it now!','WARNING')}"
    
    Shutdown.exe /F /R
    
}