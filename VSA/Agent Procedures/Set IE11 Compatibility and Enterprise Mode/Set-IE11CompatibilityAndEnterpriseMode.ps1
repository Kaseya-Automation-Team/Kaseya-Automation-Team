<#
.Synopsis
   Adds IE 11 Compatibility Mode Pointer & Configures the enterprise mode site list.
.DESCRIPTION
   Adds IE 11 Compatibility Mode Pointer & Configures the enterprise mode site list.
    - Enables Internet Explorer integration.
    - Enables Enterprise Mode site list 
    Used by the Set IE11 Compatibility and Enterprise Mode Agent procedure
.EXAMPLE
   .\Set-IE11CompatibilityAndEnterpriseMode.ps1 -SiteListPath "\\FileShare\EnterpriseModeSiteList.xml"
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true)]
    [string] $SiteListPath,
    [parameter(Mandatory=$false)]
    [switch] $LogIt
)
#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

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
                    New-Item -Path $RegKey -Force -Verbose -ErrorAction Stop
                } catch {
                    "<$RegKey> Key not created" | Write-Error
                }
                #Create property
                try {
                    New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                } catch {
                    "<$RegKey> property <$RegProperty>  not created" | Write-Error
                }
            } else
            {
                $Poperty = try {
                    Get-ItemProperty -Path Registry::$RegPath -ErrorAction Stop | Select-Object -ExpandProperty $Value -ErrorAction Stop
                    } catch { $null}
                if ($null -eq $Poperty ) {
                     #Create property
                    try {
                        New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch {
                        "<$RegKey> property <$RegProperty>  not created" | Write-Error
                    }
                }
                #Assign value to the property
                if( $UpdateExisting ) {
                    try {
                        Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch {
                        "<$RegKey> property <$RegProperty> not set" | Write-Error
                    }
                }
            }
    }
}
#endregion function Set-RegParam

[array] $RegParameters = @()
$RegParameters +=  New-Object PSObject -Property @{
ChildPath = 'Software\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode\SiteList'
ValueType = 'String'
RegValue  = $SiteListPath
}
$RegParameters +=  New-Object PSObject -Property @{
ChildPath = 'SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main\EnterpriseMode\SiteList'
ValueType = 'String'
RegValue  = $SiteListPath
}
$RegParameters +=  New-Object PSObject -Property @{
ChildPath = 'SOFTWARE\Policies\Microsoft\Edge\InternetExplorerIntegrationLevel'
ValueType = 'DWord'
RegValue  = 1
}

[string[]] $ChildPaths = @("Software\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode\SiteList", "SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main\EnterpriseMode\SiteList")


if ("Installed" -eq (Get-Package | Where-Object {$_.Name -eq "Microsoft Edge"} | Select-Object -ExpandProperty Status) ) {

    #region set machine settings
    foreach ( $item in $RegParameters ) {
        $RegPath = Join-Path -Path "HKEY_LOCAL_MACHINE" -ChildPath $item.ChildPath
        Set-RegParam -RegPath $RegPath -ValueType $item.ValueType -RegValue $item.RegValue
    }
    #endregion set machine settings

    #region Change Users' Hives
    [string] $SIDPattern = '^S-1-5-21-(\d+-?){4}$'
    [string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'
    [array]  $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                        Select-Object  @{name="SID";expression={$_.PSChildName}},
                        @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}},
                        @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                        Where-Object {$_.SID -match $SIDPattern}
    # Loop through each profile on the machine
    Foreach ( $Profile in $ProfileList ) {
        # Load User ntuser.dat if it's not already loaded
        reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)"
        #####################################################################
        # Modifying a user`s hive of the registry
        "{0} {1}" -f "`tUser:", $($Profile.UserName) | Write-Verbose
    
        foreach ( $item in $RegParameters ) {
            $RegPath = Join-Path -Path "HKU\$($Profile.SID)" -ChildPath $item.ChildPath
            Set-RegParam -RegPath $RegPath -ValueType $item.ValueType -RegValue $item.RegValue
        }

        #####################################################################
        # Unload ntuser.dat        
        [gc]::Collect()
        $ErrorActionPreferenceSaved = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        reg unload "HKU\$($Profile.SID)"
        $ErrorActionPreference = $ErrorActionPreferenceSaved
    }
    #endregion Change Users' Hives
} else {
    Write-Output 'Attention! Microsoft Edge is Not Found on this computer!'
}

#region check/stop transcript
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript