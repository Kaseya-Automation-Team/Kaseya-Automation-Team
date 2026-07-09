function Get-VSAHttpStatusName {
    <#
    .SYNOPSIS
        Returns a human-readable name for a transient HTTP status code.
    #>
    param([int]$StatusCode)
    switch ($StatusCode) {
        429 { return "Too Many Requests" }
        502 { return "Bad Gateway" }
        503 { return "Service Unavailable" }
        504 { return "Gateway Timeout" }
        default { return "HTTP Error" }
    }
}
