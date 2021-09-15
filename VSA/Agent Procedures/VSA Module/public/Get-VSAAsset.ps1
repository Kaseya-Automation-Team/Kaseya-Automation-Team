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
    .EXAMPLE
       Get-VSAAsset
    .EXAMPLE
       Get-VSAAsset -VSAConnection $connection
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
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $AssetId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
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

        [hashtable]$RolesDictionary = @{}
        [hashtable]$ScopesDictionary = @{}

        Foreach( $Role in $(Get-VSARoles @ResolveParams -ResolveIDs) )
        {
            if ( -Not $RolesDictionary[$Role.RoleId]){}
            $RolesDictionary.Add($Role.RoleId, $($Role | Select-Object * -ExcludeProperty RoleId))
        }

        Foreach( $Scope in $(Get-VSAScopes @ResolveParams) )
        {
            if ( -Not $ScopesDictionary[$Scope.ScopeId]){}
            $ScopesDictionary.Add($Scope.ScopeId, $Scope.ScopeName)
        }
        $result = $result | Select-Object -Property *, `
            @{Name = 'AdminRoles'; Expression = { $RolesDictionary[$_.AdminRoleIds] }},
            @{Name = 'AdminScopes'; Expression = { $ScopesDictionary[$_.AdminScopeIds] }}
    }

    return $result
}
Export-ModuleMember -Function Get-VSAAsset