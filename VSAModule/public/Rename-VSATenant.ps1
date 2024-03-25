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

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant?tenantId={0}&newTenantRef={1}',

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [decimal] $TenantId,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $NewName
    )
    $URISuffix = $URISuffix -f $TenantId, $NewName

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method    = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Rename-VSATenant