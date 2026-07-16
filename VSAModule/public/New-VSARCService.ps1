function New-VSARCService
{
    <#
    .Synopsis
       Creates a custom remote-control service.
    .DESCRIPTION
       Creates a custom remote-control service (protocol/port mapping) that can be assigned to assets.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceName
        Specifies the service name (e.g. 'rdp').
    .PARAMETER Port
        Specifies the TCP port.
    .PARAMETER ClientApp
        Specifies the client application. One of: http, https, ssh, telnet, tunnelonly.
    .PARAMETER Path
        Specifies an optional path.
    .EXAMPLE
       New-VSARCService -ServiceName 'rdp' -Port 3389 -ClientApp 'tunnelonly'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       The created remote-control service.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/rcservice',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [int] $Port,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('http', 'https', 'ssh', 'telnet', 'tunnelonly')]
        [string] $ClientApp,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $Path
    )
    process {
        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include @('ServiceName', 'Port', 'ClientApp', 'Path')
        return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function New-VSARCService
