<#
    Disables MS Office 2016/2019/365 hardware acceleration for all users on the system, which switches graphics and text rendering duties from GPU to CPU.
#>
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
            if( -not (Test-Path -Path $RegKey) )
            {
                try {
                    New-Item -Path $RegKey -Force -Verbose -ErrorAction Stop
                } catch { "<$RegKey> Key not created" | Write-Error }
                #Create property
                try {
                    New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                } catch { "<$RegKey> property <$RegProperty>  not created" | Write-Error}
            }            
            else
            {
                $Poperty = try {Get-ItemProperty -Path Registry::$RegPath -ErrorAction Stop | Select-Object -ExpandProperty $Value -ErrorAction Stop} catch { $null}
                if ($null -eq $Poperty )
                {
                     #Create property
                    try {
                        New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch { "<$RegKey> property <$RegProperty>  not created" | Write-Error }
                }
                #Assign value to the property
                if( $UpdateExisting )
                {
                    try {
                            Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -Verbose -ErrorAction Stop
                        } catch { "<$RegKey> property <$RegProperty> not set" | Write-Error }
                }
            }
    }
}
#endregion function Set-RegParam

# Get each user profile SID and Path to the profile
$UserProfiles = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Where {$_.PSChildName -match "^S-1-5-21-(\d+-?){4}$" } | Select-Object @{Name="SID"; Expression={$_.PSChildName}}, @{Name="UserHive";Expression={"$($_.ProfileImagePath)\NTuser.dat"}}

# Loop through each profile on the machine
Foreach ($UserProfile in $UserProfiles)
{
    # Load User ntuser.dat if it's not already loaded
    [bool] $IsProfileLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile.SID)
    If ( -Not $IsProfileLoaded )
    {
        reg load "HKU\$($UserProfile.SID)" "$($UserProfile.UserHive)"
    }

    # Manipulate the registry
    Set-RegParam -RegPath $(Join-Path -Path "HKEY_USERS\$($UserProfile.SID)" -ChildPath "Software\Microsoft\Office\16.0\Common\Graphics\DisableHardwareAcceleration") -RegValue 0x00000001 -ValueType DWord -UpdateExisting
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "MS Office hardware acceleration disabled for User SID: $($UserProfile.SID)", "Information", 200)

    # Unload NTuser.dat        
    If ( -Not $IsProfileLoaded )
    {
        [gc]::Collect()
        reg unload "HKU\$($UserProfile.SID)"
    }
}