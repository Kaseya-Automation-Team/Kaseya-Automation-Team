function Set-VSAAssetService
{
    <#
    .Synopsis
       Assigns remote-control services to an asset.
    .DESCRIPTION
       Assigns a set of remote-control services to a specified asset. The request body is the array
       of services (or service ids) to assign.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AssetId
        Specifies the asset id.
    .PARAMETER Service
        Specifies the array of services (or service ids) to assign to the asset.
    .EXAMPLE
       Set-VSAAssetService -AssetId 10001 -Service @('a1b2...', 'c3d4...')
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/{0}/assignservice',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $AssetId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [object[]] $Service
    )
    process {
        $URISuffix = $URISuffix -f $AssetId
        # This endpoint's body is a JSON array, so serialize directly (the -Body string is passed
        # through by Invoke-VSAWriteRequest, which only prunes/serializes hashtable bodies).
        [string] $Body = ConvertTo-Json -InputObject @($Service) -Depth 10
        return Invoke-VSAWriteRequest -Body $Body -Method PUT -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Set-VSAAssetService
