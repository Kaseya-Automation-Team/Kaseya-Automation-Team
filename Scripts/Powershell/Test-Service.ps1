<#
.Synopsis
   Saves service deficiency information to a csv
.DESCRIPTION
   Iterates provided services and check if they run from correct account. Log found deficiencies to a file.
   If there is no deficiency the csv-file is not created
.EXAMPLE
   Test-Service -FileName 'def_services.csv' -Path 'C:\TEMP' -AgentName '123456' -Services 'sppsvc', 'KPSSVC', 'TermService', 'sacsvr', 'MSSQLSERVER', 'w3logsvc' -ServiceUsers 'LocalSystem', 'NetworkService'
   Checks custom services and account
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
#>
#region initialization
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
    [string]$FileName = "",
    [parameter(Mandatory=$true)]
    #[ValidateScript({
    #if( -Not ($_ | Test-Path) ){
    #    throw "Provided path does not exist" 
    #}
    #return $true
    #})]
    [string]$Path = "",
    #list of services to check
    [parameter(Mandatory=$true)]
    [string[]]$Services = @(),
    #list of allowed users to start services
    [parameter(Mandatory=$true)]
    [string[]]$ServiceUsers = @()
 )

#$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
#endregion initialization

#outputArray contains information of services that run from incorrect accounts
[array]$outputArray = @()
#Iterate all the services from the list
foreach ($service in $services) {
    $currentService = try { (Get-WmiObject Win32_Service -Filter "Name = '$service'") } catch { $null }
    if ( $null -ne $currentService )
    {
        #Check if the service runs from a correct account
        if ( $serviceUsers -notcontains ($currentService.StartName -split '\\')[-1] )
        {
           #Collect if service account is wrong
           $outputArray += "Service ""$($currentService.Name)"" Runs As: ""$($currentService.StartName)"""
        }
    }
}

#Deficiencies to log
if ( 0 -lt $outputArray.Count )
{
    $outputArray -join ' ; ' | Out-File -FilePath $FileName -Force -Encoding UTF8
}
else
{
    "No Deficiencies" | Out-File -FilePath $FileName -Force -Encoding UTF8
}