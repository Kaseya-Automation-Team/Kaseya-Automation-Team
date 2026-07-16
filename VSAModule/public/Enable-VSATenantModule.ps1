function Enable-VSATenantModule {
    <#
    .Synopsis
       Activates selected modules for a specified tenant.
    .DESCRIPTION
       Activates selected modules for a specified tenant.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition.
    .PARAMETER ModuleName
        Array of modules by name to be activated.
    .PARAMETER ModuleId
        Array of modules by Id to be activated.
    .EXAMPLE
       Enable-VSATenantModule -TenantId 10001 -ModuleName 'Agent', 'Kaseya System Patch'
    .EXAMPLE
       Enable-VSATenantModule -TenantId 10001 -ModuleId 0, 95
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if successful.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
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
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/modules/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateSet('Agent', 'Agent Procedures', 'Anti-Malware', 'Antivirus', 'AuthAnvil', 'Backup', 'Cloud Backup', `
                        'Data Backup', 'Desktop Management: Migration', 'Desktop Management: Policy', 'Discovery', `
                        'Kaseya System Patch', 'Mobility', 'Network Monitoring', 'Patch Management', 'Policy', `
                        'Service Billing', 'Service Desk', 'Software Deployment', 'Software Management', `
                        'System Backup and Recovery', 'Time Tracking', 'vPro Management', 'Web Service API')]
        [string[]] $ModuleName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateSet(9, 3, 97, 95, 115, 12, 54, 34, 29, 30, 70, 0, 50, 47, 6, 44, 42, 18, 53, 60, 64, 41, 85, 57)]
        [int[]] $ModuleId,

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
        # $TenantModuleIdMap is a module-scope map shared with Remove-VSATenantModule (F-53).
        if ( 0 -eq $ModuleId.Count) {
            # F-35-style bug: indexing a hashtable with the whole [string[]] $ModuleName array as
            # a single key would never match; resolve each name individually instead.
            [array] $ResolvedModuleId = $ModuleName | ForEach-Object { $TenantModuleIdMap[$_] }
            $Body = ConvertTo-Json $ResolvedModuleId -Depth 5 -Compress
        } else {
            $Body = ConvertTo-Json $ModuleId -Depth 5 -Compress
        }
    }# Begin
    Process {
        return Invoke-VSAWriteRequest -Body ($Body) -Method 'PUT' -URISuffix ($($URISuffix -f $TenantId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }#Process
}

Export-ModuleMember -Function Enable-VSATenantModule