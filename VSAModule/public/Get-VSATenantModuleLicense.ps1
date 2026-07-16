function Get-VSATenantModuleLicense {
    <#
    .Synopsis
       Returns an array of module licenses.
    .DESCRIPTION
       Returns an array of module licenses for a specified TenantId OR for a specified ModuleId.
       Takes either Tenant or non-Tenant connection information.
    .PARAMETER VSAConnection
        Specifies existing non-Tenant VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies Tenant Id to return module licenses.
    .PARAMETER ModuleId
       Specifies Module Id to return module licenses.
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
       Get-VSATenantModuleLicense -TenantId 10001
    .EXAMPLE
       Get-VSATenantModuleLicense -ModuleId 20002
    .INPUTS
       Accepts piped non-Tenant VSAConnection
    .OUTPUTS
       Array of tof module licenses
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Tenant')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Module')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false,

            ParameterSetName = 'Tenant')]
        [parameter(Mandatory = $false,

            ParameterSetName = 'Module')]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/licensing/',

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Tenant')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId,

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Module')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ModuleId,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Tenant')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Module')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Tenant')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Module')]
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

    if( -not [string]::IsNullOrEmpty($TenantId) ) {
        $URISuffix += "modules/$TenantId"
    }
    if( -not [string]::IsNullOrEmpty($ModuleId)  ) {
        $URISuffix += "module/$ModuleId"
    }
    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if( -not [string]::IsNullOrEmpty($Filter) ) { $Params.Add('Filter', $Filter) }
    if( -not [string]::IsNullOrEmpty($Sort) )   { $Params.Add('Sort', $Sort) }

    #region messages to verbose and debug streams
    "Get-VSATenantModuleLicense: $($Params | Out-String)" | Write-Debug

    "Get-VSATenantModuleLicense: $($Params | Out-String)" | Write-Verbose

    #endregion messages to verbose and debug streams

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
    return Invoke-VSARestMethod @Params
    }
}
New-Alias -Name Get-VSATenantModuleLicenses -Value Get-VSATenantModuleLicense
Export-ModuleMember -Function Get-VSATenantModuleLicense -Alias Get-VSATenantModuleLicenses
