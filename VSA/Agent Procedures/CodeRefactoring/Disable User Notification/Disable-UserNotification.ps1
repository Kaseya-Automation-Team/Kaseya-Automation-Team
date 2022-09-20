<#
=================================================================================
Script Name:        Management: Disable User Notification
Description:        Disables User Notification Center on Windows 10 1709 & newer.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
<#
    Disables User Notification Center on Windows 10 1709 & newer.
#>
[string] $Set = 'Off'

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

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
        [string] $RegValue
    )
    
    begin {
        [string] $RegKey = Split-Path -Path Registry::$RegPath -Parent
        [string] $RegProperty = Split-Path -Path Registry::$RegPath -Leaf
    }
    
    process {
        if ( -not (Test-Path -Path $RegPath) ) {
            #Create key
            if( -not (Test-Path -Path $RegKey) ) {
                try {
                    New-Item -Path $RegKey -Force  -ErrorAction Stop
                } catch {
                    Write-Error $_.Exception.Message
                }
            }
            #Create property
            try {
                New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType DWord -Value $RegValue -Force  -ErrorAction Stop
            } catch {
                Write-Error $_.Exception.Message
            }
        } else {
            # Set property
            try {
                Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -ErrorAction Stop
            } catch {
                Write-Error $_.Exception.Message
            }
        }
    } # process
}
#endregion function Set-RegParam

#region keys & values
#depending on the reistry key different values are used to enable/disable controlled property
[array] $RegParameters = @()

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

#region Change Machine hive
foreach($item in $RegParameters) {
    [string] $RegPath = Join-Path -Path 'HKEY_LOCAL_MACHINE' -ChildPath $($item.ChildPath)
    $Value = $item | Select-Object -ExpandProperty $Set
    Set-RegParam -RegPath $RegPath -RegValue $Value
}
#endregion Change Machine hive

#region Change Users' Hives

[string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'

[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                    Select-Object  @{name="SID";expression={$_.PSChildName}}, 
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                    @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                        Where-Object { $_.SID -match $SIDPattern }

# Loop through each profile on the machine
Foreach ($Profile in $ProfileList) {
    reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)" | Out-Null

    # Modifying a user`s hive of the registry
    foreach($item in $RegParameters) {
        [string] $RegPath = Join-Path -Path "HKEY_USERS\$($Profile.SID)" -ChildPath $($item.ChildPath)
        $Value = $item | Select-Object -ExpandProperty $Set
        Set-RegParam -RegPath $RegPath -RegValue $Value
    }
 
    # Unload ntuser.dat        
    [gc]::Collect()
    reg unload "HKU\$($Profile.SID)"
}
#endregion Change Users' Hives
[System.Diagnostics.EventLog]::WriteEntry("VSA X", "User Notification Center Disabled", "Information", 200)