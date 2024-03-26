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

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
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
        if ( 0 -eq $RoleTypeIds.Count) {
                [hashtable] $HTRoleTypes = @{
                'VSA Admin'					= 4
                'End User'					= 6
                'Basic Machine'				= 8
                'Service Desk Admin'		= 100
                'Service Desk Technician'	= 101
                'SB Admin'					= 105
                'KDP Admin'					= 116
                'KDM Admin'					= 117
            }
    
            $Body = ConvertTo-Json $HTRoleTypes[$RoleType]
        } else {
            $Body = ConvertTo-Json $RoleTypeIds
        }
    }# Begin
    Process {
        $URISuffix = $URISuffix -f $TenantId

        $Body | Out-String | Write-Debug

        [hashtable]$Params =@{
            URISuffix = $URISuffix
            Method    = 'PUT'
            Body      = $Body
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        
        $Params | Out-String | Write-Debug

        return Update-VSAItems @Params
    }#Process
}

Export-ModuleMember -Function Enable-VSATenantRoleType