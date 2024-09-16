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

        [parameter(DontShow, Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/{0}?roleTypeId={1}',

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ByName')]
        [ValidateSet('VSA Admin', 'End User', 'Basic Machine', 'Service Desk Admin', 'Service Desk Technician', 'SB Admin', 'KDP Admin', 'KDM Admin')]
        [string] $RoleTypeName,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ById')]
        [ValidateSet(4, 6, 8, 100, 101, 105, 116, 117)]
        [int] $RoleTypeId
    )
    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        [array] $script:Tenants = try {
            Get-VSATenants -VSAConnection $VSAConnection -ErrorAction Stop | Select-Object Id, Ref 
        } catch {
            Write-Error $_
        }

        foreach ($param in @('TenantName', 'TenantId')) {
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.ParameterSetName = if ($param -eq 'TenantName') { 'ByName' } else { 'ById' }
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $AttributesCollection.Add($ParameterAttribute)
            $ValidateSet = $script:Tenants | Select-Object -ExpandProperty $(if ($param -eq 'TenantName') { 'Ref' } else { 'Id' })
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($param, [string], $AttributesCollection)
            $RuntimeParameterDictionary.Add($param, $RuntimeParameter)
        }

        return $RuntimeParameterDictionary
    }
    Begin {
        if (-not $TenantId) {
            $TenantId = $script:Tenants | Where-Object { $_.Ref -eq $PSBoundParameters.TenantName } | Select-Object -ExpandProperty Id
            $TenantName = $PSBoundParameters.TenantName
        }
        if (-not $TenantName) {
            $TenantName = $script:Tenants | Where-Object { $_.Id -eq $PSBoundParameters.TenantId } | Select-Object -ExpandProperty Ref
            $TenantId = $PSBoundParameters.TenantId
        }
        if ($RoleTypeName) {
            $RoleTypeId = @{
                'VSA Admin' = 4
                'End User' = 6
                'Basic Machine' = 8
                'Service Desk Admin' = 100
                'Service Desk Technician' = 101
                'SB Admin' = 105
                'KDP Admin' = 116
                'KDM Admin' = 117
            }[$RoleTypeName]
        }
    }
    Process {
        $Params = @{
            URISuffix = $($URISuffix -f $TenantId, $RoleTypeId)
            Method    = 'DELETE'
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        #region messages to verbose and debug streams
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            "Clear-VSATenantRoleType: $($Params | Out-String)" | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            "Clear-VSATenantRoleType: $($Params | Out-String)" | Write-Verbose
        }
        #endregion messages to verbose and debug streams

        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Clear-VSATenantRoleType