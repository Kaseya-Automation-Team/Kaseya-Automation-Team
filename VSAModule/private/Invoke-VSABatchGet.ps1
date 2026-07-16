function Invoke-VSABatchGet {
    <#
    .SYNOPSIS
        Fetches a by-Id endpoint for MANY ids concurrently (the N+1 fan-out), fully paged per id.
    .DESCRIPTION
        Powers the opt-in parallel path of Get-VSAItemById when several ids are supplied -- e.g.
        fetching notes for tens of thousands of service-desk tickets, the workload that otherwise runs
        for dozens of hours because the API exposes notes only per-ticket. It builds one request per id,
        runs them through the coordinator pump (Invoke-VSAParallelRequest), then issues a single
        follow-up round for the few ids whose result exceeds one page (>100 records). Results are
        returned as one flat, id-ordered array, matching what looping the single-id path would produce.
    .PARAMETER URISuffixTemplate
        The by-Id endpoint template containing '{0}' where the id goes.
    .PARAMETER Id
        The ids to fetch (each substituted into the template).
    .PARAMETER VSAConnection
        The established VSAConnection (server + token source). If omitted, the persistent connection.
    .PARAMETER ThrottleLimit
        Maximum concurrent requests. Default 8.
    .PARAMETER Filter
        Optional OData $filter applied to every request.
    .PARAMETER Sort
        Optional $orderby applied to every request.
    .PARAMETER RecordsPerPage
        Page size ($top); the server caps at 100.
    .OUTPUTS
        The concatenated result records across all ids (id order preserved).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $URISuffixTemplate,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]] $Id,
        [Parameter(Mandatory = $false)][AllowNull()][VSAConnection] $VSAConnection = $null,
        [Parameter(Mandatory = $false)][ValidateRange(1, 64)][int] $ThrottleLimit = 8,
        [Parameter(Mandatory = $false)][string] $Filter,
        [Parameter(Mandatory = $false)][string] $Sort,
        [Parameter(Mandatory = $false)][ValidateRange(1, 100)][int] $RecordsPerPage = 100
    )

    $serverUri = if ($null -ne $VSAConnection) { $VSAConnection.URI } else { Get-VSAPersistentURI }
    $baseUri   = New-Object System.Uri -ArgumentList $serverUri

    # Build an absolute request URI for a given id + skip, reusing the shared query-string builder.
    $buildUri = {
        param([string]$theId, [int]$skip)
        $suffix = $URISuffixTemplate -f $theId
        $uri    = [System.Uri]::new($baseUri, $suffix) | Select-Object -ExpandProperty AbsoluteUri
        $sep    = if ($uri -match '\?') { '&' } else { '?' }
        [hashtable]$qs = @{ '$top' = $RecordsPerPage; '$skip' = $skip }
        if (-not [string]::IsNullOrEmpty($Filter)) { $qs['$filter'] = $Filter }
        if (-not [string]::IsNullOrEmpty($Sort))   { $qs['$orderby'] = $Sort }
        '{0}{1}{2}' -f $uri, $sep, (ConvertTo-VSAQueryString -Parameters $qs)
    }

    # --- Round 1: first page of every id ---
    $round1 = foreach ($one in $Id) { @{ Id = $one; Uri = (& $buildUri $one 0) } }
    $r1 = Invoke-VSAParallelRequest -Request @($round1) -VSAConnection $VSAConnection `
        -ThrottleLimit $ThrottleLimit -Activity "Fetching $($Id.Count) items (parallel)"

    $byId    = [ordered]@{}                      # id -> ArrayList of records (page 1 first)
    $followUp = [System.Collections.Generic.List[hashtable]]::new()
    $errors  = [System.Collections.Generic.List[object]]::new()
    foreach ($one in $Id) { $byId[[string]$one] = [System.Collections.ArrayList]::new() }

    foreach ($res in $r1) {
        if ($null -ne $res.Error) { $errors.Add($res.Error); continue }
        $env = $res.Response
        [array]$recs = if ($null -ne $env) { $env.Result } else { @() }
        if ($recs.Count -gt 0) { [void]$byId[[string]$res.Id].AddRange($recs) }
        # Queue remaining pages for the (rare) id whose collection exceeds one page.
        if ($null -ne $env -and -not [string]::IsNullOrEmpty("$($env.TotalRecords)")) {
            [int]$tot = $env.TotalRecords
            for ([int]$skip = $RecordsPerPage; $skip -lt $tot; $skip += $RecordsPerPage) {
                $followUp.Add(@{ Id = ('{0}|{1}' -f $res.Id, $skip); Uri = (& $buildUri ([string]$res.Id) $skip) })
            }
        }
    }

    # --- Round 2: the follow-up pages, if any ---
    if ($followUp.Count -gt 0) {
        $r2 = Invoke-VSAParallelRequest -Request $followUp.ToArray() -VSAConnection $VSAConnection `
            -ThrottleLimit $ThrottleLimit -Activity "Fetching follow-up pages (parallel)"
        foreach ($res in $r2) {
            if ($null -ne $res.Error) { $errors.Add($res.Error); continue }
            $idPart = ([string]$res.Id).Split('|')[0]
            [array]$recs = if ($null -ne $res.Response) { $res.Response.Result } else { @() }
            if ($recs.Count -gt 0) { [void]$byId[$idPart].AddRange($recs) }
        }
    }

    if ($errors.Count -gt 0) {
        Write-Warning "Invoke-VSABatchGet: $($errors.Count) of $($Id.Count) requests failed; surfacing the first."
        throw ($errors[0])
    }

    # Flatten in the caller's id order.
    $out = [System.Collections.ArrayList]::new()
    foreach ($one in $Id) {
        $recs = $byId[[string]$one]
        if ($recs.Count -gt 0) { [void]$out.AddRange($recs) }
    }
    return $out.ToArray()
}
