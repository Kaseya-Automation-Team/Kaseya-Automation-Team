function Remove-VSATenantRoleType
{
    <#
    .Synopsis
       Removes a roletype from the entire VSA.
    .DESCRIPTION
       Removes a roletype from the entire VSA.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleTypeName
        Specifies the Role Type Name.
    .PARAMETER RoleTypeId
        Specifies the Role Type Id.
    .EXAMPLE
       Remove-VSATenantRoleType -RoleTypeId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/roletypes/{0}',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleTypeId
    )
    $URISuffix = $URISuffix -f $RoleTypeId
    $URISuffix | Write-Debug
    

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'DELETE'
                            }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Remove-VSATenantRoleType