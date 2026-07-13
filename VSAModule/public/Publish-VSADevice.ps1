function Publish-VSADevice
{
    <#
    .Synopsis
       Publishes a discovered device on a network as an asset.
    .DESCRIPTION
       Publishes a device discovered on a Discovery network as a managed asset. The full device
       inventory is a deeply-nested object; pass it via -Device (a hashtable/pscustomobject matching
       the API's publish-device schema), optionally overriding the common scalar fields.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER NetworkId
        Specifies the Discovery network id the device belongs to.
    .PARAMETER AssetName
        Specifies the name to give the published asset.
    .PARAMETER AssetTypeId
        Specifies the asset type id.
    .PARAMETER DeviceId
        Specifies the discovered device id.
    .PARAMETER Device
        Specifies the full device payload (hashtable/pscustomobject) for the publish-device request.
        Any scalar parameters supplied above are merged over this object.
    .EXAMPLE
       Publish-VSADevice -NetworkId 5 -AssetName 'SWITCH-01' -AssetTypeId 12 -DeviceId 20002
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       The published asset.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/{0}/publishdevice',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $NetworkId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $AssetName,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ((-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$")) { throw "Non-numeric Id" }
            return $true
        })]
        [string] $AssetTypeId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ((-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$")) { throw "Non-numeric Id" }
            return $true
        })]
        [string] $DeviceId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [object] $Device
    )
    process {
        $URISuffix = $URISuffix -f $NetworkId

        [hashtable] $BodyHT = if ($null -ne $Device) { ConvertTo-VSAHashtable $Device } else { @{} }
        $scalars = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include @('AssetName', 'AssetTypeId', 'DeviceId')
        foreach ($key in $scalars.Keys) { $BodyHT[$key] = $scalars[$key] }

        return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Publish-VSADevice
