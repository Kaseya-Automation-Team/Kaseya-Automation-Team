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
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return asset types as well as their respective IDs.
    .EXAMPLE
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
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Tenant')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
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
        [string] $Paging,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Tenant')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Module')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )
    
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

    #region messages to verbose and debug streams
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Get-VSATenantModuleLicense: $($Params | Out-String)" | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Get-VSATenantModuleLicense: $($Params | Out-String)" | Write-Verbose
    }
    #endregion messages to verbose and debug streams

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Get-VSATenantModuleLicenses -Value Get-VSATenantModuleLicense
Export-ModuleMember -Function Get-VSATenantModuleLicense -Alias Get-VSATenantModuleLicenses