function Start-VSAPatchScan
{
    <#
    .Synopsis
       Scans an agent machine immediately for missing patches.
    .DESCRIPTION
       Scans an agent machine immediately for missing patches.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies id of agent machine
    .EXAMPLE
       Start-VSAPatchScan -AgentId 979868787875855
    .EXAMPLE
       Start-VSAPatchScan -VSAConnection $connection -AgentId 979868787875855
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/assetmgmt/patch/{0}/scannow",

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

    $URISuffix = $URISuffix -f $AgentId

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
}

Export-ModuleMember -Function Start-VSAPatchScan