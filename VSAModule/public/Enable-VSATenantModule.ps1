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
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
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
        if ( 0 -eq $ModuleId.Count) {
                [hashtable] $TenantModules = @{
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
    
            $Body = ConvertTo-Json $TenantModules[$ModuleName] -Depth 5 -Compress
        } else {
            $Body = ConvertTo-Json $ModuleId -Depth 5 -Compress
        }
    }# Begin
    Process {
        [hashtable]$Params =@{
            URISuffix = $($URISuffix -f $TenantId)
            Method    = 'PUT'
            Body      = $Body
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        
        #region messages to verbose and debug streams
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            "Enable-VSATenantModule: $($Params | Out-String)" | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            "Enable-VSATenantModule: $($Params | Out-String)" | Write-Verbose
        }
        #endregion messages to verbose and debug streams

        return Invoke-VSARestMethod @Params
    }#Process
}

Export-ModuleMember -Function Enable-VSATenantModule