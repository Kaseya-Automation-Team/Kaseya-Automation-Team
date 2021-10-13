function Activate-VSATenantModule {
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
    .PARAMETER Modules
        Array of modules to be activated.
    .EXAMPLE
       Activate-VSATenantModule -TenantId 10001 -Modules 'Agent', 'Kaseya System Patch'
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

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/modules/{0}',

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [decimal] $TenantId,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Agent',  'Agent Procedures',  'Anti-Malware',  'Antivirus',  'AuthAnvil',  'Backup',  'Cloud Backup',  `
                        'Data Backup',  'Desktop Management: Migration',  'Desktop Management: Policy',  'Discovery',  `
                        'Kaseya System Patch',  'Mobility',  'Network Monitoring',  'Patch Management',  'Policy',  'Service Billing',  `
                        'Service Desk',  'Software Deployment',  'Software Management',  'System Backup and Recovery',  'Time Tracking',  `
                        'vPro Management',  'Web Service API')]
        [string[]] $Modules
    )
    $URISuffix = $URISuffix -f $TenantId

    [hashtable] $TenantModues = @{
        'Agent'							= 9
        'Agent Procedures'				= 3
        'Anti-Malware'					= 97
        'Antivirus'						= 95
        'AuthAnvil'						= 115
        'Backup'						= 12
        'Cloud Backup'					= 54
        'Data Backup'					= 34
        'Desktop Management: Migration' = 29
        'Desktop Management: Policy'	= 30
        'Discovery'						= 70
        'Kaseya System Patch'			= 0
        'Mobility'						= 50
        'Network Monitoring'			= 47
        'Patch Management'				= 6
        'Policy'						= 44
        'Service Billing'				= 42
        'Service Desk'					= 18
        'Software Deployment'			= 53
        'Software Management'			= 60
        'System Backup and Recovery'	= 64
        'Time Tracking'					= 41
        'vPro Management'				= 85
        'Web Service API'				= 57
    }
    
    $Body = ConvertTo-Json $TenantModues[$Modules]

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method    = 'PUT'
        Body      = $Body
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Activate-VSATenantModule