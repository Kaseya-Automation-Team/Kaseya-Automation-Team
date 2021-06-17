<#
.Synopsis
   Compares actual filesystem permissions with permissions provided in the JSON file.
.DESCRIPTION
   Used by Agent Procedure
   Compares actual filesystem permissions with permissions provided in the JSON file and saves deficiency information on changes to a TXT-file.
.EXAMPLE
   .\Test-Service.ps1.ps1 -AgentName '123456' -RefJSON 'ServicesUsers.json'
.EXAMPLE
   .\Test-Service.ps1.ps1 -AgentName '123456' -RefJSON 'ServicesUsers.json' -LogIt
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    # Path to the JSON file that lists filesystem objects with corresponding users/groups & their permissions
    [parameter(Mandatory=$true)]
    [string] $RefJSON,
    # Create transcript file
    [parameter(Mandatory=$false)]
    [switch] $LogIt
 )
#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

[array] $RefServiceParams = Get-Content -Raw -Path $RefJSON | ConvertFrom-Json
[string[]] $Deficiencies = @()

foreach ( $ServiceName in $($RefServiceParams.ServiceName | Select-Object -Unique) )
{
    $ServiceName | Write-Debug

    $CurrentService = try { (Get-WmiObject -Query "SELECT Name, StartName FROM Win32_Service WHERE Name = '$ServiceName'" -ErrorAction Stop) } catch { $null }
    if ( $null -ne $CurrentService )
    {
        [string[]] $EligibleUsers = $RefServiceParams | Where-Object {$ServiceName -eq $_.ServiceName} | Select-Object -ExpandProperty ServiceUsers
        [string]$ServiceUser = $(($CurrentService.StartName -split '\\')[-1])
        "Eligible users: $($EligibleUsers -join ', ') " | Write-Debug
        "Service runs as: $ServiceUser" | Write-Debug
        #Check if the service runs from a correct account
        if ( $EligibleUsers -inotcontains $ServiceUser )
        {
           #Collect if service account is wrong
           $Deficiencies += "Service $($CurrentService.Name) Runs under account: $($CurrentService.StartName) on $env:COMPUTERNAME. Agent $AgentName."
        }
    }
}

#Deficiencies to log
if ( 0 -lt $Deficiencies.Count )
{
    $Deficiencies -join "`n" | Write-Output
}
else
{
    "No Deficiencies" | Write-Output
}

#region check/stop transcript
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript