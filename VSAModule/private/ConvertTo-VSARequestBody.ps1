function ConvertTo-VSARequestBody {
    <#
    .SYNOPSIS
       Builds a request-body hashtable from a cmdlet's bound parameters.
    .DESCRIPTION
       Replaces the two hand-rolled body-assembly shapes that recur across the write cmdlets:

         * the `foreach ($key in $AllFields) { if ($PSBoundParameters.ContainsKey($key)) {...} }`
           loop, and
         * the long `if (-not [string]::IsNullOrEmpty($X)) { $BodyHT.Add('X', $X) }` ladders.

       Only parameters the caller actually bound are included (membership is decided by
       ContainsKey, never by truthiness -- so an explicitly-passed 0 / $false / '' is included,
       fixing the F-52 class at the source). An optional -NameMap renames a parameter to its body
       field (e.g. the parameter OrgIdNumber -> the body field OrgId).
    .PARAMETER BoundParameters
        The cmdlet's $PSBoundParameters.
    .PARAMETER Include
        The candidate parameter names to copy into the body when bound.
    .PARAMETER NameMap
        Optional @{ ParameterName = 'BodyFieldName' } renames applied on the way in.
    .EXAMPLE
        $BodyHT = New-VSARequestBody -BoundParameters $PSBoundParameters `
            -Include @('OrgName','OrgRef','Website') -NameMap @{ OrganizationName = 'OrgName' }
    .OUTPUTS
        [hashtable]
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $BoundParameters,

        [parameter(Mandatory = $true)]
        [string[]] $Include,

        [parameter(Mandatory = $false)]
        [hashtable] $NameMap = @{}
    )

    [hashtable] $BodyHT = @{}
    foreach ($name in $Include) {
        if ($BoundParameters.ContainsKey($name)) {
            $field = if ($NameMap.ContainsKey($name)) { $NameMap[$name] } else { $name }
            $BodyHT[$field] = $BoundParameters[$name]
        }
    }
    return $BodyHT
}
