function Get-VSAAPList {
    <#
    .SYNOPSIS
        Lists Agent Procedures (the procedure tree) from a VSA 9 environment.
    .DESCRIPTION
        Returns one object per Agent Procedure. VSA 9 Agent Procedures are stored as XML, so the
        underlying endpoint (api/v1.0/automation/agentprocs/proclist) returns a Kaseya ScExport XML
        document rather than JSON -- by design, not error. This cmdlet therefore has its own
        implementation instead of routing through the generic JSON read path: it fetches the raw body
        and parses it with ConvertFrom-VSAScExport, keeping XML handling local to the one endpoint
        that needs it.

        Paging matches every other collection: the ScExport `<Records totalRecords=...>` element
        carries the same total the JSON envelope exposes, so pages are fetched via $skip/$top until
        the whole tree is retrieved. Paging is sequential (there is no -Parallel here): the shared
        parallel engine deserializes JSON, so reusing it would mean teaching the generic transport to
        parse XML, which this design deliberately avoids. The full procedure `<Body>` (the step
        definition) is not returned -- this is a list, not an export; fetch a single procedure's
        detail with Get-VSAAP.
    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection. When omitted, the persistent connection
        is used.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER RecordsPerPage
        Number of records requested per page via $top (1-100; the server caps at 100).
    .EXAMPLE
        Get-VSAAPList
        Lists every Agent Procedure via the persistent connection.
    .EXAMPLE
        Get-VSAAPList -VSAConnection $connection | Where-Object { $_.Shared }
        Lists the shared Agent Procedures on a non-persistent connection.
    .INPUTS
        Accepts a piped non-persistent VSAConnection.
    .OUTPUTS
        One PSCustomObject per Agent Procedure: Id, Name, Path, FolderId, Shared (bool), TreePres.
        Ids are strings (they overflow Int32).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/agentprocs/proclist',

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int] $RecordsPerPage = 100
    )
    process {
        # Resolve base URI + cert flag from the connection; the token is fetched per page in the loop
        # below (so it stays fresh over a long tree), which is why it is not read here.
        if ($null -eq $VSAConnection) {
            $VSAServerURI                  = Get-VSAPersistentURI
            [bool]$IgnoreCertificateErrors = Get-VSAPersistentIgnoreCertErrors
        } else {
            $VSAServerURI                  = $VSAConnection.URI
            [bool]$IgnoreCertificateErrors = $VSAConnection.IgnoreCertificateErrors
        }

        $baseUri = New-Object System.Uri -ArgumentList $VSAServerURI
        [string]$endpoint = [System.Uri]::new($baseUri, $URISuffix) | Select-Object -ExpandProperty AbsoluteUri
        $UriSeparator = if ($endpoint -match '\?') { '&' } else { '?' }

        [hashtable]$HttpArgs = @{ Method = 'GET' }
        if ($IgnoreCertificateErrors) { $HttpArgs['IgnoreCertificateErrors'] = $true }

        $all = New-Object System.Collections.ArrayList
        [int]$skip  = 0
        [int]$total = -1
        do {
            # Renew the session token between pages if it is near expiry (a no-op otherwise), so a
            # long procedure tree does not outlive the token mid-fetch.
            if ($null -eq $VSAConnection) { Update-VSAConnection;                        $HttpArgs['AuthString'] = "Bearer $( Get-VSAPersistentToken )" }
            else                          { Update-VSAConnection -VSAConnection $VSAConnection; $HttpArgs['AuthString'] = "Bearer $($VSAConnection.Token)" }

            $query   = ConvertTo-VSAQueryString -Parameters @{ '$skip' = "$skip"; '$top' = $RecordsPerPage }
            $pageUri = '{0}{1}{2}' -f $endpoint, $UriSeparator, $query

            # Invoke-VSAHttp gives the raw body and still throws a typed VSAApiException on a
            # transport/HTTP failure; only the JSON envelope step is bypassed.
            $resp   = Invoke-VSAHttp -Uri $pageUri @HttpArgs
            $parsed = ConvertFrom-VSAScExport -Body $resp.Body

            if ($total -lt 0) { $total = $parsed.TotalRecords }
            foreach ($proc in $parsed.Procedures) { [void]$all.Add($proc) }

            $skip += $RecordsPerPage
            # Stop when the whole tree is in hand; the Procedures-count guard prevents an infinite
            # loop if the server ever reports a total it does not deliver.
        } while ($all.Count -lt $total -and $parsed.Procedures.Count -gt 0)

        return $all.ToArray()
    }
}
Export-ModuleMember -Function Get-VSAAPList
