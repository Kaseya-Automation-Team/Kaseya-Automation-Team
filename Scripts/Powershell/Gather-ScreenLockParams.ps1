<#
.Synopsis
   Checks if screen lock is enabled and saves settings information to a csv
.DESCRIPTION
   Checks screen lock parameters in applied GPOs and local registry. Log found parameters to a csv-file.
.EXAMPLE
   .\Gather-ScreenLockParams.ps1 -FileName 'screenlock.csv' -Path 'C:\TEMP' -AgentName '123456'
.NOTES
   Version 0.2
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

#User SID to query RSOP
$LoggedOnUser = $( try {Get-WmiObject -Class Win32_ComputerSystem -ComputerName $env:COMPUTERNAME  -ErrorAction Stop | Select-Object -ExpandProperty Username | Select-Object -First 1 } catch { 'S-1-5-18'} )
$UserSID = ([System.Security.Principal.NTAccount]$LoggedOnUser).Translate([System.Security.Principal.SecurityIdentifier]).Value  -replace '-', '_'

#The parameters that enable Screen lock: 'ScreenSaveActive', 'ScreenSaveTimeOut' and 'ScreenSaverIsSecure'
[string[]]$saverParameters = @('ScreenSaveActive', 'ScreenSaveTimeOut', 'ScreenSaverIsSecure')

#Local Registry key
[string]$RegKey = 'HKCU\Control Panel\Desktop'

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

[array]$outputArray = @()
#endregion initialization

#region Convert-Uint8ArrayToString
<#
.Synopsis
   Converts data from uint8 array to a readable string
#>
function Convert-Uint8ArrayToString
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [Byte[]]
        $InputValue
    )
    #[System.Text.Encoding]::UTF8.GetString($InputValue) -replace "\W"
    [System.Text.Encoding]::UTF8.GetString($InputValue) -replace "\x00+"
}
#endregion Convert-Uint8ArrayToString

<#
There are 3 parameters that enable Screen lock: 'ScreenSaveActive', 'ScreenSaveTimeOut' and 'ScreenSaverIsSecure'
Since GPOs override local registry settings
1. Get RSOP for the parameter
2. If no RSOP for the parameter - Get parameter settings from from local registry
#>

foreach($parameter in $saverParameters)
{
    [hashtable]$OutputData = @{
        AgentGuid = $AgentName
        Hostname = $env:COMPUTERNAME
        Name = $parameter
        Value = 'Not Set'
        RegistryKey = 'Not Set'
        SetBy = 'Not Set'
        Date = $currentDate
    }

    #region get actual settins

    #State machine approach instead of multiple nested "if"s
    #At first try to get GPO settings defined for the parameter

    [string]$State = 'LookingUpGPO'

    do {

        switch( $State )
        {
            'LookingUpGPO'
            {
                $Query = "SELECT registryKey, value, GPOID FROM RSOP_RegistryPolicySetting WHERE Name = '$parameter'"
                $gpoSetting = try {
                    Get-WmiObject -Namespace "root\rsop\user\$userSID" -Query $Query -ErrorAction Stop | Select-Object -Unique } catch { $null }

                if( $null -ne $gpoSetting)  #GPO setting obtained
                {
                    $OutputData.Value = $( Convert-Uint8ArrayToString $($gpoSetting.value) )
                    $OutputData.RegistryKey = $($gpoSetting.registryKey )
                    $OutputData.SetBy = $( $gpoSetting.GPOID )

                    $State = 'AddingDataToOutput'
                }
                else { $State = 'LookingUpRegistry' }
            }

            'LookingUpRegistry'
            {
                $regSetting = try { ( Get-ItemProperty -Path Registry::$RegKey -Name $parameter -ErrorAction Stop ).$parameter } catch { $null }

                if ( ($null -ne $regSetting) -and ( -Not [string]::IsNullOrEmpty( $regSetting.Trim()) ) )
                {
                    #non empty value exists
                    $OutputData.Value = $regSetting
                    $OutputData.RegistryKey = $RegKey
                    $OutputData.setBy = 'Local Registry'
                }
                $State = 'AddingDataToOutput' #After registry search
            }

            'AddingDataToOutput'
            {
                $outputArray += [pscustomobject]$OutputData | Select-Object AgentGuid, Hostname, Name, Value, RegistryKey, SetBy, Date
                $State = 'Processed'
            }

        }
    } while ( 'Processed' -ne $State )
    #endregion get actual settins
}

$outputArray | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation -Force