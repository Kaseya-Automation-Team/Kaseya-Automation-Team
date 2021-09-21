function Get-VSAOrganization
{
    <#
    .Synopsis
       Returns Organizations Data.
    .DESCRIPTION
       Returns Organizations Data.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrganizationID
        Specifies OrganizationID to return. All Organizations are returned if no OrganizationID specified.
        Not Compatible with -GetLocations, -GetTypes, -Filter, -Paging, -Sort parameters.
    .PARAMETER GetLocations
        Returns Organizations' Location.
        Not Compatible with -GetTypes, -OrganizationID, -Filter, -Paging, -Sort parameters.
    .PARAMETER GetTypes
        Returns Organizations' Types.
        Not Compatible with -GetLocations, -OrganizationID, -Filter, -Paging, -Sort parameters.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAOrganization
    .EXAMPLE
       Get-VSAOrganization -GetLocations
    .EXAMPLE
       Get-VSAOrganization -GetTypes
    .EXAMPLE
       Get-VSAOrganization -OrganizationID '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Organizations' Data.
    #>
    [CmdletBinding()]
    param ( 
        
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Locations')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Types')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Locations')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Types')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/orgs',

        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Locations')]
        [switch] $GetLocations,

        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Types')]
        [switch] $GetTypes,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationID,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    if( -not [string]::IsNullOrEmpty($OrganizationID)) {
        $URISuffix = "$URISuffix/$OrganizationID"
    }

    if( $GetLocations ) {
        $URISuffix = "$URISuffix/locations"
    }

    if( $GetTypes) {
        $URISuffix = "$URISuffix/types"
    }

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    $Params | Out-String | Write-Verbose
    $Params | Out-String | Write-Debug

    return Get-VSAItems @Params
}
Export-ModuleMember -Function Get-VSAOrganization