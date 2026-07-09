function Clear-VSATenantRoleType {
    <#
    .Synopsis
       Removes a roletype from a tenant partition.
    .DESCRIPTION
       Removes a roletype from a tenant partition.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition.
    .PARAMETER TenantName
        Specifies a tenant partition.
    .PARAMETER RoleTypeName
        Role Type name to be removed.
    .PARAMETER RoleTypeId
        Role Type Id to be removed.
    .EXAMPLE
       Clear-VSATenantRoleType -TenantName 'YourTenant' -Module 'Agent'
    .EXAMPLE
       Clear-VSATenantRoleType -TenantId 1001 -RoleTypeId 6
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/{0}?roleTypeId={1}',

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ByName')]
        [ValidateSet('VSA Admin', 'End User', 'Basic Machine', 'Service Desk Admin', 'Service Desk Technician', 'SB Admin', 'KDP Admin', 'KDM Admin')]
        [string] $RoleTypeName,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ById')]
        [ValidateSet(4, 6, 8, 100, 101, 105, 116, 117)]
        [int] $RoleTypeId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSATenants @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty Ref |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { }
        })]
        [ValidateNotNullOrEmpty()]
        [string] $TenantName,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ById')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSATenants @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty Id |
                    Where-Object { "$_" -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { }
        })]
        [ValidateNotNullOrEmpty()]
        [string] $TenantId
    )
    Begin {
        # A single targeted call resolves TenantName<->TenantId (F-44: no network calls during
        # parameter/command discovery; this only runs when the cmdlet actually executes).
        [hashtable]$LookupParams = @{}
        if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
        [array]$Tenants = Get-VSATenants @LookupParams | Select-Object Id, Ref

        if (-not $TenantId) {
            $TenantId = $Tenants | Where-Object { $_.Ref -eq $TenantName } | Select-Object -First 1 -ExpandProperty Id
            if ([string]::IsNullOrEmpty($TenantId)) {
                throw "Clear-VSATenantRoleType: No tenant found with name '$TenantName'."
            }
        }
        if (-not $TenantName) {
            $TenantName = $Tenants | Where-Object { $_.Id -eq $TenantId } | Select-Object -First 1 -ExpandProperty Ref
        }
        # $TenantRoleTypeIdMap is a module-scope map shared with Enable-VSATenantRoleType (F-53).
        if ($RoleTypeName) {
            $RoleTypeId = $TenantRoleTypeIdMap[$RoleTypeName]
        }
    }
    Process {
        return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $TenantId, $RoleTypeId)) -VSAConnection $VSAConnection
    }
}
Export-ModuleMember -Function Clear-VSATenantRoleType