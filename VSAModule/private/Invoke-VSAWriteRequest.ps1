function Invoke-VSAWriteRequest {
    <#
    .SYNOPSIS
       Shared dispatch tail for every write cmdlet (New/Update/Set/Enable/... POST/PUT/PATCH/DELETE).
    .DESCRIPTION
       Absorbs the boilerplate that used to be hand-copied at the end of ~100 public write cmdlets:
       body pruning, JSON serialization, request-parameter assembly, connection forwarding, and the
       optional ExtendedOutput expansion. Centralizing it removes two whole bug classes that came
       from divergent hand-rolled copies:

         * F-31 -- a cmdlet forgetting `if ($VSAConnection) { $Params.VSAConnection = ... }`, so an
           explicit -VSAConnection was silently ignored. The forwarding now happens in exactly one
           place.
         * F-52 -- pruning a body with `-not $BodyHT[$key]` (truthiness), which drops a legitimate
           0, $false, or '' the caller meant to send. This prunes ONLY $null and empty-string, so
           an explicit 0 / $false survives.

       Body handling by type of -Body:
         * [hashtable]/[IDictionary] : pruned (unless -KeepEmpty) then serialized to compact JSON at
           -Depth (default 10, deep enough for the module's most nested bodies -- ContactInfo,
           CustomFields, LicenseValues -- which the old per-cmdlet default depth of 2 silently
           truncated).
         * [string]                  : passed through unchanged (already-serialized JSON).
         * absent / $null            : no request body (e.g. a templated-URI PUT like Set-VSAAgentName).

       ExtendedOutput mirrors the historical New-VSAOrganization/Department/MachineGroup contract
       exactly: the switch is forwarded to the transport (which returns the full response envelope)
       and the caller-visible result is then $response.Result via Select-Object -ExpandProperty.
    .PARAMETER Body
        The request body: a hashtable (serialized here), a pre-serialized JSON string, or omitted.
    .PARAMETER Method
        The HTTP method (POST/PUT/PATCH/DELETE).
    .PARAMETER URISuffix
        The endpoint URI suffix (already formatted with any path segments by the caller).
    .PARAMETER VSAConnection
        The explicit connection; forwarded to the transport only when non-null (else the persistent
        connection is used).
    .PARAMETER ExtendedOutput
        When set, returns the expanded Result from the full response envelope (create-cmdlet contract).
    .PARAMETER KeepEmpty
        Skips body pruning; use when a cmdlet must transmit explicit null/empty-string fields.
    .PARAMETER Depth
        ConvertTo-Json depth for hashtable bodies (default 10).
    .OUTPUTS
        Whatever the transport returns for the request (bool status, created id, envelope, or $null).
    #>
    # This helper gates on the CALLER's ShouldProcess (via -Caller), not its own -- the caller is the
    # advanced function that declares SupportsShouldProcess. Suppress the rule that expects the
    # attribute here.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Body,

        [parameter(Mandatory = $true)]
        [ValidateSet('POST', 'PUT', 'PATCH', 'DELETE')]
        [string] $Method,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix,

        [parameter(Mandatory = $false)]
        [AllowNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false)]
        [switch] $ExtendedOutput,

        [parameter(Mandatory = $false)]
        [switch] $KeepEmpty,

        [parameter(Mandatory = $false)]
        [int] $Depth = 10,

        # The calling cmdlet's $PSCmdlet. When supplied (and the caller declares
        # SupportsShouldProcess), the write is gated through ShouldProcess so -WhatIf / -Confirm are
        # honored uniformly across every write cmdlet without each one re-implementing the check.
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCmdlet] $Caller,

        # The ShouldProcess action description; defaults to the HTTP method.
        [parameter(Mandatory = $false)]
        [string] $Operation
    )

    [hashtable] $Params = @{
        URISuffix = $URISuffix
        Method    = $Method
    }

    # Resolve the body: serialize a hashtable, pass a string through, or send none.
    if ($Body -is [System.Collections.IDictionary]) {
        [hashtable] $BodyHT = @{}
        foreach ($key in $Body.Keys) { $BodyHT[$key] = $Body[$key] }

        if (-not $KeepEmpty) {
            # Prune ONLY $null / empty-string. A legitimate 0 or $false is preserved (F-52).
            foreach ($key in @($BodyHT.Keys)) {
                $value = $BodyHT[$key]
                if ($null -eq $value -or ($value -is [string] -and $value.Length -eq 0)) {
                    $BodyHT.Remove($key)
                }
            }
        }

        $Params['Body'] = $BodyHT | ConvertTo-Json -Depth $Depth -Compress
    }
    elseif ($Body -is [string] -and -not [string]::IsNullOrEmpty($Body)) {
        $Params['Body'] = $Body
    }

    # Forward the explicit connection only when present (F-31): the transport falls back to the
    # persistent connection when it is absent.
    if ($VSAConnection) { $Params['VSAConnection'] = $VSAConnection }

    # Uniform -WhatIf / -Confirm gate: when the caller passed its $PSCmdlet, honor ShouldProcess.
    # -WhatIf short-circuits here so no request is sent.
    if ($Caller) {
        $action = if ([string]::IsNullOrEmpty($Operation)) { $Method } else { $Operation }
        if (-not $Caller.ShouldProcess($URISuffix, $action)) { return }
    }

    Write-Debug ("Invoke-VSAWriteRequest. {0} {1}`n{2}" -f $Method, $URISuffix, ($Params | Out-String))

    $Result = Invoke-VSARestMethod @Params -ExtendedOutput:$ExtendedOutput

    # Historical create-cmdlet contract: with -ExtendedOutput the transport returns the envelope,
    # from which the caller expects the expanded .Result.
    if ($ExtendedOutput) {
        $Result = $Result | Select-Object -ExpandProperty Result
    }

    return $Result
}
