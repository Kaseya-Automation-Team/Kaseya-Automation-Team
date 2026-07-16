function Get-VSAAgent
{
    <#
    .SYNOPSIS
        Retrieves all VSA agents or a specified one.
    .DESCRIPTION
        This script returns all VSA agents or a specific agent if an agent ID is supplied.
        It supports both persistent and non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSA connection.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies the ID of the agent machine.
    .PARAMETER Filter
        Specifies the REST API filter.
    .PARAMETER Sort
        Specifies the REST API sorting.
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
        Get-VSAAgent
        Retrieves all VSA agents.
    .EXAMPLE
        Get-VSAAgent -AgentId 3423232424
        Retrieves the VSA agent with the specified ID.
    .EXAMPLE
        Get-VSAAgent -VSAConnection $connection
        Retrieves VSA agents using the specified non-persistent VSA connection.
    .INPUTS
        Accepts a piped non-persistent VSAConnection.
    .OUTPUTS
        Returns an array of custom objects representing the existing VSA agents or a specific agent.
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/agents',

        [Alias('ID')]
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
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

    if( -not [string]::IsNullOrWhiteSpace( $AgentId) ) {
        $URISuffix = "$URISuffix/$AgentId"
    }

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
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

Export-ModuleMember -Function Get-VSAAgent
