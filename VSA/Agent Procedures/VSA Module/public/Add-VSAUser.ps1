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
    .PARAMETER FirstName
        Specifies user's first name.
    .PARAMETER LastName
        Specifies user's last name.
    .PARAMETER AdminName
        Specifies user's account name.
    .PARAMETER Email
        Specifies user's e-mail.
    .PARAMETER AdminRoleIds
        Specifies an Id of user's admin role.
    .PARAMETER AdminScopeIds
        Specifies an Id of user's admin scope.
    .PARAMETER AdminType
        Specifies Id of user's admin type.
    .PARAMETER DisableUntil
        Specifies time until user's account is disabled.
    .EXAMPLE
       Add-VSAUser -AdminName 'Login' -AdminPassword 'P@$$w0rd' -AdminRoleIds 2 -AdminScopeIds 2 -DefaultStaffOrgId 5 -DefaultStaffDepartmentId 10001 -FirstName 'John' -LastName 'Doe' -Email 'JohnDoe@example.mail'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    #[CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/users',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $AdminName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $AdminPassword,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $AdminType = 2,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [decimal] $AdminRoleIds,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [decimal] $AdminScopeIds,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $DefaultStaffOrgId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $DefaultStaffDepartmentId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $FirstName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $LastName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Email,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DisableUntil,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Attributes,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
    )
    
    [hashtable]$BodyHT = @{
            UserId                   = $(Get-Random -Minimum 100 -Maximum 999)
            AdminName                = $AdminName
            AdminPassword            = $AdminPassword
            Admintype                = [int]$AdminType
            AdminScopeIds            = $AdminScopeIds
            AdminRoleIds             = $AdminRoleIds
            FirstName                = $FirstName
            LastName                 = $LastName
            DefaultStaffOrgId        = [decimal]$DefaultStaffOrgId
            DefaultStaffDepartmentId = [decimal]$DefaultStaffDepartmentId
            Email                    = $Email
        }

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }

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

    $Result = Update-VSAItems @Params
    $Result | Out-String | Write-Verbose
    $Result | Out-String | Write-Debug

    if ($ExtendedOutput) { $Result = $Result | Select-Object -ExpandProperty Result }
    return $Result
}
Export-ModuleMember -Function Add-VSAUser