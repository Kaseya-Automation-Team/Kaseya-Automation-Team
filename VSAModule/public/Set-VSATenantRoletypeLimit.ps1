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

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/limits/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric"
            }
            return $true
        })]
        [string] $Limit
    )
    DynamicParam {

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
        [hashtable] $AuxParameters = @{}
        if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

        [array] $script:Roles = try {Get-VSARoleTypes @AuxParameters -ErrorAction Stop | Select-Object RoleTypeId, RoleTypeName } catch { Write-Error $_ }
        [array] $script:Tenants = try {Get-VSATenants @AuxParameters -ErrorAction Stop | Select-Object Id, Ref } catch { Write-Error $_ }

        $ParameterName = 'RoleTypeName' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ByName'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Roles | Select-Object -ExpandProperty RoleTypeName
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        $ParameterName = 'RoleTypeId' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ById'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Roles | Select-Object -ExpandProperty RoleTypeId
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        $ParameterName = 'TenantName' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ByName'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Tenants | Select-Object -ExpandProperty Ref
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

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

        return $RuntimeParameterDictionary
    }# DynamicParam
    Begin {
        if ( [string]::IsNullOrEmpty($RoleTypeId) ) {
            $RoleTypeId   = $script:Roles | Where-Object { $_.RoleTypeName -eq $PSBoundParameters.RoleTypeName } | Select-Object -ExpandProperty RoleTypeId
            $RoleTypeName = $PSBoundParameters.RoleTypeName
        }
        if ( [string]::IsNullOrEmpty($RoleTypeName) ) {
            $RoleTypeName   = $script:Roles | Where-Object { $_.RoleTypeId -eq $PSBoundParameters.RoleTypeId } | Select-Object -ExpandProperty RoleTypeName
            $RoleTypeId = $PSBoundParameters.RoleTypeId
        }
        if ( [string]::IsNullOrEmpty($TenantId)  ) {
            $TenantId = $script:Tenants | Where-Object { $_.Ref -eq $PSBoundParameters.TenantName } | Select-Object -ExpandProperty Id
            $TenantName = $PSBoundParameters.TenantName
        }
        if ( [string]::IsNullOrEmpty($TenantName)  ) {
            $TenantName = $script:Tenants | Where-Object { $_.Id -eq $PSBoundParameters.TenantId } | Select-Object -ExpandProperty Ref
            $TenantId = $PSBoundParameters.TenantId
        }
    }# Begin
    Process {

        $URISuffix = $URISuffix -f $TenantId
        [string] $Body = ConvertTo-Json @(
                            @{
                                RoleName = $RoleTypeName
                                RoleType = [decimal]$RoleTypeId
                                Limit    = [decimal]$Limit
                            }
                        )
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

Export-ModuleMember -Function Set-VSATenantRoletypeLimit