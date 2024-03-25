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
       Set-VSATenantModuleUsageType -TenantId 10001 -ModuleName 'Anti-Malware' -UsageType 1
    .EXAMPLE
       Set-VSATenantModuleUsageType -TenantName 'Your Tenant' -ModuleId 20002 -UsageType 1
    .INPUTS
       Accepts piped non-Tenant VSAConnection 
    .OUTPUTS
       Array of tof module licenses
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
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
            ParameterSetName = 'ByName')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $ModuleId,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $UsageType
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
        <#
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
        #>
        if ( -not [string]::IsNullOrEmpty($TenantId) ) {
            $AuxParameters.Add('TenantId', $TenantId)
            [array]$script:Modules = Get-VSATenantModuleLicenses @AuxParameters

            $ParameterName = 'ModuleName' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.ParameterSetName = 'ById'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:Modules | Select-Object -ExpandProperty Name
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        }

        return $RuntimeParameterDictionary
    }# DynamicParam
    Begin {
            if ( -not [string]::IsNullOrEmpty($TenantId) ) {
                $ModuleId = $script:Modules | Where-Object {$_.Name -eq $PSBoundParameters.ModuleName} | Select-Object -ExpandProperty ModuleId 
            }

            if ( [string]::IsNullOrEmpty($TenantId)  ) {
                $TenantId = $script:Tenants | Where-Object { $_.Ref -eq $PSBoundParameters.TenantName } | Select-Object -ExpandProperty Id
                $TenantName = $PSBoundParameters.TenantName
            }
            if ( [string]::IsNullOrEmpty($TenantName)  ) {
                $TenantName = $script:Tenants | Where-Object { $_.Id -eq $PSBoundParameters.TenantId } | Select-Object -ExpandProperty Ref
                $TenantId = $PSBoundParameters.TenantId
            }
            
    } # Begin 
     Process {
        $URISuffix = $URISuffix -f $TenantId, $ModuleId, $UsageType

        [string]$Body

        [hashtable]$Params =@{
            URISuffix = $URISuffix
            Method    = 'PUT'
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        
        $Params | Out-String | Write-Debug

        return Update-VSAItems @Params
    }#Process
}
Export-ModuleMember -Function Set-VSATenantModuleUsageType