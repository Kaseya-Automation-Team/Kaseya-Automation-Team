function ConvertTo-VSAHashtable {
    <#
    .SYNOPSIS
       Normalizes a nested-object argument to a [hashtable].
    .DESCRIPTION
       Accepts a nested structure in any of the forms VSA cmdlets receive it and returns a
       plain [hashtable] ready to place into a request body:

         - [hashtable] / [System.Collections.IDictionary] -- returned as a hashtable (the
           idiomatic, preferred input).
         - [pscustomobject] / [psobject]                  -- each NoteProperty becomes a key.
         - [string] (legacy)                              -- two historical micro-syntaxes are
           accepted:
             * brace form   "{ Key1= val1; Key2= val2 }"  (as used by New-VSAOrganization,
               New-VSATenant LicenseValues)
             * plain form   "Key1=val1`nKey2=val2"        (ConvertFrom-StringData form, as used
               by the *Attributes* parameters of the other cmdlets)
           Both are parsed by the same hardened logic: optional surrounding braces are stripped,
           pairs are split on ';' OR newlines, and each pair is split on the FIRST '=' only so a
           value may itself contain '='. Unlike the previous ConvertFrom-StringData approach this
           does not treat '\' as an escape introducer and does not depend on the pipeline-global
           $Matches automatic variable.

       Empty / whitespace-only keys and $null inputs yield an empty hashtable. Empty VALUES are
       preserved; callers that want empty values pruned should do so after conversion (the write
       cmdlets already prune empty keys from the assembled body).
    .PARAMETER InputObject
        The nested structure to normalize. May be $null.
    .EXAMPLE
        ConvertTo-VSAHashtable @{ City = 'New York'; PrimaryEmail = 'a@b.com' }
    .EXAMPLE
        ConvertTo-VSAHashtable '{ City= New York; PrimaryPhone= 555;x99 }'
    .OUTPUTS
        [hashtable]
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [object] $InputObject
    )

    if ($null -eq $InputObject) { return @{} }

    # Already a dictionary -- the elegant, preferred path. Copy into a fresh hashtable so callers
    # can safely mutate the result without touching the argument they passed in.
    if ($InputObject -is [System.Collections.IDictionary]) {
        $ht = @{}
        foreach ($key in $InputObject.Keys) { $ht[$key] = $InputObject[$key] }
        return $ht
    }

    # PSCustomObject / PSObject with note properties.
    if ($InputObject -is [psobject] -and -not ($InputObject -is [string]) -and $InputObject.PSObject.Properties.Count -gt 0) {
        $ht = @{}
        foreach ($prop in $InputObject.PSObject.Properties) { $ht[$prop.Name] = $prop.Value }
        return $ht
    }

    # Legacy string form (both brace and plain variants).
    [string] $text = "$InputObject"
    if ([string]::IsNullOrWhiteSpace($text)) { return @{} }

    # Strip a single optional pair of surrounding braces without regex (regex '{(.*?)\}' was
    # brace-blind and truncated on any '}' inside a value).
    $text = $text.Trim()
    if ($text.StartsWith('{') -and $text.EndsWith('}')) {
        $text = $text.Substring(1, $text.Length - 2)
    }

    $result = @{}
    foreach ($pair in ($text -split '[;\r\n]+')) {
        if ([string]::IsNullOrWhiteSpace($pair)) { continue }
        $eq = $pair.IndexOf('=')
        if ($eq -lt 0) { continue }                       # not a key=value pair -- skip
        $key = $pair.Substring(0, $eq).Trim()
        if ([string]::IsNullOrEmpty($key)) { continue }
        $value = $pair.Substring($eq + 1).Trim()          # first '=' only -> value keeps any '='
        $result[$key] = $value
    }
    return $result
}
