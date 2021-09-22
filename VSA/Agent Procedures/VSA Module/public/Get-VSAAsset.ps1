function Get-VSAAsset
{
    <#
    .Synopsis
       Returns VSA assets.
    .DESCRIPTION
       Returns existing VSA assets.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AssetID
        Specifies Asset ID. Returns all assets if not Asset ID specified
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return asset types as well as their respective IDs.
    .EXAMPLE
       Get-VSAAsset
    .EXAMPLE
       Get-VSAAsset -AssetId '10001'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent existing VSA assets
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets',

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AssetId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort, 
        
        [Parameter(Mandatory = $false)]
        [switch] $ResolveIDs
    )

    if( -not [string]::IsNullOrWhiteSpace( $AssetId) ) {
        $URISuffix += "/$AssetId"
    }
    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    $result = Get-VSAItems @Params

    if ($ResolveIDs)
    {
        [hashtable]$ResolveParams =@{}
        if($VSAConnection) {$ResolveParams.Add('VSAConnection', $VSAConnection)}

        "Call Get-VSAAssetTypes to resolve AssetTypes" | Write-Verbose
        $AssetTypes = Get-VSAAssetTypes @ResolveParams
        [hashtable]$AssetTypeDictionary = @{}

        Foreach( $AssetType in $($AssetTypes | Where-Object {0 -eq $_.ParentAssetTypeId} ) ) { # Resolve Parent AssetTypes
            if ( -Not $AssetTypeDictionary[$AssetType.AssetTypeId]) {
                $AssetTypeDictionary.Add($AssetType.AssetTypeId, $AssetType.AssetTypeName)
            }
        }

        Foreach( $AssetType in $($AssetTypes | Where-Object {0 -lt $_.ParentAssetTypeId} ) ) { # Resolve AssetTypes
            $ParentAssetTypeName = $AssetTypeDictionary[$AssetType.ParentAssetTypeId]
            if ( -Not $AssetTypeDictionary[$AssetType.AssetTypeId]) {
                $AssetTypeName = "$ParentAssetTypeName.$($AssetType.AssetTypeName)"
                $AssetTypeDictionary.Add($AssetType.AssetTypeId, $AssetTypeName)
            }
        }

        $result = $result | Select-Object -Property *, `
            @{Name = 'AssetType'; Expression = { $AssetTypeDictionary[$_.AssetTypeId] }}
    }    

    return $result
}
Export-ModuleMember -Function Get-VSAAsset