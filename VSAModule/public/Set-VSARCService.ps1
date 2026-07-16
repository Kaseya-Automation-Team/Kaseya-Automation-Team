function Set-VSARCService
{
    <#
    .Synopsis
       Updates a custom remote-control service.
    .DESCRIPTION
       Updates an existing custom remote-control service identified by its service id.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceId
        Specifies the id of the remote-control service to update.
    .PARAMETER ServiceName
        Specifies the service name.
    .PARAMETER Port
        Specifies the TCP port.
    .PARAMETER ClientApp
        Specifies the client application. One of: http, https, ssh, telnet, tunnelonly.
    .PARAMETER Path
        Specifies an optional path.
    .PARAMETER Force
        Forces the update even when the service is in use.
    .EXAMPLE
       Set-VSARCService -ServiceId 'a1b2...' -ServiceName 'rdp' -Port 3390
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the update was successful.
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/updatercservice',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [int] $Port,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('http', 'https', 'ssh', 'telnet', 'tunnelonly')]
        [string] $ClientApp,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [switch] $Force
    )
    process {
        $query = "?serviceid={0}&force={1}" -f [uri]::EscapeDataString($ServiceId), $Force.IsPresent.ToString().ToLower()
        $URISuffix = $URISuffix + $query
        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include @('ServiceName', 'Port', 'ClientApp', 'Path')
        return Invoke-VSAWriteRequest -Body $BodyHT -Method PUT -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Set-VSARCService
