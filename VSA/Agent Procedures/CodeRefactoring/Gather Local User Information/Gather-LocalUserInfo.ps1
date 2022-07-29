<#
.Synopsis
   Gathers domain users accounts that have logged on the computer.
.NOTES
   Version 0.2.2
   Author: Proserv Team - VS
#>


#Write-Debug "Script execution started"

#Import .Net Framework AccountManagement library
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

[string]$ContextType = 'Machine'
$PrincipalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext($ContextType, $env:COMPUTERNAME)
$UserPrincipal = New-Object System.DirectoryServices.AccountManagement.UserPrincipal($PrincipalContext)
$GroupPrincipal = New-Object System.DirectoryServices.AccountManagement.GroupPrincipal($PrincipalContext)
$searcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher

#Create array where all objects for export will be storred
[array]$Results = @()

#Find local users
$ErrorActionPreference = 'SilentlyContinue'
$searcher.QueryFilter = $UserPrincipal
$LocalUsers = $searcher.FindAll() | Select-Object -Property Name, LastLogon, Enabled

#Write-Debug ($LocalUsers| Select-Object * | Out-String)

#Find local admins
$searcher.QueryFilter = $GroupPrincipal
[string[]]$LocalAdmins = $( ($searcher.FindAll() | Where-Object {'S-1-5-32-544' -eq $_.Sid} ).Members | Where-Object { $ContextType -eq $_.ContextType } | Select-Object -ExpandProperty Name )
$ErrorActionPreference = 'Continue'
#Write-Debug ($LocalAdmins | Select-Object * |Out-String)


ForEach ($User in $LocalUsers){
    
   
    $Output = New-Object PSObject -Property @{
                        UserName = $User.Name
                        Enabled = $User.Enabled
                        LastLogon = ''
                        IsLocalAdmin = 'False'
                        }
    if ( -not [string]::IsNullOrEmpty($User.LastLogon) ) {
        $Output.LastLogon = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f ($User.LastLogon)
    }


    if ( $LocalAdmins -contains $($User.Name) ) {
        $Output.IsLocalAdmin = 'True'

    }

    #Add object to the previously created array
    $Results += $Output
}
$Results | Out-String | Write-Output