function Get-VSATenantRoletypeFunclist {
    <#
    .Synopsis
       Returns an array of funclist entries.
    .DESCRIPTION
       Returns an array of funclist entries for a specified roletype id OR for each roletype.
       Takes either Tenant or non-Tenant connection information.
    .PARAMETER VSAConnection
        Specifies existing non-Tenant VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleTypeId
        Specifies roletype id to return an array of funclist entries.
    .PARAMETER Filter
        Specifies an OData $filter expression applied by the server.
    .PARAMETER Sort
        Specifies an OData $orderby expression applied by the server.
    .PARAMETER Parallel
        Fetches the remaining pages of a large collection concurrently instead of one after another.
        Opt-in: without it, behaviour is unchanged. Results are identical either way (same records,
        merged in $skip order). Only engages once the collection is large enough to be worth it
        (see -ParallelThreshold).
    .PARAMETER ThrottleLimit
        Maximum number of concurrent requests when -Parallel is used (default 8). On shared SaaS you
        are one tenant among many, so a modest value is a good citizen; the engine also reduces
        concurrency automatically if the server returns HTTP 429, then recovers.
    .PARAMETER ParallelThreshold
        Minimum total record count before -Parallel actually engages. 0 (default) means automatic:
        two full throttle windows, i.e. 2 * ThrottleLimit * 100 records. Below that the sequential
        path is used, because it is faster than paying to set up extra connections.    .EXAMPLE
       Get-VSATenantRoletypeFunclist -RoleTypeId 4
    .INPUTS
       Accepts piped non-Tenant VSAConnection
    .OUTPUTS
       Array of funclist entries.
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/roletypes',

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleTypeId,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Sort,

        # Opt-in parallel paging for large collections (see Invoke-VSARestMethod). No effect on small
        # ones: below -ParallelThreshold the sequential path is used.
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

    if( -not [string]::IsNullOrEmpty($RoleTypeId) ) {
        $URISuffix += "/$RoleTypeId"
    }
    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if( -not [string]::IsNullOrEmpty($Filter) ) { $Params.Add('Filter', $Filter) }
    if( -not [string]::IsNullOrEmpty($Sort) )   { $Params.Add('Sort', $Sort) }

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
    return Invoke-VSARestMethod @Params
    }
}
New-Alias -Name Get-VSATenantRoletypesFunclists -Value Get-VSATenantRoletypeFunclist
Export-ModuleMember -Function Get-VSATenantRoletypeFunclist -Alias Get-VSATenantRoletypesFunclists
