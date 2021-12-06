function Remove-VSATenant
{
    <#
    .Synopsis
       Removes a tenant partition.
    .DESCRIPTION
       Removes a tenant partition.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantName
        Specifies the Tenant Name.
    .PARAMETER TenantId
        Specifies the Tenant Id.
    .EXAMPLE
       Remove-VSATenant -TenantId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant?tenantId={0}',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId
    )
    $URISuffix = $URISuffix -f $TenantId
    $URISuffix | Write-Debug
    

    [hashtable]$Params = @{
            'URISuffix' = $URISuffix
            'Method'    = 'DELETE'
            }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    if( $PSCmdlet.ShouldProcess( $TenantId ) ) {
        return Update-VSAItems @Params
    }
}
Export-ModuleMember -Function Remove-VSATenant