function Get-VSATenants {
    <#
    .Synopsis
       Returns an array of tenant partitions in the VSA. Does not include partition 1.
    .DESCRIPTION
       Returns properties for the tenant partition your API authentication provides access to in the VSA.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        When specified returns the activated modules, activated roletypes, and other properties of a single tenant partition.
    .EXAMPLE
       Get-VSATenants
    .EXAMPLE
       Get-VSATenants -TenantId 10001
    .EXAMPLE
       Get-VSATenants -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of tenant's properties
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenants',

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [decimal] $TenantId
    )

    if( 0 -ne $TenantId ) {
        $URISuffix += "/$TenantId"
    }
    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Get-VSAItems @Params
}

Export-ModuleMember -Function Get-VSATenants