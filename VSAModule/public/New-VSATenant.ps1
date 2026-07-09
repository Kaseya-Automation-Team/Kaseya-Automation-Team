function New-VSATenant
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
    .PARAMETER Ref
        Specifies the Tenant Name.
    .PARAMETER AdminUserName
        Specifies the Admin User Name.
    .PARAMETER Password
        Specifies the password as a SecureString. Password must be at least 16 characters with upper, lower, numeric, and special characters.
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
    .PARAMETER ScopeRef
        Specifies the scope to assign to the tenant admin user. Optional; documented on the
        TenantUser schema (see the URI above) but not required to create a tenant.
    .PARAMETER RoleRef
        Specifies the role to assign to the tenant admin user. Optional; documented on the
        TenantUser schema (see the URI above) but not required to create a tenant.
    .EXAMPLE
       $securePassword = ConvertTo-SecureString 'YourLongPasswordHere!' -AsPlainText -Force
       New-VSATenant -Ref 'NewTenantName' -AdminUserName 'NewTenantUser' -EMail 'NewTenantUser@domain.mail' -Password $securePassword
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUsernameAndPasswordParams','')]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Ref,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $AdminUserName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [securestring] $Password,

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
        # Each element accepts a [hashtable]/[pscustomobject] (preferred) or the legacy
        # "{ DataType= ..; Name= .. }" string.
        [object[]] $LicenseValues = @(),

        [Parameter(Mandatory = $false)]
        [array] $NamedRoleTypeLimits = @(),

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ScopeRef,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RoleRef,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Type,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $TimeZoneOffset,

        [parameter(DontShow,
            Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        # Accepts a [hashtable]/[pscustomobject] (preferred) or the legacy "Key=value" string.
        [object] $Attributes
    )
    process {
    
    [string] $HashName = 'SHA256'
    
    # Convert SecureString password to plaintext for hashing and API transmission
    $passwordPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($Password)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($passwordPtr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($passwordPtr)
    
    $HashStringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$PlainPassword$AdminUserName")) | `
    Foreach-Object  {
        [Void]$HashStringBuilder.Append($_.ToString("x2"))
    }

    $HashedPassword = $HashStringBuilder.ToString()

    # Both Password and HashedPassword are sent because both are documented TenantUser fields
    # (Add Tenant, help.vsa9.kaseya.com/help/Content/Modules/rest-api/37656.htm) — confirmed
    # against the official docs, not a guess (T-6.13 / F-55).
    $TenantUser = [ordered]@{
        UserName = $AdminUserName
        HashedPassword = $HashedPassword
        Password = $PlainPassword
        EMail = $EMail
    }
    if (-not [string]::IsNullOrEmpty($ScopeRef)) { $TenantUser.Add('ScopeRef', $ScopeRef) }
    if (-not [string]::IsNullOrEmpty($RoleRef))  { $TenantUser.Add('RoleRef', $RoleRef) }

    # The plaintext password now lives only inside $TenantUser (for JSON serialization below);
    # clear the standalone variable immediately so it doesn't linger in memory (T-5.5 / F-55).
    $PlainPassword = $null

    $BodyHT = [ordered]@{
        TenantUser = $TenantUser
        ModuleIds = $ModuleIds
    }
    if ( 0 -lt $LicenseValues.Count )
    {
        [hashtable[]]$LicenseValuesArray = @()
        [string[]] $LicenseFields = @("DataType", "Name", "StringValue", "DateValue", "zzValId", "LicenseType", "Limit", "zzVal")
        Foreach ( $LicenseValue in $LicenseValues )
        {
            [hashtable] $items = ConvertTo-VSAHashtable $LicenseValue

            # Copy keys to an array to avoid enumerating them directly on the hashtable
            $keys = @($items.Keys)
            # Remove elements not matching the expected pattern
            $keys | ForEach-Object {
                if ($_ -notin $LicenseFields) {
                    $items.Remove($_)
                }
            }

            $LicenseValuesArray += $items
        }
        $BodyHT.Add('LicenseValues', $LicenseValuesArray )
    }
    $BodyHT.Add('Ref', $Ref )
    if ( -not [string]::IsNullOrEmpty($TimeZoneOffset) ) { $BodyHT.Add('TimeZoneOffset', [int]$TimeZoneOffset) }
    if ( -not [string]::IsNullOrEmpty($Type) ) { $BodyHT.Add('Type', $Type) }
    if ( -not [string]::IsNullOrEmpty($ForcePasswordChange) ) { $BodyHT.Add('ForcePasswordChange', [int]$ForcePasswordChange) }


    if ( 0 -lt $NamedRoleTypeLimits.Count ) { $BodyHT.Add('NamedRoleTypeLimits', $NamedRoleTypeLimits) }

    if ( $null -ne $Attributes ) {
        [hashtable] $AttributesHT = ConvertTo-VSAHashtable $Attributes
        if ( 0 -lt $AttributesHT.Count ) { $BodyHT.Add('Attributes', $AttributesHT ) }
    }

    [string] $Body = ConvertTo-Json $BodyHT

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        # Never write the plaintext/hashed password to the debug stream (T-5.5 / F-55): redact
        # both password field values in the already-serialized JSON before logging it.
        $RedactedBody = $Body -replace '("Password"\s*:\s*)"[^"]*"', '$1"<redacted>"'
        $RedactedBody = $RedactedBody -replace '("HashedPassword"\s*:\s*)"[^"]*"', '$1"<redacted>"'
        Write-Debug "New-VSATenant. Body: $RedactedBody"
    }

    return Invoke-VSAWriteRequest -Body $Body -Method POST -URISuffix $URISuffix -VSAConnection $VSAConnection
    }
}
New-Alias -Name Add-VSATenant -Value New-VSATenant
Export-ModuleMember -Function New-VSATenant -Alias Add-VSATenant