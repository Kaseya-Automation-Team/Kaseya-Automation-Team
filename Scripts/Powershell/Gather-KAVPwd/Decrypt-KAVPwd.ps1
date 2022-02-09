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

[scriptblock] $ScriptBlock = {
    $DllPath = Join-Path -Path $Using:ScriptPath -ChildPath "Kaseya.AppFoundation.dll"
    [System.Reflection.Assembly]::LoadFrom( $DllPath ) | Out-Null
    [Hermes.shared.MaskData]::HashAndUnmaskDataStringForDb($Using:InputPassword, $Using:AgentGuid) | Write-Output
}

$InvokeParameters = @{
    ScriptBlock = $ScriptBlock
    ConfigurationName = "Microsoft.PowerShell32"
    ComputerName = $($env:COMPUTERNAME)
}

Invoke-Command @InvokeParameters