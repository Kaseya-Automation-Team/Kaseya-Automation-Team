function Set-VSATenantModuleLicense {
    <#
    .Synopsis
       Updates a selected license within a specified tenant.
    .DESCRIPTION
       Updates a selected license within a specified tenant. Typically, only the Limit field is updated.
       Takes either Tenant or non-Tenant connection information.
    .PARAMETER VSAConnection
        Specifies existing non-Tenant VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies Tenant Id.
    .PARAMETER TenantName
        Specifies Tenant Name.
    .PARAMETER DataType
        Specifies the data type for the limit. 
    .PARAMETER Limit
        Specifies License Limit.
    .PARAMETER Name
        Specifies module name.
    .PARAMETER zzValId
        Specifies License Id.
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

    [CmdletBinding(DefaultParameterSetName = 'ById')]
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
            } catch { }
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

        [parameter(Mandatory = $true, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $zzValId,

        [parameter(Mandatory = $true, ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
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
            } catch { }
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
            $TenantId = $Tenants | Where-Object { $_.Ref -eq $TenantName } | Select-Object -First 1 -ExpandProperty Id
            if ( [string]::IsNullOrEmpty($TenantId) ) {
                throw "Set-VSATenantModuleLicense: No tenant found with name '$TenantName'."
            }
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
        

        return Invoke-VSAWriteRequest -Body ($Body) -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection
    }#Process
}
New-Alias -Name Set-VSATenantModuleLicenses -Value Set-VSATenantModuleLicense
Export-ModuleMember -Function Set-VSATenantModuleLicense -Alias Set-VSATenantModuleLicenses