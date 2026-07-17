function Invoke-VSARequestWithRenewal {
    <#
    .SYNOPSIS
        Sends one request via Get-RequestData, recovering ONCE from an invalidated session (F-77).
    .DESCRIPTION
        A VSA session can be invalidated server-side long before its client-tracked expiration:
        SaaS instances cut sessions short (the reason the paging loop renews proactively every
        MaxRecordsPerSession records), and Close-VSAUserSession logs the current session out
        outright. Update-VSAConnection only compares the CLIENT-tracked SessionExpiration against
        the clock, so it cannot see a server-side invalidation -- every subsequent call then fails
        with HTTP 401 until the operator manually reconnects, even though the module holds the PAT
        and could re-authenticate itself. Found live: after Close-VSAUserSession, a connection whose
        SessionExpiration lay two days in the future returned 401 forever.

        This wrapper closes that gap on the sequential path, mirroring the parallel pump's existing
        semantics (one forced renewal per 401, then redispatch): on a typed 401 it renews the token
        once with the stored PAT and retries the request once. A second 401 (a genuinely revoked or
        wrong PAT) surfaces as the typed error. A 401 is safe to retry for ANY method, including
        writes: unlike a connection reset, the server explicitly refused the request without
        processing it.

        The AuthString refresh mutates the passed-in hashtable by design: hashtables are reference
        types, so the caller's subsequent requests (e.g. the remaining pages of a paged read)
        continue with the fresh token as well.
    .PARAMETER WebRequestParams
        The splat hashtable for Get-RequestData (Uri/Method/AuthString/...). AuthString is updated
        in place on renewal.
    .PARAMETER VSAConnection
        The explicit connection to renew, or $null to renew the persistent connection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $WebRequestParams,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [VSAConnection] $VSAConnection = $null
    )

    try {
        return Get-RequestData @WebRequestParams
    } catch {
        $ex = $_.Exception
        if (-not ($ex -is [VSAApiException] -and 401 -eq $ex.StatusCode)) { throw }

        Write-Verbose "Invoke-VSARequestWithRenewal: HTTP 401 with an unexpired client-side session; the server invalidated the session early. Renewing the token once and retrying."
        if ($null -eq $VSAConnection) {
            Update-VSAConnection -Force
            $WebRequestParams.AuthString = "Bearer $( Get-VSAPersistentToken )"
        } else {
            Update-VSAConnection -VSAConnection $VSAConnection -Force
            $WebRequestParams.AuthString = "Bearer $($VSAConnection.Token)"
        }
        # One retry only: a second 401 is a real authentication problem and surfaces typed.
        return Get-RequestData @WebRequestParams
    }
}

