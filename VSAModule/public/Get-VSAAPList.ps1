function Get-VSAAPList {
    <#
    .SYNOPSIS
        Lists Agent Procedures (the procedure tree) from a VSA 9 environment.
    .DESCRIPTION
        Returns one object per Agent Procedure. VSA 9 Agent Procedures are stored as XML, so the
        underlying endpoint (api/v1.0/automation/agentprocs/proclist) returns a Kaseya ScExport XML
        document rather than a JSON envelope -- by design, not error.

        This is a thin wrapper over the module's shared read engine (Invoke-VSARestMethod). The only
        thing unique to the AP list is how a page body is decoded: it passes the ScExport decoder
        (ConvertFrom-VSAScExportResponse) as the engine's -Decoder, and everything else -- URI and
        $skip/$top paging, session-token renewal, server-side session-invalidation recovery (F-77),
        transient-failure retry, the progress bar, and opt-in -Parallel paging -- is inherited from the
        same engine every other read uses. (Earlier versions hand-rolled their own loop below the shared
        stack and, as a result, silently lacked the F-77 recovery; routing through the engine fixes that
        class of gap by construction.)

        The full procedure `<Body>` (the step definition) is not returned -- this is a list, not an
        export; fetch a single procedure's detail with Get-VSAAP.
    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSAConnection. When omitted, the persistent connection
        is used.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER RecordsPerPage
        Number of records requested per page via $top (1-100; the server caps at 100).
    .PARAMETER Parallel
        Fetches pages 2..N concurrently through the shared coordinator pump (same engine the JSON reads
        use). Additive and opt-in; the result is identical to the sequential path.
    .PARAMETER ThrottleLimit
        Maximum concurrent in-flight page requests when -Parallel is set. Default 8.
    .PARAMETER ParallelThreshold
        Minimum TotalRecords before -Parallel actually engages (0 = auto).
    .EXAMPLE
        Get-VSAAPList
        Lists every Agent Procedure via the persistent connection.
    .EXAMPLE
        Get-VSAAPList -Parallel
        Lists every Agent Procedure, fetching pages concurrently for a large procedure tree.
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
        [int] $RecordsPerPage = 100,

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
        [hashtable]$params = @{
            URISuffix      = $URISuffix
            RecordsPerPage = $RecordsPerPage
            Decoder        = 'ConvertFrom-VSAScExportResponse'
        }
        if ($null -ne $VSAConnection) { $params['VSAConnection'] = $VSAConnection }
        if ($Parallel) {
            $params['Parallel']          = $true
            $params['ThrottleLimit']     = $ThrottleLimit
            $params['ParallelThreshold'] = $ParallelThreshold
        }

        return Invoke-VSARestMethod @params
    }
}
Export-ModuleMember -Function Get-VSAAPList
