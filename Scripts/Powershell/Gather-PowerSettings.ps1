<#
.Synopsis
   Gets active power settings and saves the settings information to a csv-file
.DESCRIPTION
   Gets active power settings and saves the settings information to a csv-file
.EXAMPLE
   test-PowerSettings -FileName 'powersettings.csv' -Path 'C:\TEMP' -AgentName '123456'
.NOTES
   Version 0.2
   Much slower, but works with problems related to obtaining Win32_PowerSetting class objects
   Author: Proserv Team - VS
#>
#region initialization

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path
 )

#region initialization
$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

#Get the active power plan
$ActivePlan = try {
    Get-WmiObject -Namespace root\cimv2\power -Query "SELECT InstanceID, ElementName FROM win32_PowerPlan WHERE IsActive=True" -ErrorAction Stop
} catch {
    $null
    exit
}

$PowerSettings = $ActivePlan.GetRelated("Win32_PowerSettingDataIndex") | ForEach-Object `
{
    $PowerSettingIndex = $_;
    $PowerSettingIndex.GetRelated("Win32_PowerSetting") | Select-Object `
        @{ Label="PowerSetting";Expression={$_.InstanceID} },
        @{ Label="AgentGuid";Expression={$AgentName} },
        @{ Label="Hostname";Expression={$env:COMPUTERNAME} },
        @{ Label="PlanName";Expression={$ActivePlan.ElementName} },
        @{ Label="PowerSource";Expression={ $(if ($PowerSettingIndex.InstanceID -match "AC") {"Plugged in"} else {"On battery"}) } },
        @{ Label="SettingName";Expression={$_.ElementName}},
        @{ Label="SettingValue";Expression={$PowerSettingIndex.SettingIndexValue} },
        @{ Label="Date";Expression={$currentDate} }
}
if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

$PowerSettings | Select-Object AgentGuid, Hostname, PlanName, PowerSource, SettingName, SettingValue, Date  | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation -Force