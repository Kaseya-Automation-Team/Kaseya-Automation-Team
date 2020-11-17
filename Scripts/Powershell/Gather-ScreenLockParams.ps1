<#
.Synopsis
   Checks if screen lock is enabled and saves settings information to a csv
.DESCRIPTION
   Checks screen lock parameters in applied GPOs and local registry. Log found parameters to a csv-file.
.EXAMPLE
   Gather-ScreenLockParams.ps1 -FileName 'screenlock.csv' -Path 'C:\TEMP' -AgentName '123456'
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
    [string]$Path = ""
 )
#User GUID to query RSOP
$userGUID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value -replace '-', '_'

#The parameters that enable Screen lock: 'ScreenSaveActive', 'ScreenSaveTimeOut' and 'ScreenSaverIsSecure'
[string[]]$saverParameters = @('ScreenSaveActive', 'ScreenSaveTimeOut', 'ScreenSaverIsSecure')

#Local Registry key
[string]$RegKey = 'HKCU:Control Panel\Desktop'

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

#Make sure that the existing output file deleted before collecting the data
if(Test-Path "$Path\$FileName") {Remove-Item "$Path\$FileName" -Force}

[array]$outputArray = @()
#endregion initialization

#region Get-RegistryValue
<#
.Synopsis
   Returns specified registry as a string
#>
function Get-RegistryValue
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()] 
        [string] $RegKey,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateNotNullOrEmpty()] 
        [string] $Name
    )
    try { ( Get-ItemProperty -path $RegKey -name $Name -ErrorAction Stop ).$Name } catch { $null }
}
#endregion Get-RegistryValue

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
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
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
                    Get-WmiObject -Namespace "root\rsop\user\$userGUID" -Query $Query -ErrorAction Stop | Select-Object -Unique } catch { $null }

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
                $regSetting = try {Get-RegistryValue -RegKey $RegKey -Name $parameter -ErrorAction Stop } catch { $null }

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

#region output
if ( 0 -lt $outputArray.Count )
{
    if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
    if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

    $outputArray | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation
}
#endregion output