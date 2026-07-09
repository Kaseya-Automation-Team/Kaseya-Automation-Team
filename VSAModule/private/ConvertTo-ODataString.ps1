function ConvertTo-ODataString {
    <#
    .SYNOPSIS
       Escapes a single OData string *value* so it can be embedded inside single quotes.
    .DESCRIPTION
       Per the OData literal rules used by the Kaseya VSA REST API, a single quote inside a
       string value is escaped by doubling it. This function escapes one value only; it does
       NOT touch backslashes and must NOT be applied to a whole filter expression (doing so
       would corrupt the operators, field names and parentheses of a legitimate filter).
    .PARAMETER Value
        The value to escape (e.g. O'Brien -> O''Brien).
    .EXAMPLE
       ConvertTo-ODataString -Value "O'Brien"   # returns O''Brien
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Value
    )
    return ($Value -replace "'", "''")
}
