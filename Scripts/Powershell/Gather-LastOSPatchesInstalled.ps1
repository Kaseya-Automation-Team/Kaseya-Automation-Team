<#
.Synopsis
   Gather list of Top (3 by default) latest Windows updates and saves information to a csv-file
.DESCRIPTION
   Gather list of Top given number latest Windows updates and saves information as well as last boot time to a csv-file
.EXAMPLE
   .\Gather-LastOSPatchesInstalled.ps1 -FileName 'latest_os_patches.csv' -Path 'C:\TEMP' -AgentName '123456'
.EXAMPLE
    .\Gather-LastOSPatchesInstalled.ps1 -FileName 'latest_os_patches.csv' -Path 'C:\TEMP' -AgentName '123456' -Top 10
.EXAMPLE
    .\Gather-LastOSPatchesInstalled.ps1 -FileName 'latest_os_patches.csv' -Path 'C:\TEMP' -AgentName '123456' -Top 10 -LogIt 1
.NOTES
   Version 0.1.2
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    [parameter(Mandatory=$false)]
    [int]$Top = 3,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

#[string] $LastBootUp = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f [System.Management.ManagementDateTimeConverter]::ToDateTime($(Get-WmiObject -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime))
[string] $LastBootUp = "{0:MM'/'dd'/'yyyy H:mm:ss}" -f (Get-Date).AddMilliseconds( -([System.Environment]::TickCount) )

Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object HotFixID, InstalledOn -First $Top | Select-Object -Property `
@{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, `
@{Name = 'AgentGuid'; Expression = {$AgentName}}, `
@{Name = 'PatchName'; Expression = {$_.HotFixID}}, `
@{Name = 'InstallData'; Expression = {"{0:MM'/'dd'/'yyyy}" -f $_.InstalledOn}}, `
@{Name = 'LastBootTime'; Expression = {$LastBootUp}} `
| Export-Csv -Path "FileSystem::$FileName"-Force -Encoding UTF8 -NoTypeInformation

#region check/stop transcript
if (1 -eq $LogIt)
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript