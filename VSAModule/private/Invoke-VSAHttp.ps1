# The module's single HTTP stack (F-67).
#
# Every request the module makes -- sequential or parallel -- is issued by System.Net.Http.HttpClient
# and governed by the policy defined in this file. Before v1.5.1 there were two stacks: the
# sequential path used Invoke-RestMethod while the parallel engine used HttpClient, each with its own
# copy of the retry rules, envelope handling and error typing. Those copies had already drifted (the
# parallel path ignored Retry-After, and surfaced raw exceptions instead of a typed VSAApiException),
# so the duplication was not merely untidy -- it was a source of live defects.
#
# Layering:
#   Get-VSAHttpClient   - the shared, cached HttpClient (edition-specific certificate strategy)
#   New-VSAHttpContent  - request body -> HttpContent
#   Get-VSARetryAfterSeconds / Get-VSABackoffSeconds / $script:VSARetryStatuses - the retry policy
#   Invoke-VSAHttp      - blocking send + retry (used by Get-RequestData)
# The API envelope rules are NOT here: they are decode policy, not byte handling, and live one layer
# up in the decode module (Resolve-VSAResponse in private/ConvertFrom-VSAResponseBody.ps1). This file
# stays pure transport. Invoke-VSAParallelRequest reuses every piece above except Invoke-VSAHttp
# itself, substituting its own asynchronous pump for the blocking send -- the only intentional
# difference between the two paths.

# ONE definition of the transient-retry status set, shared by both dispatch modes.
$script:VSARetryStatuses = @(429, 502, 503, 504)

# HttpClient is designed to be long-lived and shared; constructing one per request exhausts sockets
# (each disposed client leaves a connection in TIME_WAIT). Cache one per certificate strategy.
$script:VSAHttpClients = @{}

function Get-VSAHttpClient {
    <#
    .SYNOPSIS
        Returns the shared HttpClient for the requested certificate strategy, creating it on first use.
    .DESCRIPTION
        Certificate bypass is edition-specific, mirroring the strategy feature-detected once at import
        (F-27):
          - PowerShell 7 / .NET Core: a per-handler validation callback. ServicePointManager is
            ignored on Core, so the bypass must live on the handler and is scoped to this client.
          - Windows PowerShell 5.1 / .NET Framework: HttpClient is built on HttpWebRequest and so
            honours the process-wide ICertificatePolicy that VSAPushCertBypass installs. The handler
            callback is deliberately NOT used there: it is unavailable on older Framework versions,
            and the process-wide policy is the path the module already proves out on 5.1.
        The returned client MUST NOT be disposed by callers -- it is shared and cached.
    .PARAMETER IgnoreCertificateErrors
        Selects the certificate-bypassing client rather than the strict one.
    .OUTPUTS
        System.Net.Http.HttpClient
    #>
    [CmdletBinding()]
    [OutputType([System.Net.Http.HttpClient])]
    param(
        [Parameter(Mandatory = $false)]
        [bool] $IgnoreCertificateErrors = $false
    )

    $key = if ($IgnoreCertificateErrors) { 'bypass' } else { 'strict' }
    if ($script:VSAHttpClients.ContainsKey($key)) { return $script:VSAHttpClients[$key] }

    # System.Net.Http is loaded at module import (VSAModule.psm1), NOT here. On .NET Framework it is
    # a separate assembly, and PowerShell resolves this function's type literals when it compiles the
    # body on first invocation -- an Add-Type at this point would already be too late to satisfy them.
    $handler = [System.Net.Http.HttpClientHandler]::new()

    if ($IgnoreCertificateErrors -and $script:VSASupportsSkipCertCheck) {
        $handler.ServerCertificateCustomValidationCallback = [System.Net.Http.HttpClientHandler]::DangerousAcceptAnyServerCertificateValidator
    }

    # Concurrency is governed by the parallel pump's own in-flight window; these caps only need to be
    # wide enough not to throttle it behind the platform default (2 per host on .NET Framework).
    try { $handler.MaxConnectionsPerServer = 64 } catch { Write-Debug "MaxConnectionsPerServer unavailable on this runtime: $($_.Exception.Message)" }
    if (-not $script:VSASupportsSkipCertCheck) {
        try { [System.Net.ServicePointManager]::DefaultConnectionLimit = [Math]::Max([System.Net.ServicePointManager]::DefaultConnectionLimit, 64) } catch { Write-Debug "Could not raise DefaultConnectionLimit: $($_.Exception.Message)" }
    }

    $client = [System.Net.Http.HttpClient]::new($handler)
    # Timeouts are enforced per request via a CancellationToken, because this client is shared and
    # HttpClient.Timeout is a client-wide property that cannot vary per call.
    $client.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan

    $script:VSAHttpClients[$key] = $client
    return $client
}

