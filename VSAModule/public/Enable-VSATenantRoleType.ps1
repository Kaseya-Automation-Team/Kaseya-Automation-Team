function Enable-VSATenantRoleType {
    <#
    .Synopsis
       Activates selected roletypes for the tenant specified.
    .DESCRIPTION
       Activates selected roletypes for the tenant specified.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition.
    .PARAMETER RoleType
        Array of role types by name to be activated.
    .PARAMETER RoleTypeId
        Array of role types by Id to be activated.
    .EXAMPLE
       Enable-VSATenantRoleType -TenantId 10001 -RoleType 'SB Admin', 'KDP Admin'
    .EXAMPLE
       Enable-VSATenantRoleType -TenantId 10001 -RoleTypeId 105, 106
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            
            ParameterSetName = 'ByName')]
        [parameter(DontShow, Mandatory=$false,
            
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateSet('VSA Admin', 'End User', 'Basic Machine', 'Service Desk Admin', 'Service Desk Technician', 'SB Admin', 'KDP Admin', 'KDM Admin')]
        [string[]] $RoleType,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateSet(4, 6, 8, 100, 101, 105, 116, 117)]
        [int[]] $RoleTypeId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId
    )
    Begin {
        # F-35: the original code referenced a nonexistent $RoleTypeIds (the real parameter is
        # $RoleTypeId, singular), so .Count was always $null and every invocation fell through
        # to serializing that same nonexistent, always-null variable ("null" body every time).
        # Branch on the actual bound parameter set instead.
        # $TenantRoleTypeIdMap is a module-scope map shared with Clear-VSATenantRoleType (F-53).
        if ( $PSCmdlet.ParameterSetName -eq 'ByName' ) {
            [array] $ResolvedRoleTypeId = $RoleType | ForEach-Object { $TenantRoleTypeIdMap[$_] }
        } else {
            [array] $ResolvedRoleTypeId = $RoleTypeId
        }

        $Body = ConvertTo-Json $ResolvedRoleTypeId -Depth 5 -Compress
    }# Begin
    Process {

        return Invoke-VSAWriteRequest -Body ($Body) -Method 'PUT' -URISuffix ($($URISuffix -f $TenantId)) -VSAConnection $VSAConnection
    }#Process
}

Export-ModuleMember -Function Enable-VSATenantRoleType