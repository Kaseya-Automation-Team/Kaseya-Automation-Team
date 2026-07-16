function Get-VSAUser
{
    <#
    .Synopsis
       Returns VSA users
    .DESCRIPTION
       Returns existing VSA users.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserId
        Specifies User Id. Returns all users if no User ID specified
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
       Get-VSAUser
    .PARAMETER CurrentUser
        Returns only the currently authenticated user, rather than the full user list.
    .EXAMPLE
       Get-VSAUser -UserId 34243232324
    .EXAMPLE
       Get-VSAUser -CurrentUser
    .EXAMPLE
       Get-VSAUser -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Array of objects that represent existing VSA users
    #>
    [CmdletBinding(DefaultParameterSetName = 'Users')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'CurrentUser')]
        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'Users')]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/users',

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $UserId,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Users')]
        [ValidateNotNullOrEmpty()]
        [string] $Sort,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'CurrentUser')]
        [switch] $CurrentUser,

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

    if( -not [string]::IsNullOrWhiteSpace($UserId) ) {
        $URISuffix += "/$UserId"
    }
    if ($CurrentUser) {$URISuffix = 'api/v1.0/system/currentUser'}

    [hashtable]$Params = @{
        URISuffix     = $URISuffix
        VSAConnection = $VSAConnection
        Filter        = $Filter
        Sort          = $Sort
    }

    foreach ( $key in @($Params.Keys)  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
    return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSAUser
