function Update-VSAUser
{
    <#
    .Synopsis
       Updates a single user account record.
    .DESCRIPTION
       Updates a single user account record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserId
        Specifies a user account Id.
    .PARAMETER AdminName
        Specifies a user account name.
    .PARAMETER DefaultStaffDepartmentId
        Specifies the Department Id to which a user is added.
    .PARAMETER DefaultStaffOrgId
        Specifies the Organization Id to which a user is added.
    .PARAMETER DefaultStaffOrgName
        Specifies the Organization Name to which a user is added.
    .PARAMETER FirstName
        Specifies user's first name.
    .PARAMETER LastName
        Specifies user's last name.
    .PARAMETER Email
        Specifies user's e-mail.
    .PARAMETER AdminRoleIds
        Specifies Ids of user's admin roles.
    .PARAMETER AdminRoleNames
        Specifies user's admin roles.
    .PARAMETER AdminScopeIds
        Specifies Ids of user's admin scopes.
    .PARAMETER AdminScopeNames
        Specifies user's admin scopes.
    .PARAMETER AdminType
        Specifies Id of user's admin type.
    .EXAMPLE
       Update-VSAUser -UserId 10001 -AdminName 'Login' -AdminPassword 'P@$$w0rd' -AdminRoleIds 1, 2 -AdminScopeIds 3, 4 -DefaultStaffOrgId 5 -DefaultStaffDepartmentId 6 -FirstName 'John' -LastName 'Doe' -Email 'JohnDoe@example.mail'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if update was successful.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    #[CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
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
        [string] $URISuffix = 'api/v1.0/system/users/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [decimal] $UserId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string] $AdminPassword,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [decimal] $AdminType,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            foreach ($item in $_) {
                if ( -not [decimal]::TryParse($item, [ref]$null) ) {
                    throw "All elements must be numeric. '$item' is not a valid number."
                }
            }
            return $true
        })]
        [decimal[]] $AdminRoleIds,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            foreach ($item in $_) {
                if ( -not [decimal]::TryParse($item, [ref]$null) ) {
                    throw "All elements must be numeric. '$item' is not a valid number."
                }
            }
            return $true
        })]
        [decimal[]] $AdminScopeIds,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [decimal] $DefaultStaffOrgId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [decimal] $DefaultStaffDepartmentId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string] $FirstName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string] $LastName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string] $Email,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Attributes
    )

    DynamicParam {

            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
            [hashtable] $AuxParameters = @{}
            if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

            [array] $script:Users = Get-VSAUser @AuxParameters | Select UserId, AdminName
            [array] $script:Roles = Get-VSARoles @AuxParameters | Select-Object RoleId, RoleName
            [array] $script:Scopes = Get-VSAScope @AuxParameters | Select-Object ScopeId, ScopeName
            [array] $script:Organizations = Get-VSAOrganization @AuxParameters | Select-Object OrgId, OrgName

            $ParameterName = 'AdminName' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.ParameterSetName = 'ByName'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:Users | Select-Object -ExpandProperty AdminName
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

            $ParameterName = 'AdminRoleNames' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.ParameterSetName = 'ByName'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:Roles | Select-Object -ExpandProperty RoleName
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            
            $ParameterName = 'AdminScopeNames' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.ParameterSetName = 'ByName'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:Scopes | Select-Object -ExpandProperty ScopeName
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

            $ParameterName = 'DefaultStaffOrgName' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $ParameterAttribute.ParameterSetName = 'ByName'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:Organizations | Select-Object -ExpandProperty OrgName
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

            return $RuntimeParameterDictionary
        #}
    }# DynamicParam
    Begin {
        if ( -not $UserId ) {
            $UserId = $script:Users | Where-Object {$_.AdminName -eq $($PSBoundParameters.AdminName ) } | Select-Object -ExpandProperty UserId
        }
        if ( (0 -eq $AdminRoleIds.Count) -and (0 -lt ($PSBoundParameters.AdminRoleNames).Count) ) {
            $AdminRoleIds = $script:Roles  | Where-Object {$_.RoleName -in $($PSBoundParameters.AdminRoleNames ) } | Select-Object -ExpandProperty RoleId
        }
        if ( (0 -eq $AdminScopeIds.Count) -and (0 -lt ($PSBoundParameters.AdminScopeNames).Count) ) {
            $AdminScopeIds = $script:Scopes | Where-Object {$_.ScopeName -in $($PSBoundParameters.AdminScopeNames ) } | Select-Object -ExpandProperty ScopeId
        }
        if ( (-not $DefaultStaffOrgId) -and (-not [string]::IsNullOrEmpty($($PSBoundParameters.DefaultStaffOrgName))) ) {
            $DefaultStaffOrgId = $script:Organizations | Where-Object {$_.OrgName -eq $($PSBoundParameters.DefaultStaffOrgName ) } | Select-Object -ExpandProperty OrgId
        }
    }# Begin
    Process {
    
    [hashtable]$BodyHT = @{
        UserId                   = $UserId
        AdminName                = $AdminName
        AdminPassword            = $AdminPassword
        AdminScopeIds            = $AdminScopeIds
        AdminRoleIds             = $AdminRoleIds
        FirstName                = $FirstName
        LastName                 = $LastName
        DefaultStaffOrgId        = $DefaultStaffOrgId
        DefaultStaffDepartmentId = $DefaultStaffDepartmentId
        Email                    = $Email
        Attributes               = $Attributes
    }
    foreach ( $key in $BodyHT.Keys.Clone()  ) {
        if ( -not $BodyHT[$key]) { $BodyHT.Remove($key) }
    }


    [hashtable]$Params = @{
        URISuffix = $($URISuffix -f $UserId)
        Method    = 'PUT'
        Body      = $(ConvertTo-Json $BodyHT -Depth 5 -Compress)
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Update-VSAUser