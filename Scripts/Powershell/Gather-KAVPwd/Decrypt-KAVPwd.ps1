param (
    [parameter(Mandatory=$true)]
    [ValidateScript({
            if( $_ -notmatch "^CoveredData2::\w+$" ) {
                throw "Wrong format"
            }
            return $true
        })]
    [string] $InputPassword,

    [parameter(Mandatory=$true)]
    [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
    [string] $AgentGuid
)

$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path

$DllPath = Join-Path -Path $ScriptPath -ChildPath "Kaseya.AppFoundation.dll"
[System.Reflection.Assembly]::LoadFrom( $DllPath ) | Out-Null
[Hermes.shared.MaskData]::HashAndUnmaskDataStringForDb($InputPassword, $AgentGuid) | Write-Output