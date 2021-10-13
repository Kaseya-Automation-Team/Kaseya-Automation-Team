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
        Specifies a tenant partition.
    .PARAMETER Modules
        Array of modules to be activated.
    .EXAMPLE
       Set-VSATenantRoletypeLimit -TenantId 10001 -Modules 'Agent', 'Kaseya System Patch'
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
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [decimal] $TenantId,

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

        [array] $script:Roles = Get-VSARoleTypes @AuxParameters | Select-Object RoleTypeId, RoleTypeName
        [array] $script:Tenants = Get-VSATenants @AuxParameters | Select-Object RoleTypeId, RoleTypeName

        $ParameterName = 'RoleName' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ByName'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Roles | Select-Object -ExpandProperty RoleTypeName
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
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
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }# DynamicParam
    Begin {
        if ( -not [string]::IsNullOrEmpty($RoleTypeId) ) {
            $RoleTypeId = $script:Roles  | Where-Object {$_.RoleName -in $($PSBoundParameters.AdminRoleNames ) } | Select-Object -ExpandProperty RoleId
        }
        if ( 0 -eq $AdminScopeIds.Count ) {
            $AdminScopeIds = $script:Scopes | Where-Object {$_.ScopeName -in $($PSBoundParameters.AdminScopeNames ) } | Select-Object -ExpandProperty ScopeId
        }
        if ( -not $DefaultStaffOrgId ) {
            $DefaultStaffOrgId = $script:Organizations | Where-Object {$_.OrgName -eq $($PSBoundParameters.DefaultStaffOrgName ) } | Select-Object -ExpandProperty OrgId
        }
    }# Begin
    Process {

        $URISuffix = $URISuffix -f $TenantId
    
        $Body = ConvertTo-Json $TenantModues[$Modules]

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