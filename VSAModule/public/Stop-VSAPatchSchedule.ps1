function Stop-VSAPatchSchedule
{
    <#
    .Synopsis
       Cancels scheduled patch installations for an agent.
    .DESCRIPTION
       Cancels one or more scheduled patch installations on an agent machine, identified by their
       patch data ids.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies the agent id.
    .PARAMETER PatchDataIds
        Specifies one or more patch data ids whose scheduled installation should be cancelled.
    .EXAMPLE
       Stop-VSAPatchSchedule -AgentId 123456789 -PatchDataIds 55
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the cancellation was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/patch/{0}/cancelschedule',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $AgentId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            foreach ($id in $_) { if ($id -notmatch "^\d+$") { throw "Non-numeric patch data Id" } }
            return $true
        })]
        [string[]] $PatchDataIds
    )
    process {
        $URISuffix = $URISuffix -f $AgentId
        $query = '?' + (($PatchDataIds | ForEach-Object { "patchDataIds=$([uri]::EscapeDataString($_))" }) -join '&')
        $URISuffix = $URISuffix + $query
        return Invoke-VSAWriteRequest -Method DELETE -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Stop-VSAPatchSchedule
