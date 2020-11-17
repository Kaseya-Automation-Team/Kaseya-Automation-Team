<#
.Synopsis
   Gets active power settings and saves the settings information to a csv-file
.DESCRIPTION
   Gets active power settings and saves the settings information to a csv-file
.EXAMPLE
   Gather-PowerSettings -FileName 'powersettings.csv' -Path 'C:\TEMP' -AgentName '123456'
.NOTES
   Version 0.1
   Author: Vladislav Semko
   Email: Vladislav.Semko@kaseya.com
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

#Create an object to store all the settings
$Settings = New-Object System.Collections.Generic.List[PSObject] 

$OutputObject = [PSCustomObject]@{
    PlanId = $null
    ElementName = $null
    Settings =  $Settings
}

#Get the active power plan
$ActivePlan = try {
    Get-WmiObject -Namespace root\cimv2\power -Query "SELECT InstanceID, ElementName FROM win32_PowerPlan WHERE IsActive=True" -ErrorAction Stop
} catch {
    $null
    exit
}

#Get just ID from the query's output
[string]$regexp = '\{(.+?)\}'
$ActivePlanId = [regex]::match( $ActivePlan.InstanceID, $regexp ).Groups[1].Value

#Add Plan ID & name to the output object
$OutputObject.PlanId = $ActivePlanId
$OutputObject.ElementName = $ActivePlan.ElementName

#region prepare info for replacing settings' IDs with their names
# Get the readable names for the settings
try {
    $SettingNames = Get-WmiObject -Namespace root\cimv2\power -Query "SELECT ElementName,InstanceID FROM Win32_PowerSetting" -ErrorAction Stop
} catch {
    $null
    exit
}

#Create  dictionary to match setting names and their ID's
[hashtable]$SettingsDictionary = @{}

foreach ($item in $SettingNames)
{
    $SettingId = [regex]::match( $item.InstanceID, $regexp ).Groups[0].Value
    $SettingsDictionary.Add( $SettingId, $item  )
}
#endregion prepare info for replacing settings' IDs with their names

#region obtin settings for the active plan
try {
    $Settings = Get-WmiObject -Namespace root\cimv2\power -Query "SELECT InstanceId,SettingIndexValue FROM Win32_PowerSettingDataIndex WHERE InstanceId Like '%$ActivePlanId%'" -ErrorAction Stop
}
catch {
    $null
    exit
}
#endregion obtin settings for the active plan

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"
#Fill Up output object's settings with values
foreach ( $item in $Settings )
{
    $SettingID = $item.InstanceId.Split("\")[-1]
    $SettingsElement = [PSCustomObject]@{
        AgentGuid = $AgentName
        Hostname = $env:COMPUTERNAME
        #PlanId = $OutputObject.PlanId
        PlanName = $OutputObject.ElementName
        PowerSource = $null
        #SettingId = $SettingID
        SettingName = $SettingsDictionary.($SettingID).ElementName
        SettingValue = $item.SettingIndexValue
        Date = $currentDate
    }
    # Mark if on battery or plugged In

    if ($item.InstanceId -match "AC") {
        $SettingsElement.PowerSource = "Plugged in"
    }
    if ($item.InstanceId -match "DC")
    {
        $SettingsElement.PowerSource = "On battery"
    }
    # Add the setting to the output object
    $OutputObject.Settings.Add($SettingsElement)
}
# Output collected settings

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

$OutputObject.Settings | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation