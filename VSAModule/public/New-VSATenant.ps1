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

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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
        [string[]] $LicenseValues = @(),

        [Parameter(Mandatory = $false)]
        [array] $NamedRoleTypeLimits = @(), 

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
        [hashtable] $Attributes
    )
    
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

    $TenantUser = [ordered]@{
        UserName = $AdminUserName
        HashedPassword = $HashedPassword
        Password = $PlainPassword
        EMail = $EMail
    }

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
            $LicenseValue -match '{(.*?)\}' | Out-Null
            [hashtable] $items = $( ConvertFrom-StringData -StringData $($Matches[1] -replace '= ','=' -replace '; ',';' -split ';' -join "`n") )

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

    

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }

    if ( 0 -lt $NamedRoleTypeLimits.Count ) { $BodyHT.Add('NamedRoleTypeLimits', $NamedRoleTypeLimits) }

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }

    [string] $Body = ConvertTo-Json $BodyHT

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSATenant. Body: $Body"
    }

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'POST'
                            'Body'      = $Body
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSATenant. $($Params | Out-String)"
    }

    return Invoke-VSARestMethod @Params
    
}
New-Alias -Name Add-VSATenant -Value New-VSATenant
Export-ModuleMember -Function New-VSATenant -Alias Add-VSATenant