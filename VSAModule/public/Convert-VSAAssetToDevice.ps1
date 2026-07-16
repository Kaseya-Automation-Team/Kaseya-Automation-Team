function Convert-VSAAssetToDevice
{
    <#
    .Synopsis
       Demotes an asset to a device.
    .DESCRIPTION
       Demotes a managed asset back to an unmanaged network device.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AssetId
        Specifies the asset id to demote.
    .EXAMPLE
       Convert-VSAAssetToDevice -AssetId 10001
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the demotion was successful.
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/asset/{0}/demoteToDevice',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $AssetId
    )
    process {
        $URISuffix = $URISuffix -f $AssetId
        return Invoke-VSAWriteRequest -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Convert-VSAAssetToDevice
