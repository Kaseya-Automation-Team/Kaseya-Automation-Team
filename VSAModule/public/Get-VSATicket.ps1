function Get-VSATicket
{
    <#
    .SYNOPSIS
       Returns Tickets from a VSA environment.
    .DESCRIPTION
       Retrieves tickets from a VSA environment.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection object.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER TicketID
        Specifies the TicketId to return. All Tickets are returned if no TicketId is specified.
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
       Get-VSATicket
    .EXAMPLE
       Get-VSATicket -TicketId '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection.
    .OUTPUTS
       Array of objects that represent ticket data.
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

        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'All')]
        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/tickets',

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string] $TicketId,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
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

    if( -not [string]::IsNullOrEmpty($TicketId)) {
        $URISuffix = "{0}/{1}" -f $URISuffix, $TicketId
    }

    [hashtable]$Params = @{
        URISuffix = $URISuffix
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    #region messages to verbose and debug streams
    "Get-VSATicket: $($Params | Out-String)" | Write-Debug

    "Get-VSATicket: $($Params | Out-String)" | Write-Verbose

    #endregion messages to verbose and debug streams

    # No -TicketId  -> GET /automation/tickets returns the TicketSummary list (5 fields) in one call.
    # With -TicketId -> GET /automation/tickets/{id} returns the full Ticket (17 fields).
    # Previously the no-id path fanned out one GET per ticket (N+1) to full-expand every row; that is
    # removed (F-9/D-1). Callers who need full detail pass the summary's TicketId back to
    # Get-VSATicket -TicketId (the list has no bulk-detail endpoint on the API).
    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
    return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSATicket
