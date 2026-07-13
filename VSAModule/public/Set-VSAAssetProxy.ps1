function Set-VSAAssetProxy
{
    <#
    .Synopsis
       Sets the remote-control proxy agent for an asset.
    .DESCRIPTION
       Assigns the agent that acts as the remote-control proxy for a specified asset.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AssetId
        Specifies the asset id.
    .PARAMETER ProxyAgentGuid
        Specifies the agent guid to use as the proxy.
    .EXAMPLE
       Set-VSAAssetProxy -AssetId 10001 -ProxyAgentGuid 123456789
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the assignment was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/{0}/setproxy',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $AssetId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $ProxyAgentGuid
    )
    process {
        $URISuffix = $URISuffix -f $AssetId
        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters `
            -Include @('ProxyAgentGuid') -NameMap @{ ProxyAgentGuid = 'agentGuid' }
        return Invoke-VSAWriteRequest -Body $BodyHT -Method PUT -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Set-VSAAssetProxy
