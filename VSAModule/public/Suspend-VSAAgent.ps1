function Suspend-VSAAgent
{
    <#
    .Synopsis
       Suspends (or resumes) agents.
    .DESCRIPTION
       Suspends one or more agents so they stop checking in and running procedures. Pass
       -SuspendAgent:$false to resume previously-suspended agents.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentGuids
        Specifies one or more agent guids to suspend or resume.
    .PARAMETER SuspendAgent
        $true (default) suspends the agents; $false resumes them.
    .EXAMPLE
       Suspend-VSAAgent -AgentGuids 123456789
    .EXAMPLE
       Suspend-VSAAgent -AgentGuids 123456789, 987654321 -SuspendAgent:$false
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the operation was successful.
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/agent/suspend',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]] $AgentGuids,

        [Parameter(Mandatory = $false)]
        [bool] $SuspendAgent = $true
    )
    process {
        # Built explicitly: SuspendAgent is a boolean that must always be sent (including $false), and
        # AgentGuids is a JSON array.
        [hashtable] $BodyHT = @{
            AgentGuids   = @($AgentGuids)
            SuspendAgent = $SuspendAgent
        }
        return Invoke-VSAWriteRequest -Body $BodyHT -KeepEmpty -Method PUT -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Suspend-VSAAgent
