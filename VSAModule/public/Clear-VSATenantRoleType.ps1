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

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/{0}?roleTypeId={1}',

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSARoleType @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty RoleTypeName |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new("'$_'", $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [ValidateNotNullOrEmpty()]
        [string] $RoleTypeName,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ById')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSARoleType @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty RoleTypeId |
                    Where-Object { "$_" -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleTypeId,

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
            } catch { Write-Debug "Argument completer suppressed error: $_" }
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
            } catch { Write-Debug "Argument completer suppressed error: $_" }
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
            # Resolve into a LOCAL first: assigning an unresolved (empty) value straight to $TenantId
            # re-triggers that parameter's validator, which masks the accurate message below (F-4).
            $ResolvedTenantId = $Tenants | Where-Object { $_.Ref -eq $TenantName } | Select-Object -First 1 -ExpandProperty Id
            if ([string]::IsNullOrEmpty($ResolvedTenantId)) {
                throw "Clear-VSATenantRoleType: No tenant found with name '$TenantName'."
            }
            $TenantId = $ResolvedTenantId
        }
        if (-not $TenantName) {
            $TenantName = $Tenants | Where-Object { $_.Id -eq $TenantId } | Select-Object -First 1 -ExpandProperty Ref
        }
        # Resolve the role-type name to its Id from the live VSA (F-64): role types are
        # instance-specific, so the former hardcoded name->id map went stale. Reuse the roles fetched
        # for the tenant lookup is not possible (different endpoint), so make one targeted call.
        if ($RoleTypeName) {
            [hashtable]$RoleLookupParams = @{}
            if ($VSAConnection) { $RoleLookupParams['VSAConnection'] = $VSAConnection }
            $ResolvedRoleTypeId = Get-VSARoleType @RoleLookupParams | Where-Object { $_.RoleTypeName -eq $RoleTypeName } | Select-Object -First 1 -ExpandProperty RoleTypeId
            if ([string]::IsNullOrEmpty("$ResolvedRoleTypeId")) {
                throw "Clear-VSATenantRoleType: No role type found with name '$RoleTypeName' on this VSA."
            }
            $RoleTypeId = $ResolvedRoleTypeId
        }
    }
    Process {
        return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $TenantId, $RoleTypeId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Clear-VSATenantRoleType