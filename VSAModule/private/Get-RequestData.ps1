function Get-VSAErrorBody {
    <#
    .SYNOPSIS
        Returns the response body of a failed web request on either PowerShell edition.
    #>
    param($ErrorRecord)

    # PowerShell 7 / Core surfaces the body here.
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
        return $ErrorRecord.ErrorDetails.Message
    }

    # Windows PowerShell 5.1: read the response stream.
    $resp = $ErrorRecord.Exception.Response
    if ($resp -and ($resp.PSObject.Methods.Name -contains 'GetResponseStream')) {
        try {
            $stream = $resp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
        } catch {
            return $null
        }
    }
    return $null
}

function Get-VSARetryAfterSeconds {
    <#
    .SYNOPSIS
        Returns the Retry-After delay (in seconds) from a failed web request, or $null.
    #>
    param($ErrorRecord)
    try {
        $resp = $ErrorRecord.Exception.Response
        if ($null -eq $resp) { return $null }

        # PowerShell 7 / Core: HttpResponseMessage.Headers.RetryAfter (RetryConditionHeaderValue).
        if ($resp.Headers -and ($resp.Headers.PSObject.Properties.Name -contains 'RetryAfter') -and $resp.Headers.RetryAfter) {
            if ($resp.Headers.RetryAfter.Delta) {
                return [int][Math]::Ceiling($resp.Headers.RetryAfter.Delta.TotalSeconds)
            }
        }

        # Windows PowerShell 5.1: WebHeaderCollection string indexer.
        $raw = $null
        try { $raw = $resp.Headers['Retry-After'] } catch { $raw = $null }
        if ($raw) {
            $secs = 0
            if ([int]::TryParse([string]$raw, [ref]$secs)) { return $secs }
        }
    } catch {
        return $null
    }
    return $null
}

