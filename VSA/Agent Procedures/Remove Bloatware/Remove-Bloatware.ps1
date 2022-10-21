# Requires -Version 5.1 
<#
.Synopsis
   Disables Windows 10 bloatware.
.DESCRIPTION
   Used by Agent Procedure
   - Disables 'Upgrade to Windows 11' pop-ups
   - Disables Cortana
   - Disables the Notification Center
   - Clears browsers' caches
   - Clears temp folders
   Designed for Windows 10.
.EXAMPLE
   .\Set-Notification.ps1 Off -LogIt 0
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    
[parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0)]
            [ValidateScript({
                if( $_ -notmatch "(\d){2}H\d" ) {
                    throw "The Target Release provided does not match Windows 10 release pattern"
                }
                return $true
            })]
    [string] $TargetReleaseVersion
)

#region function Clear-Folder
<#
.Synopsis
   Removes folder's content
#>
function Clear-Folder {
[CmdletBinding()]
param (
    [parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $TheFolder)
    if ( Test-Path -Path $TheFolder -PathType Container) {
        Get-ChildItem -Path $TheFolder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}
#endregion function Clear-Folder

#region function Set-RegParam
<#
.Synopsis
   Sets Registry parameter
#>
function Set-RegParam {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0)]
        [string] $RegPath,
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=1)]
        [AllowEmptyString()]
        [string] $RegValue,
        [parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=2)]
        [ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'None', 'QWord', 'String', 'Unknown')]
        [string] $ValueType = 'DWord',
        [parameter(Mandatory=$false)]
        [Switch] $UpdateExisting
    )
    
    begin {
        [string] $RegKey = Split-Path -Path Registry::$RegPath -Parent
        [string] $RegProperty = Split-Path -Path Registry::$RegPath -Leaf
    }
    process {
            #Create key
            if( -not (Test-Path -Path $RegKey) ) {
                try {
                    New-Item -Path $RegKey -Force -ErrorAction Stop
                } catch { "<$RegKey> Key not created" }
                #Create property
                try {
                    New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -ErrorAction Stop
                } catch { "<$RegKey> property <$RegProperty>  not created"}
            } else {
                $Poperty = try {Get-ItemProperty -Path Registry::$RegPath -ErrorAction Stop | Select-Object -ExpandProperty $Value -ErrorAction Stop} catch { $null}
                if ($null -eq $Poperty ) {
                     #Create property
                    try {
                        New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -ErrorAction Stop
                    } catch { "<$RegKey> property <$RegProperty>  not created"}
                }
                #Assign value to the property
                if( $UpdateExisting ) {
                    try {
                        Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -ErrorAction Stop
                    } catch { "<$RegKey> property <$RegProperty> not set" }
                }
            }
    }
}
#endregion function Set-RegParam

#Disable Cortana
[string] $PolicyPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
#region Disable Cortana
Set-RegParam -RegPath $(Join-Path -Path $PolicyPath -ChildPath 'Windows Search\AllowCortana') -RegValue 0 -UpdateExisting
#endregion Disable Cortana

#region Disable Upgrade to Windows 11
Set-RegParam -RegPath $(Join-Path -Path $PolicyPath -ChildPath 'WindowsUpdate\SetUpdateNotificationLevel') -RegValue 0 -UpdateExisting
Set-RegParam -RegPath $(Join-Path -Path $PolicyPath -ChildPath 'WindowsUpdate\ProductVersion') -ValueType String -RegValue 'Windows 10' -UpdateExisting
Set-RegParam -RegPath $(Join-Path -Path $PolicyPath -ChildPath 'WindowsUpdate\TargetReleaseVersion') -RegValue 1 -UpdateExisting
Set-RegParam -RegPath $(Join-Path -Path $PolicyPath -ChildPath 'WindowsUpdate\TargetReleaseVersionInfo') -ValueType String -RegValue $TargetReleaseVersion -UpdateExisting
#endregion Disable Upgrade to Windows 11

[array] $ItemsToClear = Get-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name "TEMP" | Select-Object -ExpandProperty "TEMP"

[string] $SIDPattern = '^S-1-5-21-(\d+-?){4}$'
Get-CimInstance Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        
        [string] $UserProfilePath = $_.LocalPath

        [bool] $IsUserLoggedIn = Test-Path Registry::HKEY_USERS\$($_.SID)
        if ( -Not $IsUserLoggedIn ) {
            reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"
        }
        [string] $TempFolderPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "Environment") -Name "TEMP" | Select-Object -ExpandProperty "TEMP"
        [string] $AppDataPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Local AppData" | Select-Object -ExpandProperty "Local AppData"

        $RunningProcessProfilePath = $env:USERPROFILE
        
        $AppDataPath = $AppDataPath.Replace($RunningProcessProfilePath, $UserProfilePath)

        #region Collect Browser Cache containers
        #Mozilla
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\cache*" -Resolve -ErrorAction SilentlyContinue
        #Chrome
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\Cache\Cache_Data*" -Resolve -ErrorAction SilentlyContinue
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\Media Cache*" -Resolve -ErrorAction SilentlyContinue
        #MS Edge
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Microsoft\Edge\User Data\Default\Cache\Cache_Data*" -Resolve -ErrorAction SilentlyContinue
        #MS IE
        $ItemsToClear += $(Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Cache" `
                | Select-Object -ExpandProperty "Cache").Replace($RunningProcessProfilePath, $UserProfilePath)
        #endregion Collect Browser Cache containers
        $ItemsToClear += $($TempFolderPath.Replace($RunningProcessProfilePath, $UserProfilePath))

        #region Disable Notification Center
        Set-RegParam -RegPath $(Join-Path -Path "HKU\$($_.SID)" -ChildPath 'Software\Policies\Microsoft\Windows\Explorer\DisableNotificationCenter') -RegValue 1 -UpdateExisting
        Set-RegParam -RegPath $(Join-Path -Path "HKU\$($_.SID)" -ChildPath 'Software\Microsoft\Windows\CurrentVersion\PushNotifications\ToastEnabled') -RegValue 0 -UpdateExisting
        #endregion Disable Notification Center

        [gc]::Collect()
        If ( -Not $IsUserLoggedIn ) {
            (reg unload "HKU\$($_.SID)" ) 2> $null
        }
    }
#Remove cached & temp items
$ItemsToClear | ForEach-Object { Clear-Folder $_ }