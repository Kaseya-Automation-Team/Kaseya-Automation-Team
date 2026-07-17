# Typed API exception so callers can branch programmatically on the failure kind instead of parsing
# the message string. Guarded against re-import type collision (F-30), like the VSAConnection class.
# Defined here (dot-sourced at import) because it is only referenced at runtime, never in a param type.
if (-not ('VSAApiException' -as [type])) {
Add-Type -TypeDefinition @'
using System;

public class VSAApiException : Exception
{
    // HTTP status code of the failed call. 0 means no HTTP response was received at all
    // (the socket was reset / the endpoint was unreachable or blocked) -- see ConnectionReset.
    public int StatusCode;
    public string HttpMethod;
    public string RequestUri;
    // The VSA-specific "Error" field parsed from the response body, when present.
    public string VSAError;
    // True when no HTTP response arrived (connection reset / blocked / unreachable). On hardened
    // (post-2021) VSA builds, user-mutation endpoints reset the connection, surfacing here.
    public bool ConnectionReset;

    public VSAApiException(string message) : base(message) { }
    public VSAApiException(string message, Exception inner) : base(message, inner) { }
}
'@
}

function New-VSAApiError {
    <#
    .SYNOPSIS
        Builds a typed [System.Management.Automation.ErrorRecord] (wrapping a VSAApiException) so
        callers can branch on $_.Exception.StatusCode / .ConnectionReset or on $_.CategoryInfo.Category.
    #>
    # Pure object factory -- constructs and returns an ErrorRecord, changes no system state; the
    # 'New' verb here does not warrant ShouldProcess.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        [Parameter(Mandatory)] [string] $Message,
        [int]       $StatusCode = 0,
        [string]    $Method,
        [string]    $Uri,
        [string]    $VSAError,
        [Exception] $InnerException,
        # Set only when no HTTP response arrived (socket reset / blocked / unreachable).
        [switch]    $ConnectionReset
    )
    $ex = if ($InnerException) {
        New-Object VSAApiException($Message, $InnerException)
    } else {
        New-Object VSAApiException($Message)
    }
    $ex.StatusCode      = $StatusCode
    $ex.HttpMethod      = $Method
    $ex.RequestUri      = $Uri
    $ex.VSAError        = $VSAError
    $ex.ConnectionReset = $ConnectionReset.IsPresent

    $category = switch ($StatusCode) {
        401     { [System.Management.Automation.ErrorCategory]::AuthenticationError }
        403     { [System.Management.Automation.ErrorCategory]::PermissionDenied }
        404     { [System.Management.Automation.ErrorCategory]::ObjectNotFound }
        0       { [System.Management.Automation.ErrorCategory]::ConnectionError }
        default { [System.Management.Automation.ErrorCategory]::InvalidOperation }
    }
    $errorId = if ($StatusCode -eq 0) { 'VSAConnectionReset' } else { "VSAHttp$StatusCode" }
    return New-Object System.Management.Automation.ErrorRecord($ex, $errorId, $category, $Uri)
}

function Get-RequestData
{
    <#
    .SYNOPSIS
       Executes a web request and returns the response with automatic retry on transient failures.
    .DESCRIPTION
       This function performs a web request and returns the response. It supports various HTTP methods
       such as GET, POST, PUT, DELETE, and PATCH, and allows customization of the request parameters.

       This is the blocking entry point to the module's single HTTP stack: it issues the request via
       Invoke-VSAHttp (System.Net.Http.HttpClient) and interprets the result with Resolve-VSAResponse.
       Both are shared verbatim with the parallel engine, so the two dispatch modes cannot drift in
       their retry, envelope or error-typing behaviour (F-67). This function therefore contains no
       HTTP logic of its own -- it is the sequential adapter over that stack.

       Automatic retry covers transient HTTP errors (429, 502, 503, 504) and honours the server's
       Retry-After hint when present, otherwise exponential backoff. A request that gets no HTTP
       response at all (socket reset / timeout) is retried only for idempotent methods: for a
       POST/PUT/DELETE the server may have applied the change before the connection dropped, so a
       retry could duplicate it, and on hardened VSA builds a reset is simply how a blocked write
       endpoint answers. Such calls therefore fail fast with ConnectionReset.

       Works on both Windows PowerShell 5.1 (Desktop) and PowerShell 7 (Core): the certificate-error
       bypass strategy is feature-detected once at import and applied inside the shared stack.
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
    "Get-RequestData. $LogMessage" | Write-Debug
    Write-Verbose "Get-RequestData. $LogMessage"

    [hashtable] $HttpParams = @{
        Uri         = $URI
        Method      = $Method
        AuthString  = $AuthString
        ContentType = $ContentType
        MaxRetries  = $MaxRetries
        TimeoutSec  = $TimeoutSec
    }
    if ($Body)    { $HttpParams['Body'] = $Body }
    if ($OutFile) { $HttpParams['OutFile'] = $OutFile }
    if ($IgnoreCertificateErrors) { $HttpParams['IgnoreCertificateErrors'] = $true }

    # Transport: throws a typed VSAApiException on a terminal HTTP/transport failure.
    $Result = Invoke-VSAHttp @HttpParams

    # A file download has no API envelope to validate.
    if ($OutFile) { return }

    "$($MyInvocation.MyCommand). Response:`n{0}" -f ($Result.Body | Out-String) | Write-Debug

    # An empty-body 2xx response (HTTP 204 No Content, returned by DELETE and some PUT endpoints)
    # is a success with nothing to deserialize; Resolve-VSAResponse normalizes it to $null (F-21).
    if ([string]::IsNullOrWhiteSpace($Result.Body)) { return $null }

    # A 2xx body that is not JSON. Some VSA 9 endpoints return XML by design (e.g. the agent-procedure
    # export api/v1.0/automation/agentprocs/proclist, Kaseya's ScExport format), and a genuine error
    # page can also arrive as HTML/text. ConvertFrom-Json throws an opaque parser error on either
    # edition (on 5.1: "Invalid JSON primitive"); surface it as a typed VSAApiException that names the
    # cause, so callers get the same branchable error contract as any other transport failure. (F-72)
    try {
        $Response = $Result.Body | ConvertFrom-Json
    } catch {
        $bodyStart = ("$($Result.Body)").TrimStart()
        $kind = if ($bodyStart -like '<?xml*' -or $bodyStart -like '<*') { 'XML' } else { 'not JSON' }
        throw (New-VSAApiError -Message "The VSA API returned a non-JSON response for $Method $URI. The response body is $kind, not JSON, so it cannot be deserialized. Underlying error: $($_.Exception.Message)" `
            -StatusCode ([int]$Result.StatusCode) -Method $Method -Uri $URI -InnerException $_.Exception)
    }

    return (Resolve-VSAResponse -Response $Response -Method $Method -Uri $URI)
    }
}
#endregion function Get-RequestData