function New-VSAHttpContent {
    <#
    .SYNOPSIS
        Converts a request body ([string] JSON or [byte[]] raw/multipart) into an HttpContent.
    .DESCRIPTION
        Always uses ByteArrayContent and sets Content-Type verbatim via TryAddWithoutValidation.
        StringContent is deliberately avoided: it appends its own charset parameter, which would
        corrupt a multipart Content-Type whose boundary= parameter must survive byte-for-byte (F-37).
    .PARAMETER Body
        [string] for JSON bodies, [byte[]] for raw/multipart bodies.
    .PARAMETER ContentType
        The Content-Type header to send verbatim.
    .OUTPUTS
        System.Net.Http.HttpContent, or $null when there is no body.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Body,

        [Parameter(Mandatory = $false)]
        [string] $ContentType = 'application/json'
    )
    if ($null -eq $Body) { return $null }

    [byte[]] $bytes = if ($Body -is [byte[]]) { $Body } else { [System.Text.Encoding]::UTF8.GetBytes([string]$Body) }

    $content = [System.Net.Http.ByteArrayContent]::new($bytes)
    $content.Headers.Remove('Content-Type') | Out-Null
    $content.Headers.TryAddWithoutValidation('Content-Type', $ContentType) | Out-Null
    return $content
}

function Get-VSARetryAfterSeconds {
    <#
    .SYNOPSIS
        Returns the Retry-After delay in seconds from an HttpResponseMessage, or $null if absent.
    .DESCRIPTION
        Handles both header forms: delta-seconds (Retry-After: 120) and an HTTP-date. A server that
        states its own back-off is always more accurate than client-side exponential guessing, so this
        value takes precedence in Get-VSABackoffSeconds.
    .PARAMETER Response
        The System.Net.Http.HttpResponseMessage to inspect.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Response
    )
    if ($null -eq $Response) { return $null }
    try {
        $ra = $Response.Headers.RetryAfter
        if ($null -eq $ra) { return $null }
        if ($null -ne $ra.Delta) { return [int][Math]::Ceiling($ra.Delta.TotalSeconds) }
        if ($null -ne $ra.Date) {
            $secs = [int][Math]::Ceiling(($ra.Date.UtcDateTime - [datetime]::UtcNow).TotalSeconds)
            if ($secs -gt 0) { return $secs }
        }
    } catch { Write-Debug "Retry-After parse skipped: $($_.Exception.Message)" }
    return $null
}

function Test-VSARetryable {
    <#
    .SYNOPSIS
        The single decision of "should this failed attempt be retried?", shared by both dispatch modes.
    .DESCRIPTION
        Two distinct cases, and the difference between them matters for correctness:

        1. **A transient HTTP status (429/502/503/504).** The server answered and told us it did not
           process the request, so retrying is safe for ANY method.
        2. **No HTTP response at all** (socket reset / timeout). Here we cannot know whether the
           server processed the request before the connection dropped, so retrying is only safe for
           an IDEMPOTENT method. Retrying a POST/PUT/DELETE could apply it twice. It is also the
           wrong call in practice: on hardened (post-2021) VSA builds a reset is precisely how a
           blocked write endpoint answers, so retrying merely spends the backoff before returning the
           same ConnectionReset.

        GET is the only method the module issues in bulk, so read fan-outs still survive a transient
        socket blip, while writes fail fast and exactly once.
    .PARAMETER StatusCode
        HTTP status, or 0 when no response arrived.
    .PARAMETER Method
        The HTTP method of the attempt.
    .PARAMETER NoResponse
        True when the attempt produced no HTTP response at all.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]  [int] $StatusCode,
        [Parameter(Mandatory = $false)] [string] $Method = 'GET',
        [Parameter(Mandatory = $false)] [bool] $NoResponse = $false
    )
    if ($StatusCode -in $script:VSARetryStatuses) { return $true }
    if ($NoResponse -and $Method -in @('GET', 'HEAD', 'OPTIONS')) { return $true }
    return $false
}

