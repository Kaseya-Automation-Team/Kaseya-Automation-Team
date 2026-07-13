function Remove-VSATenantModule {
    <#
    .Synopsis
       Removes a module from a tenant partition.
    .DESCRIPTION
       Removes a module from a tenant partition.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition.
    .PARAMETER Module
        Modules name to be removed.
    .PARAMETER ModuleIds
        Modules Id to be removed.
    .EXAMPLE
       Remove-VSATenantModule -TenantId 1001 -ModuleName 'Agent'
    .EXAMPLE
       Remove-VSATenantModule -TenantId 1001 -ModuleId 12
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if successful.
    #>

    [CmdletBinding(SupportsShouldProcess)]
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
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/modules/{0}?moduleId={1}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateSet('Agent', 'Agent Procedures', 'Anti-Malware', 'Antivirus', 'AuthAnvil', 'Backup', 'Cloud Backup', `
                        'Data Backup', 'Desktop Management: Migration', 'Desktop Management: Policy', 'Discovery', `
                        'Kaseya System Patch', 'Mobility', 'Network Monitoring', 'Patch Management', 'Policy', `
                        'Service Billing', 'Service Desk', 'Software Deployment', 'Software Management', `
                        'System Backup and Recovery', 'Time Tracking', 'vPro Management', 'Web Service API')]
        [string] $ModuleName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateSet(9, 3, 97, 95, 115, 12, 54, 34, 29, 30, 70, 0, 50, 47, 6, 44, 42, 18, 53, 60, 64, 41, 85, 57)]
        [int] $ModuleId,

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
        # $TenantModuleIdMap is a module-scope map shared with Enable-VSATenantModule (F-53).
        if ( -not [string]::IsNullOrEmpty($ModuleName)) {
            $ModuleId = $TenantModuleIdMap[$ModuleName]
        }
    }# Begin
    Process {

        return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $TenantId, $ModuleId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }#Process
}

Export-ModuleMember -Function Remove-VSATenantModule