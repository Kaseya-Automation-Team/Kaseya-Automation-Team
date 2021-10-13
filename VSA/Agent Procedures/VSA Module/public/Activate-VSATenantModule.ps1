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
    .PARAMETER TenantName
        Specifies a tenant partition.
    .PARAMETER Modules
        Array of modules by name to be activated.
    .PARAMETER ModuleIds
        Array of modules by Id to be activated.
    .EXAMPLE
       Activate-VSATenantModule -TenantName 'YourTenant' -Modules 'Agent', 'Kaseya System Patch'
    .EXAMPLE
       Activate-VSATenantModule -TenantId 1001 -ModuleIds 0, 95
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
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/modules/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateSet('Agent',  'Agent Procedures',  'Anti-Malware',  'Antivirus',  'AuthAnvil',  'Backup',  'Cloud Backup',  `
                        'Data Backup',  'Desktop Management: Migration',  'Desktop Management: Policy',  'Discovery',  `
                        'Kaseya System Patch',  'Mobility',  'Network Monitoring',  'Patch Management',  'Policy',  'Service Billing',  `
                        'Service Desk',  'Software Deployment',  'Software Management',  'System Backup and Recovery',  'Time Tracking',  `
                        'vPro Management',  'Web Service API')]
        [string[]] $Modules,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateSet(9,  3,  97,  95,  115,  12,  54,  34,  29,  30,  70,  0,  50,  47,  6,  44,  42,  18,  53,  60,  64,  41,  85,  57)]
        [int[]] $ModuleIds
    )
    DynamicParam {

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
        [hashtable] $AuxParameters = @{}
        if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

        [array] $script:Tenants = try {Get-VSATenants @AuxParameters -ErrorAction Stop | Select-Object Id, Ref } catch { Write-Error $_ }

        $ParameterName = 'TenantName' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ByName'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Tenants | Select-Object -ExpandProperty Ref # | ForEach-Object {Write-Output "'$_'"}
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        $ParameterName = 'TenantId' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ById'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Tenants | Select-Object -ExpandProperty Id
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }# DynamicParam
    Begin {
        if ( [string]::IsNullOrEmpty($TenantId)  ) {
            $TenantId = $script:Tenants | Where-Object { $_.Ref -eq $PSBoundParameters.TenantName } | Select-Object -ExpandProperty Id
            $TenantName = $PSBoundParameters.TenantName
        }
        if ( [string]::IsNullOrEmpty($TenantName)  ) {
            $TenantName = $script:Tenants | Where-Object { $_.Id -eq $PSBoundParameters.TenantId } | Select-Object -ExpandProperty Ref
            $TenantId = $PSBoundParameters.TenantId
        }
        if ( 0 -eq $ModuleIds.Count) {
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
        } else {
            $Body = ConvertTo-Json $ModuleIds
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

Export-ModuleMember -Function Activate-VSATenantModule