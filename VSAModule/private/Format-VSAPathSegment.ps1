function Format-VSAPathSegment {
    <#
    .SYNOPSIS
       URL-encodes user text destined for a URI path, escaping each '/'-separated segment.
    .DESCRIPTION
       Splits on '/', percent-encodes every segment individually with EscapeDataString, then
       re-joins with '/'. A single segment (no slash) is simply encoded; a remote path keeps
       its separators while spaces, '#', '&' etc. inside each part are encoded.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path
    )
    return (($Path -split '/', 0, 'SimpleMatch') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
}
