function Start-VSAAgentUpgrade
{
    <#
    .Synopsis
       Upgrades the agent software on a machine.
    .DESCRIPTION
       Triggers an update of the Kaseya agent software on the specified agent machine.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies the agent id to upgrade.
    .EXAMPLE
       Start-VSAAgentUpgrade -AgentId 123456789
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the upgrade was initiated successfully.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/agent/upgrade/{0}',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $AgentId
    )
    process {
        $URISuffix = $URISuffix -f $AgentId
        return Invoke-VSAWriteRequest -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Start-VSAAgentUpgrade
