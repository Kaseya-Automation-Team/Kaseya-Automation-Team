# The module's JSON response decoder -- the SINGLE definition of how a raw VSA response body
# becomes engine-consumable data. Before this file existed, that knowledge lived in two places
# that had to be kept in agreement by hand: Get-RequestData held the parse step (ConvertFrom-Json,
# the F-72 non-JSON typing, the F-21 empty-body rule via Resolve-VSAResponse), and
# Invoke-VSARestMethod re-inspected the same envelope a second time (the F-63 raw-payload check,
# '.Result' extraction, TotalRecords detection). Split-brain policy is this module's recurring
# failure mode (see the v1.6.0 transport unification); both halves now live here, verbatim, and
# the callers consume them.
#
# Layering (the read stack, bottom-up):
#   1. Transport      Invoke-VSAHttp            bytes, retries, typed transport errors
#   2. Session send   Get-RequestData (+ Invoke-VSARequestWithRenewal)   auth, 401 recovery
#   3. Decode         THIS FILE                 body -> resolved object -> classification
#   4. Read engine    Invoke-VSARestMethod      URI building, paging, progress
#
# The XML sibling for step 3 is ConvertFrom-VSAScExport (Kaseya's ScExport format).

function Resolve-VSAResponse {
    <#
    .SYNOPSIS
        Applies the VSA API envelope rules to a deserialized 2xx response body.
    .DESCRIPTION
        The single definition of "what does a successful VSA response look like", shared by the
        sequential and parallel paths. Returns the value the caller should receive, or throws a typed
        VSAApiException for an application-level error carried inside an HTTP 200 envelope. It lives
        in the decode layer (not the transport) because it is envelope policy, not byte handling --
        the transport deliberately does no envelope work and delegates it here.

        Rules, in order:
          1. Empty body (HTTP 204, returned by DELETE and some PUT endpoints) -> $null, a single
             empty-success sentinel for callers (F-21).
          2. ResponseCode 4xx/5xx inside a 200 -> application error, throw typed.
          3. ResponseCode 0/20x, or Status 'OK' -> success, return the envelope.
          4. Neither ResponseCode nor Status present -> a raw, non-enveloped payload. Cloud Backup
             (kcb/*) returns a bare JSON map with none of the envelope fields; that is a successful
             result, not a broken envelope, so return it as-is (F-63).
          5. Anything else -> an envelope we do not recognise; throw rather than return it silently.
    .PARAMETER Response
        The deserialized response body ($null for an empty body).
    .PARAMETER Method
        HTTP method, for error context.
    .PARAMETER Uri
        Request URI, for error context.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Response,

        [Parameter(Mandatory = $false)]
        [string] $Method,

        [Parameter(Mandatory = $false)]
        [string] $Uri
    )

    if ($null -eq $Response -or ($Response -is [string] -and [string]::IsNullOrWhiteSpace($Response))) {
        return $null
    }

    if ($Response.ResponseCode -match "(^40\d|^50\d)") {
        $code = 0; [void][int]::TryParse([string]$Response.ResponseCode, [ref]$code)
        throw (New-VSAApiError -Message "API Error (Code: $($Response.ResponseCode)) for $Method $Uri. Error: '$($Response.Error)'. Result: '$($Response.Result)'." `
            -StatusCode $code -Method $Method -Uri $Uri -VSAError ([string]$Response.Error))
    }

    if (($Response.ResponseCode -match "(^0$)|(^20\d+$)") -or ('OK' -eq $Response.Status)) {
        return $Response
    }

    if (($null -eq $Response.PSObject.Properties['ResponseCode']) -and
        ($null -eq $Response.PSObject.Properties['Status'])) {
        return $Response
    }

    throw (New-VSAApiError -Message "Unexpected API response for $Method $Uri. Response Code: '$($Response.ResponseCode)'. Error: '$($Response.Error)'." `
        -StatusCode 0 -Method $Method -Uri $Uri -VSAError ([string]$Response.Error))
}

function ConvertFrom-VSAResponseBody {
    <#
    .SYNOPSIS
        Decodes a raw VSA response body into the resolved response object (JSON default decoder).
    .DESCRIPTION
        The first half of the decode layer: raw body text in, resolved response object out.

        Rules (each moved verbatim from Get-RequestData, where they were proven live):
          * An empty or whitespace body (HTTP 204 No Content, returned by DELETE and some PUT
            endpoints) is a success with nothing to deserialize -> $null (F-21).
          * A 2xx body that is not JSON: some VSA 9 endpoints return XML by design (e.g. the
            agent-procedure export api/v1.0/automation/agentprocs/proclist, Kaseya's ScExport
            format), and a genuine error page can also arrive as HTML/text. ConvertFrom-Json throws
            an opaque parser error on either edition (on 5.1: "Invalid JSON primitive"); surface it
            as a typed VSAApiException that names the cause, so callers get the same branchable
            error contract as any other transport failure (F-72).
          * A parsed body is then interpreted by Resolve-VSAResponse -- the envelope success/error
            rules shared with the parallel pump -- which may throw typed for an application-level
            error carried inside an HTTP 200.
    .PARAMETER Body
        The raw response body text ($null/empty for an empty-body success).
    .PARAMETER StatusCode
        The HTTP status code of the response, for error context on a non-JSON body.
    .PARAMETER Method
        HTTP method, for error context.
    .PARAMETER Uri
        Request URI, for error context.
    .OUTPUTS
        The resolved response object, or $null for an empty-body success.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Body,

        [Parameter(Mandatory = $false)]
        [int] $StatusCode = 0,

        [Parameter(Mandatory = $false)]
        [string] $Method,

        [Parameter(Mandatory = $false)]
        [string] $Uri
    )

    if ([string]::IsNullOrWhiteSpace($Body)) { return $null }

    try {
        $Response = $Body | ConvertFrom-Json
    } catch {
        $bodyStart = ("$Body").TrimStart()
        $kind = if ($bodyStart -like '<?xml*' -or $bodyStart -like '<*') { 'XML' } else { 'not JSON' }
        throw (New-VSAApiError -Message "The VSA API returned a non-JSON response for $Method $Uri. The response body is $kind, not JSON, so it cannot be deserialized. Underlying error: $($_.Exception.Message)" `
            -StatusCode $StatusCode -Method $Method -Uri $Uri -InnerException $_.Exception)
    }

    return (Resolve-VSAResponse -Response $Response -Method $Method -Uri $Uri)
}

function ConvertFrom-VSAScExportResponse {
    <#
    .SYNOPSIS
        The ScExport XML decoder: a raw agent-procedure body into an engine-consumable response.
    .DESCRIPTION
        The XML sibling of ConvertFrom-VSAResponseBody, and the reason the read engine can page an XML
        endpoint without knowing anything about XML. VSA 9 stores Agent Procedures as XML, so
        api/v1.0/automation/agentprocs/proclist answers with Kaseya's ScExport document rather than a
        JSON envelope (by design, not error). This decoder parses that document with the existing
        ConvertFrom-VSAScExport helper and shapes it into the SAME contract the engine already
        consumes from Expand-VSAEnvelope: an object exposing `.Result` (the procedures on this page)
        and `.TotalRecords` (the tree total, from the ScExport <Records> element). The engine's paging,
        token renewal, session-invalidation recovery (F-77), retry and progress therefore all apply to
        the AP list unchanged -- it is just another paged collection whose page decoder differs.

        Signature matches ConvertFrom-VSAResponseBody exactly (Body/StatusCode/Method/Uri) so the two
        are interchangeable as the engine's -Decoder. An empty body normalizes to $null (F-21), like
        every other read.
    .PARAMETER Body
        The raw ScExport XML body text.
    .PARAMETER StatusCode
        The HTTP status code (unused here; present for decoder-signature parity).
    .PARAMETER Method
        HTTP method, for signature parity.
    .PARAMETER Uri
        Request URI, for signature parity.
    .OUTPUTS
        [pscustomobject] @{ Result = <procedures[]>; TotalRecords = <int> }, or $null for an empty body.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Body,

        [Parameter(Mandatory = $false)]
        [int] $StatusCode = 0,

        [Parameter(Mandatory = $false)]
        [string] $Method,

        [Parameter(Mandatory = $false)]
        [string] $Uri
    )

    if ([string]::IsNullOrWhiteSpace($Body)) { return $null }

    $parsed = ConvertFrom-VSAScExport -Body $Body
    return [pscustomobject]@{
        Result       = $parsed.Procedures
        TotalRecords = $parsed.TotalRecords
    }
}

function Expand-VSAEnvelope {
    <#
    .SYNOPSIS
        Classifies a resolved VSA response for the read engine (the second half of the decode layer).
    .DESCRIPTION
        Turns the resolved response object into the flat facts the paging engine consumes, so the
        engine itself contains zero envelope knowledge. Each rule moved verbatim from
        Invoke-VSARestMethod:

          * IsNull: a successful empty-body 2xx (HTTP 204 from DELETE / some PUT) has no envelope to
            expand or page; the engine must return nothing rather than expand a non-existent
            '.Result' property, which would throw on the success path (F-21).
          * IsEnvelope: a raw (non-enveloped) payload -- e.g. Cloud Backup's flat
            { <agentId>: <status> } map -- carries its data directly and has none of the standard
            envelope fields (Result/ResponseCode/Status). There is no '.Result' to unwrap and
            nothing to page, so the engine returns it as-is (F-63). A status-only envelope (has
            ResponseCode/Status but no Result) IS an envelope: its absent '.Result' correctly
            yields an empty result set (F-23).
          * Result: extracted with member access, not Select-Object -ExpandProperty, because
            -ExpandProperty throws on a missing property while '.Result' yields $null for the
            status-only envelopes above (F-23).
          * Paginated/TotalRecords: pagination is signalled by the PRESENCE of TotalRecords
            (stringified non-empty check), so TotalRecords=0 still counts as paginated -- the page
            loop then simply has nothing further to fetch. This preserves the engine's historical
            behaviour exactly.
    .PARAMETER Response
        The resolved response object from ConvertFrom-VSAResponseBody ($null for empty success).
    .OUTPUTS
        [pscustomobject] @{ IsNull; IsEnvelope; Result; Paginated; TotalRecords }
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Response
    )

    if ($null -eq $Response) {
        return [pscustomobject]@{ IsNull = $true; IsEnvelope = $false; Result = $null; Paginated = $false; TotalRecords = 0 }
    }

    $isEnvelope = ($null -ne $Response.PSObject.Properties['Result']) -or
                  ($null -ne $Response.PSObject.Properties['ResponseCode']) -or
                  ($null -ne $Response.PSObject.Properties['Status'])

    [array]$result = $Response.Result
    [bool]$paginated = -not [string]::IsNullOrEmpty("$($Response.TotalRecords)")

    return [pscustomobject]@{
        IsNull       = $false
        IsEnvelope   = $isEnvelope
        Result       = $result
        Paginated    = $paginated
        TotalRecords = if ($paginated) { $Response.TotalRecords } else { 0 }
    }
}
