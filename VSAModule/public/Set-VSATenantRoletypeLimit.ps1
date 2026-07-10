function Set-VSATenantRoletypeLimit {
    <#
    .Synopsis
       Sets the maximum number of users allowed for a given role type within the tenant partition.
    .DESCRIPTION
       Sets the maximum number of users allowed for a given role type within the tenant partition.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition by Id.
    .PARAMETER TenantName
        Specifies a tenant partition by name.
    .PARAMETER RoleTypeName
        Specifies a role type by name.
    .PARAMETER RoleTypeId
        Specifies a role type by Id.
    .PARAMETER Limit
        Number of users.
    .EXAMPLE
       Set-VSATenantRoletypeLimit -Limit 1 -RoleTypeId 2 -TenantId 10001
    .EXAMPLE
       Set-VSATenantRoletypeLimit -Limit 1 -RoleTypeName 'KDM Admin' -TenantName 'YourTenantName'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ById')]
    param ( 
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/limits/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric"
            }
            return $true
        })]
        [string] $Limit,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName = 'ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSARoleTypes @CompleterParams -ErrorAction Stop |
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
                Get-VSARoleTypes @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty RoleTypeId |
                    Where-Object { "$_" -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [ValidateNotNullOrEmpty()]
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
        # Single targeted calls resolve RoleType/Tenant Name<->Id (F-44: no network calls during
        # parameter/command discovery; this only runs when the cmdlet actually executes).
        [hashtable]$LookupParams = @{}
        if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
        [array]$Roles = Get-VSARoleTypes @LookupParams | Select-Object RoleTypeId, RoleTypeName
        [array]$Tenants = Get-VSATenants @LookupParams | Select-Object Id, Ref

        if ( [string]::IsNullOrEmpty($RoleTypeId) ) {
            $RoleTypeId = $Roles | Where-Object { $_.RoleTypeName -eq $RoleTypeName } | Select-Object -First 1 -ExpandProperty RoleTypeId
            if ([string]::IsNullOrEmpty($RoleTypeId)) { throw "Set-VSATenantRoletypeLimit: No role type found with name '$RoleTypeName'." }
        }
        if ( [string]::IsNullOrEmpty($RoleTypeName) ) {
            $RoleTypeName = $Roles | Where-Object { $_.RoleTypeId -eq $RoleTypeId } | Select-Object -First 1 -ExpandProperty RoleTypeName
        }
        if ( [string]::IsNullOrEmpty($TenantId)  ) {
            $TenantId = $Tenants | Where-Object { $_.Ref -eq $TenantName } | Select-Object -First 1 -ExpandProperty Id
            if ([string]::IsNullOrEmpty($TenantId)) { throw "Set-VSATenantRoletypeLimit: No tenant found with name '$TenantName'." }
        }
        if ( [string]::IsNullOrEmpty($TenantName)  ) {
            $TenantName = $Tenants | Where-Object { $_.Id -eq $TenantId } | Select-Object -First 1 -ExpandProperty Ref
        }
    }# Begin
    Process {

        $URISuffix = $URISuffix -f $TenantId
        [string] $Body = ConvertTo-Json @(
            @{
                RoleName = $RoleTypeName
                RoleType = $RoleTypeId
                Limit    = $Limit
            }
        )

        return Invoke-VSAWriteRequest -Body ($Body) -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }#Process
}

Export-ModuleMember -Function Set-VSATenantRoletypeLimit