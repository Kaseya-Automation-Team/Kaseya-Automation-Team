function Convert-VSADeviceToAsset
{
    <#
    .Synopsis
       Promotes a device to an asset.
    .DESCRIPTION
       Promotes an unmanaged network device to a managed asset.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER DeviceId
        Specifies the device id to promote.
    .EXAMPLE
       Convert-VSADeviceToAsset -DeviceId 20002
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the promotion was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/device/{0}/promoteToAsset',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $DeviceId
    )
    process {
        $URISuffix = $URISuffix -f $DeviceId
        return Invoke-VSAWriteRequest -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Convert-VSADeviceToAsset
