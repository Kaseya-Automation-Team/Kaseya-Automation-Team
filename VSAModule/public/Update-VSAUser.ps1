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
    .PARAMETER Attributes
        Specifies additional attributes to send in the request body.
    .PARAMETER AdminPassword
        Specifies the user's password as a SecureString.
    .EXAMPLE
       $securePassword = ConvertTo-SecureString 'P@$$w0rd!' -AsPlainText -Force
       Update-VSAUser -UserId 10001 -AdminName 'Login' -AdminPassword $securePassword -AdminRoleIds 1, 2 -AdminScopeIds 3, 4 -DefaultStaffOrgId 5 -DefaultStaffDepartmentId 6 -FirstName 'John' -LastName 'Doe' -Email 'JohnDoe@example.mail'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if update was successful.
        .NOTES
        On hardened (post-2021) VSA builds this user-mutation endpoint may be blocked at the network
        layer. The call then fails with a VSAApiException whose ConnectionReset property is $true and
        the StatusCode is 0 (the connection is reset before any HTTP status is returned) -- it is not a
        403/404. Read-only user cmdlets (Get-VSAUser) are unaffected.
#>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ById')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUsernameAndPasswordParams','')]
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

            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,

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
        [ValidateNotNull()]
        [securestring] $AdminPassword,

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
        [hashtable] $Attributes,

        # ByName selectors. These were a DynamicParam block that eagerly called Get-VSAUser/
        # Get-VSARoles/Get-VSAScope/Get-VSAOrganization on every tab-completion and Get-Command
        # introspection (F-44 / A-2). They are now static parameters with lazy, best-effort
        # [ArgumentCompleter]s; Name->Id resolution happens in Begin, only when the cmdlet runs.
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSAUser @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty AdminName |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [ValidateNotNullOrEmpty()]
        [string[]] $AdminName,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSARoles @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty RoleName |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [string[]] $AdminRoleNames,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSAScope @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty ScopeName |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [string[]] $AdminScopeNames,

        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSAOrganization @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty OrgName |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { Write-Debug "Argument completer suppressed error: $_" }
        })]
        [string[]] $DefaultStaffOrgName
    )

    Begin {
        # Resolve the ByName selectors to their Ids with single targeted lookups, only when the
        # cmdlet actually runs -- never during parameter/command discovery (F-44 / A-2). Logic and
        # variable targets are unchanged from the former DynamicParam+Begin; only the data source
        # moved from eagerly-cached module-scope arrays to on-demand calls here.
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            [hashtable] $AuxParameters = @{}
            if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

            if ( -not $UserId ) {
                # Resolve into a LOCAL and verify BEFORE assigning: an unresolved name previously left
                # $UserId empty with no check at all, which silently built a malformed target URL
                # instead of reporting the unknown user (F-4).
                $ResolvedUserId = Get-VSAUser @AuxParameters | Where-Object {$_.AdminName -eq $AdminName } | Select-Object -First 1 -ExpandProperty UserId
                if ( [string]::IsNullOrEmpty($ResolvedUserId) ) {
                    throw "Update-VSAUser: No user found with AdminName '$AdminName'."
                }
                $UserId = $ResolvedUserId
            }
            # Each name->Id lookup below verifies its result before assigning. An unresolved name
            # otherwise leaves the target empty/0, and the body-prune further down then drops that
            # key entirely: the caller's explicit request would be silently ignored rather than
            # reported (F-4).
            if ( (0 -eq $AdminRoleIds.Count) -and (0 -lt $AdminRoleNames.Count) ) {
                [array]$ResolvedRoleIds = Get-VSARoles @AuxParameters | Where-Object {$_.RoleName -in $AdminRoleNames } | Select-Object -ExpandProperty RoleId
                if ( 0 -eq $ResolvedRoleIds.Count ) {
                    throw "Update-VSAUser: No roles found matching: $($AdminRoleNames -join ', ')."
                }
                $AdminRoleIds = $ResolvedRoleIds
            }
            if ( (0 -eq $AdminScopeIds.Count) -and (0 -lt $AdminScopeNames.Count) ) {
                [array]$ResolvedScopeIds = Get-VSAScope @AuxParameters | Where-Object {$_.ScopeName -in $AdminScopeNames } | Select-Object -ExpandProperty ScopeId
                if ( 0 -eq $ResolvedScopeIds.Count ) {
                    throw "Update-VSAUser: No scopes found matching: $($AdminScopeNames -join ', ')."
                }
                $AdminScopeIds = $ResolvedScopeIds
            }
            if ( (-not $DefaultStaffOrgId) -and (-not [string]::IsNullOrEmpty($DefaultStaffOrgName)) ) {
                $ResolvedStaffOrgId = Get-VSAOrganization @AuxParameters | Where-Object {$_.OrgName -eq $DefaultStaffOrgName } | Select-Object -First 1 -ExpandProperty OrgId
                if ( [string]::IsNullOrEmpty("$ResolvedStaffOrgId") ) {
                    throw "Update-VSAUser: No organization found with name '$DefaultStaffOrgName'."
                }
                $DefaultStaffOrgId = $ResolvedStaffOrgId
            }

            # The Process body-prune keeps only keys present in $PSBoundParameters. In the ByName set
            # these Ids are resolved here (not bound from input), so without registering them they
            # would be silently dropped from the update body (F-25). Register the ones we resolved.
            if ( $UserId )                { $PSBoundParameters['UserId'] = $UserId }
            if ( $AdminRoleIds.Count )    { $PSBoundParameters['AdminRoleIds'] = $AdminRoleIds }
            if ( $AdminScopeIds.Count )   { $PSBoundParameters['AdminScopeIds'] = $AdminScopeIds }
            if ( $DefaultStaffOrgId )     { $PSBoundParameters['DefaultStaffOrgId'] = $DefaultStaffOrgId }
        }
    }# Begin
    Process {

    # Convert SecureString password to plaintext for API transmission if provided
    $PasswordForBody = $AdminPassword
    if ($AdminPassword -and $AdminPassword -is [securestring]) {
        $passwordPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($AdminPassword)
        $PasswordForBody = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($passwordPtr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($passwordPtr)
    }

    [hashtable]$BodyHT = @{
        UserId                   = $UserId
        AdminName                = $AdminName
        AdminPassword            = $PasswordForBody
        AdminScopeIds            = $AdminScopeIds
        AdminRoleIds             = $AdminRoleIds
        FirstName                = $FirstName
        LastName                 = $LastName
        DefaultStaffOrgId        = $DefaultStaffOrgId
        DefaultStaffDepartmentId = $DefaultStaffDepartmentId
        Email                    = $Email
        Attributes               = $Attributes
    }

    # The plaintext password now lives only inside $BodyHT (for JSON serialization below); clear
    # the standalone variable immediately so it doesn't linger in memory (T-5.5 / F-55).
    $PasswordForBody = $null

    # Prune by whether the caller actually bound the parameter, not by truthiness (F-52): a
    # truthiness check would silently drop legitimate values like 0 or '' that a caller explicitly
    # asked to send.
    foreach ( $key in @($BodyHT.Keys)  ) {
        if ( -not $PSBoundParameters.ContainsKey($key)) { $BodyHT.Remove($key) }
    }

    return Invoke-VSAWriteRequest -Body ($(ConvertTo-Json $BodyHT -Depth 5 -Compress)) -Method 'PUT' -URISuffix ($($URISuffix -f $UserId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Update-VSAUser