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
    [CmdletBinding(DefaultParameterSetName='All')]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ParameterSetName = 'All')]
        [parameter(DontShow, Mandatory=$false,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets',

        [Parameter(Mandatory = $false,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AssetId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
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

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    foreach ( $key in $Params.Keys.Clone()  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    $result = Invoke-VSARestMethod @Params

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