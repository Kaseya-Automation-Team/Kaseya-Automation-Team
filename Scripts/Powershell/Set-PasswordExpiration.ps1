<#
.Synopsis
   Enables password expiration option across all local or AD accounts
.DESCRIPTION
   Script checks if computer is part of domain (and it should be domain controller) and if so, disables password expiration option for all active accounts
   with this option enabled.
   If computer is not in domain, it disables password expiration option across all local active accounts with this option enabled
.EXAMPLE
   .\Set-PasswordExpiration.ps1

.NOTES
   Version 0.1
   Author: Aliaksandr Serzhankou
   Email: a.serzhankou@kaseya.com
#>

#Determine if computer is part of domain or not
if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {

    #If computer is part of domain (and we suppose it's the domain controller).
    #Get list of enabled users, with no password expiration date.
    $AllUsers = Get-ADUser -Filter {(Enabled -eq $true) -and (PasswordNeverExpires -eq $true)}

    #Continue if we have an active users with password expiration option enabled
    if ($AllUsers) {
        Write-Host "PasswordNeverExpires option has been disabled for following accounts:"

        #Enable password expiration option for all accounts matching the criteria
        foreach ($User in $AllUsers) {
            Set-ADUser -Identity $User.SamAccountName -PasswordNeverExpires $false
            Write-Host $User.SamAccountName
        }

    }

}

else {
    #If computer is not in domain, get list of local users with password expiration option disable

    Import-Module Microsoft.Powershell.LocalAccounts

    $AllUsers = Get-WmiObject Win32_UserAccount -filter "LocalAccount=True AND Disabled=False AND PasswordExpires=False"

    #Continue if we have an active users with password expiration option enabled
    if ($AllUsers) {
        foreach ($User in $AllUsers) {
            Write-Host "PasswordNeverExpires option has been disabled for following accounts:"

            #Enable password expiration option for all accounts matching the criteria
            Set-LocalUser -SID $User.SID -PasswordNeverExpires $false
            Write-Host $User.Name
        }
    }

}