function Get-RequestData
{
    <#
    .SYNOPSIS
       Executes a web request and returns the response with automatic retry on transient failures.
    .DESCRIPTION
       This function performs a web request and returns the response. It supports various HTTP methods
       such as GET, POST, PUT, DELETE, and PATCH, and allows customization of the request parameters.

       Implements automatic retry logic for transient HTTP errors (429, 502, 503, 504) with the
       server's Retry-After hint when present, otherwise exponential backoff.

       Works on both Windows PowerShell 5.1 (Desktop) and PowerShell 7 (Core): certificate-error
       bypass and HTTP error handling branch on the PowerShell edition without referencing any
       edition-specific type by name at parse time.
    .PARAMETER URI
        Specifies the URI for the web request.
    .PARAMETER AuthString
        Specifies the authentication string.
    .PARAMETER Method
        Specifies the REST API method (GET, POST, PUT, DELETE, PATCH).
    .PARAMETER Body
        Specifies the request's body.
    .PARAMETER ContentType
        Specifies the content type of the request (default is "application/json").
    .PARAMETER IgnoreCertificateErrors
        Ignores certificate errors if this switch is present.
    .PARAMETER MaxRetries
        Specifies the maximum number of retry attempts for transient errors (default is 3).
        Valid Range: 0 to 10. Applies to HTTP status codes 429, 502, 503, 504.
    .PARAMETER TimeoutSec
        Specifies the request timeout in seconds (default 100).
    .PARAMETER OutFile
        When specified, the response body is written to this path (file download) instead of
        being parsed as an API envelope.
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString -IgnoreCertificateErrors
    .EXAMPLE
       Get-RequestData -URI $URI -AuthString $AuthString -Method POST -Body $Body
    .INPUTS
       None. You cannot pipe objects to Get-RequestData.
    .OUTPUTS
       Array of custom objects returned by the remote server.
    .NOTES
        Version 1.1.0
        RELIABILITY: Automatic retry with Retry-After / exponential backoff for transient failures.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URI,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $AuthString,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string] $Method = 'GET',

        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        # [string] for JSON request bodies, [byte[]] for raw/multipart bodies (e.g. file uploads).
        [object] $Body,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ContentType = 'application/json',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0, 10)]
        [int] $MaxRetries = 3,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(1, 3600)]
        [int] $TimeoutSec = 100,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $OutFile,

        [switch] $IgnoreCertificateErrors
    )
    process {

    $LogMessage = "URI: '$URI': Method '$Method'"

    $AuthHeader = @{
        Authorization = $AuthString
    }

    $WebRequestParams = @{
        Uri        = $URI
        Method     = $Method
        Headers    = $AuthHeader
        TimeoutSec = $TimeoutSec
    }

    if ($Body) {
        $WebRequestParams.Add('Body', $Body)
        $WebRequestParams.Add('ContentType', $ContentType)
    }

    if ($OutFile) {
        $WebRequestParams.Add('OutFile', $OutFile)
    }

    # Certificate-error bypass uses the strategy selected once at module load (feature-detected in
    # VSAModule.psm1): on PowerShell 7+ this adds -SkipCertificateCheck to the request splat; on
    # Windows PowerShell 5.1 it is a no-op here (bypass is installed per-attempt via a compiled
    # ICertificatePolicy in VSAPushCertBypass / restored in VSAPopCertBypass).
    if ($IgnoreCertificateErrors) {
        & $script:VSAAddSkipCertCheck $WebRequestParams
    }

            "Get-RequestData. $LogMessage" | Write-Debug
        "JSON:$($WebRequestParams | ConvertTo-Json -Depth 3 | Out-String)" | Write-Debug
    
            Write-Verbose "Get-RequestData. $LogMessage"
    

    $retryStatuses = @(429, 502, 503, 504)
    [int]$RetryCount = 0

    while ($true) {
        $certBypassPushed = $false
        try {
            if ($IgnoreCertificateErrors) {
                & $script:VSAPushCertBypass
                $certBypassPushed = $true
            }

            $Response = Invoke-RestMethod @WebRequestParams -ErrorAction Stop

                            "$($MyInvocation.MyCommand). Response:`n{0}" -f ($Response | Out-String) | Write-Debug
            

            # A file download has no API envelope to validate.
            if ($OutFile) {
                return $Response
            }

            # An empty-body 2xx response (HTTP 204 No Content, returned by DELETE and some PUT
            # endpoints) comes back as $null or an empty string depending on edition. Invoke-RestMethod
            # only returns without throwing on a 2xx status, so reaching here with no body means the
            # call succeeded. Normalize to $null so callers have a single empty-success sentinel,
            # rather than falling through to the "unexpected response" throw (F-21).
            if ($null -eq $Response -or ($Response -is [string] -and [string]::IsNullOrWhiteSpace($Response))) {
                return $null
            }

            # Application-level error carried inside an HTTP 200 envelope.
            if ($Response.ResponseCode -match "(^40\d|^50\d)") {
                throw "API Error (Code: $($Response.ResponseCode)) for $Method $URI. Error: '$($Response.Error)'. Result: '$($Response.Result)'."
            }

            if (($Response.ResponseCode -match "(^0$)|(^20\d+$)") -or ('OK' -eq $Response.Status)) {
                return $Response
            }

            throw "Unexpected API response for $Method $URI. Response Code: '$($Response.ResponseCode)'. Error: '$($Response.Error)'."
        }
        catch {
            $statusCode = Get-VSAHttpStatus -ErrorRecord $_

            if (($retryStatuses -contains $statusCode) -and ($RetryCount -lt $MaxRetries)) {
                $RetryCount++
                $retryAfter = Get-VSARetryAfterSeconds -ErrorRecord $_
                if ($null -ne $retryAfter -and $retryAfter -gt 0) {
                    $WaitSeconds = $retryAfter
                } else {
                    $WaitSeconds = [int][Math]::Pow(2, $RetryCount - 1)
                }
                $statusCodeName = Get-VSAHttpStatusName -StatusCode $statusCode

                Write-Warning "Transient HTTP $statusCode ($statusCodeName) on $Method $URI. Retry $RetryCount of $MaxRetries in $WaitSeconds second(s)..."
                                    Write-Verbose "Transient error (HTTP $statusCode). Retrying in $WaitSeconds seconds. (Attempt $RetryCount of $MaxRetries)"
                

                if ($WaitSeconds -gt 0) { Start-Sleep -Seconds $WaitSeconds }
                continue
            }

            # Non-transient (or retries exhausted): throw exactly once, with all available context.
            $errorBody = Get-VSAErrorBody -ErrorRecord $_
            $vsaError = $null
            if ($errorBody) {
                try {
                    $parsed = $errorBody | ConvertFrom-Json -ErrorAction Stop
                    if ($parsed.Error) { $vsaError = $parsed.Error }
                } catch {
                    $vsaError = $null
                }
            }

            $detail = @(
                "Failed to call REST API endpoint."
                "Method: $Method"
                "URI: $URI"
                if ($null -ne $statusCode) { "HTTP Status: $statusCode" }
                "Error: $($_.Exception.Message)"
                if ($vsaError)   { "VSA Error: $vsaError" }
                elseif ($errorBody) { "Response Body: $errorBody" }
            ) -join "`n"

            throw $detail
        }
        finally {
            if ($certBypassPushed) {
                & $script:VSAPopCertBypass
            }
        }
    }
    }
}
#endregion function Get-RequestData
