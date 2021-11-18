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
        Specifies ISO8601 formatted DateTime until which user's account is disabled.
    .EXAMPLE
       Add-VSAUser -AdminName 'Login' -AdminPassword 'P@$$w0rd' -AdminRoleIds 2 -AdminScopeIds 2 -DefaultStaffOrgId 5 -DefaultStaffDepartmentId 10001 -FirstName 'John' -LastName 'Doe' -Email 'JohnDoe@example.mail'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
    #>
    #[CmdletBinding(DefaultParameterSetName = 'ById')]
    [CmdletBinding()]
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
        [decimal[]] $AdminRoleIds,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [decimal[]] $AdminScopeIds,

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
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$") ) {
                throw "Invalid ISO8601 DateTime format"
            }
            return $true
        })]
        [string] $DisableUntil,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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