function Remove-VSAUser
{
    <#
    .Synopsis
       Deletes a single user.
    .DESCRIPTION
       Deletes a single user.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserId
        Specifies a user account Id.
    .PARAMETER AdminName
        Specifies a user account name.
    .EXAMPLE
       Remove-VSAUser -UserId 10001
    .EXAMPLE
       Remove-VSAUser -VSAConnection $connection -UserId 10001
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
        .NOTES
        On hardened (post-2021) VSA builds this user-mutation endpoint may be blocked at the network
        layer. The call then fails with a VSAApiException whose .ConnectionReset is $true and
        .StatusCode is 0 (the connection is reset before any HTTP status is returned) -- it is not a
        403/404. Read-only user cmdlets (Get-VSAUser) are unaffected.
#>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ById')]
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

        [parameter(DontShow, Mandatory=$false,
            
            ParameterSetName = 'ByName')]
        [parameter(DontShow, Mandatory=$false,
            
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/users/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $UserId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
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
        [string] $AdminName
    )

    Begin {
        # A single targeted call resolves AdminName to UserId (F-44: no network calls during
        # parameter/command discovery; this only runs when the cmdlet actually executes).
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            [hashtable]$LookupParams = @{}
            if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
            [array]$Users = Get-VSAUser @LookupParams
            $UserId = $Users | Where-Object { $_.AdminName -eq $AdminName } | Select-Object -First 1 -ExpandProperty UserId
            if ([string]::IsNullOrEmpty($UserId)) {
                throw "Remove-VSAUser: No user found with AdminName '$AdminName'."
            }
        }
    }# Begin
    Process {

        return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $UserId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Remove-VSAUser