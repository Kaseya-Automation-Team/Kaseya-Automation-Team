function Disable-VSATenant
{
    <#
    .Synopsis
       Deactivates a tenant partition instead of deleting it.
    .DESCRIPTION
       Deactivates a tenant partition instead of deleting it.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantName
        Specifies the Tenant Name.
    .PARAMETER TenantId
        Specifies the Tenant Id.
    .EXAMPLE
       Disable-VSATenant -TenantName 'TenantToDeactivate'
    .EXAMPLE
       Disable-VSATenant -TenantId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'ByName')]
        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/deactivate?tenantId={0}',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId,

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'ByName')]
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
        [string] $TenantName
    )
    Begin {
        # A single targeted call resolves TenantName to TenantId (F-44: no network calls during
        # parameter/command discovery; this only runs when the cmdlet actually executes).
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            [hashtable]$LookupParams = @{}
            if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
            [array]$RoleTenants = Get-VSATenants @LookupParams | Select-Object Id, @{N = 'TenantName'; E={$_.Ref}}
            # Resolve into a LOCAL first: assigning an unresolved (empty) value straight to $TenantId
            # re-triggers that parameter's ValidateScript, whose "Non-numeric Id" masks the accurate
            # message below (F-4).
            $ResolvedTenantId = $RoleTenants | Where-Object { $_.TenantName -eq $TenantName } | Select-Object -First 1 -ExpandProperty Id
            if ([string]::IsNullOrEmpty($ResolvedTenantId)) {
                throw "Disable-VSATenant: No tenant found with name '$TenantName'."
            }
            $TenantId = $ResolvedTenantId
        }
    }# Begin
    Process {

        return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $TenantId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Disable-VSATenant