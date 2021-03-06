﻿<#
.Synopsis
   Gathers domain users accounts that have logged on the computer.
.DESCRIPTION
   Used by the "Gather Local User Info" Agent Procedure
   Gathers local users' accounts and saves information to a CSV-file.
.EXAMPLE
   .\Gather-LocalUserInfo.ps1 -AgentName '12345' -FileName 'local_accounts.csv' -Path 'C:\TEMP' -Limit 0
.EXAMPLE
   .\Gather-LocalUserInfo.ps1 -AgentName '12345' -FileName 'local_accounts.csv' -Path 'C:\TEMP' -LogIt 0
.NOTES
   Version 0.2.2
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
	[string]$Path,
    [parameter(Mandatory=$true)]
	[string]$Filename,
    [parameter(Mandatory=$false)]
    [int]$Limit = 0,
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$Path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

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

$Counter = 0

ForEach ($User in $LocalUsers){
    
    $Counter++

    #Write-Debug $Counter
    #Write-Debug $User.Name
    
    $Output = New-Object PSObject -Property @{
                        UserName = $User.Name
                        MachineID = $AgentName
                        Enabled = $User.Enabled
                        LastLogon = 'Never'
                        IsLocalAdmin = 'False'
                        }
    if ( -not [string]::IsNullOrEmpty($User.LastLogon) )
    {
        $Output.LastLogon = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f ($User.LastLogon)
    }
    
    
    #Write-Debug ( "{0:MM'/'dd'/'yyyy H:mm:ss}" -f ($User.LastLogon) )

    if ( $LocalAdmins -contains $($User.Name) )
    {
        $Output.IsLocalAdmin = 'True'

    }

    #Add object to the previously created array
    $Results += $Output

    If ($Limit -ne 0) {

        if ($Counter -eq $Limit) {

            #Write-Debug "Limit of $Limit records has been reached"
            Break
        }
            
    }
}

#Export results to csv file

try { $Results | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation -Force -ErrorAction Stop } catch { $_.Exception.Message }

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}