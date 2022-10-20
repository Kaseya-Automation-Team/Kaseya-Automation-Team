#region function Clear-Folder
function Clear-Folder {
[CmdletBinding()]
param (
    [parameter(Mandatory=$true, 
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $TheFolder)
    if ( Test-Path -Path $TheFolder -PathType Container) {
        Get-ChildItem -Path $TheFolder -Recurse -Force | Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}
#endregion function Clear-Folder

#region function Set-RegParam
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
Set-RegParam -RegPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search\AllowCortana' -RegValue 0 -UpdateExisting


[array] $ItemsToClear = Get-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name "TEMP" | Select-Object -ExpandProperty "TEMP"


[array] $RegParameters = @()

#region keys & values
#depending on the reistry key different values are used to enable/disable controlled property
$RegParameters +=  New-Object PSObject -Property @{
ChildPath = 'Software\Policies\Microsoft\Windows\Explorer\DisableNotificationCenter'
On = 0
Off = 1
}
$RegParameters += New-Object PSObject -Property @{
ChildPath = 'Software\Microsoft\Windows\CurrentVersion\PushNotifications\ToastEnabled'
On = 1
Off = 0
}
#endregion keys & values

[string] $SIDPattern = '^S-1-5-21-(\d+-?){4}$'
Get-CimInstance Win32_UserProfile | Where-Object {$_.SID -match $SIDPattern} | Select-Object LocalPath, SID | `
    ForEach-Object {
        
        $UserProfilePath = $_.LocalPath

        [bool] $IsUserLoggedIn = Test-Path Registry::HKEY_USERS\$($_.SID)
        if ( -Not $IsUserLoggedIn ) {
            reg load "HKU\$($_.SID)" "$UserProfilePath\ntuser.dat"
        }

        [string] $AppDataPath = Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Local AppData" | Select-Object -ExpandProperty "Local AppData"

        $RunningProcessProfilePath = $env:USERPROFILE
        
        $AppDataPath = $AppDataPath.Replace($RunningProcessProfilePath, $UserProfilePath)

        #region Collect Browser Cache containers
        #Mozilla
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Mozilla\Firefox\Profiles\*.default*\cache*" -Resolve -ErrorAction SilentlyContinue
        #Chrome
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\cache*" -Resolve -ErrorAction SilentlyContinue
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Google\Chrome\User Data\Default\Media Cache*" -Resolve -ErrorAction SilentlyContinue
        #MS Edge
        $ItemsToClear += Join-Path -Path $AppDataPath -ChildPath "Microsoft\Edge\User Data\Default\Cache\Cache_Data*" -Resolve -ErrorAction SilentlyContinue
        #MS IE
        $ItemsToClear += $(Get-ItemProperty -Path Registry::$(Join-Path -Path "HKEY_USERS\$($_.SID)" -ChildPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") -Name "Cache" `
                | Select-Object -ExpandProperty "Cache").Replace($RunningProcessProfilePath, $UserProfilePath)
        #endregion Collect Browser Cache containers

        foreach($item in $RegParameters) {
            [string] $RegPath = Join-Path -Path $($_.SID) -ChildPath $($item.ChildPath)
            $Value = $item | Select-Object -ExpandProperty $Set
            Set-RegParam -RegPath $RegPath -RegValue $Value
        }

        [gc]::Collect()
        If ( -Not $IsUserLoggedIn ) {
            (reg unload "HKU\$($_.SID)" ) 2> $null
        }
    }
#Remove cached & temp items
$ItemsToClear | ForEach-Object { Clear-Folder $_ }