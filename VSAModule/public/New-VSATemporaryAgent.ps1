function New-VSATemporaryAgent
{
    <#
    .Synopsis
       Creates a new temporary (Live Connect) agent.
    .DESCRIPTION
       Creates a new temporary agent and returns its details (agent guid, install package).
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       New-VSATemporaryAgent
    .EXAMPLE
       New-VSATemporaryAgent -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       The created temporary agent.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/temporaryagent'
    )
    process {
        return Invoke-VSAWriteRequest -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function New-VSATemporaryAgent
