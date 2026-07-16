function Get-VSAOrganization
{
    <#
    .Synopsis
        Returns Organizations Data.
    .DESCRIPTION
        Returns Organizations Data.
        Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies an established VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrgID
        Specifies OrgID to return. All Organizations are returned if no OrgID specified.
        Not Compatible with -GetLocations, -GetTypes, -Filter, -Sort parameters.
    .PARAMETER GetLocations
        Returns Organizations' Location.
        Not Compatible with -GetTypes, -OrgID, -Filter, -Sort parameters.
    .PARAMETER GetTypes
        Returns Organizations' Types.
        Not Compatible with -GetLocations, -OrgID, -Filter, -Sort parameters.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER Parallel
        Fetches the remaining pages of a large collection concurrently instead of one after another.
        Opt-in: without it, behaviour is unchanged. Results are identical either way (same records,
        merged in $skip order). Only engages once the collection is large enough to be worth it
        (see -ParallelThreshold).
    .PARAMETER ThrottleLimit
        Maximum number of concurrent requests when -Parallel is used (default 8). On shared SaaS you
        are one tenant among many, so a modest value is a good citizen; the engine also reduces
        concurrency automatically if the server returns HTTP 429, then recovers.
    .PARAMETER ParallelThreshold
        Minimum total record count before -Parallel actually engages. 0 (default) means automatic:
        two full throttle windows, i.e. 2 * ThrottleLimit * 100 records. Below that the sequential
        path is used, because it is faster than paying to set up extra connections.    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection
    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection -GetLocations
    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection -GetTypes
    .EXAMPLE
       Get-VSAOrganization -VSAConnection $VSAConnection -OrgID '10001'
    .INPUTS
       Accepts piped VSAConnection
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

        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'Locations')]
        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'Types')]
        [parameter(DontShow, Mandatory = $false,

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

        [Alias('OrganizationId','Id')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Filtering')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgId,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Filtering')]
        [ValidateNotNullOrEmpty()]
        [string] $Sort,

        # Opt-in parallel paging for large collections (see Invoke-VSARestMethod). No effect on small
        # ones: below -ParallelThreshold the sequential path is used.
        [parameter(Mandatory = $false)]
        [switch] $Parallel,

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 8,

        [parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ParallelThreshold = 0
    )
    process {

    if( -not [string]::IsNullOrEmpty($OrgId)) {
        $URISuffix = "{0}/{1}" -f $URISuffix, $OrgId
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
        Sort          = $Sort
    }

    #Remove empty keys
    foreach ( $key in @($Params.Keys)  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    #region messages to verbose and debug streams
    "Get-VSAOrganization: $($Params | Out-String)" | Write-Debug

    "Get-VSAOrganization: $($Params | Out-String)" | Write-Verbose

    #endregion messages to verbose and debug streams

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
    return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSAOrganization
