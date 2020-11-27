<#
.Synopsis
   Sets account lockout threshold
.DESCRIPTION
   Script checks if computer is part of domain (and it should be domain controller) or not and depending on that chooses corresponding method to change
   account lockout threshold from any current value to new one provided in $Threshold input parameters.
.EXAMPLE
   .\Set-LockoutThreshold.ps1

.NOTES
   Version 0.1
   Author: Aliaksandr Serzhankou
   Email: a.serzhankou@kaseya.com
#>

#Read new threshold value from input parameters
param (
    [parameter(Mandatory=$true)]
    [int]$Threshold = ""
 )

#Determine if computer is part of domain or not
if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
    
    #If computer is part of domain, execute command to set new threshold
    Get-ADDefaultDomainPasswordPolicy -Current LoggedOnUser|Set-ADDefaultDomainPasswordPolicy -LockoutThreshold $Threshold
	Write-Host "Account lockout threshold has been set to: $Threshold"

} else

{

    #Store path to temp directory into custom variable
    $Temp = $env:TEMP

    #If computer is NOT part of domain, export current security policies into file
    secedit.exe /export /cfg $Temp\secpol.cfg /quiet

    #Change the value of account lockout threshold
    $Config = Get-Content $Temp\secpol.cfg
    $Config -replace("LockoutBadCount = [0-9]+", "LockoutBadCount = $Threshold") | Out-File $Temp\secpol.cfg

    #Import policy back from the file
    secedit.exe /configure /db c:\windows\security\local.sdb /cfg $Temp\secpol.cfg /areas SECURITYPOLICY /quiet

    #Clean up
    Remove-Item -force $Temp\secpol.cfg -confirm:$false
	
	Write-Host "Account lockout threshold has been set to: $Threshold"

}