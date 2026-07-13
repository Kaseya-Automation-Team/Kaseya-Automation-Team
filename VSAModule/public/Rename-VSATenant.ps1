function Rename-VSATenant {
    <#
    .Synopsis
       Renames the tenant partition.
    .DESCRIPTION
       Renames the tenant partition.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition.
    .PARAMETER NewName
        Specifies a new name for the tenant partition.
    .EXAMPLE
       Rename-VSATenant -TenantId 10001 -NewName 'NewTenantName'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Array of tenant's properties
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant?tenantId={0}&newTenantRef={1}',

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId,

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $NewName
    )
    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $TenantId, $NewName)) -VSAConnection $VSAConnection -Caller $PSCmdlet
}

Export-ModuleMember -Function Rename-VSATenant