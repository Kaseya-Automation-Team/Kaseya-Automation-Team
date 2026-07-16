function Set-VSATenantModuleLicense {
    <#
    .Synopsis
       Updates a selected license within a specified tenant.
    .DESCRIPTION
       Updates a selected license within a specified tenant. Typically, only the Limit field is updated.
       Takes either Tenant or non-Tenant connection information.

       This cmdlet has two parameter sets, which differ in BOTH how the tenant is identified and how
       the license is selected:

         ById   : -TenantId   + -LicenseName + -zzVal   + -Limit + -LicenseType
                  Looks the named license up on the tenant and updates its Limit in place.
         ByName : -TenantName + -zzValId     + -Limit + -LicenseType
                  Resolves the tenant name to its Id, then writes a license record built from the
                  supplied values.

       NAMING NOTE: 'zzValId' and 'zzVal' are not placeholder names. They are the VSA REST API's own
       request-body field names for this endpoint and are transmitted verbatim, so they are kept as-is
       to stay greppable against the Kaseya API documentation. The friendlier aliases -LicenseValueId
       and -LicenseValue are accepted for readability.
    .PARAMETER VSAConnection
        Specifies existing non-Tenant VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies Tenant Id. Belongs to the ById parameter set.
    .PARAMETER TenantName
        Specifies Tenant Name. Belongs to the ByName parameter set; resolved to a Tenant Id at runtime.
    .PARAMETER DataType
        Specifies the data type for the limit.
    .PARAMETER Limit
        Specifies License Limit. Required by both parameter sets.
    .PARAMETER Name
        Specifies module name.
    .PARAMETER zzValId
        Specifies License Id (the API's 'zzValId' body field). Required by the ByName parameter set.
        Also accepted as -LicenseValueId.
    .PARAMETER zzVal
        Specifies the license value (the API's 'zzVal' body field). Required by the ById parameter set.
        When omitted on the ByName path it defaults to "zzvals<zzValId>". Also accepted as -LicenseValue.
    .PARAMETER LicenseType
        Specifies the license type id. Required by both parameter sets.
    .PARAMETER LicenseName
        Specifies the name of the existing license to update. Required by the ById parameter set, and
        tab-completes from the licenses already present on the given -TenantId.
    .PARAMETER StringValue
        Specifies String Value.
    .PARAMETER DateValue
        Specifies Date.
    .EXAMPLE
       Set-VSATenantModuleLicense -TenantId 10001 -Name 'MalwareBytes Anti-Malware' -Limit 1000000000000
    .EXAMPLE
       Set-VSATenantModuleLicense -TenantName 'Your Tenant' -zzValId 1600000000000 -LicenseType 900000000000 -Limit 2000000000000
    .INPUTS
       Accepts piped non-Tenant VSAConnection.
    .OUTPUTS
       Array of module licenses.
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ById')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/modules/licenses/{0}',

        [parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId,

        [parameter(Mandatory = $true, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName = $true)]
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

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $DataType,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # 'zzValId' / 'zzVal' mirror the VSA API's own request-body field names (they are sent verbatim
        # in Process), so they are kept as the primary names to stay greppable against the Kaseya API
        # docs. The aliases below give callers a readable alternative without diverging from the API.
        [parameter(Mandatory = $true, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName = $true)]
        [Alias('LicenseValueId')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $zzValId,

        [parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [Alias('LicenseValue')]
        [ValidateNotNullOrEmpty()]
        [string] $zzVal,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $Limit,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $LicenseType,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $StringValue,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DateValue,

        # ById selector for an existing license. This was a DynamicParam that eagerly called
        # Get-VSATenantModuleLicense on every tab-completion / Get-Command (F-44 / A-2). It is now a
        # static parameter with a lazy completer that uses the already-typed -TenantId; the actual
        # license fetch happens in Begin.
        [parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                if ($fakeBoundParameters['TenantId'])      { $CompleterParams['TenantId']      = $fakeBoundParameters['TenantId'] }
                Get-VSATenantModuleLicense @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty ModuleLicenses |
                    Select-Object -ExpandProperty Name |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [ValidateNotNullOrEmpty()]
        [string] $LicenseName
    )

    Begin {
        # Name<->Id resolution moved out of the former DynamicParam so no REST call fires during
        # parameter/command discovery (F-44 / A-2). Process is unchanged and still reads
        # $Licenses (populated here only for the ById set).
        [hashtable] $AuxParameters = @{ErrorAction = 'Stop'}
        if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

        [array] $Licenses = @()

        if ( $PSCmdlet.ParameterSetName -eq 'ByName' ) {
            $Tenants  = Get-VSATenant @AuxParameters | Select-Object Id, Ref
            # Resolve into a LOCAL first: assigning an unresolved (empty) value straight to $TenantId
            # re-triggers that parameter's ValidateScript, which throws its own "Non-numeric Id" and
            # masks the accurate "No tenant found" message below (F-4).
            $ResolvedTenantId = $Tenants | Where-Object { $_.Ref -eq $TenantName } | Select-Object -First 1 -ExpandProperty Id
            if ( [string]::IsNullOrEmpty($ResolvedTenantId) ) {
                throw "Set-VSATenantModuleLicense: No tenant found with name '$TenantName'."
            }
            $TenantId = $ResolvedTenantId
        } else {
            $AuxParameters['TenantId'] = $TenantId
            [array] $Licenses = Get-VSATenantModuleLicense @AuxParameters |
                Select-Object -ExpandProperty ModuleLicenses |
                Where-Object { $_.Name -eq $LicenseName }
        }
    } # Begin
     Process {
        $URISuffix = $URISuffix -f $TenantId

        if ( 0 -lt $Licenses.Count ) {
            $Licenses[0].Limit = $Limit
            [string] $Body = $Licenses | ConvertTo-Json
        } else {

            if ( [string]::IsNullOrEmpty($zzVal))    { $zzVal = "zzvals$zzValId" }

            [string] $Body = @( [PSCustomObject]@{

                zzValId     = $zzValId
                LicenseType = $LicenseType
                Limit       = $Limit
                zzVal       = $zzVal
                StringValue = $StringValue
                DateValue   = $DateValue
                DataType    = $DataType
                Name        = $Name
            } | Where-Object { $_.Value } ) | ConvertTo-Json
        }

        Write-Debug "Set-VSATenantModuleLicense. $($Body | Out-String)"

        return Invoke-VSAWriteRequest -Body ($Body) -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }#Process
}
New-Alias -Name Set-VSATenantModuleLicenses -Value Set-VSATenantModuleLicense
Export-ModuleMember -Function Set-VSATenantModuleLicense -Alias Set-VSATenantModuleLicenses