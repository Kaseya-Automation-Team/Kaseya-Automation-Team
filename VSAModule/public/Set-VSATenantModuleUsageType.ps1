function Set-VSATenantModuleUsageType {
    <#
    .Synopsis
       Sets the usage type for a module in a tenant ID. A usage type, if available for a module, enables a specialized feature in a module.
    .DESCRIPTION
       USets the usage type for a module in a tenant ID. A usage type, if available for a module, enables a specialized feature in a module.
       Takes either Tenant or non-Tenant connection information.
    .PARAMETER VSAConnection
        Specifies existing non-Tenant VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies Tenant Id.
    .PARAMETER TenantName
        Specifies Tenant Name.
    .PARAMETER ModuleId
        Specifies module Id
    .PARAMETER ModuleName
        Specifies module name
    .PARAMETER UsageType
        Specifies a usage type
    .EXAMPLE
       Set-VSATenantModuleUsageType -TenantId 10001 -ModuleId 20002 -UsageType 1
    .EXAMPLE
       Set-VSATenantModuleUsageType -TenantName 'Your Tenant' -ModuleName 'Anti-Malware' -UsageType 1
    .INPUTS
       Accepts piped non-Tenant VSAConnection
    .OUTPUTS
       Array of tof module licenses
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ById')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/modules/usagetype/{0}?moduleId={1}&usageType={2}',

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId,

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $ModuleId,

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $UsageType,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSATenant @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty Ref |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [ValidateNotNullOrEmpty()]
        [string] $TenantName,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                if ($fakeBoundParameters['TenantId']) { $CompleterParams['TenantId'] = $fakeBoundParameters['TenantId'] }
                Get-VSATenantModuleLicense @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty Name |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [ValidateNotNullOrEmpty()]
        [string] $ModuleName
    )
    Begin {
        # Single targeted calls resolve Tenant/Module Name<->Id (F-44: no network calls during
        # parameter/command discovery; this only runs when the cmdlet actually executes).
        [hashtable]$LookupParams = @{}
        if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
        [array]$Tenants = Get-VSATenant @LookupParams | Select-Object Id, Ref

        if ( [string]::IsNullOrEmpty($TenantId)  ) {
            $TenantId = $Tenants | Where-Object { $_.Ref -eq $TenantName } | Select-Object -First 1 -ExpandProperty Id
            if ([string]::IsNullOrEmpty($TenantId)) { throw "Set-VSATenantModuleUsageType: No tenant found with name '$TenantName'." }
        }
        if ( [string]::IsNullOrEmpty($TenantName)  ) {
            $TenantName = $Tenants | Where-Object { $_.Id -eq $TenantId } | Select-Object -First 1 -ExpandProperty Ref
        }

        if ( -not [string]::IsNullOrEmpty($ModuleName) ) {
            [hashtable]$ModuleLookupParams = $LookupParams.Clone()
            $ModuleLookupParams['TenantId'] = $TenantId
            [array]$Modules = Get-VSATenantModuleLicense @ModuleLookupParams
            $ModuleId = $Modules | Where-Object { $_.Name -eq $ModuleName } | Select-Object -First 1 -ExpandProperty ModuleId
            if ([string]::IsNullOrEmpty($ModuleId)) { throw "Set-VSATenantModuleUsageType: No module found with name '$ModuleName' for tenant '$TenantName'." }
        }
    } # Begin
     Process {
        $URISuffix = $URISuffix -f $TenantId, $ModuleId, $UsageType

        return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }#Process
}
Export-ModuleMember -Function Set-VSATenantModuleUsageType