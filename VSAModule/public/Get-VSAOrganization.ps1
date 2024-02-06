function Get-VSAOrganization
{
    <#
    .Synopsis
       Returns Organizations Data.
    .DESCRIPTION
       Returns Organizations Data.
    .PARAMETER VSAConnection
        Specifies an established VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrgID
        Specifies OrgID to return. All Organizations are returned if no OrgID specified.
        Not Compatible with -GetLocations, -GetTypes, -Filter, -Paging, -Sort parameters.
    .PARAMETER GetLocations
        Returns Organizations' Location.
        Not Compatible with -GetTypes, -OrgID, -Filter, -Paging, -Sort parameters.
    .PARAMETER GetTypes
        Returns Organizations' Types.
        Not Compatible with -GetLocations, -OrgID, -Filter, -Paging, -Sort parameters.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection
    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection -GetLocations
    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection -GetTypes
    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection -OrgID '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped VSAConnection 
    .OUTPUTS
       Array of objects that represent Organizations' Data.
    .NOTES
        Version 0.1.1
    #>
    [CmdletBinding()]
    param ( 
        
        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Locations')] 
        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Types')]
        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Locations')] 
        [parameter(DontShow, Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Types')]
        [parameter(DontShow, Mandatory = $false,  
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

        [Alias('OrganizationID','ID')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()]
        [string] $OrgID,

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

    if( -not [string]::IsNullOrEmpty($OrgID)) {
        $URISuffix = "{0}/{1}" -f $URISuffix, $OrgID
    }

    if( $GetLocations ) {
        $URISuffix = "{0}/{1}" -f $URISuffix, 'locations'
    }

    if( $GetTypes) {
        $URISuffix = "{0}/{1}" -f $URISuffix, 'types'
    }

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    #Remove empty keys
    foreach ( $key in $Params.Keys.Clone()  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    #region messages to verbose and debug streams
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Get-VSAOrganization: $($Params | Out-String)"  | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Get-VSAOrganization: $($Params | Out-String)"   | Write-Verbose
    }
    #endregion messages to verbose and debug streams

    return Invoke-VSARestMethod @Params
}
Export-ModuleMember -Function Get-VSAOrganization