<#
.Synopsis
   Enable password complexity policy, if it's not enabled yet
.DESCRIPTION
   Script checks if computer is part of domain (and it should be domain controller) or not and depending on that chooses corresponding method to change
   password complexity changes.
.EXAMPLE
   .\Set-PasswordComplexity.ps1

.NOTES
   Version 0.1
   Author: Aliaksandr Serzhankou
   Email: a.serzhankou@kaseya.com
#>

#Store path to temp directory into custom variable
$Temp = $env:TEMP

#Determine if computer is part of domain or not
if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {

    #If computer is part of domain (and we suppose it's the domain controller)
    Get-ADDefaultDomainPasswordPolicy -Current LoggedOnUser|Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $true


}

else {
    #if computer is NOT part of domain, export current security policies into file
    secedit.exe /export /cfg $Temp\secpol.cfg

    #Change the value of password complexity
    (Get-Content $Temp\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1") | Out-File $Temp\secpol.cfg

    #Import policy back from the file
    secedit.exe /configure /db c:\windows\security\local.sdb /cfg $Temp\secpol.cfg /areas SECURITYPOLICY

    #Clean up
    Remove-Item -force $Temp\secpol.cfg -confirm:$false
}