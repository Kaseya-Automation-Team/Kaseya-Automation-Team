function Set-VSATenantModuleLicenses {
    <#
    .Synopsis
       Updates a selected license within a specified tenant.
    .DESCRIPTION
       Updates a selected license within a specified tenant. Typically only the Limit field is updated.
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
        Specifiels data type for the limit
    .PARAMETER Limit
        Specifies Lincense Limit.
    .PARAMETER Name
        Specifies module name
    .PARAMETER zzValId
        Specifies License Id
    .PARAMETER StringValue
        Specifies String Value
    .PARAMETER DateValue
        Specifies Date
    .EXAMPLE
       Set-VSATenantModuleLicenses -TenantId 10001 -LicenseName 'MalwareBytes Anti-Malware' -Limit 1
    .EXAMPLE
       Set-VSATenantModuleLicenses -TenantName 'Your Tenant' -zzValId 160 -LicenseType 9 -Limit 2
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
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/modules/licenses/{0}',

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

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })] $DataType,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [string] $Name,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [int] $zzValId,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $Limit,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $LicenseType,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()] 
        [string] $zzVal,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $StringValue,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $DateValue
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
            [array]$Script:Licenses = Get-VSATenantModuleLicenses @AuxParameters | Select-Object -ExpandProperty ModuleLicenses

            $ParameterName = 'LicenseName' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.ParameterSetName = 'ById'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $Script:Licenses | Select-Object -ExpandProperty Name
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        }

        return $RuntimeParameterDictionary
    }# DynamicParam
    Begin {
            if ( -not [string]::IsNullOrEmpty($TenantId) ) {
                $Script:Licenses = $Script:Licenses | Where-Object {$_.Name -eq $PSBoundParameters.LicenseName}
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
        $URISuffix = $URISuffix -f $TenantId

        [string]$Body

        if ( 0 -lt $Script:Licenses.Count ) {
            $Script:Licenses[0].Limit = [decimal]$Limit
            $Body = ConvertTo-Json $Script:Licenses
        } else {

            if ( [string]::IsNullOrEmpty($zzVal))    { $zzVal = "zzvals$zzValId" }

            $BodyHT = @([ordered]@{
                
                zzValId     = $zzValId
                LicenseType = $LicenseType
                Limit       = [decimal]$Limit
                zzVal       = $zzVal
            })
            if ( -not [string]::IsNullOrEmpty($StringValue))    {$BodyHT.Add('StringValue', $StringValue) }
            if ( -not [string]::IsNullOrEmpty($DateValue))      {$BodyHT.Add('DateValue', $DateValue) }
            if ( -not [string]::IsNullOrEmpty($LicenseType))    {$BodyHT.Add('LicenseType', [int]$LicenseType) }
            if ( -not [string]::IsNullOrEmpty($DataType))       {$BodyHT.Add('DataType', [int]$DataType) }
            if ( -not [string]::IsNullOrEmpty($Name))           {$BodyHT.Add('Name', $Name) }

            $Body = ConvertTo-Json $BodyHT
        }

        $Body | Write-Debug

        [hashtable]$Params =@{
            URISuffix = $URISuffix
            Method    = 'PUT'
            Body      = $Body
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        
        $Params | Out-String | Write-Debug

        return Update-VSAItems @Params
    }#Process
}
Export-ModuleMember -Function Set-VSATenantModuleLicenses