function ConvertTo-VSAQueryString {
    <#
    .SYNOPSIS
       Builds a URL query string from a hashtable, URL-encoding each value (not the key).
    .DESCRIPTION
       OData parameter names such as $filter, $orderby, $skip, $top must be transmitted
       literally, so only the value is percent-encoded via [uri]::EscapeDataString. This is
       what lets a legitimate filter containing quotes, parentheses, commas and spaces pass
       through unchanged except for URL-encoding.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [hashtable] $Parameters
    )
    $pairs = foreach ($key in $Parameters.Keys) {
        '{0}={1}' -f $key, [uri]::EscapeDataString([string]$Parameters[$key])
    }
    return ($pairs -join '&')
}