function Invoke-VSARestMethod {
    <#
    .SYNOPSIS
       Invokes VSA REST API methods with automatic paging, token renewal and retry.
    .DESCRIPTION
       Executes VSA REST API methods and returns the response or success status.
       Pages through collections using $skip/$top, renews the session token behind the scenes,
       and retries transient HTTP errors (handled in Get-RequestData).

       The Filter value is passed through to the server unchanged except for URL-encoding; the
       caller is responsible for OData value escaping (see ConvertTo-ODataString).
    .PARAMETER VSAConnection
        Specifies the established VSAConnection. If omitted, the persistent connection is used.
    .PARAMETER URISuffix
        Specifies the URI suffix appended to the server base URI.
    .PARAMETER Method
        Specifies the REST API Method (default is "GET").
    .PARAMETER Body
        Specifies the request body for methods that require it.
    .PARAMETER ContentType
        Specifies the content type of the request (default is "application/json").
    .PARAMETER MaxRetries
        Maximum number of retry attempts for transient HTTP errors (429, 502, 503, 504).
    .PARAMETER ExtendedOutput
        Returns the full response envelope (with the merged Result) instead of just Result.
    .PARAMETER Filter
        Specifies an OData $filter expression. Passed through unchanged except URL-encoding.
    .PARAMETER RecordsPerPage
        Number of records requested per page via $top (1-100; the server caps at 100).
    .PARAMETER Skip
        Number of records to skip ($skip). Numeric string.
    .PARAMETER Sort
        Specifies $orderby. Allowed: letters, digits, spaces, commas, hyphens.
    .PARAMETER OutFile
        When set, the response body is downloaded to this path (passed to Get-RequestData).
    .INPUTS
       Accepts piped VSAConnection.
    .OUTPUTS
       Varies based on the method invoked.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowNull()]
        [VSAConnection] $VSAConnection = $null,

        [parameter(DontShow, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string] $Method = 'GET',

        [parameter(Mandatory = $false)]
        [ValidateNotNull()]
        # [string] for JSON request bodies, [byte[]] for raw/multipart bodies (e.g. file uploads).
        [object] $Body,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ContentType = "application/json",

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string] $Filter,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 100)]
        [int] $RecordsPerPage = 100,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string] $Skip,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string] $Sort,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int] $MaxRecordsPerSession = 25000,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0, 10)]
        [int] $MaxRetries = 3,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $OutFile,

        # Opt-in parallel paging. When set (and the collection is large enough), pages 2..N are fetched
        # concurrently through the coordinator pump (Invoke-VSAParallelRequest). Absent, behaviour is
        # byte-for-byte the historical sequential path.
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $Parallel,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 8,

        # Minimum TotalRecords before -Parallel actually engages. 0 = auto (two full throttle windows,
        # i.e. 2 * ThrottleLimit * RecordsPerPage) -- below that the sequential path is faster anyway.
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ParallelThreshold = 0
    )

    # Renew the session token BEFORE reading it, so a token that is about to expire is
    # refreshed and the request below uses the fresh token (F-13).
    $VSAServerURI = [string]::Empty
    [bool]$IgnoreCertificateErrors = $false

    if ( $null -eq $VSAConnection ) {
        Update-VSAConnection
        $VSAServerURI            = Get-VSAPersistentURI
        $UsersToken              = "Bearer $( Get-VSAPersistentToken )"
        $IgnoreCertificateErrors = Get-VSAPersistentIgnoreCertErrors
    } else {
        Update-VSAConnection -VSAConnection $VSAConnection
        $VSAServerURI            = $VSAConnection.URI
        $UsersToken              = "Bearer $($VSAConnection.Token)"
        $IgnoreCertificateErrors = $VSAConnection.IgnoreCertificateErrors
    }

    # Filter is passed through untouched (only URL-encoded when the query is built). OData
    # value escaping (doubling single quotes) is the caller's responsibility.

    # Validate Sort ($orderby): allow only letters, digits, spaces, commas, hyphens.
    if (-not [string]::IsNullOrEmpty($Sort)) {
        if ($Sort -notmatch '^[\w\s,\-]+$') {
            throw "Sort parameter contains invalid characters. Allowed: letters, digits, spaces, commas, hyphens. Received: '$Sort'."
        }
    }

    # Validate Skip (must be a non-negative integer).
    if (-not [string]::IsNullOrEmpty($Skip)) {
        if ($Skip -notmatch '^\d+$') {
            throw "Skip parameter validation failed. Received: '$Skip'. Expected a non-negative integer (e.g. '0', '100', '500')."
        }
    }

    $baseUri = New-Object System.Uri -ArgumentList $VSAServerURI
    [string]$URI = [System.Uri]::new($baseUri, $URISuffix) | Select-Object -ExpandProperty AbsoluteUri

    # The URISuffix may already carry its own query string (e.g. '?flag=', '?tenantId='). The OData
    # params below must then be joined with '&', not a second '?', which would build a malformed
    # double-'?' URL that the server rejects (F-22).
    $UriSeparator = if ($URI -match '\?') { '&' } else { '?' }

    [hashtable]$ApiSearchParams = @{}
    if (-not [string]::IsNullOrEmpty($Filter)) { $ApiSearchParams['$filter']  = $Filter }
    if (-not [string]::IsNullOrEmpty($Sort))   { $ApiSearchParams['$orderby'] = $Sort }
    if (-not [string]::IsNullOrEmpty($Skip))   { $ApiSearchParams['$skip']    = $Skip }
    # Always transmit the page size as $top (default 100, which is also the server ceiling).
    $ApiSearchParams['$top'] = $RecordsPerPage

    if ($ApiSearchParams.Count -eq 0) {
        $CombinedURI = $URI
    } else {
        $CombinedURI = '{0}{1}{2}' -f $URI, $UriSeparator, (ConvertTo-VSAQueryString -Parameters $ApiSearchParams)
    }

    [hashtable]$WebRequestParams = @{
        Uri                     = $CombinedURI
        Method                  = $Method
        AuthString              = $UsersToken
        IgnoreCertificateErrors = $IgnoreCertificateErrors
        MaxRetries              = $MaxRetries
    }

    if ($Body) {
        $WebRequestParams.Add('Body', $Body)
        $WebRequestParams.Add('ContentType', $ContentType)
    }
    if ($OutFile) {
        $WebRequestParams.Add('OutFile', $OutFile)
    }

    Write-Debug "$($MyInvocation.MyCommand)"
    Write-Debug "Invoke-VSARestMethod. Request details:"
    $WebRequestParams | ConvertTo-Json -Depth 3 | Out-String | Write-Debug

    Write-Verbose "Invoke-VSARestMethod. Calling Get-RequestData on URI: $($WebRequestParams.Uri)"

    try {
        $response = Invoke-VSARequestWithRenewal -WebRequestParams $WebRequestParams -VSAConnection $VSAConnection
    } catch {
        # Preserve the typed API error (StatusCode / ConnectionReset / Category) so callers can
        # branch programmatically -- e.g. distinguish 403 vs 404 vs a blocked/reset endpoint --
        # rather than flattening everything into an opaque string. The transport already recorded
        # Method + URI on the exception; the extra request context goes to the verbose stream.
        if ($_.Exception -is [VSAApiException]) {
            Write-Verbose ("Invoke-VSARestMethod failed. URISuffix: {0}; Filter: {1}; Sort: {2}; Skip: {3}; RecordsPerPage: {4}" -f `
                $URISuffix, $(if ($Filter) { $Filter } else { 'None' }), $(if ($Sort) { $Sort } else { 'None' }), $(if ($Skip) { $Skip } else { '0' }), $RecordsPerPage)
            throw $_
        }

        # Non-API failure (e.g. bad URI construction): keep the contextual string throw.
        $contextInfo = @(
            "Failed to retrieve data from VSA API"
            "URI Suffix: $URISuffix"
            "Filter: $(if ($Filter) { $Filter } else { 'None' })"
            "Sort: $(if ($Sort) { $Sort } else { 'None' })"
            "Skip: $(if ($Skip) { $Skip } else { '0' })"
            "Records Per Page: $RecordsPerPage"
            "Method: $Method"
            "Error: $($_.Exception.Message)"
        ) -join "`n"
        throw $contextInfo
    }

    Write-Debug "Invoke-VSARestMethod. Response:`n$($response | Out-String)"

    # A successful empty-body 2xx (HTTP 204 No Content from DELETE / some PUT) comes back as $null
    # -- there is no envelope to expand or page. Return nothing rather than trying to expand a
    # non-existent .Result property, which would throw on the success path (F-21).
    if ($null -eq $response) {
        return $null
    }

    # A raw (non-enveloped) payload -- e.g. Cloud Backup's flat { <agentId>: <status> } map -- carries
    # its data directly and has none of the standard envelope fields (Result/ResponseCode/Status).
    # There is no '.Result' to unwrap and nothing to page, so return it as-is (F-63). A status-only
    # envelope (has ResponseCode/Status but no Result) is NOT raw and still flows through below, where
    # its absent '.Result' correctly yields an empty result set (F-23).
    $isEnvelope = ($null -ne $response.PSObject.Properties['Result']) -or
                  ($null -ne $response.PSObject.Properties['ResponseCode']) -or
                  ($null -ne $response.PSObject.Properties['Status'])
    if (-not $isEnvelope) {
        return $response
    }

    # Use member access, not Select-Object -ExpandProperty: some write endpoints (e.g. the
    # 'ask before executing' settings PUT) return a status-only envelope with no 'Result' property,
    # and -ExpandProperty throws on a missing property. '.Result' yields $null there instead (F-23).
    [array]$result = $response.Result
    [bool]$paginated = $false

    if (-not [string]::IsNullOrEmpty("$($response.TotalRecords)")) {
        $paginated = $true
        [int]$TotalRecords = $response.TotalRecords

        Write-Verbose "Invoke-VSARestMethod. TotalRecords: $TotalRecords"

        $resultCollection = [System.Collections.ArrayList]@($result)

        # Decide sequential vs. parallel paging. -Parallel engages only past the auto/explicit
        # threshold (below it the extra-connection setup outweighs the win); the count is exact here
        # because page 1 already returned TotalRecords.
        [int]$autoThreshold = 2 * $ThrottleLimit * $RecordsPerPage
        [int]$effThreshold  = if ($ParallelThreshold -gt 0) { $ParallelThreshold } else { $autoThreshold }
        # There must also be a page 2 to fetch: page 1 is already in hand, so a collection that fits
        # in a single page has no remaining work to parallelise. Without this the pump would be handed
        # an empty request list and fail its own ValidateNotNullOrEmpty. The default auto-threshold
        # hides this (it is far above one page), but an explicit low -ParallelThreshold reaches it.
        [bool]$useParallel  = $Parallel.IsPresent -and ($TotalRecords -ge $effThreshold) -and ($TotalRecords -gt $RecordsPerPage)

        if ($useParallel) {
            Write-Verbose "Invoke-VSARestMethod. Parallel paging: $TotalRecords records, throttle $ThrottleLimit."

            # Build one work item per remaining page (page 1 / skip 0 already fetched above).
            $pageRequests = [System.Collections.Generic.List[hashtable]]::new()
            for ([int]$skipValue = $RecordsPerPage; $skipValue -lt $TotalRecords; $skipValue += $RecordsPerPage) {
                $pageParams = @{} + $ApiSearchParams
                $pageParams['$skip'] = $skipValue
                $pageUri = '{0}{1}{2}' -f $URI, $UriSeparator, (ConvertTo-VSAQueryString -Parameters $pageParams)
                $pageRequests.Add(@{ Id = $skipValue; Uri = $pageUri })
            }

            $pageResults = Invoke-VSAParallelRequest -Request $pageRequests.ToArray() -VSAConnection $VSAConnection `
                -ThrottleLimit $ThrottleLimit -TimeoutSec 100 -MaxRetries $MaxRetries -Activity "Fetching $URISuffix (parallel)"

            $failed = @($pageResults | Where-Object { $null -ne $_.Error })
            if ($failed.Count -gt 0) {
                # Surface the first typed failure but report the scope; hours of work are not discarded
                # silently -- the caller sees exactly how many pages failed.
                throw ($failed[0].Error)
            }

            # Merge pages in $skip order so the result set matches the sequential path exactly.
            foreach ($pr in ($pageResults | Sort-Object { [int]$_.Id })) {
                [array]$temp = $pr.Response.Result
                if ($temp.Count -gt 0) { $resultCollection.AddRange($temp) | Out-Null }
            }
        }
        else {
            # Workaround for SaaS session limitation: renew the token every $MaxRecordsPerSession.
            [int]$RenewTimes = 1
            [int]$RenewThreshold = $MaxRecordsPerSession

            # The first page (skip 0) is already fetched above; continue while more remain.
            [int]$skipValue = $RecordsPerPage
            while ($skipValue -lt $TotalRecords) {

                $ApiSearchParams['$skip'] = $skipValue
                $WebRequestParams.Uri = '{0}{1}{2}' -f $URI, $UriSeparator, (ConvertTo-VSAQueryString -Parameters $ApiSearchParams)

                if ($skipValue -ge $RenewThreshold) {
                    Write-Verbose "Fetching in progress... So far fetched $RenewThreshold records. Renewing session token."

                    if ($null -eq $VSAConnection) {
                        Update-VSAConnection -Force
                        $UsersToken = "Bearer $( Get-VSAPersistentToken )"
                    } else {
                        Update-VSAConnection -VSAConnection $VSAConnection -Force
                        $UsersToken = "Bearer $($VSAConnection.Token)"
                    }
                    $WebRequestParams.AuthString = $UsersToken
                    $RenewTimes += 1
                    $RenewThreshold = $MaxRecordsPerSession * $RenewTimes
                }

                [array]$temp = Invoke-VSARequestWithRenewal -WebRequestParams $WebRequestParams -VSAConnection $VSAConnection | Select-Object -ExpandProperty Result
                if ($temp.Count -gt 0) {
                    $resultCollection.AddRange($temp) | Out-Null
                }

                $skipValue += $RecordsPerPage
            }
        }
        $result = $resultCollection.ToArray()
    }

    Write-Debug "Invoke-VSARestMethod. Result`n $($result | Out-String)"

    if ($ExtendedOutput) {
        if ($paginated) {
            # Return the envelope but with the fully-merged Result (F-57).
            $merged = $response.PSObject.Copy()
            $merged.Result = $result
            return $merged
        }
        return $response
    }

    return $result
}
