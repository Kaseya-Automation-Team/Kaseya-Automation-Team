function Remove-VSAAsset {
    <#
    .Synopsis
        Deletes an existing asset.
    .DESCRIPTION
        Deletes an existing asset.
        Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER FieldName
        Custom field name to selete.
    .EXAMPLE
        Remove-VSAAsset -AssetId '10001'
    .EXAMPLE
        Remove-VSAAsset -VSAConnection connection -AssetId '10001'
    .INPUTS
        Accepts piped non-persistent VSAConnection 
    .OUTPUTS
        True if removing was successful
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AssetId,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = '/assetmgmt/assets/{0}'
        )

    [bool]$result = $false
    
    $URISuffix = $URISuffix -f $FieldName

    [hashtable]$Params =@{}

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    [string[]]$ExistingAssets = Get-VSAAsset @Params | Select-Object -ExpandProperty AssetId

    If ( $AssetId -in $ExistingAssets ) {

        $Params.Add('URISuffix', $URISuffix)
        $Params.Add('Method', 'DELETE')
        $result = Update-VSAItems @Params
    } else {
        $Message = "Asset with ID `'$AssetId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }
    return $result
}
Export-ModuleMember -Function Remove-VSAAsset