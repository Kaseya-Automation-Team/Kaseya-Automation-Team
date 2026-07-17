function ConvertFrom-VSAScExport {
    <#
    .SYNOPSIS
        Parses a Kaseya VSA 9 ScExport XML body (the agent-procedure export format) into objects.
    .DESCRIPTION
        VSA 9 Agent Procedures are stored as XML, so the agent-procedure list endpoint
        (api/v1.0/automation/agentprocs/proclist) returns an ScExport document rather than JSON -- by
        design, not error. This helper is the one place that understands that format, keeping XML
        handling local to the cmdlet that needs it (Get-VSAAPList) instead of teaching the generic
        JSON transport to sniff content types.

        The document shape (confirmed live) is:

            <ScExport xmlns="http://www.kaseya.com/vsa/2008/12/Scripting">
              <Records name="TotalRecords" totalRecords="786" startingRecordIndex="0" currentNumRecords="100" />
              <Procedure name="..." treePres="3" id="659091963" folderId="546051318732114"
                         treeFullPath="Core\..." shared="true"> <Body>...</Body> </Procedure>
              ...
            </ScExport>

        The `<Records>` element carries the same paging totals the JSON envelope exposes as
        TotalRecords, so callers page it identically. The heavy `<Body>` child (the full procedure
        definition) is intentionally not projected -- a list cmdlet returns the summary, not the body.
    .PARAMETER Body
        The raw ScExport XML string (e.g. the body returned by Invoke-VSAHttp for the proclist endpoint).
    .OUTPUTS
        A PSCustomObject with the paging totals (TotalRecords, StartingRecordIndex, CurrentNumRecords)
        and a Procedures array, one PSCustomObject per <Procedure> node
        (Id, Name, Path, FolderId, Shared [bool], TreePres). All ids are strings: folderId overflows
        Int32.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Body
    )

    [xml] $doc = $Body
    $root = $doc.DocumentElement   # <ScExport>; a default namespace makes XPath awkward, so walk by LocalName.

    # --- paging totals from <Records> ---
    [int] $total = 0; [int] $start = 0; [int] $current = 0
    $recordsNode = $root.ChildNodes | Where-Object { $_.LocalName -eq 'Records' } | Select-Object -First 1
    if ($recordsNode) {
        [void][int]::TryParse($recordsNode.GetAttribute('totalRecords'),        [ref]$total)
        [void][int]::TryParse($recordsNode.GetAttribute('startingRecordIndex'), [ref]$start)
        [void][int]::TryParse($recordsNode.GetAttribute('currentNumRecords'),   [ref]$current)
    }

    # --- one object per <Procedure> node; <Body> is deliberately omitted ---
    $procedures = foreach ($node in ($root.ChildNodes | Where-Object { $_.LocalName -eq 'Procedure' })) {
        [pscustomobject]@{
            Id       = $node.GetAttribute('id')            # string: big numeric id
            Name     = $node.GetAttribute('name')
            Path     = $node.GetAttribute('treeFullPath')
            FolderId = $node.GetAttribute('folderId')      # string: overflows Int32
            Shared   = ($node.GetAttribute('shared') -eq 'true')
            TreePres = $node.GetAttribute('treePres')
        }
    }

    return [pscustomobject]@{
        TotalRecords        = $total
        StartingRecordIndex = $start
        CurrentNumRecords   = $current
        Procedures          = @($procedures)
    }
}
