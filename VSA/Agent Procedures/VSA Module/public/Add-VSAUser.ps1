function Add-VSAUser
{
    <#
    .Synopsis
       Adds a single user account record.
    .DESCRIPTION
       Adds a single user account record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
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
    .PARAMETER AdminName
        Specifies user's account name.
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
    .PARAMETER DisableUntil
        Specifies time until user's account is disabled.
    .EXAMPLE
       Add-VSAUser -AdminName 'Login' -AdminPassword 'P@$$w0rd' -AdminRoleIds 1, 2 -AdminScopeIds 3, 4 -DefaultStaffOrgId 5 -DefaultStaffDepartmentId 6 -FirstName 'John' -LastName 'Doe' -Email 'JohnDoe@example.mail'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
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
        [string] $URISuffix = 'api/v1.0/system/users',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string] $AdminName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$true,
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
        [int] $AdminType = 2,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [decimal[]] $AdminRoleIds,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [decimal[]] $AdminScopeIds,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [decimal] $DefaultStaffOrgId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [decimal] $DefaultStaffDepartmentId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string] $FirstName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string] $LastName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string] $Email,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string] $DisableUntil,

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

            [array] $script:Roles = Get-VSARoles @AuxParameters | Select-Object RoleId, RoleName
            [array] $script:Scopes = Get-VSAScope @AuxParameters | Select-Object ScopeId, ScopeName
            [array] $script:Organizations = Get-VSAOrganization @AuxParameters | Select-Object OrgId, OrgName

            $ParameterName = 'AdminRoleNames' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
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
            $ParameterAttribute.Mandatory = $true
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
            $ParameterAttribute.Mandatory = $true
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
        if ( 0 -eq $AdminRoleIds.Count ) {
            $AdminRoleIds = $script:Roles  | Where-Object {$_.RoleName -in $($PSBoundParameters.AdminRoleNames ) } | Select-Object -ExpandProperty RoleId
        }
        if ( 0 -eq $AdminScopeIds.Count ) {
            $AdminScopeIds = $script:Scopes | Where-Object {$_.ScopeName -in $($PSBoundParameters.AdminScopeNames ) } | Select-Object -ExpandProperty ScopeId
        }
        if ( -not $DefaultStaffOrgId ) {
            $DefaultStaffOrgId = $script:Organizations | Where-Object {$_.OrgName -eq $($PSBoundParameters.DefaultStaffOrgName ) } | Select-Object -ExpandProperty OrgId
        }
    }# Begin
    Process {
    $URISuffix | Write-Debug
    
    [hashtable]$BodyHT = @{
            UserId                   = $(Get-Random -Minimum 100 -Maximum 999)
            AdminName                = $AdminName
            AdminPassword            = $AdminPassword
            Admintype                = $AdminType
            AdminScopeIds            = $AdminScopeIds
            AdminRoleIds             = $AdminRoleIds
            FirstName                = $FirstName
            LastName                 = $LastName
            DefaultStaffOrgId        = $DefaultStaffOrgId
            DefaultStaffDepartmentId = $DefaultStaffDepartmentId
            Email                    = $Email
        }

    if ($Attributes) { $BodyHT.Add('Attributes', $Attributes) }
    if ( -not [string]::IsNullOrEmpty($DisableUntil) ) { $BodyHT.Add('DisableUntil', $DisableUntil) }

    $Body = ConvertTo-Json $BodyHT

    $Body | Out-String | Write-Debug

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'POST'
                            'Body'      = $Body
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
    }
}
Export-ModuleMember -Function Add-VSAUser