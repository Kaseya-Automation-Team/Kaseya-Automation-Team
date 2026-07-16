function Start-VSAAuditBaseLine
{
    <#
    .Synopsis
       Runs a baseline audit.
    .DESCRIPTION
       Runs a baseline audit immediately for a single agent. A baseline audit shows the configuration of the system in its original state. Typically a baseline audit is performed when a system is first set up.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentID
        Specifies the agent Id.
    .EXAMPLE
       Start-VSAAuditBaseLine -AgentID 10001
    .EXAMPLE
       Start-VSAAuditBaseLine -AgentID 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if start of baseline audit was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/baseline/{0}/runnow',

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID
    )

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $AgentID)) -VSAConnection $VSAConnection -Caller $PSCmdlet
}
Export-ModuleMember -Function Start-VSAAuditBaseLine