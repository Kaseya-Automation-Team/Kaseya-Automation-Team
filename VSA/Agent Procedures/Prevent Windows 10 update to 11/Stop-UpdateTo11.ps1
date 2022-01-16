<#
.Synopsis
   Modifies the registry to prevent Windows 10 from being upgraded to Windows 11. At the same time, it allows Windows 10 upgrade to the target versions.
.DESCRIPTION
   Modifies the registry to prevent Windows 10 from being upgraded to Windows 11. At the same time, it allows Windows 10 upgrade to the target versions.
   Used by the "Prevent Windows 10 update to 11" Agent Procedure
.EXAMPLE
   .\Stop-UpdateTo11 -TargetVersion  "21H2"
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true,
                Position=0)]
    [ValidateNotNull()] 
    [string] $TargetVersion
)

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
        [string] $ValueType = 'String',
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
                } catch { Write-Error $_.Exception.Message}
                #Create property
                try {
                    New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                } catch { Write-Error $_.Exception.Message}
            }            
            else
            {
                $Poperty = try {Get-ItemProperty -Path $RegPath -ErrorAction Stop | Out-Null} catch { $null}
                if ($null -eq $Poperty )
                {
                     #Create property
                    try {
                        New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch { Write-Error $_.Exception.Message}
                }
                #Assign value to the property
                if( $UpdateExisting )
                {
                    try {
                            Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -Verbose -ErrorAction Stop
                        } catch {Write-Error $_.Exception.Message}
                }
            }
    }
}
#endregion function Set-RegParam


#Apply New Settings
Set-RegParam -RegPath $(Join-Path -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows" -ChildPath "WindowsUpdate\TargetReleaseVersion") -RegValue '1' -ValueType DWord -UpdateExisting
Set-RegParam -RegPath $(Join-Path -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows" -ChildPath "WindowsUpdate\ProductVersion") -RegValue $TargetVersion -ValueType String -UpdateExisting 