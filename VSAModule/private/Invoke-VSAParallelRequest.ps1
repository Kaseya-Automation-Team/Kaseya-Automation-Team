function Invoke-VSAParallelRequest {
    <#
    .SYNOPSIS
        Fetches many independent GET requests concurrently via a single-threaded coordinator pump.
    .DESCRIPTION
        The performance engine behind the module's opt-in -Parallel reads. It runs a sliding window of
        up to -ThrottleLimit in-flight .NET HttpClient requests, and a single PowerShell coordinator
        thread that dispatches new work as each request completes (Task.WaitAny), so throughput stays
        near the throttle width without the convoy effect of fixed waves.

        WHY A SINGLE-THREADED PUMP (the token story): the session token is read and stamped onto each
        request AT DISPATCH TIME, on the coordinator thread. Because only the coordinator ever
        dispatches, the "renew if near expiry" check is single-flight BY CONSTRUCTION -- no lock, no
        race. In-flight requests keep the token they were stamped with; renewal happens with a safety
        margin (Update-VSAConnection renews ~1 min before expiry), so a token that is still valid keeps
        working while the next dispatch already carries the fresh one. The worker Tasks are pure HTTP:
        they never touch the token, the counters, or any shared state, and JSON is deserialized back on
        the coordinator thread -- keeping the workers free of PowerShell/runspace affinity.

        Transient failures (HTTP 429/502/503/504) are retried with capped exponential backoff by
        re-queueing the work item; a 429 also shrinks the active window adaptively (halve, then recover
        on a success streak) so the module behaves as a well-mannered SaaS tenant. Items that still fail
        after -MaxRetries are returned with their error rather than aborting the whole batch.

        Edition strategy mirrors the transport (F-27): on PowerShell 7 the HttpClientHandler carries a
        per-handler certificate-bypass validator; on Windows PowerShell 5.1 the process-wide cert policy
        is used and the .NET Framework default 2-connections-per-host cap is raised to the window width
        (without which a wide window quietly serialises behind 2 TCP connections).
    .PARAMETER Request
        An array of work items, each a hashtable with:
          Id  - a caller tag used to correlate/sort results (e.g. the $skip value or a ticket id)
          Uri - the absolute request URI to GET
    .PARAMETER VSAConnection
        The established VSAConnection (token source). If omitted, the persistent connection is used.
    .PARAMETER ThrottleLimit
        Maximum concurrent in-flight requests (the initial window width). Default 8.
    .PARAMETER TimeoutSec
        Per-request timeout in seconds. Default 100.
    .PARAMETER MaxRetries
        Maximum retry attempts per work item for transient failures. Default 3.
    .PARAMETER Activity
        Write-Progress activity label.
    .OUTPUTS
        One PSCustomObject per work item: Id, Response (the deserialized envelope, or $null), Error
        (a VSAApiException/Exception, or $null). Order is not guaranteed; sort by Id.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable[]] $Request,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [VSAConnection] $VSAConnection = $null,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 8,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3600)]
        [int] $TimeoutSec = 100,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int] $MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [string] $Activity = 'Fetching (parallel)',

        # The decode function for each page body, forwarded from the read engine so the parallel path
        # decodes exactly as the sequential path does (JSON by default, ScExport XML for Get-VSAAPList).
        # Without this the pump hard-coded the JSON decoder, so a -Parallel XML read would fail per page.
        [Parameter(Mandatory = $false)]
        [ValidateSet('ConvertFrom-VSAResponseBody', 'ConvertFrom-VSAScExportResponse')]
        [string] $Decoder = 'ConvertFrom-VSAResponseBody'
    )

    [bool]$ignoreCert = if ($null -ne $VSAConnection) { $VSAConnection.IgnoreCertificateErrors } else { Get-VSAPersistentIgnoreCertErrors }
    [bool]$isCore     = [bool]$script:VSASupportsSkipCertCheck   # $true on PS7/Core, $false on 5.1 (F-27 detection)

    # The shared HttpClient (F-67): the same instance and certificate strategy the sequential path
    # uses. It is cached module-wide and MUST NOT be disposed here. On 5.1 the bypass is a
    # process-wide policy that has to be installed around the sends rather than on the handler, so
    # push it for the lifetime of the pump; on Core the handler already carries the validator.
    $client = Get-VSAHttpClient -IgnoreCertificateErrors $ignoreCert
    $certPushed = $false
    if ($ignoreCert -and -not $isCore) {
        & $script:VSAPushCertBypass
        $certPushed = $true
    }

    # Renew-if-near-expiry (single-flight, coordinator thread) and return the current bearer string.
    $getToken = {
        if ($null -eq $VSAConnection) {
            Update-VSAConnection
            return "Bearer $(Get-VSAPersistentToken)"
        } else {
            Update-VSAConnection -VSAConnection $VSAConnection
            return "Bearer $($VSAConnection.Token)"
        }
    }
    # Force a renewal now (used when the SaaS invalidates a session before its stated expiry -> 401).
    $forceRenew = {
        if ($null -eq $VSAConnection) { Update-VSAConnection -Force } else { Update-VSAConnection -VSAConnection $VSAConnection -Force }
    }
    [int]$tokenGen = 0   # bumped on each forced renewal; de-dupes the 401 stampede across in-flight items
    # A 401 renewal is an auth refresh, NOT a transient failure, so it must not consume the
    # transient-retry budget (Attempt/MaxRetries) that 429/502/503/504 draw on -- otherwise a long
    # fan-out that hits both throttling and a token expiry would fail streams that only needed a
    # fresh token. Auth renewals get their own small, separate budget per work item (F-78); it also
    # bounds the pathological case of a genuinely revoked PAT that 401s no matter how often renewed.
    [int]$MaxAuthRenewals = 3

    # Pending work queue (each item: Id, Uri, Attempt=transient retries, AuthAttempt=401 renewals,
    # ReadyAt gates backoff).
    $pending = [System.Collections.Generic.Queue[object]]::new()
    foreach ($r in $Request) {
        $pending.Enqueue([pscustomobject]@{ Id = $r.Id; Uri = $r.Uri; Attempt = 0; AuthAttempt = 0; ReadyAt = [datetime]::MinValue })
    }

    $results   = [System.Collections.Generic.List[object]]::new()
    $inflightTasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
    $inflightMeta  = [System.Collections.Generic.List[object]]::new()

    [int]$total     = $Request.Count
    [int]$done      = 0
    [int]$window    = $ThrottleLimit          # adaptive current window
    [int]$successStreak = 0
    [int]$progressId = New-VSAProgressId       # own bar, isolated from a caller's progress id 0

    try {
        while ($pending.Count -gt 0 -or $inflightTasks.Count -gt 0) {

            # Dispatch up to the current window, honouring per-item backoff ReadyAt.
            while ($inflightTasks.Count -lt $window -and $pending.Count -gt 0) {
                # Peek: if the head isn't ready yet, stop filling (queue is roughly FIFO by readiness).
                $next = $pending.Peek()
                if ($next.ReadyAt -gt [datetime]::Now) { break }
                [void]$pending.Dequeue()

                $req = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $next.Uri)
                $req.Headers.TryAddWithoutValidation('Authorization', (& $getToken)) | Out-Null
                # The shared client's own Timeout is infinite (it cannot vary per call), so each
                # request carries its own cancellation deadline.
                $cts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSec))
                $task = $client.SendAsync($req, $cts.Token)
                $inflightTasks.Add($task)
                $inflightMeta.Add([pscustomobject]@{ Work = $next; Request = $req; Cts = $cts; Gen = $tokenGen })
            }

            if ($inflightTasks.Count -eq 0) {
                # Nothing in flight but pending items are backing off; wait out the shortest ReadyAt.
                $soonest = ($pending | Measure-Object -Property ReadyAt -Minimum).Minimum
                $sleepMs = [Math]::Max(50, [Math]::Min(2000, [int]([Math]::Ceiling(($soonest - [datetime]::Now).TotalMilliseconds))))
                Start-Sleep -Milliseconds $sleepMs
                continue
            }

            # Wait for any in-flight request to finish (short timeout keeps Ctrl+C responsive).
            [int]$idx = [System.Threading.Tasks.Task]::WaitAny($inflightTasks.ToArray(), 500)
            if ($idx -lt 0) { continue }

            $task = $inflightTasks[$idx]
            $meta = $inflightMeta[$idx]
            $inflightTasks.RemoveAt($idx)
            $inflightMeta.RemoveAt($idx)
            $work = $meta.Work

            [int]$status = 0
            $body = $null
            $faulted = $null
            $retryAfter = $null
            try {
                $resp = $task.GetAwaiter().GetResult()
                $status = [int]$resp.StatusCode
                # Read the server's own back-off hint before disposing the response.
                $retryAfter = Get-VSARetryAfterSeconds -Response $resp
                $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                $resp.Dispose()
            } catch {
                $faulted = $_.Exception
            } finally {
                $meta.Request.Dispose()
                $meta.Cts.Dispose()
            }

            # A 401 mid-batch means the session was invalidated before its stated expiry (SaaS early
            # cut-off, or a Close-VSAUserSession elsewhere). Force ONE renewal per token generation
            # (the first 401 bumps the generation; later 401s still carrying the old generation just
            # re-dispatch with the fresh token, avoiding a stampede of simultaneous renewals from
            # every in-flight request), then RESTART the failed stream with the fresh token.
            # Uses its own AuthAttempt budget, NOT the transient-retry Attempt/MaxRetries (F-78): a
            # token refresh must not eat the retries reserved for 429/503, and its own cap bounds a
            # genuinely revoked PAT (a renewed token that still 401s) rather than looping forever.
            if ($status -eq 401 -and $work.AuthAttempt -lt $MaxAuthRenewals) {
                if ($meta.Gen -eq $tokenGen) { & $forceRenew; $tokenGen++ }
                $work.AuthAttempt++
                $work.ReadyAt = [datetime]::Now
                $pending.Enqueue($work)
                continue
            }

            # Retry transient failures using the module's shared retry policy (F-67): the same status
            # set and the same back-off rule the sequential path uses, including honouring a server
            # Retry-After -- which this path previously ignored, exactly where it matters most (a
            # throttling SaaS answers a wide window with 429s). The adaptive window below is the one
            # behaviour genuinely unique to the parallel pump, since only it has a window to shrink.
            # The pump only ever issues GET, so Test-VSARetryable permits a reset retry here (an
            # idempotent read is safe to repeat) while the same shared rule denies it to writes.
            $isTransient = Test-VSARetryable -StatusCode $status -Method 'GET' -NoResponse ($null -ne $faulted)
            if ($isTransient -and $work.Attempt -lt $MaxRetries) {
                if ($status -eq 429) {
                    $window = [Math]::Max(1, [int][Math]::Floor($window / 2))
                    $successStreak = 0
                }
                $work.Attempt++
                $backoffSeconds = Get-VSABackoffSeconds -Attempt $work.Attempt -RetryAfterSeconds $retryAfter
                $work.ReadyAt = [datetime]::Now.AddSeconds($backoffSeconds)
                $pending.Enqueue($work)
                continue
            }

            # Terminal outcome for this item. Both the error shape and the envelope rules come from
            # the shared stack (F-67), so a -Parallel caller receives exactly the errors and payloads
            # a sequential caller would. Previously this path re-threw the raw transport exception,
            # which silently defeated the typed-error contract (.StatusCode / .ConnectionReset) under
            # -Parallel, and it lacked the raw non-enveloped payload rule (F-63) entirely.
            if ($null -ne $faulted -or $status -ge 400) {
                $err = New-VSATransportError -StatusCode $status -Method 'GET' -Uri $work.Uri -Body $body -InnerException $faulted
                $results.Add([pscustomobject]@{ Id = $work.Id; Response = $null; Error = $err })
            } else {
                try {
                    # Decode through the module's single decode layer, exactly as the sequential path
                    # does (F-67): empty-body -> $null (F-21), the F-72 non-JSON typed error, and the
                    # envelope rules via Resolve-VSAResponse. The decoder is forwarded from the engine,
                    # so a -Parallel XML read (Get-VSAAPList) decodes ScExport here just as it would
                    # sequentially -- previously this was hard-coded to JSON.
                    $resolved = & $Decoder -Body $body -StatusCode $status -Method 'GET' -Uri $work.Uri
                    $results.Add([pscustomobject]@{ Id = $work.Id; Response = $resolved; Error = $null })
                    # Recover the window on a sustained success streak (up to the requested throttle).
                    $successStreak++
                    if ($successStreak -ge $window -and $window -lt $ThrottleLimit) { $window++; $successStreak = 0 }
                } catch {
                    # A typed application-level error (from Resolve-VSAResponse) or a non-JSON body
                    # (F-72), both already VSAApiException; surface it for this item.
                    $results.Add([pscustomobject]@{ Id = $work.Id; Response = $null; Error = $_ })
                }
            }

            $done++
            Write-VSAProgress -Id $progressId -Activity $Activity -Current $done -Total $total -Status "$done / $total (window $window)"
        }
    }
    finally {
        Write-VSAProgress -Id $progressId -Activity $Activity -Completed
        # $client is the shared, cached instance -- deliberately NOT disposed here.
        if ($certPushed) { & $script:VSAPopCertBypass }
    }

    return $results.ToArray()
}
