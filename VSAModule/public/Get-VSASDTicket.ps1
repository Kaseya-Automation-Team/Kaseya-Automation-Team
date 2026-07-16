function Get-VSASDTicket {
    <#
    .Synopsis
       Returns an array of tickets or specified service desk or details on specified ticket.
    .DESCRIPTION
       Returns an array of tickets or specified service desk or details on specified ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER ServiceDeskId
        Specifies id of the service desk whose tickets are returned. Supply exactly one of
        -ServiceDeskId or -ServiceDeskTicketId.
    .PARAMETER ServiceDeskTicketId
        Specifies id of a single ticket to return. Supply exactly one of -ServiceDeskId or
        -ServiceDeskTicketId.
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
       Get-VSASDTicket -ServiceDeskId 123456
    .EXAMPLE
       Get-VSASDTicket -VSAConnection $connection -ServiceDeskId 123456
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Array of items that represent service desk tickets or ticket details
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [Alias('ID')]
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) { throw "ServiceDeskId cannot be empty." }
            if ($_ -notmatch "^\d+$") { throw "ServiceDeskId must be a numeric string." }
            return $true
        })]
        [string] $ServiceDeskId,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) { throw "ServiceDeskTicketId cannot be empty." }
            if ($_ -notmatch "^\d+$") { throw "ServiceDeskTicketId must be a numeric string." }
            return $true
        })]
        [string] $ServiceDeskTicketId,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false)]
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

    # Ensure exactly one of ServiceDeskId or ServiceDeskTicketId is provided. The API exposes no
    # "all tickets" collection (a bare api/v1.0/automation/servicedesktickets returns HTTP 403), so
    # this restriction mirrors the API rather than being a module limitation; the message says so,
    # and names the cmdlet that lists the desk ids, because "provide an id" is not actionable if you
    # do not know where ids come from.
    if ([string]::IsNullOrWhiteSpace($ServiceDeskId) -eq [string]::IsNullOrWhiteSpace($ServiceDeskTicketId)) {
        throw @'
Get-VSASDTicket: supply exactly one of -ServiceDeskId or -ServiceDeskTicketId.
  -ServiceDeskId <id>        every ticket on that service desk (supports -Parallel)
  -ServiceDeskTicketId <id>  a single ticket
The VSA API has no "all tickets" endpoint: tickets are addressable only per service desk.
List the desks and their ids with:  Get-VSASD
Then, for example:                  Get-VSASD | ForEach-Object { Get-VSASDTicket -ServiceDeskId $_.ServiceDeskId -Parallel }
'@
    }

    # Set URI based on input
    $URISuffix = if ($ServiceDeskTicketId) {
        "api/v1.0/automation/servicedesktickets/$ServiceDeskTicketId"
    } else {
        "api/v1.0/automation/servicedesks/$ServiceDeskId/tickets"
    }

    # Build parameters
    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Sort          = $Sort
    }

    # Remove empty keys
    foreach ($key in @($Params.Keys)) {
        if (-not $Params[$key]) { $Params.Remove($key) }
    }

    # Sanitize inputs to prevent injection
    foreach ($key in @('Filter', 'Sort')) {
        if ($Params[$key]) {
            $Params[$key] = $Params[$key] -replace '[<>;]', ''
        }
    }

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
    Invoke-VSARestMethod @Params
    }
}

Export-ModuleMember -Function Get-VSASDTicket