function Get-VSABackoffSeconds {
    <#
    .SYNOPSIS
        Returns how long to wait before retry attempt $Attempt, honouring a server Retry-After.
    .DESCRIPTION
        The single back-off rule for the whole module. A server-supplied Retry-After always wins;
        otherwise exponential (2^(Attempt-1)) capped at 30s.
    .PARAMETER Attempt
        The 1-based retry attempt about to be made.
    .PARAMETER RetryAfterSeconds
        The server's Retry-After value, if it supplied one.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [int] $Attempt,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $RetryAfterSeconds = $null
    )
    if ($null -ne $RetryAfterSeconds -and [int]$RetryAfterSeconds -gt 0) {
        return [Math]::Min(30, [int]$RetryAfterSeconds)
    }
    return [int][Math]::Min(30, [Math]::Pow(2, [Math]::Max(0, $Attempt - 1)))
}

function ConvertFrom-VSAErrorBody {
    <#
    .SYNOPSIS
        Extracts the VSA-specific "Error" field from a raw error-response body, or $null.
    .PARAMETER Body
        The raw response body text.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Body
    )
    if ([string]::IsNullOrWhiteSpace($Body)) { return $null }
    try {
        $parsed = $Body | ConvertFrom-Json -ErrorAction Stop
        if ($parsed.Error) { return [string]$parsed.Error }
    } catch { Write-Debug "Error body is not JSON: $($_.Exception.Message)" }
    return $null
}

