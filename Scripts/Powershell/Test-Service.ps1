<#
.Synopsis
   Saves service deficiency information to a file
.DESCRIPTION
   Iterates provided services and check if they run from correct account. Log found deficiencies to a file.
.EXAMPLE
   Test-Service -FileName 'def_services.txt' -Path 'C:\TEMP' -AgentName '123456' -Services 'sppsvc', 'KPSSVC', 'TermService', 'sacsvr', 'MSSQLSERVER', 'w3logsvc' -ServiceUsers 'LocalSystem', 'NetworkService'
   Checks provided services and accounts
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
#region initialization
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    #[ValidateScript({
    #if( -Not ($_ | Test-Path) ){
    #    throw "Provided path does not exist" 
    #}
    #return $true
    #})]
    [string]$Path,
    #list of services to check
    [parameter(Mandatory=$true)]
    [string[]]$Services,
    #list of allowed users to start services
    [parameter(Mandatory=$true)]
    [string[]]$ServiceUsers
 )

#$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }
$Services = $Services | Select-Object -Unique
#endregion initialization

#outputArray contains information of services that run from incorrect accounts
[array]$outputArray = @()

#Iterate all the services from the list
foreach ($service in $Services) {
    $currentService = try { (Get-WmiObject Win32_Service -Filter "Name = '$service'" -ErrorAction Stop) } catch { $null }
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
    $outputArray -join ' ; ' | Out-File -FilePath $FileName -Force
}
else
{
    "No Deficiencies" | Out-File -FilePath $FileName -Force
}