<#
.Synopsis
   Checks if screen lock is enabled and saves settings information to a csv
.DESCRIPTION
   Checks screen lock parameters in applied GPOs and local registry for each user found in the system. Log found parameters to a csv-file.
.EXAMPLE
   .\Gather-ScreenLockParams.ps1 -FileName 'screenlock.csv' -Path 'C:\TEMP' -AgentName '123456'
   .EXAMPLE
   .\Gather-ScreenLockParams.ps1 -FileName 'screenlock.csv' -Path 'C:\TEMP' -AgentName '123456' -LogIt 1
.NOTES
   Version 0.3
   Author: Proserv Team - VS
#>
#region initialization

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName,
    [parameter(Mandatory=$true)]
    [string]$FileName,
    [parameter(Mandatory=$true)]
    [string]$Path,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
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

$currentDate = Get-Date -UFormat "%m/%d/%Y %T"

[array]$outputArray = @()

#The parameters that enable Screen lock: 'ScreenSaveActive', 'ScreenSaveTimeOut' and 'ScreenSaverIsSecure'
[string[]]$saverParameters = @('ScreenSaveActive', 'ScreenSaveTimeOut', 'ScreenSaverIsSecure')

# under the Registry key there are Screen lock settings
[string]$RegKeyScreenLock = 'HKCU\Control Panel\Desktop'

# under the ProfileList key there are subkeys for each user in the system. 
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

[string[]] $UserAccountSIDs = try {
    (Get-ChildItem -Name Registry::$RegKeyUserProfiles -ErrorAction Stop).PSChildName | `
    Where-Object { $_ -match "S-1-5-21-\d+" } #skip non-user accounts
} catch {$null}

if ( 0 -ne $UserAccountSIDs.Length )
{
    Foreach ( $UserSID in $UserAccountSIDs )
    {
        $Account = New-Object Security.Principal.SecurityIdentifier("$UserSID")
        $NetbiosName = $(  try { $Account.Translate([Security.Principal.NTAccount]) | Select-Object -ExpandProperty Value } catch { $_.Exception.Message } )

        if ( $NetbiosName -notmatch 'Exception' )
        {
            #To query resultant set of GPOs for the user the user's SID has to be modified
            [string]$UserNameSpace = $UserSID -replace '-', '_'

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
                    User = $NetbiosName 
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
                                Get-WmiObject -Namespace "root\rsop\user\$UserNameSpace" -Query $Query -ErrorAction Stop | Select-Object -Unique } catch { $null }

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
                            $outputArray += New-Object PSObject –Property $OutputData | Select-Object AgentGuid, Hostname, User, Name, Value, RegistryKey, SetBy, Date
                            $State = 'Processed'
                        }

                    }
                } while ( 'Processed' -ne $State )
                #endregion get actual settins
            }
        }
    }
}

$outputArray | Export-Csv -Path "FileSystem::$FileName" -Encoding UTF8 -NoTypeInformation -Force

#region check/stop transcript
if ( 1 -eq $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript