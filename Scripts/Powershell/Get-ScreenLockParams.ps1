<#
.Synopsis
   Checks if screen lock is enabled and saves settings information to a csv
.DESCRIPTION
   Checks screen lock parameters in applied GPOs and local registry. Log found parameters to a csv-file.
.EXAMPLE
   Get-ScreenLockParams -FileName 'screenlock.csv' -Path 'C:\TEMP' -AgentName '123456'
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
$user = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value -replace '-', '_'
#The parameters that enable Screen lock: 'ScreenSaveActive', 'ScreenSaveTimeOut' and 'ScreenSaverIsSecure'
[string[]]$saverParameters = @('ScreenSaveActive', 'ScreenSaveTimeOut', 'ScreenSaverIsSecure')
#Local Registry key
[string]$RegKey = 'HKCU:Control Panel\Desktop'

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

if (-not [string]::IsNullOrEmpty( $FileName ) ) { $FileName = $FileName.Trim()}
if (-not [string]::IsNullOrEmpty( $Path ) ) { $Path = $Path.Trim()}
if (-not [string]::IsNullOrEmpty( $AgentName ) ) { $AgentName = $AgentName.Trim()}

#Make sure that the existing output file deleted before collecting the data
if(Test-Path "$Path\$FileName") {Remove-Item "$Path\$FileName" -Force}

[bool]$SettingMissed = $false   #Shows if some of setting present

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

#region Convert-Uint8arrayToString
<#
.Synopsis
   Converts data from uint8 array to a readable string
#>
function Convert-Uint8arrayToString
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
#endregion Convert-Uint8arrayToString

#Get-WmiObject -Namespace root\rsop\user\$user -List RSOP*

<#
There are 3 parameters that enable Screen lock: 'ScreenSaveActive', 'ScreenSaveTimeOut' and 'ScreenSaverIsSecure'
Since GPOs override local registry settings
1. Get RSOP for the parameter
2. If no RSOP for the parameter - Get parameter settings from from local registry
#>

foreach($parameter in $saverParameters)
{
    $Value = 'Not Set'
    $registryKey = ''
    $setBy = 'Not Set'

    #At first try to get GPO settings defined for the parameter
    [string]$Action = 'LookUpGPO'

    do {
        switch($Action)
        {
            'LookUpGPO'
            {
                $gpoSetting = Get-WmiObject -Namespace root\rsop\user\$user -Class RSOP_RegistryPolicySetting -Filter "Name = '$parameter'" `
                    | Select-Object registryKey, value, GPOID | Select-Object -Unique

                if( $null -ne $gpoSetting)  #GPO setting obtained
                {
                    
                    $Value = Convert-Uint8arrayToString $($gpoSetting.value)
                    $registryKey = $gpoSetting.registryKey
                    $setBy = $gpoSetting.GPOID

                    $Action = 'AddOutput'
                }
                else { $Action = 'LookUpRegistry' }
            }

            'LookUpRegistry'
            {
                $regSetting = Get-RegistryValue -RegKey $RegKey -Name $parameter
                if ( ($null -ne $regSetting) -and ( -Not [string]::IsNullOrEmpty( $regSetting.Trim()) ) )
                {
                    #non empty value exists
                    $Value = $regSetting
                    $registryKey = $RegKey
                    $setBy = 'Local Registry'

                    $Action = 'AddOutput'
                    
                }
                else { $Action = 'AddMissed'}
            }

            'AddOutput'
            {
                #GPO setting obtained. Adding to output
                $outputArray += [pscustomobject]@{ AgentGuid = $AgentName
                                                Hostname = $env:COMPUTERNAME
                                                Name = $parameter
                                                Value = $Value
                                                RegistryKey = $registryKey
                                                SetBy = $setBy
                                                Date = $currentDate
                                                }
                

                $Action = 'Stop'
            }
            'AddMissed'
            {
                $SettingMissed = $true
                $outputArray += [pscustomobject]@{ AgentGuid = $AgentName
                                                Hostname = $env:COMPUTERNAME
                                                Name = $parameter
                                                Value = 'Not Set'
                                                RegistryKey = $RegKey
                                                SetBy = 'Not Set'
                                                Date = $currentDate
                                                }
                $Action = 'Stop'
            }

        }
    } while ( 'Stop'-ne $Action )
}

if ( 0 -lt $outputArray.Count )
{
    if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
    if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

    $outputArray | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation
}