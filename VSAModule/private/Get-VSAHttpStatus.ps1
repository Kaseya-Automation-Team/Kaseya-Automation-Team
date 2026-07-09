function Get-VSAHttpStatus {
    <#
    .SYNOPSIS
        Extracts the HTTP status code from an error record on either PowerShell edition.
    .DESCRIPTION
        On Windows PowerShell 5.1 the terminating error is a System.Net.WebException whose
        .Response is an HttpWebResponse. On PowerShell 7 it is a HttpResponseException whose
        .Response is an HttpResponseMessage. Both expose a StatusCode that casts to [int].
        This helper never references those types by name so it parses on both editions.
    #>
    param($ErrorRecord)
    $resp = $ErrorRecord.Exception.Response
    if ($resp -and $resp.StatusCode) { return [int]$resp.StatusCode }
    return $null
}
