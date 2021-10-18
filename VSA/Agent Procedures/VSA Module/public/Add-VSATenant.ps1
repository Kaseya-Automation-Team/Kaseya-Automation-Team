function Add-VSATenant
{
    <#
    .Synopsis
       Adds a tenant partition.
    .DESCRIPTION
       Adds a tenant partition, including activated modules, activated roletypes, and license limits.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantName
        Specifies the Tenant Name.
    .PARAMETER UserName
        Specifies the User Name.
    .PARAMETER EMail
        Specifies the User's Email.
    .PARAMETER ForcePasswordChange
        Specifies if enforce password change at first user's login.
    .PARAMETER ModuleIds
        Array of modules to be activated.
    .PARAMETER LicenseValues
        Array of Licens Values. See help.kaseya.com/webhelp/EN/RESTAPI/9050000/index.asp#37656.htm.
    .PARAMETER NamedRoleTypeLimits
        Array of Role Type Limits. See help.kaseya.com/webhelp/EN/RESTAPI/9050000/index.asp#37656.htm.
    .EXAMPLE
       Add-VSATenant -TenantName 'NewTenantName' -Username 'NewTenantUser' -EMail 'NewTenantUser@domain.mail' -Password 'YourLongPasswordHere'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $TenantName,

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $UserName,

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch  "(?=(.*[0-9]))(?=.*[\!@#$%^&*()\\[\]{}\-_+=~`|:;`"'<>,./?])(?=.*[a-z])(?=(.*[A-Z]))(?=(.*)).{16,}" ) {
                throw "The password must contain both upper and lower case letters, numeric & non-alphaNumeric character. Its length must be at least 16 symbols"
            }
            return $true
        })]
        [string] $Password,

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$" ) {
                throw "Incorrect email"
            }
            return $true
        })]
        [string] $EMail,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("0", "1")]
        [string] $ForcePasswordChange,

        [Parameter(Mandatory = $false)]
        [array] $ModuleIds = @(),

        [Parameter(Mandatory = $false)]
        [array] $LicenseValues = @(),

        [Parameter(Mandatory = $false)]
        [array] $NamedRoleTypeLimits = @(), 

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Type,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $TimeZoneOffset,

        [parameter(DontShow,
            Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Attributes
    )
    
    [string] $HashName = 'SHA256'
    $HashStringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$Password$Username")) | `
    Foreach-Object  {
        [Void]$HashStringBuilder.Append($_.ToString("x2"))
    }

    $HashedPassword = $HashStringBuilder.ToString()

    $TenantUser = [ordered]@{
        UserName = $UserName
        HashedPassword = $HashedPassword
        Password = $Password
        EMail = $EMail
    }

    $BodyHT = [ordered]@{
        TenantUser = $TenantUser
        ModuleIds = $ModuleIds
        LicenseValues = $LicenseValues
        Ref = $TenantName
    }
    if ( -not [string]::IsNullOrEmpty($TimeZoneOffset) ) { $BodyHT.Add('TimeZoneOffset', [int]$TimeZoneOffset) }
    if ( -not [string]::IsNullOrEmpty($Type) ) { $BodyHT.Add('Type', $Type) }
    if ( -not [string]::IsNullOrEmpty($ForcePasswordChange) ) { $BodyHT.Add('ForcePasswordChange', [int]$ForcePasswordChange) }
    if ( 0 -lt $NamedRoleTypeLimits.Count ) { $BodyHT.Add('NamedRoleTypeLimits', $NamedRoleTypeLimits) }

    if ($Attributes) { $BodyHT.Add('Attributes', $Attributes) }

    [string] $Body = ConvertTo-Json $BodyHT

    $Body | Write-Debug

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'POST'
                            'Body'      = $Body
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Add-VSATenant