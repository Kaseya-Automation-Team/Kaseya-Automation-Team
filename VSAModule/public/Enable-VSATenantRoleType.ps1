function Enable-VSATenantRoleType {
    <#
    .Synopsis
       Activates selected roletypes for the tenant specified.
    .DESCRIPTION
       Activates selected roletypes for the tenant specified.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition.
    .PARAMETER RoleType
        Array of role types by name to be activated.
    .PARAMETER RoleTypeId
        Array of role types by Id to be activated.
    .EXAMPLE
       Enable-VSATenantRoleType -TenantId 10001 -RoleType 'SB Admin', 'KDP Admin'
    .EXAMPLE
       Enable-VSATenantRoleType -TenantId 10001 -RoleTypeId 105, 106
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
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
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
        [string[]] $RoleType,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
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
        [int[]] $RoleTypeId,

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
        # Resolve role-type names to Ids from the live VSA (F-64): role types are instance-specific
        # -- beyond the built-ins, an instance can carry custom and multi-tenant role types (e.g.
        # 'Multi-Tenant', 'Multi-Tenant Admin') with instance-specific Ids -- so the former hardcoded
        # name->id map (and its ValidateSet) went stale and could not target them. A single targeted
        # Get-VSARoleType call resolves each name (F-44: no network calls during parameter/command
        # discovery; this runs only when the cmdlet actually executes).
        if ( $PSCmdlet.ParameterSetName -eq 'ByName' ) {
            [hashtable]$LookupParams = @{}
            if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
            [array]$Roles = Get-VSARoleType @LookupParams | Select-Object RoleTypeId, RoleTypeName
            [array] $ResolvedRoleTypeId = foreach ($name in $RoleType) {
                $id = $Roles | Where-Object { $_.RoleTypeName -eq $name } | Select-Object -First 1 -ExpandProperty RoleTypeId
                if ([string]::IsNullOrEmpty("$id")) {
                    throw "Enable-VSATenantRoleType: No role type found with name '$name' on this VSA. Available: $(($Roles.RoleTypeName | Sort-Object) -join ', ')."
                }
                [int]$id
            }
        } else {
            [array] $ResolvedRoleTypeId = $RoleTypeId
        }

        $Body = ConvertTo-Json $ResolvedRoleTypeId -Depth 5 -Compress
    }# Begin
    Process {

        return Invoke-VSAWriteRequest -Body ($Body) -Method 'PUT' -URISuffix ($($URISuffix -f $TenantId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }#Process
}

Export-ModuleMember -Function Enable-VSATenantRoleType