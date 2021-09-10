function Get-VSAUserRoles
{
    <#
    .Synopsis
       Returns VSA user roles
    .DESCRIPTION
       Returns existing VSA user roles.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return Role Types as well as their IDs.
    .EXAMPLE
       Get-VSAUserRoles
    .EXAMPLE
       Get-VSAUserRoles -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent existing VSA users
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/roles',
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [switch] $ResolveIDs

    )

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    return Get-VSAItems @Params
}
Export-ModuleMember -Function Get-VSAUserRoles