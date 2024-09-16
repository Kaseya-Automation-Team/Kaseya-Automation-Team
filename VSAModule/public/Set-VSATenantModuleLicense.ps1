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

        [parameter(DontShow, Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
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
        [string] $DateValue
    )

    DynamicParam {

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        [hashtable] $AuxParameters = @{ErrorAction = 'Stop'}
        if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

        [array] $script:Tenants = try {
            Get-VSATenant @AuxParameters | Select-Object Id, Ref
        } catch {
            $null
            Write-Error $_
        }

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

        if ( -not [string]::IsNullOrEmpty($TenantId) ) {

            $AuxParameters.Add('TenantId', $TenantId)

            [array]$Script:Licenses = try {
                Get-VSATenantModuleLicense @AuxParameters | Select-Object -ExpandProperty ModuleLicenses
            } catch {
                $null
                Write-Error $_
            }

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

        if ( 0 -lt $Script:Licenses.Count ) {
            $Script:Licenses[0].Limit = $Limit
            [string] $Body = $Script:Licenses | ConvertTo-Json
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

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "Set-VSATenantModuleLicense. $($Body | Out-String)"
        }

        [hashtable]$Params =@{
            URISuffix = $URISuffix
            Method    = 'PUT'
            Body      = $Body
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        return Invoke-VSARestMethod @Params
    }#Process
}
Export-ModuleMember -Function Set-VSATenantModuleLicenses


New-Alias -Name Set-VSATenantModuleLicenses -Value Set-VSATenantModuleLicense
Export-ModuleMember -Function Set-VSATenantModuleLicense -Alias Set-VSATenantModuleLicenses