function New-VSATransportError {
    <#
    .SYNOPSIS
        Builds the typed error for a terminal HTTP failure, shared by both dispatch modes.
    .DESCRIPTION
        Centralises the two terminal shapes so the parallel path can no longer surface a raw
        exception where the sequential path surfaces a typed VSAApiException:
          - StatusCode 0 (no HTTP response): the socket was reset or the endpoint is unreachable.
            On hardened (post-2021) VSA builds, user-mutation endpoints reset the connection here
            rather than returning 403/404, so ConnectionReset is set for callers to branch on.
          - Any other status: a real HTTP error, with the VSA error text if the body carried one.
    .PARAMETER StatusCode
        HTTP status, or 0 when no response arrived.
    .PARAMETER Method
        HTTP method.
    .PARAMETER Uri
        Request URI.
    .PARAMETER Body
        Raw response body, if any.
    .PARAMETER InnerException
        The underlying transport exception, if any.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [int] $StatusCode,
        [Parameter(Mandatory = $false)] [string] $Method,
        [Parameter(Mandatory = $false)] [string] $Uri,
        [Parameter(Mandatory = $false)] [string] $Body,
        [Parameter(Mandatory = $false)] [Exception] $InnerException
    )

    $vsaError = ConvertFrom-VSAErrorBody -Body $Body

    if ($StatusCode -eq 0) {
        $detail = @(
            "No HTTP response for $Method $Uri."
            "The connection was reset or the endpoint is unreachable -- it may be blocked or"
            "restricted on this VSA build (common for user-mutation endpoints on hardened,"
            "post-2021 instances)."
            if ($InnerException) { "Underlying error: $($InnerException.Message)" }
            if ($Body) { "Response Body: $Body" }
        ) -join "`n"
        return (New-VSAApiError -Message $detail -StatusCode 0 -Method $Method -Uri $Uri `
            -VSAError $vsaError -InnerException $InnerException -ConnectionReset)
    }

    $statusName = Get-VSAHttpStatusName -StatusCode $StatusCode
    $detail = @(
        "Failed to call REST API endpoint."
        "Method: $Method"
        "URI: $Uri"
        "HTTP Status: $StatusCode"
        "Error: Response status code does not indicate success: $StatusCode ($statusName)."
        if ($vsaError) { "VSA Error: $vsaError" }
        elseif ($Body) { "Response Body: $Body" }
    ) -join "`n"

    return (New-VSAApiError -Message $detail -StatusCode $StatusCode -Method $Method -Uri $Uri `
        -VSAError $vsaError -InnerException $InnerException)
}

function Invoke-VSAHttp {
    <#
    .SYNOPSIS
        Issues a single HTTP request via the shared HttpClient, with the module's retry policy.
    .DESCRIPTION
        The blocking half of the module's single HTTP stack. Sends one request, retries transient
        failures per the shared policy, and returns the raw outcome. Envelope interpretation is NOT
        done here -- that is Resolve-VSAResponse's job -- so this function stays a pure transport.

        Unlike Invoke-RestMethod, HttpClient does not throw on 4xx/5xx, so the error body is simply
        read rather than reconstructed from an ErrorRecord.
    .PARAMETER Uri
        Absolute request URI.
    .PARAMETER Method
        HTTP method.
    .PARAMETER AuthString
        Full Authorization header value.
    .PARAMETER Body
        [string] JSON body, or [byte[]] raw/multipart body.
    .PARAMETER ContentType
        Content-Type for the body.
    .PARAMETER TimeoutSec
        Per-request timeout.
    .PARAMETER OutFile
        Write the response body to this path instead of returning it.
    .PARAMETER MaxRetries
        Maximum transient-failure retries.
    .PARAMETER IgnoreCertificateErrors
        Bypass TLS certificate validation.
    .OUTPUTS
        PSCustomObject: StatusCode [int], Body [string] ($null when -OutFile was used).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]  [ValidateNotNullOrEmpty()] [string] $Uri,
        [Parameter(Mandatory = $false)] [ValidateSet('GET','POST','PUT','DELETE','PATCH')] [string] $Method = 'GET',
        [Parameter(Mandatory = $true)]  [ValidateNotNullOrEmpty()] [string] $AuthString,
        [Parameter(Mandatory = $false)] [object] $Body,
        [Parameter(Mandatory = $false)] [string] $ContentType = 'application/json',
        [Parameter(Mandatory = $false)] [ValidateRange(1, 3600)] [int] $TimeoutSec = 100,
        [Parameter(Mandatory = $false)] [string] $OutFile,
        [Parameter(Mandatory = $false)] [ValidateRange(0, 10)] [int] $MaxRetries = 3,
        [Parameter(Mandatory = $false)] [switch] $IgnoreCertificateErrors
    )

    $client = Get-VSAHttpClient -IgnoreCertificateErrors $IgnoreCertificateErrors.IsPresent
    [int] $attempt = 0

    while ($true) {
        $certBypassPushed = $false
        $request = $null
        $response = $null
        $cts = $null
        try {
            # On 5.1 the bypass is a process-wide policy that must be installed around the send;
            # on Core this is a no-op (the handler already carries the validator).
            if ($IgnoreCertificateErrors) {
                & $script:VSAPushCertBypass
                $certBypassPushed = $true
            }

            $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($Method), $Uri)
            $request.Headers.TryAddWithoutValidation('Authorization', $AuthString) | Out-Null
            $content = New-VSAHttpContent -Body $Body -ContentType $ContentType
            if ($null -ne $content) { $request.Content = $content }

            $cts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSec))

            [int] $status = 0
            [string] $responseBody = $null
            $transportError = $null

            try {
                $response = $client.SendAsync($request, $cts.Token).GetAwaiter().GetResult()
                $status = [int]$response.StatusCode
                if ($OutFile -and $response.IsSuccessStatusCode) {
                    [System.IO.File]::WriteAllBytes($OutFile, $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
                } else {
                    $responseBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                }
            } catch {
                # No HTTP response at all: reset socket, DNS failure, or the timeout token firing.
                $transportError = $_.Exception
                $status = 0
            }

            if ((Test-VSARetryable -StatusCode $status -Method $Method -NoResponse ($null -ne $transportError)) -and $attempt -lt $MaxRetries) {
                $attempt++
                $waitSeconds = Get-VSABackoffSeconds -Attempt $attempt -RetryAfterSeconds (Get-VSARetryAfterSeconds -Response $response)
                $statusLabel = if ($status -eq 0) { 'no response' } else { "HTTP $status ($(Get-VSAHttpStatusName -StatusCode $status))" }
                Write-Warning "Transient $statusLabel on $Method $Uri. Retry $attempt of $MaxRetries in $waitSeconds second(s)..."
                if ($waitSeconds -gt 0) { Start-Sleep -Seconds $waitSeconds }
                continue
            }

            if ($null -ne $transportError -or $status -ge 400) {
                throw (New-VSATransportError -StatusCode $status -Method $Method -Uri $Uri -Body $responseBody -InnerException $transportError)
            }

            return [pscustomobject]@{ StatusCode = $status; Body = $responseBody }
        }
        finally {
            if ($null -ne $response) { $response.Dispose() }
            if ($null -ne $request)  { $request.Dispose() }
            if ($null -ne $cts)      { $cts.Dispose() }
            if ($certBypassPushed)   { & $script:VSAPopCertBypass }
        }
    }
}
